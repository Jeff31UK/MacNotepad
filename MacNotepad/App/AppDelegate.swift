import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation, NotepadWindowDelegate {

    private var windowControllers: [NotepadWindowController] = []

    /// The controller for the currently active (key) window
    private var activeController: NotepadWindowController? {
        guard let keyWindow = NSApp.keyWindow else {
            return windowControllers.last
        }
        return windowControllers.first { $0.window === keyWindow }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()

        openNewWindow()

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Prompt save for all windows with unsaved changes
        for controller in windowControllers {
            controller.window.makeKeyAndOrderFront(nil)
            if !controller.promptSaveIfNeeded() {
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    // MARK: - Window Management

    private func openNewWindow() {
        let controller = NotepadWindowController()
        controller.delegate = self
        windowControllers.append(controller)
        controller.window.makeKeyAndOrderFront(nil)
    }

    private func openNewWindow(with url: URL) {
        let controller = NotepadWindowController()
        controller.delegate = self
        windowControllers.append(controller)
        controller.openFile(at: url)
        controller.window.makeKeyAndOrderFront(nil)
    }

    // MARK: - NotepadWindowDelegate

    func windowControllerDidClose(_ controller: NotepadWindowController) {
        windowControllers.removeAll { $0 === controller }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // Application menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Notepad", action: #selector(showAbout(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Notepad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New", action: #selector(newDocument(_:)), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open...", action: #selector(openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Save", action: #selector(saveDocument(_:)), keyEquivalent: "s")
        fileMenu.addItem(withTitle: "Save As...", action: #selector(saveDocumentAs(_:)), keyEquivalent: "S")
        fileMenu.items.last?.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Page Setup...", action: #selector(pageSetup(_:)), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Print...", action: #selector(printDocument(_:)), keyEquivalent: "p")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Exit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        fileMenuItem.submenu = fileMenu

        // Edit menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(undoAction(_:)), keyEquivalent: "z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(cutAction(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(copyAction(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(pasteAction(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Delete", action: #selector(deleteAction(_:)), keyEquivalent: "")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Select All", action: #selector(selectAllAction(_:)), keyEquivalent: "a")
        editMenu.addItem(withTitle: "Time/Date", action: #selector(insertTimeDate(_:)), keyEquivalent: "")
        editMenuItem.submenu = editMenu

        // Search menu
        let searchMenuItem = NSMenuItem()
        mainMenu.addItem(searchMenuItem)
        let searchMenu = NSMenu(title: "Search")
        searchMenu.addItem(withTitle: "Find...", action: #selector(showFind(_:)), keyEquivalent: "f")
        searchMenu.addItem(withTitle: "Find Next", action: #selector(findNext(_:)), keyEquivalent: "g")
        searchMenu.addItem(withTitle: "Replace...", action: #selector(showReplace(_:)), keyEquivalent: "h")
        searchMenu.addItem(withTitle: "Go To...", action: #selector(showGoToLine(_:)), keyEquivalent: "G")
        searchMenu.items.last?.keyEquivalentModifierMask = [.command, .shift]
        searchMenuItem.submenu = searchMenu

        // Format menu (classic Notepad: Word Wrap + Font)
        let formatMenuItem = NSMenuItem()
        mainMenu.addItem(formatMenuItem)
        let formatMenu = NSMenu(title: "Format")
        formatMenu.addItem(withTitle: "Word Wrap", action: #selector(toggleWordWrap(_:)), keyEquivalent: "")
        formatMenu.addItem(withTitle: "Font...", action: #selector(showFontPanel(_:)), keyEquivalent: "")
        formatMenuItem.submenu = formatMenu

        // Window menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        // Help menu
        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "About Notepad", action: #selector(showAbout(_:)), keyEquivalent: "")
        helpMenuItem.submenu = helpMenu

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Menu Actions

    @objc func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc func newDocument(_ sender: Any?) {
        openNewWindow()
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openNewWindow(with: url)
    }

    @objc func saveDocument(_ sender: Any?) {
        activeController?.saveDocument()
    }

    @objc func saveDocumentAs(_ sender: Any?) {
        activeController?.saveDocumentAs()
    }

    @objc func pageSetup(_ sender: Any?) {
        activeController?.pageSetup()
    }

    @objc func printDocument(_ sender: Any?) {
        activeController?.printDocument()
    }

    @objc func undoAction(_ sender: Any?) {
        NSApp.sendAction(Selector(("undo:")), to: nil, from: sender)
    }

    @objc func cutAction(_ sender: Any?) {
        NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: sender)
    }

    @objc func copyAction(_ sender: Any?) {
        NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: sender)
    }

    @objc func pasteAction(_ sender: Any?) {
        NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: sender)
    }

    @objc func deleteAction(_ sender: Any?) {
        activeController?.deleteSelection()
    }

    @objc func selectAllAction(_ sender: Any?) {
        activeController?.selectAll()
    }

    @objc func insertTimeDate(_ sender: Any?) {
        activeController?.insertTimeDate()
    }

    @objc func toggleWordWrap(_ sender: Any?) {
        activeController?.toggleWordWrap()
    }

    @objc func showFontPanel(_ sender: Any?) {
        activeController?.showFontPanel()
    }

    @objc func showFind(_ sender: Any?) {
        activeController?.showFind()
    }

    @objc func findNext(_ sender: Any?) {
        activeController?.findNextFromMenu()
    }

    @objc func showReplace(_ sender: Any?) {
        activeController?.showReplace()
    }

    @objc func showGoToLine(_ sender: Any?) {
        activeController?.showGoToLine()
    }

    // MARK: - Menu Validation

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let controller = activeController

        switch menuItem.action {
        case #selector(toggleWordWrap(_:)):
            menuItem.state = (controller?.isWordWrapEnabled ?? true) ? .on : .off
        case #selector(showGoToLine(_:)):
            return !(controller?.isWordWrapEnabled ?? true)
        case #selector(saveDocument(_:)), #selector(saveDocumentAs(_:)),
             #selector(printDocument(_:)), #selector(pageSetup(_:)),
             #selector(deleteAction(_:)), #selector(selectAllAction(_:)),
             #selector(insertTimeDate(_:)), #selector(showFind(_:)),
             #selector(findNext(_:)), #selector(showReplace(_:)),
             #selector(showFontPanel(_:)):
            return controller != nil
        default:
            break
        }
        return true
    }
}
