import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Io
import "../style/common"
import "../style/bar/menus"

Column {
    id: menu

    property bool open: false
    signal run(string cmd)

    spacing: 10

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var networks: wifiDev
        ? wifiDev.networks.values.filter(n => n.name !== "").slice().sort((a, b) =>
            (b.connected - a.connected) || (b.known - a.known) || (strength(b) - strength(a)))
        : []
    property string asking: ""
    property bool askingEap: false
    property bool hidden: false
    property string editing: ""
    readonly property bool joining: joiner.running
    readonly property bool listing: editing === ""
    readonly property bool holdOpen: asking !== "" || hidden || !listing || joining || editor.saving
    property var failed: ({})
    property var vpns: []
    property string vpnBusy: ""

    Binding {
        target: menu.wifiDev
        property: "scannerEnabled"
        value: true
        when: menu.open && !menu.holdOpen && !!menu.wifiDev && Networking.wifiEnabled
        restoreMode: Binding.RestoreBindingOrValue
    }

    onOpenChanged: if (open) vpnList.running = true; else { asking = ""; hidden = false; editing = "" }
    Component.onCompleted: if (open) vpnList.running = true

    function strength(n) {
        const s = n.signalStrength ?? 0
        return s > 1 ? s / 100 : s
    }

    function glyph(n) {
        const f = strength(n)
        return f > 0.75 ? "󰤨" : f > 0.5 ? "󰤥" : f > 0.25 ? "󰤢" : "󰤟"
    }

    function secured(n) {
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe
    }

    function enterprise(n) {
        return n.security === WifiSecurityType.Wpa2Eap || n.security === WifiSecurityType.WpaEap
            || n.security === WifiSecurityType.Wpa3SuiteB192
    }

    function ask(n) {
        hidden = false
        askingEap = enterprise(n)
        asking = n.name
    }

    function askHidden() {
        asking = ""
        askingEap = false
        hidden = !hidden
    }

    function setFailed(name, why) {
        failed = Object.assign({}, failed, { [name]: why })
    }

    function pick(n) {
        if (joining) return
        setFailed(n.name, "")
        if (n.connected) n.disconnect()
        else if (n.known || !secured(n)) n.connect()
        else if (asking === n.name) asking = ""
        else ask(n)
    }

    function edit(n) {
        asking = ""
        hidden = false
        editor.load(n ? "wifi" : "ethernet", n ? n.name : wired.name, n)
        editing = editor.name
    }

    function join(ssid, user, psk) {
        if (joining || ssid === "" || (!hidden && psk.length === 0) || (askingEap && user === "")) return
        setFailed(ssid, "")
        joiner.ssid = ssid
        joiner.hidden = hidden
        joiner.command = askingEap
            ? [Quickshell.shellPath("shared/net.sh"), "eap", ssid, user, psk]
            : ["nmcli", "--wait", "30", "device", "wifi", "connect", ssid]
                .concat(psk !== "" ? ["password", psk] : []).concat(hidden ? ["hidden", "yes"] : [])
        joiner.running = true
    }

    function lastLine(text) {
        return text.trim().replace(/^Error:\s*/, "").split("\n").pop()
    }

    Process {
        id: joiner
        property string ssid: ""
        property bool hidden: false
        stderr: StdioCollector { id: joinErr }
        onExited: code => {
            if (code === 0) {
                if (menu.asking === joiner.ssid) menu.asking = ""
                if (joiner.hidden) menu.hidden = false
                return
            }
            const msg = menu.lastLine(joinErr.text)
            menu.setFailed(joiner.ssid, /secret|password|802-11-wireless-security/i.test(msg) ? "Wrong password" : (msg || "Error " + code))
            if (!joiner.hidden) menu.asking = joiner.ssid
            prompt.reset()
        }
    }

    function toggleVpn(v) {
        if (vpnBusy !== "") return
        vpnBusy = v.uuid
        vpnToggle.command = ["nmcli", "connection", v.active ? "down" : "up", "uuid", v.uuid]
        vpnToggle.running = true
    }

    Process {
        id: vpnList
        property bool clear: false
        command: ["nmcli", "-t", "-f", "UUID,TYPE,ACTIVE,NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const m = line.match(/^([^:]*):([^:]*):([^:]*):(.*)$/)
                    if (m && (m[2] === "vpn" || m[2] === "wireguard"))
                        out.push({ uuid: m[1], name: m[4].replace(/\\(.)/g, "$1"), active: m[3] === "yes" })
                }
                if (JSON.stringify(out) !== JSON.stringify(menu.vpns)) menu.vpns = out
                if (vpnList.clear) { vpnList.clear = false; menu.vpnBusy = "" }
            }
        }
    }
    Process {
        id: vpnToggle
        onExited: { vpnList.clear = true; if (!vpnList.running) vpnList.running = true }
    }

    Header {
        visible: menu.listing
        title: "Wi-Fi"
        Round {
            visible: Networking.wifiEnabled && !!menu.wifiDev
            anchors.verticalCenter: parent.verticalCenter
            glyph: menu.hidden ? "" : ""
            onClicked: menu.askHidden()
        }
        Switch {
            anchors.verticalCenter: parent.verticalCenter
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Group {
        visible: !!menu.wired && menu.listing

        Entry {
            glyph: "󰈀"
            label: "Ethernet"
            active: true
            gear: true
            onClicked: menu.edit(null)
            onSettingsClicked: menu.edit(null)
        }
    }

    Group {
        visible: menu.listing
        maxHeight: 248
        empty: !menu.wifiDev ? "No adapter" : !Networking.wifiEnabled ? "Off" : "Searching…"

        Item {
            id: stack
            readonly property int rowH: Theme.menuRow
            readonly property int gapH: 0
            readonly property int count: Networking.wifiEnabled ? menu.networks.length : 0
            width: parent.width
            height: count > 0 ? count * (rowH + gapH) - gapH : 0
            Behavior on height { SettleShared { duration: Theme.move } }

            Repeater {
                model: Networking.wifiEnabled && menu.wifiDev ? menu.wifiDev.networks : null

                Entry {
                    id: net
                    required property var modelData
                    readonly property int rank: menu.networks.indexOf(modelData)
                    readonly property bool joiningThis: menu.joining && joiner.ssid === modelData.name
                    readonly property bool connecting: joiningThis || modelData.state === ConnectionState.Connecting || modelData.stateChanging

                    visible: rank >= 0
                    y: Math.max(0, rank) * (stack.rowH + stack.gapH)
                    height: stack.rowH
                    Behavior on y { SettleShared { duration: Theme.ms(420) } }

                    Connections {
                        target: net.modelData
                        function onConnectionFailed(reason) {
                            if (net.joiningThis) return
                            menu.setFailed(net.modelData.name, ConnectionFailReason.toString(reason))
                            if (!net.modelData.known && menu.secured(net.modelData)) menu.ask(net.modelData)
                        }
                        function onConnectedChanged() { if (net.modelData.connected && menu.asking === net.modelData.name && !menu.joining) menu.asking = "" }
                    }

                    glyph: menu.glyph(modelData)
                    label: modelData.name
                    sub: net.connecting ? "Connecting" : (menu.failed[modelData.name] || "")
                    trailing: menu.secured(modelData) ? "" : ""
                    active: modelData.connected || menu.asking === modelData.name
                    busy: net.connecting
                    gear: true
                    onClicked: menu.pick(modelData)
                    onRightClicked: if (modelData.known) modelData.forget()
                    onSettingsClicked: menu.edit(modelData)
                }
            }
        }
    }

    Column {
        id: prompt
        visible: (menu.asking !== "" || menu.hidden) && menu.listing
        width: parent.width
        spacing: 6
        opacity: menu.joining ? 0.6 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }

        readonly property string target: menu.hidden ? ssid.text.trim() : menu.asking

        function reset() {
            pass.text = ""
            if (menu.hidden && ssid.text === "") ssid.grab()
            else if (menu.askingEap && user.text === "") user.grab()
            else pass.grab()
        }
        function submit() {
            if (menu.hidden && ssid.text.trim() === "") { ssid.grab(); return }
            if (menu.askingEap && user.text === "") { user.grab(); return }
            menu.join(prompt.target, user.text.trim(), pass.text)
        }
        function cancel() { menu.asking = ""; menu.hidden = false }
        Keys.onEscapePressed: cancel()

        onVisibleChanged: if (visible) reset()
        Connections {
            target: menu
            function onAskingChanged() { if (menu.asking !== "") prompt.reset() }
            function onHiddenChanged() { if (menu.hidden) { ssid.text = ""; prompt.reset() } }
        }

        Field {
            id: ssid
            visible: menu.hidden
            readOnly: menu.joining
            placeholder: "Name"
            onAccepted: pass.grab()
        }

        Field {
            id: user
            visible: menu.askingEap
            readOnly: menu.joining
            placeholder: "Username"
            onAccepted: pass.grab()
        }

        Item {
            width: parent.width
            height: 34

            Field {
                id: pass
                anchors.left: parent.left
                anchors.right: go.left
                anchors.rightMargin: 6
                height: parent.height
                secret: true
                readOnly: menu.joining
                placeholder: "Password"
                onAccepted: prompt.submit()
            }

            Button {
                id: go
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 34
                primary: true
                label: menu.joining ? "…" : "Join"
                onPressed: prompt.submit()
            }
        }

        OopsShared { text: menu.hidden ? (menu.failed[prompt.target] || "") : "" }
    }

    Group {
        visible: menu.vpns.length > 0 && menu.listing
        maxHeight: 130

        Repeater {
            model: menu.vpns

            Entry {
                required property var modelData
                glyph: "󰖂"
                label: modelData.name
                active: modelData.active
                busy: menu.vpnBusy === modelData.uuid
                onClicked: menu.toggleVpn(modelData)
            }
        }
    }

    WifiEditorShared {
        id: editor
        menu: menu
        visible: !menu.listing
        width: parent.width
    }
}
