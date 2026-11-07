import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Io
import "../style/common"
import "../style/bar/menus"

Column {
    id: editor

    component Caption: Say {
        x: 4
        font.pixelSize: 10
        font.letterSpacing: 1.6
        color: Theme.dim
    }

    component Addr: Row {
        property alias addr: a
        property alias gw: g
        width: parent ? parent.width : 0
        spacing: 6
        Field { id: a; width: (parent.width - 6) / 2; placeholder: "Address"; onAccepted: g.grab() }
        Field { id: g; width: (parent.width - 6) / 2; placeholder: "Gateway" }
    }

    property var menu
    readonly property bool saving: saver.running
    spacing: 10

    property string kind: "wifi"
    property string name: ""
    property alias tab: tabs.value
    property string uuid: ""
    property alias sec: secChips.value
    property alias eap: eapChips.value
    property alias phase2: phase2Chips.value
    property alias auto: autoT.checked
    property bool more: false
    property alias ip4: ip4Chips.value
    property string ip4Was: "auto"
    property alias ip6: ip6Chips.value
    property string ip6Was: "auto"
    property alias ignoreDns: ignoreDnsT.checked
    property alias allUsers: allUsersT.checked
    property bool allUsersWas: true
    property alias metered: meteredT.checked
    property alias ssidHidden: hiddenT.checked
    property alias band: bandChips.value
    property alias mac: macChips.value
    property string error: ""
    readonly property bool wifi: kind === "wifi"
    readonly property string hw: wifi ? "802-11-wireless" : "802-3-ethernet"
    readonly property bool saved: uuid !== ""
    readonly property bool busy: saver.running || loader.running
    Keys.onEscapePressed: menu.editing = ""

    function load(k, nm, n) {
        Object.assign(editor, { kind: k, name: nm, tab: k === "wifi" ? "sec" : "ip", uuid: "", error: "", more: false,
            sec: !n ? "none" : menu.enterprise(n) ? "wpa-eap" : n.security === WifiSecurityType.Sae ? "sae" : menu.secured(n) ? "wpa-psk" : "none",
            eap: "peap", phase2: "mschapv2", ip4: "auto", ip4Was: "auto", ip6: "auto", ip6Was: "auto", band: "", mac: "",
            auto: true, allUsers: true, allUsersWas: true, metered: false, ssidHidden: false, ignoreDns: false })
        for (const f of [psk, identity, eapPass, anon, ca, domain, v4.addr, v4.gw, v6.addr, v6.gw, dns, mtu]) f.text = ""
        refresh()
    }

    function refresh() {
        const f = ["connection.uuid", "connection.autoconnect", "connection.metered", "connection.permissions",
            "ipv4.method", "ipv4.addresses", "ipv4.gateway", "ipv4.dns", "ipv4.ignore-auto-dns",
            "ipv6.method", "ipv6.addresses", "ipv6.gateway", "ipv6.dns", hw + ".cloned-mac-address", hw + ".mtu"]
        if (wifi) f.push("802-11-wireless.hidden", "802-11-wireless.band", "802-11-wireless-security.key-mgmt",
            "802-1x.eap", "802-1x.phase2-auth", "802-1x.identity", "802-1x.anonymous-identity", "802-1x.ca-cert", "802-1x.domain-suffix-match")
        loader.command = [Quickshell.shellPath("shared/net.sh"), "show", f.join(","), kind, name]
        loader.running = true
    }

    function apply(f) {
        const get = k => (f[k] ?? "") === "--" ? "" : (f[k] ?? "")
        uuid = get("connection.uuid")
        auto = get("connection.autoconnect") !== "no"
        metered = get("connection.metered") === "yes"
        allUsers = allUsersWas = get("connection.permissions") === ""
        const m4 = get("ipv4.method")
        ip4 = ip4Was = ["manual", "shared", "disabled"].includes(m4) ? m4 : "auto"
        const m6 = get("ipv6.method")
        ip6 = ip6Was = m6 === "manual" ? "manual" : m6 === "disabled" || m6 === "ignore" ? "disabled" : "auto"
        v4.addr.text = get("ipv4.addresses")
        v4.gw.text = get("ipv4.gateway")
        v6.addr.text = get("ipv6.addresses")
        v6.gw.text = get("ipv6.gateway")
        dns.text = [get("ipv4.dns"), get("ipv6.dns")].filter(s => s).join(", ")
        ignoreDns = get("ipv4.ignore-auto-dns") === "yes"
        mac = get(hw + ".cloned-mac-address")
        const m = get(hw + ".mtu")
        mtu.text = m === "auto" || m === "0" ? "" : m
        if (!wifi) return
        ssidHidden = get("802-11-wireless.hidden") === "yes"
        band = get("802-11-wireless.band")
        const km = get("802-11-wireless-security.key-mgmt")
        sec = km === "" || km === "owe" ? "none" : km.startsWith("wpa-eap") ? "wpa-eap" : km === "sae" ? "sae" : "wpa-psk"
        if (get("802-1x.eap")) eap = get("802-1x.eap").split(",")[0]
        if (get("802-1x.phase2-auth")) phase2 = get("802-1x.phase2-auth")
        identity.text = get("802-1x.identity")
        anon.text = get("802-1x.anonymous-identity")
        ca.text = get("802-1x.ca-cert").replace(/^file:\/\//, "")
        domain.text = get("802-1x.domain-suffix-match")
        if (anon.text || ca.text || domain.text) more = true
    }

    function fail(msg, field, where) {
        error = msg
        if (where) tab = where
        if (field) field.grab()
    }

    function save(up) {
        if (busy) return
        error = ""
        const kv = ["connection.autoconnect", auto ? "yes" : "no"]
        const opt = (key, val) => { if (val !== "" || saved) kv.push(key, val) }
        const cidr = (s, p) => s.split(/[\s,]+/).filter(a => a).map(a => a.includes("/") ? a : a + "/" + p).join(",")

        if (wifi) {
            if (sec === "wpa-psk" || sec === "sae") {
                if (!saved && psk.text === "") return fail("Password needed", psk, "sec")
                kv.push("802-11-wireless-security.key-mgmt", sec)
                if (psk.text !== "") kv.push("802-11-wireless-security.psk", psk.text)
            } else if (sec === "wpa-eap") {
                if (identity.text.trim() === "") return fail("Username needed", identity, "sec")
                if (!saved && eapPass.text === "") return fail("Password needed", eapPass, "sec")
                kv.push("802-11-wireless-security.key-mgmt", "wpa-eap", "802-1x.eap", eap,
                    "802-1x.phase2-auth", phase2, "802-1x.identity", identity.text.trim())
                if (eapPass.text !== "") kv.push("802-1x.password", eapPass.text)
                opt("802-1x.anonymous-identity", anon.text.trim())
                opt("802-1x.ca-cert", ca.text.trim().replace(/^~(?=\/)/, Quickshell.env("HOME")))
                opt("802-1x.domain-suffix-match", domain.text.trim())
            }
        }

        if (ip4 !== ip4Was || ip4 === "manual") kv.push("ipv4.method", ip4)
        if (ip4 === "manual") {
            if (v4.addr.text.trim() === "") return fail("Address needed", v4.addr, "ip")
            kv.push("ipv4.addresses", cidr(v4.addr.text, 24), "ipv4.gateway", v4.gw.text.trim())
        } else if (ip4 !== ip4Was) kv.push("ipv4.addresses", "", "ipv4.gateway", "")
        if (ip6 !== ip6Was || ip6 === "manual") kv.push("ipv6.method", ip6)
        if (ip6 === "manual") {
            if (v6.addr.text.trim() === "") return fail("Address needed", v6.addr, "ip")
            kv.push("ipv6.addresses", cidr(v6.addr.text, 64), "ipv6.gateway", v6.gw.text.trim())
        } else if (ip6 !== ip6Was) kv.push("ipv6.addresses", "", "ipv6.gateway", "")

        const ds = dns.text.split(/[\s,]+/).filter(a => a)
        if (ip4 !== "disabled") {
            opt("ipv4.dns", ds.filter(a => !a.includes(":")).join(","))
            kv.push("ipv4.ignore-auto-dns", ignoreDns ? "yes" : "no")
        }
        if (ip6 !== "disabled") {
            opt("ipv6.dns", ds.filter(a => a.includes(":")).join(","))
            kv.push("ipv6.ignore-auto-dns", ignoreDns ? "yes" : "no")
        }

        kv.push("connection.metered", metered ? "yes" : "unknown")
        if (allUsers !== allUsersWas || (!saved && !allUsers))
            kv.push("connection.permissions", allUsers ? "" : "user:" + Quickshell.env("USER"))
        opt(hw + ".cloned-mac-address", mac)
        const mt = mtu.text.trim()
        if (mt !== "" && !/^\d+$/.test(mt)) return fail("Bad MTU", mtu, "adv")
        if (mt !== "" || saved) kv.push(hw + ".mtu", mt || "0")
        if (wifi) {
            if (ssidHidden || saved) kv.push("802-11-wireless.hidden", ssidHidden ? "yes" : "no")
            opt("802-11-wireless.band", band)
        }

        saver.forgetting = false
        saver.command = [Quickshell.shellPath("shared/net.sh"), "save", up ? "up" : "save", uuid, name, sec, kind].concat(kv)
        saver.running = true
    }

    function forget() {
        if (busy || !saved) return
        error = ""
        saver.forgetting = true
        saver.command = ["nmcli", "connection", "delete", "uuid", uuid]
        saver.running = true
    }

    Process {
        id: loader
        stdout: StdioCollector {
            onStreamFinished: {
                const f = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf(":")
                    if (i > 0) f[line.slice(0, i)] = line.slice(i + 1).replace(/\\(.)/g, "$1")
                }
                if (f["connection.uuid"]) editor.apply(f)
            }
        }
    }

    Process {
        id: saver
        property bool forgetting: false
        stderr: StdioCollector { id: saveErr }
        onExited: code => {
            if (code === 0) {
                menu.setFailed(editor.name, "")
                menu.editing = ""
                return
            }
            editor.error = menu.lastLine(saveErr.text) || "Error " + code
            if (!saver.forgetting) editor.refresh()
        }
    }

    Item {
        width: parent.width
        height: 26

        Round {
            id: back
            glyph: ""
            onClicked: menu.editing = ""
        }

        Say {
            anchors.left: back.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: editor.wifi ? editor.name : "Ethernet"
            elide: Text.ElideRight
            font.pixelSize: 16
            color: Theme.bright
        }
    }

    Chips {
        options: editor.wifi ? [["sec", "Security"], ["ip", "IP"], ["adv", "More"]] : [["ip", "IP"], ["adv", "More"]]
        id: tabs
    }

    CardShared {
        visible: editor.tab === "sec" && editor.wifi

        Chips {
            options: [["none", "Open"], ["wpa-psk", "WPA2"], ["sae", "WPA3"], ["wpa-eap", "802.1X"]]
            id: secChips
        }

        Field {
            id: psk
            visible: editor.sec === "wpa-psk" || editor.sec === "sae"
            secret: true
            placeholder: editor.saved ? "••••••••" : "Password"
            onAccepted: editor.save(true)
        }

        Column {
            visible: editor.sec === "wpa-eap"
            width: parent.width
            spacing: 8

            Field {
                id: identity
                placeholder: "Username"
                onAccepted: eapPass.grab()
            }
            Field {
                id: eapPass
                secret: true
                placeholder: editor.saved ? "••••••••" : "Password"
                onAccepted: editor.save(true)
            }

            Caption { text: "EAP" }
            Chips {
                options: [["peap", "PEAP"], ["ttls", "TTLS"]]
                id: eapChips
            }

            Caption { text: "PHASE 2" }
            Chips {
                options: [["mschapv2", "MSCHAPv2"], ["pap", "PAP"], ["gtc", "GTC"], ["mschap", "MSCHAP"]]
                id: phase2Chips
            }

            LabelShared {
                x: 4
                text: (editor.more ? "" : "") + "  More"
                font.pixelSize: 11
                color: moreArea.containsMouse ? Theme.fg : Theme.dim
                MouseArea { id: moreArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: editor.more = !editor.more }
            }

            Field {
                id: anon
                visible: editor.more
                placeholder: "Anonymous identity"
            }
            Field {
                id: ca
                visible: editor.more
                placeholder: "CA certificate"
            }
            Field {
                id: domain
                visible: editor.more
                placeholder: "Domain"
            }
        }
    }

    CardShared {
        visible: editor.tab === "ip"

        Caption { text: "IPV4" }
        Chips {
            options: [["auto", "Auto"], ["manual", "Manual"], ["shared", "Shared"], ["disabled", "Off"]]
            id: ip4Chips
        }
        Addr { id: v4; visible: editor.ip4 === "manual" }

        Caption { text: "IPV6" }
        Chips {
            options: [["auto", "Auto"], ["manual", "Manual"], ["disabled", "Off"]]
            id: ip6Chips
        }
        Addr { id: v6; visible: editor.ip6 === "manual" }

        Field { id: dns; placeholder: "DNS" }
        ToggleShared { id: ignoreDnsT; label: "Ignore auto DNS" }
    }

    CardShared {
        visible: editor.tab === "adv"

        ToggleShared { id: autoT; label: "Auto-connect" }
        ToggleShared { id: allUsersT; label: "All users" }
        ToggleShared { id: meteredT; label: "Metered" }
        ToggleShared { id: hiddenT; visible: editor.wifi; label: "Hidden" }

        Caption { visible: editor.wifi; text: "BAND" }
        Chips {
            visible: editor.wifi
            options: [["", "Auto"], ["bg", "2.4 GHz"], ["a", "5 GHz"]]
            id: bandChips
        }

        Caption { text: "MAC" }
        Chips {
            options: [["", "Default"], ["permanent", "Real"], ["random", "Random"], ["stable", "Stable"]]
            id: macChips
        }

        Field { id: mtu; placeholder: "MTU" }
    }

    OopsShared { text: editor.error }

    Item {
        width: parent.width
        height: 32
        opacity: editor.busy ? 0.6 : 1

        Button {
            visible: editor.saved
            anchors.left: parent.left
            label: "Forget"
            onPressed: editor.forget()
        }

        Row {
            anchors.right: parent.right
            spacing: 6

            Button {
                label: "Save"
                onPressed: editor.save(false)
            }
            Button {
                primary: true
                label: saver.running && !saver.forgetting ? "…" : "Connect"
                onPressed: editor.save(true)
            }
        }
    }
}
