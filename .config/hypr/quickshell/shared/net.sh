#!/bin/bash
cmd="$1"
shift

case "$cmd" in
    eap)
        nmcli connection delete id "$1" >/dev/null 2>&1
        nmcli connection add type wifi con-name "$1" ssid "$1" wifi-sec.key-mgmt wpa-eap \
            802-1x.eap peap 802-1x.phase2-auth mschapv2 802-1x.identity "$2" 802-1x.password "$3" >/dev/null || exit 1
        nmcli --wait 30 connection up id "$1" >/dev/null && exit 0
        nmcli connection delete id "$1" >/dev/null 2>&1
        exit 1
        ;;
    show)
        f=$1 kind=$2 name=$3
        if [ "$kind" = ethernet ]; then
            u=$(nmcli -g UUID,DEVICE connection show --active | sed -n "s/:$name\$//p" | head -n1)
            [ -n "$u" ] && exec nmcli -t -f "$f" connection show uuid "$u"
            exit 0
        fi
        for u in $(nmcli -g UUID,TYPE connection show | sed -n 's/:802-11-wireless$//p'); do
            [ "$(nmcli -g 802-11-wireless.ssid connection show uuid "$u")" = "$name" ] || continue
            exec nmcli -t -f "$f" connection show uuid "$u"
        done
        ;;
    save)
        mode=$1 uuid=$2 name=$3 sec=$4 kind=$5
        shift 5
        if [ -z "$uuid" ]; then
            if [ "$kind" = ethernet ]; then
                out=$(nmcli connection add type ethernet con-name "$name" ifname "$name" "$@") || exit 1
            else
                out=$(nmcli connection add type wifi con-name "$name" ssid "$name" "$@") || exit 1
            fi
            uuid=$(printf '%s' "$out" | grep -oE '[0-9a-f]{8}-[0-9a-f-]{27}') || exit 1
        else
            if [ "$kind" = wifi ]; then
                [ "$sec" = wpa-eap ] || nmcli connection modify uuid "$uuid" remove 802-1x >/dev/null 2>&1
                [ "$sec" = none ] && nmcli connection modify uuid "$uuid" remove 802-11-wireless-security >/dev/null 2>&1
            fi
            nmcli connection modify uuid "$uuid" "$@" || exit 1
        fi
        [ "$mode" = up ] && exec nmcli --wait 30 connection up uuid "$uuid" >/dev/null
        exit 0
        ;;
esac
