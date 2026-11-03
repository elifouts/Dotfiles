pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// the todos both themes show. { "2026-10-30": ["thing"], "_done": 12 }, no file = no todos
Singleton {
    id: root

    property var todos: ({})
    readonly property int done: todos._done ?? 0
    // true while my own save lands, so lists don't rebuild mid animation
    property bool saving: false
    property string written: ""

    function key(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
    function tasks(d) { return todos[key(d)] ?? [] }
    function put(d, list, finished) {
        const next = Object.assign({}, todos)
        if (list.length) next[key(d)] = list
        else delete next[key(d)]
        if (finished) next._done = (next._done ?? 0) + finished
        written = JSON.stringify(next, null, 1) + "\n"
        saving = true
        todos = next
        saving = false
        store.setText(written)
    }

    FileView {
        id: store
        path: Hypr.state + "/todos.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            if (text() === root.written) return
            try { root.todos = JSON.parse(text()) || {} } catch (e) { root.todos = {} }
        }
        onLoadFailed: root.todos = {}
    }
}
