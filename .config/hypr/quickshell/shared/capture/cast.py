#!/usr/bin/env python3

import json, os, re, shutil, signal, socket, ssl, struct, subprocess, sys, tempfile, threading, time
import urllib.parse, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape

RUN = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
RTSP, SSDP, HTTP = 7236, 7238, 7240
STATE = os.path.join(RUN, "cast-state")


def sh(cmd, inp=None):
    try:
        return subprocess.run(cmd, input=inp, capture_output=True, text=True, timeout=60).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ""


def note(title, body=""):
    subprocess.run(["notify-send", "-e", "-a", "Cast", "-i", "video-display", title, body])


def state(s):
    with open(STATE + ".tmp", "w") as f:
        f.write(json.dumps(s) if s else "")
    os.replace(STATE + ".tmp", STATE)


def chromecasts():
    found = {}
    for line in sh(["avahi-browse", "-rtp", "_googlecast._tcp"]).splitlines():
        f = line.split(";", 9)
        if len(f) < 10 or f[0] != "=" or f[2] != "IPv4":
            continue
        txt = dict(t.split("=", 1) for t in re.findall(r'"([^"]*)"', f[9]) if "=" in t)
        found[f[7]] = {"kind": "cast", "target": f"{f[7]}:{f[8]}", "name": txt.get("fn") or f[3]}
    return list(found.values())


def miracasts():
    found = {}
    for line in sh(["avahi-browse", "-rtp", "_display._tcp"]).splitlines():
        f = line.split(";", 9)
        if len(f) < 10 or f[0] != "=" or f[2] != "IPv4":
            continue
        name = re.sub(r"\\(\d{3})", lambda m: chr(int(m.group(1))), f[3])
        found[f[7]] = {"kind": "miracast", "target": f"{f[7]}:{f[8]}", "name": re.sub(r"-[A-Z0-9]{3}$", "", name)}
    return list(found.values())


def nm(*a):
    return sh(["busctl", "--json=short", *a])


NM = "org.freedesktop.NetworkManager"
P2P = NM + ".Device.WifiP2P"
SOURCE_IES = "00:00:06:00:90:1c:44:00:c8"
LINK = "cast-direct"


def p2p_iface():
    for line in sh(["nmcli", "-t", "-f", "DEVICE,TYPE", "device"]).splitlines():
        if line.endswith(":wifi-p2p"):
            return line.split(":")[0]
    return ""


def directs():
    iface = p2p_iface()
    if not iface:
        return []
    try:
        path = json.loads(nm("call", NM, "/org/freedesktop/NetworkManager", NM, "GetDeviceByIpIface", "s", iface))["data"][0]
        nm("call", NM, path, P2P, "StartFind", "a{sv}", "1", "timeout", "i", "6")
        time.sleep(4)
        peers = json.loads(nm("get-property", NM, path, P2P, "Peers"))["data"]
    except (ValueError, KeyError, IndexError):
        return []
    out = []
    for p in peers:
        try:
            prop = lambda k: json.loads(nm("get-property", NM, p, NM + ".WifiP2PPeer", k))["data"]
            ies = prop("WfdIEs")
            if len(ies) >= 5 and ies[4] & 3 in (1, 3):
                out.append({"kind": "direct", "target": prop("HwAddress"), "name": prop("Name")})
        except (ValueError, KeyError):
            pass
    return out


def describe(loc):
    root = ET.fromstring(urllib.request.urlopen(loc, timeout=2).read())
    for e in root.iter():
        e.tag = e.tag.split("}")[-1]
    for sv in root.iter("service"):
        if "AVTransport" in (sv.findtext("serviceType") or ""):
            base = root.findtext("URLBase") or loc
            return {"kind": "dlna", "target": urllib.parse.urljoin(base, sv.findtext("controlURL") or ""),
                    "name": root.findtext(".//device/friendlyName") or urllib.parse.urlparse(loc).hostname}
    return None


