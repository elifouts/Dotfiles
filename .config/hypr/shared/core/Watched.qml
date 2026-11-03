import Quickshell.Io

// FileView that rereads itself whenever the file changes, i had this copy pasted everywhere
FileView {
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
}
