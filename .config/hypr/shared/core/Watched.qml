import Quickshell.Io

FileView {
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
}