def renderers():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
    try:
        s.bind(("0.0.0.0", SSDP))
    except OSError:
        pass
    s.settimeout(0.4)
    msgs = [("M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\n"
             f"ST: {st}\r\n\r\n").encode() for st in ("urn:schemas-upnp-org:device:MediaRenderer:1",
                                                      "urn:schemas-upnp-org:service:AVTransport:1", "ssdp:all")]
    locs, end = set(), time.time() + 3
    try:
        for msg in msgs * 2:
            s.sendto(msg, ("239.255.255.250", 1900))
        while time.time() < end:
            try:
                m = re.search(rb"(?im)^location:\s*(\S+)", s.recvfrom(4096)[0])
                if m:
                    locs.add(m.group(1).decode())
            except socket.timeout:
                pass
    except OSError:
        pass
    out = []
    for loc in locs:
        try:
            d = describe(loc)
            if d:
                out.append(d)
        except Exception:
            pass
    return out


def scan():
    res = {}
    jobs = [threading.Thread(target=lambda k=k, f=f: res.__setitem__(k, f()))
            for k, f in (("cast", chromecasts), ("dlna", renderers), ("miracast", miracasts), ("direct", directs))]
    for j in jobs:
        j.start()
    for j in jobs:
        j.join()
    tvs, names = [], set()
    for k in ("direct", "miracast", "cast", "dlna"):
        tvs += [t for t in res.get(k, []) if t["name"] not in names]
        names = {t["name"] for t in tvs}
    print(json.dumps(sorted(tvs, key=lambda t: t["name"].lower())))


def area(mode):
    mons = json.loads(sh(["hyprctl", "-j", "monitors"]) or "[]")
    if mode == "screen":
        o = sh(["slurp", "-o", "-f", "%o"]).strip() if len(mons) > 1 else (mons[0]["name"] if mons else "")
        return ["-o", o] if o else None
    if mode == "window":
        ws = [m["activeWorkspace"]["id"] for m in mons]
        boxes = [f"{c['at'][0]},{c['at'][1]} {c['size'][0]}x{c['size'][1]}"
                 for c in json.loads(sh(["hyprctl", "-j", "clients"]) or "[]") if c["mapped"] and c["workspace"]["id"] in ws]
        g = sh(["slurp", "-r"], "\n".join(boxes))
    else:
        g = sh(["slurp", "-d"])
    return ["-g", g.strip()] if g.strip() else None


X264 = ["-c", "libx264", "-r", "30", "-p", "preset=ultrafast", "-p", "tune=zerolatency", "-p", "g=15"]
COLOR = ["-p", "colorspace=bt709", "-p", "color_primaries=bt709", "-p", "color_trc=bt709", "-p", "color_range=tv"]
RATE = 16000000
PACE = 1344 * 8 / (RATE * 2.5)


def mirror_codec(fps, high):
    if os.path.exists("/dev/nvidiactl") and "h264_nvenc" in sh(["ffmpeg", "-hide_banner", "-encoders"]):
        return ["-c", "h264_nvenc", "-r", str(fps), "-p", "preset=p3", "-p", "tune=ull", "-p", "rc=cbr", "-p", f"b={RATE}",
                "-p", f"maxrate={RATE}", "-p", f"bufsize={RATE // 8}", "-p", "bf=0", "-p", f"g={fps // 2}",
                "-p", "profile=" + ("high" if high else "baseline"), *COLOR]
    return ["-c", "libx264", "-r", str(fps), "-p", "preset=veryfast", "-p", "tune=zerolatency", "-p", "profile=baseline",
            "-p", f"g={fps // 2}", "-p", f"b={RATE // 2}", "-p", f"maxrate={RATE // 2}", "-p", f"bufsize={RATE // 16}", *COLOR]


def capture(args, vf="scale=-2:1080", audio=True, codec=X264):
    cmd = ["wf-recorder", "-y", *args, *codec, "-x", "yuv420p", "-F", vf, "-m", "mpegts", "-f", "pipe:1"]
    sink = sh(["pactl", "get-default-sink"]).strip()
    if sink and audio:
        cmd[2:2] = [f"--audio={sink}.monitor", "-C", "aac"]
    return subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)


