#!/usr/bin/env bash

shopt -u patsub_replacement 2>/dev/null

FRAME=0.04
FADE_MS=600
PRESS_MS=320
TITLE_MAX=21
ARTIST_MAX=30
TAIL=5
TAIL_A=(75 52 33 18 8)
COLORS_FILE="$HOME/.cache/wal/colors-hyprland"
CARD_VAR=backgroundCol

DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-player"
CARD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hyprlock-player"
mkdir -p "$DIR" "$CARD_DIR"
now_ms() { NOW=$(( ${EPOCHREALTIME/[.,]/} / 1000 )); }

case $1 in
  ensure)
    setsid -f "$0" daemon >/dev/null 2>&1 </dev/null
    exit 0 ;;
  lock)
    setsid -f "$0" daemon >/dev/null 2>&1 </dev/null
    for _ in {1..75}; do [[ -e $DIR/ready ]] && break; sleep 0.02; done
    exec hyprlock "${@:2}" ;;
  press)
    now_ms; printf '%s\n' "$NOW" > "$DIR/press-$2"
    case $2 in
      prev)   playerctl previous ;;
      toggle) playerctl play-pause ;;
      next)   playerctl next ;;
    esac
    exit 0 ;;
  daemon) ;;
  *) echo "usage: $0 lock|ensure|press <prev|toggle|next>|daemon" >&2; exit 1 ;;
esac

exec 9>"$DIR/lock"; flock -n 9 || exit 0
trap 'rm -f "$DIR"/ready "$DIR"/title "$DIR"/artist "$DIR"/prev "$DIR"/toggle "$DIR"/next "$DIR"/.*.tmp; set_card clear; exit' EXIT TERM INT
exec {sfd}<> <(:)

declare -A CUR PRV TCH LAST

make_cards() {
  python3 - "$COLORS_FILE" "$CARD_VAR" "$CARD_DIR" <<'PY'
import re, struct, sys, zlib
src, var, out = sys.argv[1:4]
def lookup(name, depth=0):
    try: text = open(src).read()
    except OSError: return None
    m = re.search(r'^\s*\$' + re.escape(name) + r'\s*=\s*(.+?)\s*(?:#.*)?$', text, re.M)
    if not m: return None
    v = m.group(1).strip()
    if v.startswith('$') and depth < 3: return lookup(v[1:], depth + 1)
    return v
def parse(v):
    if not v: return None
    v = v.strip()
    m = re.fullmatch(r'rgba?\(\s*([0-9a-fA-F]{6})([0-9a-fA-F]{2})?\s*\)', v)
    if m: return tuple(int(m.group(1)[i:i+2], 16) for i in (0, 2, 4)) + (int(m.group(2), 16) if m.group(2) else 255,)
    m = re.fullmatch(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([0-9.]+)\s*)?\)', v)
    if m: return (int(m.group(1)), int(m.group(2)), int(m.group(3)), round(float(m.group(4) or 1) * 255))
    m = re.fullmatch(r'0x([0-9a-fA-F]{8})', v)
    if m: h = m.group(1); return (int(h[2:4], 16), int(h[4:6], 16), int(h[6:8], 16), int(h[0:2], 16))
    return None
rgba = parse(lookup(var)) or (20, 20, 20, 235)
def png(path, w, h, px):
    raw = b''.join(b'\x00' + bytes(px) * w for _ in range(h))
    ch = lambda t, d: struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + ch(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) + ch(b'IDAT', zlib.compress(raw)) + ch(b'IEND', b''))
png(out + '/solid.png', 96, 50, rgba)
png(out + '/clear.png', 96, 50, (0, 0, 0, 0))
PY
}
make_cards

set_card() {
  cp -f "$CARD_DIR/$1.png" "$CARD_DIR/.card.tmp" && mv -f "$CARD_DIR/.card.tmp" "$CARD_DIR/card.png"
}

