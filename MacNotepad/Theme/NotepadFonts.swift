import Cocoa

enum NotepadFonts {
    // Classic Notepad used Fixedsys - closest macOS equivalent is a monospaced font
    static let editor = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    static let statusBar = NSFont.systemFont(ofSize: 11)
    static let menuFont = NSFont.systemFont(ofSize: 13)
}