class Serve(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_HEAD(self):
        self.route(False)

    def do_GET(self):
        self.route(True)

    def head(self, ctype, extra=()):
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        for k, v in extra:
            self.send_header(k, v)
        self.end_headers()

    def route(self, body):
        srv, p = self.server, urllib.parse.urlparse(self.path).path
        if p == "/live.ts":
            self.head("video/mp2t", [("transferMode.dlna.org", "Streaming"),
                                     ("contentFeatures.dlna.org", "DLNA.ORG_OP=00;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000")])
            if body:
                srv.stream(self.wfile)
            return
        f = os.path.join(srv.dir, os.path.basename(p))
        if p.startswith("/hls/") and os.path.isfile(f):
            data = open(f, "rb").read()
            self.head("application/vnd.apple.mpegurl" if f.endswith(".m3u8") else "video/mp2t", [("Content-Length", str(len(data)))])
            if body:
                self.wfile.write(data)
            return
        self.send_error(404)


class Server(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, d, args):
        try:
            super().__init__(("0.0.0.0", HTTP), Serve)
        except OSError:
            super().__init__(("0.0.0.0", 0), Serve)
        self.dir, self.args, self.procs = d, args, []
        self.watching, self.seen, self.idle = 0, False, time.time()

    def stream(self, out):
        rec = capture(self.args)
        self.procs.append(rec)
        self.watching += 1
        self.seen = True
        try:
            while chunk := rec.stdout.read1(65536):
                out.write(chunk)
        except OSError:
            pass
        finally:
            rec.kill()
            self.watching -= 1
            self.idle = time.time()


def varint(n):
    out = b""
    while True:
        b, n = n & 0x7F, n >> 7
        if not n:
            return out + bytes([b])
        out += bytes([b | 0x80])


def readvar(d, i):
    n = s = 0
    while True:
        b = d[i]
        i += 1
        n |= (b & 0x7F) << s
        s += 7
        if b < 0x80:
            return n, i


def unpb(d):
    i, f = 0, {}
    while i < len(d):
        key, i = readvar(d, i)
        if key & 7 == 0:
            f[key >> 3], i = readvar(d, i)
        elif key & 7 == 2:
            n, i = readvar(d, i)
            f[key >> 3], i = d[i:i + n], i + n
        else:
            break
    return f


CONN, BEAT = "urn:x-cast:com.google.cast.tp.connection", "urn:x-cast:com.google.cast.tp.heartbeat"
RECV, MEDIA = "urn:x-cast:com.google.cast.receiver", "urn:x-cast:com.google.cast.media"
PLAYER = "CC1AD845"


class Chromecast:
    def __init__(self, host, port):
        ctx = ssl.create_default_context()
        ctx.check_hostname, ctx.verify_mode = False, ssl.CERT_NONE
        self.s = ctx.wrap_socket(socket.create_connection((host, port), timeout=10))

    def send(self, ns, msg, dest="receiver-0"):
        body = json.dumps(msg).encode()
        d = b"".join([varint(1 << 3), varint(0)] +
                     [varint(n << 3 | 2) + varint(len(v)) + v for n, v in ((2, b"sender-0"), (3, dest.encode()), (4, ns.encode()))] +
                     [varint(5 << 3), varint(0), varint(6 << 3 | 2), varint(len(body)), body])
        self.s.sendall(struct.pack(">I", len(d)) + d)

    def exact(self, n):
        b = b""
        while len(b) < n:
            c = self.s.recv(n - len(b))
            if not c:
                raise ConnectionError("tv closed the connection")
            b += c
        return b

    def recv(self):
        f = unpb(self.exact(struct.unpack(">I", self.exact(4))[0]))
        ns, msg = f.get(4, b"").decode(), json.loads(f.get(6, b"{}") or b"{}")
        if ns == BEAT and msg.get("type") == "PING":
            self.send(BEAT, {"type": "PONG"}, "receiver-0")
        return ns, msg

    def app(self, msg):
        if msg.get("type") != "RECEIVER_STATUS":
            return None
        return next((a for a in msg.get("status", {}).get("applications", []) if a.get("appId") == PLAYER), False)


def chromecast(target, url, ready):
    host, port = target.rsplit(":", 1)
    cc = Chromecast(host, int(port))
    cc.send(CONN, {"type": "CONNECT"})
    cc.send(RECV, {"type": "LAUNCH", "appId": PLAYER, "requestId": 1})
    app, end = None, time.time() + 20
    while not app:
        if time.time() > end:
            raise TimeoutError("tv didn't open the player")
        app = cc.app(cc.recv()[1])
    ready()
    tid = app["transportId"]
    cc.send(CONN, {"type": "CONNECT"}, tid)
    cc.send(MEDIA, {"type": "LOAD", "requestId": 2, "autoplay": True,
                    "media": {"contentId": url, "contentType": "application/x-mpegURL", "streamType": "LIVE"}}, tid)
    return cc, app["sessionId"]


def watch_chromecast(cc, live):
    cc.s.settimeout(5)
    while True:
        try:
            ns, msg = cc.recv()
        except socket.timeout:
            cc.send(BEAT, {"type": "PING"})
            continue
        if cc.app(msg) is False:
            return
        t = msg.get("type")
        if t in ("LOAD_FAILED", "LOAD_CANCELLED"):
            raise RuntimeError("tv couldn't play the stream")
        if t == "MEDIA_STATUS":
            if any(s.get("playerState") == "PLAYING" for s in msg.get("status", [])):
                live()
            if any(s.get("idleReason") in ("ERROR", "CANCELLED") for s in msg.get("status", [])):
                return


def mice(cmd, name, sid, port=0):
    tlv = lambda t, v: struct.pack(">BH", t, len(v)) + v
    body = tlv(0, (name + "\0").encode("utf-16-le")) + (tlv(2, struct.pack(">H", port)) if port else b"") + tlv(3, sid)
    return struct.pack(">HBB", len(body) + 4, 1, cmd) + body


CEA = {8: (1920, 1080, 60), 7: (1920, 1080, 30), 6: (1280, 720, 60), 5: (1280, 720, 30), 0: (640, 480, 60)}


def link_down():
    sh(["nmcli", "connection", "delete", LINK])


def link_up(mac):
    link_down()
    sh(["nmcli", "connection", "add", "type", "wifi-p2p", "con-name", LINK, "ifname", p2p_iface(), "save", "no",
        "connection.autoconnect", "no", "wifi-p2p.peer", mac, "wifi-p2p.wfd-ies", SOURCE_IES, "ipv6.method", "disabled"])
    return subprocess.Popen(["sh", "-c", f"for i in 1 2 3 4 5; do nmcli -w 11 connection up {LINK} && exit 0; sleep 1; done; exit 1"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


class Miracast:
    def __init__(self, target, args, procs, direct=False):
        self.args, self.procs = args, procs
        self.sid, self.name, self.seq, self.buf = os.urandom(16), socket.gethostname(), 0, b""
        self.c = self.ctl = self.link = None
        try:
            self.ls = socket.create_server(("0.0.0.0", RTSP))
        except OSError:
            self.ls = socket.create_server(("0.0.0.0", 0))
        if not direct:
            host, port = target.rsplit(":", 1)
            self.ctl = socket.create_connection((host, int(port)), timeout=10)
            self.ctl.sendall(mice(1, self.name, self.sid, self.ls.getsockname()[1]))
        else:
            self.link = link_up(target)
        self.ls.settimeout(60 if direct else 30)
        try:
            self.c = self.ls.accept()[0]
        except socket.timeout:
            if self.link and self.link.poll():
                raise RuntimeError("tv refused the wifi direct link, accept it on the tv and try again") from None
            raise TimeoutError("tv never called back, a firewall is probably blocking 7236. InstallScripts/apply.sh opens it") from None
        self.c.settimeout(20)
        self.c.setsockopt(socket.IPPROTO_TCP, socket.TCP_USER_TIMEOUT, 30000)
        self.host, self.me = self.c.getpeername()[0], self.c.getsockname()[0]

    def more(self):
        b = self.c.recv(65536)
        if not b:
            raise ConnectionError("tv hung up")
        self.buf += b

    def read(self):
        while b"\r\n\r\n" not in self.buf:
            self.more()
        head, self.buf = self.buf.split(b"\r\n\r\n", 1)
        lines = head.decode(errors="replace").split("\r\n")
        h = {k.strip().lower(): v.strip() for k, _, v in (l.partition(":") for l in lines[1:])}
        n = int(h.get("content-length", 0))
        while len(self.buf) < n:
            self.more()
        body, self.buf = self.buf[:n].decode(errors="replace"), self.buf[n:]
        return lines[0].split(" ", 2), h, body

    def ask(self, method, url="rtsp://localhost/wfd1.0", body="", extra=""):
        self.seq += 1
        msg = f"{method} {url} RTSP/1.0\r\nCSeq: {self.seq}\r\n{extra}"
        if body:
            msg += f"Content-Type: text/parameters\r\nContent-Length: {len(body)}\r\n"
        self.c.sendall((msg + "\r\n" + body).encode())
        return self.seq

    def ok(self, h, extra=""):
        self.c.sendall(f"RTSP/1.0 200 OK\r\nCSeq: {h.get('cseq', '0')}\r\n{extra}\r\n".encode())

    def formats(self, caps):
        modes = caps.get("wfd_video_formats", "").split(", ")
        first = modes[0].split()
        native = int(first[0], 16)
        rows = [first[2:5]] + [m.split()[:3] for m in modes[1:]]
        row = next((r for r in rows if int(r[0], 16) & 2), rows[0])
        prof, level, cea = int(row[0], 16), row[1], int(row[2], 16)
        if not native & 7:
            cea |= 1 << (native >> 3)
        bit = next((b for b in CEA if cea >> b & 1), 0)
        self.size = CEA[bit]
        self.high = bool(prof & 2)
        self.audio = "AAC" in caps.get("wfd_audio_codecs", "")
        self.port = int(re.search(r"unicast (\d+)", caps.get("wfd_client_rtp_ports", "")).group(1))
        lines = [f"wfd_video_formats: {bit << 3:02x} 00 {(prof & -prof):02x} {level} {1 << bit:08x} 00000000 00000000 00 0000 0000 00 none none",
                 f"wfd_presentation_URL: rtsp://{self.me}/wfd1.0/streamid=0 none",
                 f"wfd_client_rtp_ports: RTP/AVP/UDP;unicast {self.port} 0 mode=play"]
        if self.audio:
            lines.insert(1, "wfd_audio_codecs: AAC 00000001 00")
        return "\r\n".join(lines) + "\r\n"

    def stream(self):
        w, h, fps = self.size
        vf = (f"scale={w}:{h}:force_original_aspect_ratio=decrease:force_divisible_by=2:out_color_matrix=bt709:out_range=tv,"
              f"pad={w}:{h}:(ow-iw)/2:(oh-ih)/2,format=yuv420p")
        rec = capture(self.args, vf, self.audio, mirror_codec(fps, self.high))
        mux = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-fflags", "nobuffer", "-probesize", "500000", "-analyzeduration", "200000", "-i", "pipe:0",
                                "-map", "0:v", "-map", "0:a?", "-c", "copy", "-streamid", "0:0x1011", "-streamid", "1:0x1100", "-mpegts_pmt_start_pid", "0x100",
                                "-muxdelay", "0", "-muxpreload", "0", "-flush_packets", "1", "-pcr_period", "20", "-pat_period", "0.1",
                                "-f", "mpegts", "pipe:1"], stdin=rec.stdout, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        rec.stdout.close()
        self.procs += [rec, mux]
        def send():
            s, seq, ssrc, t0 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM), 0, struct.unpack(">I", os.urandom(4))[0], time.monotonic()
            s.setsockopt(socket.IPPROTO_IP, socket.IP_TOS, 0xA0)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1 << 21)
            due = time.monotonic()
            while len(chunk := mux.stdout.read(1316)) == 1316:
                now = time.monotonic()
                if due > now:
                    time.sleep(due - now)
                due = max(due, now) + PACE
                ts = int((now - t0) * 90000) & 0xFFFFFFFF
                try:
                    s.sendto(struct.pack(">BBHII", 0x80, 33, seq, ts, ssrc) + chunk, (self.host, self.port))
                except OSError:
                    pass
                seq = (seq + 1) & 0xFFFF
        threading.Thread(target=send, daemon=True).start()
        return mux

    def run(self, live):
        mux, want = None, {self.ask("OPTIONS", "*", extra="Require: org.wfa.wfd1.0\r\n"): "m1"}
        while True:
            try:
                first, h, body = self.read()
            except socket.timeout:
                if mux and mux.poll() is not None:
                    raise RuntimeError("screen capture stopped")
                self.ask("GET_PARAMETER")
                continue
            if first[0].startswith("RTSP/"):
                if first[1] != "200":
                    raise RuntimeError("tv said " + " ".join(first[1:]))
                step = want.pop(int(h.get("cseq", 0)), "")
                if step == "m3":
                    caps = dict(l.split(":", 1) for l in body.splitlines() if ":" in l)
                    want[self.ask("SET_PARAMETER", body=self.formats({k.strip(): v.strip() for k, v in caps.items()}))] = "m4"
                elif step == "m4":
                    self.ask("SET_PARAMETER", body="wfd_trigger_method: SETUP\r\n")
                continue
            method = first[0]
            if method == "OPTIONS":
                self.ok(h, "Public: org.wfa.wfd1.0, SETUP, TEARDOWN, PLAY, PAUSE, GET_PARAMETER, SET_PARAMETER\r\n")
                want[self.ask("GET_PARAMETER", body="wfd_video_formats\r\nwfd_audio_codecs\r\nwfd_client_rtp_ports\r\n")] = "m3"
            elif method == "SETUP":
                self.ok(h, f"Session: 6B8B4567;timeout=30\r\nTransport: RTP/AVP/UDP;unicast;client_port={self.port};server_port=19000\r\n")
            elif method == "PLAY":
                self.ok(h, "Session: 6B8B4567\r\nRange: npt=now-\r\n")
                mux = mux or self.stream()
                live()
            elif method == "TEARDOWN":
                self.ok(h, "Session: 6B8B4567\r\n")
                return
            else:
                self.ok(h)

    def close(self):
        for f in (lambda: self.ask("SET_PARAMETER", body="wfd_trigger_method: TEARDOWN\r\n"),
                  lambda: self.ctl and self.ctl.sendall(mice(2, self.name, self.sid))):
            try:
                f()
            except Exception:
                pass
        for sk in (self.c, self.ctl, self.ls):
            if sk:
                sk.close()
        if self.link:
            self.link.kill()
            link_down()