smooth() { local t=$1; SM=$(( (3*t*t - 2*t*t*t/1000) / 1000 )); }
esc()    { REPLY=${1//&/&amp;}; REPLY=${REPLY//</&lt;}; REPLY=${REPLY//>/&gt;}; }
put()    { [[ ${LAST[$1]-} == "$2" ]] && return; LAST[$1]=$2
           printf '%s' "$2" > "$DIR/.$1.tmp" && mv -f "$DIR/.$1.tmp" "$DIR/$1"; }

fade_render() {
  local s=$1 max=$2 g=$3 head tail="" i a out
  if (( ${#s} > max )); then head=${s:0:max-TAIL}; tail=${s:max-TAIL:TAIL}; else head=$s; fi
  esc "$head"; out="<span alpha=\"$g\">$REPLY</span>"
  for (( i=0; i<${#tail}; i++ )); do
    esc "${tail:i:1}"; a=$(( g * TAIL_A[i] / 100 )); (( a < 1 )) && a=1
    out+="<span alpha=\"$a\">$REPLY</span>"
  done
  REPLY=$out
}

anim_text() {
  local k=$1 raw=$2 max=$3 half=$(( FADE_MS / 2 )) e g text
  if [[ -z ${TCH[$k]+x} ]]; then CUR[$k]=$raw; PRV[$k]=""; TCH[$k]=0
  elif [[ ${CUR[$k]} != "$raw" ]]; then PRV[$k]=${CUR[$k]}; CUR[$k]=$raw; TCH[$k]=$NOW; fi
  e=$(( NOW - TCH[$k] ))
  if (( e >= FADE_MS )); then g=65535; text=$raw
  elif (( e < half )); then smooth $(( e * 1000 / half )); g=$(( 65535 * (1000 - SM) / 1000 )); text=${PRV[$k]}
  else smooth $(( (e - half) * 1000 / half )); g=$(( 65535 * SM / 1000 )); text=$raw; fi
  (( g < 1 )) && g=1
  fade_render "$text" "$max" "$g"
}

anim_btn() {
  local ts=0 e d t
  [[ -r $DIR/press-$1 ]] && read -r ts < "$DIR/press-$1"
  e=$(( NOW - ts ))
  if (( e >= PRESS_MS || e < 0 )); then REPLY=$2; return; fi
  if (( e < 90 )); then smooth $(( e * 1000 / 90 )); d=$SM
  else smooth $(( (e - 90) * 1000 / (PRESS_MS - 90) )); d=$(( 1000 - SM )); fi
  REPLY="<span size=\"$(( $3 * 1024 * (1000 - 150*d/1000) / 1000 ))\" alpha=\"$(( 65535 - 26214*d/1000 ))\">$2</span>"
}

n=0; stat=""; title=""; artist=""
while :; do
  now_ms
  if (( n % 4 == 0 )); then
    (( n % 25 == 0 && n >= 100 )) && ! pgrep -x hyprlock >/dev/null && exit 0
    if raw=$(playerctl metadata --format $'{{status}}\x1f{{xesam:title}}\x1f{{xesam:artist}}' 2>/dev/null) && [[ -n $raw ]]; then
      IFS=$'\x1f' read -r stat title artist <<< "$raw"
    else stat=""; fi
  fi

  want=solid; [[ -z $stat ]] && want=clear
  if [[ ${CARD-} != "$want" ]]; then CARD=$want; set_card "$want"; pkill -USR2 -x hyprlock
  elif (( n % 125 == 10 )); then pkill -USR2 -x hyprlock; fi

  if [[ -z $stat ]]; then
    put title ""; put artist ""; put prev ""; put toggle ""; put next ""
    CUR=(); PRV=(); TCH=()
  else
    anim_text title  "$title"  "$TITLE_MAX";  put title  "$REPLY"
    anim_text artist "$artist" "$ARTIST_MAX"; put artist "$REPLY"
    anim_btn prev '&#xf048;' 20;  put prev "$REPLY"
    anim_btn next '&#xf051;' 20;  put next "$REPLY"
    if [[ $stat == Playing ]]; then anim_btn toggle '&#xf04c;' 30; else anim_btn toggle '&#xf04b;' 30; fi
    put toggle "$REPLY"
  fi
  (( n++ )) || : > "$DIR/ready"
  read -rt "$FRAME" -u "$sfd" || :
done