def soap(url, action, args=""):
    body = ('<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
            's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
            f'<u:{action} xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID>{args}</u:{action}>'
            '</s:Body></s:Envelope>')
    req = urllib.request.Request(url, body.encode(), {"Content-Type": 'text/xml; charset="utf-8"',
                                                      "SOAPAction": f'"urn:schemas-upnp-org:service:AVTransport:1#{action}"'})
    urllib.request.urlopen(req, timeout=8).read()


def dlna(target, url):
    didl = ('<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" '
            'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/"><item id="0" parentID="-1" restricted="1">'
            '<dc:title>Screen</dc:title><upnp:class>object.item.videoItem</upnp:class>'
            f'<res protocolInfo="http-get:*:video/mp2t:*">{escape(url)}</res></item></DIDL-Lite>')
    try:
        soap(target, "Stop")
    except Exception:
        pass
    soap(target, "SetAVTransportURI", f"<CurrentURI>{escape(url)}</CurrentURI><CurrentURIMetaData>{escape(didl)}</CurrentURIMetaData>")
    soap(target, "Play", "<Speed>1</Speed>")


def unspeak():
    for line in sh(["pactl", "list", "short", "modules"]).splitlines():
        if "sink_name=cast " in line + " ":
            sh(["pactl", "unload-module", line.split()[0]])


class Speaker:
    def __init__(self, name):
        unspeak()
        self.old = sh(["pactl", "get-default-sink"]).strip()
        if self.old == "cast":
            self.old = ""
        desc = name.replace('"', "")
        self.mod = sh(["pactl", "load-module", "module-null-sink", "sink_name=cast", f'device.description="{desc}"']).strip()
        vol = re.search(r"(\d+)%", sh(["pactl", "get-sink-volume", self.old]))
        if vol:
            sh(["pactl", "set-sink-volume", "cast", vol.group(1) + "%"])
        self.move("cast")

    def move(self, sink):
        sh(["pactl", "set-default-sink", sink])
        for line in sh(["pactl", "list", "short", "sink-inputs"]).splitlines():
            sh(["pactl", "move-sink-input", line.split()[0], sink])

    def close(self):
        if self.old:
            self.move(self.old)
        if self.mod:
            sh(["pactl", "unload-module", self.mod])


def local_ip(host):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect((host, 9))
        return s.getsockname()[0]
    finally:
        s.close()


def stop():
    try:
        pid = json.load(open(STATE)).get("pid", 0)
    except (OSError, ValueError):
        return
    try:
        if pid == os.getpid():
            return
        if "cast.py" not in open(f"/proc/{pid}/cmdline").read():
            raise ProcessLookupError
        os.kill(pid, signal.SIGTERM)
        for _ in range(100):
            if not os.path.exists(f"/proc/{pid}"):
                break
            time.sleep(0.1)
    except OSError:
        for d in os.listdir(RUN):
            if d.startswith("cast-") and d != "cast-state" and not d.startswith("cast-state."):
                shutil.rmtree(os.path.join(RUN, d), ignore_errors=True)
        unspeak()
        link_down()
        state(None)


def start(kind, target, name, mode):
    for tool in ("wf-recorder", "ffmpeg"):
        if not shutil.which(tool):
            return note("Can't cast", tool + " isn't installed")
    args = area(mode)
    if not args:
        return
    stop()
    signal.signal(signal.SIGTERM, lambda *a: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *a: sys.exit(0))
    signal.signal(signal.SIGHUP, lambda *a: sys.exit(0))
    began = int(time.time())
    state({"pid": os.getpid(), "name": name, "started": 0})
    shown = []
    def live():
        if not shown:
            shown.append(1)
            state({"pid": os.getpid(), "name": name, "started": began})

    d = tempfile.mkdtemp(prefix="cast-", dir=RUN)
    srv = Server(d, args)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    base = ""
    if kind in ("cast", "dlna"):
        host = target.rsplit(":", 1)[0] if kind == "cast" else urllib.parse.urlparse(target).hostname
        base = f"http://{local_ip(host)}:{srv.server_address[1]}"
    cc = session = mc = spk = None
    try:
        spk = Speaker(name)
        if kind in ("miracast", "direct"):
            mc = Miracast(target, args, srv.procs, kind == "direct")
            mc.run(live)
        elif kind == "cast":
            rec = capture(args)
            seg = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-i", "pipe:0", "-c", "copy", "-f", "hls", "-hls_time", "0.5",
                                    "-hls_list_size", "4", "-hls_flags", "delete_segments+omit_endlist", os.path.join(d, "index.m3u8")],
                                   stdin=rec.stdout)
            rec.stdout.close()
            srv.procs += [rec, seg]
            def ready():
                end = time.time() + 15
                while not os.path.exists(os.path.join(d, "index.m3u8")):
                    if time.time() > end or seg.poll() is not None:
                        raise RuntimeError("screen capture didn't start")
                    time.sleep(0.05)
            cc, session = chromecast(target, base + "/hls/index.m3u8", ready)
            watch_chromecast(cc, live)
        else:
            dlna(target, base + "/live.ts")
            end = time.time() + 20
            while srv.watching or (srv.seen and time.time() - srv.idle < 10) or (not srv.seen and time.time() < end):
                if srv.watching:
                    live()
                time.sleep(1)
            if not srv.seen:
                raise RuntimeError("tv never asked for the stream")
    except SystemExit:
        pass
    except Exception as e:
        note("Couldn't cast to " + name, str(e))
    finally:
        try:
            if cc:
                cc.send(RECV, {"type": "STOP", "sessionId": session, "requestId": 3})
            elif kind == "dlna":
                soap(target, "Stop")
            elif mc:
                mc.close()
        except Exception:
            pass
        for p in srv.procs:
            p.kill()
        if spk:
            spk.close()
        srv.shutdown()
        shutil.rmtree(d, ignore_errors=True)
        state(None)


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["scan"]:
        scan()
    elif a[:1] == ["start"] and len(a) == 5:
        start(*a[1:])
    elif a[:1] == ["stop"]:
        stop()
    else:
        sys.exit("usage: cast.py scan | start cast|dlna|miracast|direct <target> <name> region|window|screen | stop")
