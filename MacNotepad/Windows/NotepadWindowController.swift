import Cocoa
import SwiftUI

protocol NotepadWindowDelegate: AnyObject {
    func windowControllerDidClose(_ controller: NotepadWindowController)
}

class NotepadWindowController: NSObject, NSWindowDelegate, FindReplacePanelDelegate, GoToLinePanelDelegate {

    var window: NSWindow!
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var statusBarHostView: NSHostingView<StatusBarView>!
    private var statusBarContainer: NSView!

    private(set) var currentFileURL: URL?
    private(set) var isDocumentEdited = false
    private var wordWrapEnabled = true
    var statusBarVisible = true

    private let findReplacePanel = FindReplacePanel()
    private let goToLinePanel = GoToLinePanel()

    weak var delegate: NotepadWindowDelegate?

    private static var cascadePoint = NSPoint.zero
    private static var isFirstWindow = true
    private static let savedFrameKey = "NotepadWindowFrame"

    override init() {
        super.init()
        findReplacePanel.delegate = self
        goToLinePanel.delegate = self
        setupWindow()
        updateTitle()
    }

    // MARK: - Window Setup

    private func setupWindow() {
        let windowRect = NSRect(x: 0, y: 0, width: 640, height: 480)
        window = NSWindow(contentRect: windowRect,
                         styleMask: [.titled, .closable, .miniaturizable, .resizable],
                         backing: .buffered, defer: false)
        window.minSize = NSSize(width: 300, height: 200)
        window.delegate = self
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: windowRect)

        setupTextView(in: contentView)
        setupStatusBar(in: contentView)

        window.contentView = contentView
        updateLayout()

        // Restore saved position for first window, cascade subsequent ones
        if NotepadWindowController.isFirstWindow,
           let frameString = UserDefaults.standard.string(forKey: NotepadWindowController.savedFrameKey) {
            window.setFrame(NSRectFromString(frameString), display: true)
            NotepadWindowController.isFirstWindow = false
        } else {
            if NotepadWindowController.isFirstWindow {
                window.center()
                NotepadWindowController.isFirstWindow = false
            }
        }
        NotepadWindowController.cascadePoint = window.cascadeTopLeft(from: NotepadWindowController.cascadePoint)
    }

    private func setupTextView(in container: NSView) {
        scrollView = NSScrollView(frame: .zero)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wordWrapEnabled
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
        scrollView.borderType = .bezelBorder

        textView = NSTextView(frame: .zero)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = NotepadFonts.editor
        textView.textColor = NotepadColors.contentText
        textView.backgroundColor = NotepadColors.contentBackground
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.delegate = self

        updateWordWrap()

        scrollView.documentView = textView
        container.addSubview(scrollView)
    }

    private func setupStatusBar(in container: NSView) {
        statusBarContainer = NSView(frame: .zero)
        let statusView = StatusBarView(line: 1, column: 1)
        statusBarHostView = NSHostingView(rootView: statusView)
        statusBarHostView.frame = statusBarContainer.bounds
        statusBarHostView.autoresizingMask = [.width, .height]
        statusBarContainer.addSubview(statusBarHostView)
        container.addSubview(statusBarContainer)
    }

    func updateLayout() {
        guard let contentView = window.contentView else { return }
        let bounds = contentView.bounds
        let statusHeight: CGFloat = statusBarVisible ? NotepadTheme.statusBarHeight : 0

        if statusBarVisible {
            statusBarContainer.frame = NSRect(x: 0, y: 0, width: bounds.width, height: statusHeight)
            statusBarContainer.isHidden = false
        } else {
            statusBarContainer.isHidden = true
        }

        scrollView.frame = NSRect(x: 0, y: statusHeight, width: bounds.width, height: bounds.height - statusHeight)

        // Autoresize
        scrollView.autoresizingMask = [.width, .height]
        statusBarContainer.autoresizingMask = [.width]
    }

    // MARK: - Title

    func updateTitle() {
        let fileName = currentFileURL?.lastPathComponent ?? "Untitled"
        let modified = isDocumentEdited ? "*" : ""
        window.title = "\(modified)\(fileName) - Notepad"
    }

    // MARK: - Document State

    func markEdited() {
        if !isDocumentEdited {
            isDocumentEdited = true
            updateTitle()
        }
    }

    func markClean() {
        isDocumentEdited = false
        updateTitle()
    }

    // MARK: - File Operations

    func openFile(at url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            textView.string = text
            currentFileURL = url
            markClean()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    func saveDocument() {
        if let url = currentFileURL {
            saveToFile(url)
        } else {
            saveDocumentAs()
        }
    }

    func saveDocumentAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = currentFileURL?.lastPathComponent ?? "Untitled.txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        saveToFile(url)
    }

    private func saveToFile(_ url: URL) {
        do {
            try textView.string.write(to: url, atomically: true, encoding: .utf8)
            currentFileURL = url
            markClean()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    /// Returns true if it's safe to proceed, false if the user cancelled
    func promptSaveIfNeeded() -> Bool {
        guard isDocumentEdited else { return true }

        let fileName = currentFileURL?.lastPathComponent ?? "Untitled"
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes to \(fileName)?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            saveDocument()
            return !isDocumentEdited // false if save was cancelled
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    // MARK: - Edit Operations

    func insertTimeDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a M/d/yyyy"
        let dateString = formatter.string(from: Date())

        let selectedRange = textView.selectedRange()
        if textView.shouldChangeText(in: selectedRange, replacementString: dateString) {
            textView.replaceCharacters(in: selectedRange, with: dateString)
            textView.didChangeText()
        }
    }

    func deleteSelection() {
        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else { return }
        if textView.shouldChangeText(in: selectedRange, replacementString: "") {
            textView.replaceCharacters(in: selectedRange, with: "")
            textView.didChangeText()
        }
    }

    func selectAll() {
        textView.selectAll(nil)
    }

    // MARK: - Font

    func showFontPanel() {
        let fontManager = NSFontManager.shared
        fontManager.target = self
        fontManager.setSelectedFont(textView.font ?? NotepadFonts.editor, isMultiple: false)
        fontManager.orderFrontFontPanel(nil)
    }

    @objc func changeFont(_ sender: Any?) {
        guard let fontManager = sender as? NSFontManager else { return }
        let newFont = fontManager.convert(textView.font ?? NotepadFonts.editor)
        textView.font = newFont
    }

    // MARK: - Word Wrap

    var isWordWrapEnabled: Bool { wordWrapEnabled }

    func toggleWordWrap() {
        wordWrapEnabled.toggle()
        updateWordWrap()
        // Status bar only visible when word wrap is OFF (classic Notepad behavior)
        statusBarVisible = !wordWrapEnabled
        updateLayout()
    }

    private func updateWordWrap() {
        guard let textContainer = textView.textContainer else { return }

        if wordWrapEnabled {
            textView.isHorizontallyResizable = false
            textContainer.widthTracksTextView = true
            textContainer.size = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = false
        } else {
            textView.isHorizontallyResizable = true
            textContainer.widthTracksTextView = false
            textContainer.size = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = true
        }

        textView.needsDisplay = true
    }

    // MARK: - Status Bar

    func toggleStatusBar() {
        // In classic Notepad, status bar is only available when word wrap is off
        if wordWrapEnabled { return }
        statusBarVisible.toggle()
        updateLayout()
    }

    private func updateStatusBar() {
        let (line, column) = currentLineAndColumn()
        let statusView = StatusBarView(line: line, column: column)
        statusBarHostView.rootView = statusView
    }

    private func currentLineAndColumn() -> (Int, Int) {
        let text = textView.string
        let selectedRange = textView.selectedRange()
        let nsText = text as NSString

        // Count lines up to cursor position
        var lineNumber = 1
        var lineStart = 0
        let cursorPos = selectedRange.location

        nsText.enumerateSubstrings(in: NSRange(location: 0, length: min(cursorPos, nsText.length)),
                                    options: [.byLines, .substringNotRequired]) { _, range, _, _ in
            lineNumber += 1
            lineStart = range.location + range.length
            _ = lineStart
        }

        // Column is 1-based offset from line start
        let column = cursorPos - lineStart + 1
        return (lineNumber, max(column, 1))
    }

    // MARK: - Search

    func showFind() {
        findReplacePanel.showFind(relativeTo: window)
    }

    func showReplace() {
        findReplacePanel.showReplace(relativeTo: window)
    }

    func findNextFromMenu() {
        findReplacePanel.findNext()
    }

    func showGoToLine() {
        goToLinePanel.show(relativeTo: window)
    }

    // MARK: - FindReplacePanelDelegate

    func findNext(searchText: String, matchCase: Bool, searchDown: Bool) {
        let text = textView.string as NSString
        let selectedRange = textView.selectedRange()

        let searchRange: NSRange
        if searchDown {
            let start = selectedRange.location + selectedRange.length
            searchRange = NSRange(location: start, length: text.length - start)
        } else {
            searchRange = NSRange(location: 0, length: selectedRange.location)
        }

        var options: NSString.CompareOptions = searchDown ? [] : .backwards
        if !matchCase { options.insert(.caseInsensitive) }

        let foundRange = text.range(of: searchText, options: options, range: searchRange)
        if foundRange.location != NSNotFound {
            textView.setSelectedRange(foundRange)
            textView.scrollRangeToVisible(foundRange)
        } else {
            // Wrap around search
            let wrapRange = NSRange(location: 0, length: text.length)
            let wrapFound = text.range(of: searchText, options: matchCase ? [] : [.caseInsensitive], range: wrapRange)
            if wrapFound.location != NSNotFound {
                textView.setSelectedRange(wrapFound)
                textView.scrollRangeToVisible(wrapFound)
            } else {
                let alert = NSAlert()
                alert.messageText = "Notepad"
                alert.informativeText = "Cannot find \"\(searchText)\""
                alert.runModal()
            }
        }
    }

    func replace(searchText: String, replacementText: String, matchCase: Bool, searchDown: Bool) {
        let selectedRange = textView.selectedRange()
        let selectedText = (textView.string as NSString).substring(with: selectedRange)

        let match: Bool
        if matchCase {
            match = selectedText == searchText
        } else {
            match = selectedText.caseInsensitiveCompare(searchText) == .orderedSame
        }

        if match && selectedRange.length > 0 {
            if textView.shouldChangeText(in: selectedRange, replacementString: replacementText) {
                textView.replaceCharacters(in: selectedRange, with: replacementText)
                textView.didChangeText()
            }
        }

        findNext(searchText: searchText, matchCase: matchCase, searchDown: searchDown)
    }

    func replaceAll(searchText: String, replacementText: String, matchCase: Bool) {
        let text = textView.string as NSString
        let newText = text.replacingOccurrences(of: searchText, with: replacementText,
                                                 options: matchCase ? [] : [.caseInsensitive],
                                                 range: NSRange(location: 0, length: text.length))
        let fullRange = NSRange(location: 0, length: text.length)
        if textView.shouldChangeText(in: fullRange, replacementString: newText) {
            textView.replaceCharacters(in: fullRange, with: newText)
            textView.didChangeText()
        }
    }

    // MARK: - GoToLinePanelDelegate

    func goToLine(_ lineNumber: Int) {
        let text = textView.string as NSString
        var currentLine = 1
        var lineRange = NSRange(location: 0, length: 0)

        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length),
                                  options: [.byLines, .substringNotRequired]) { _, range, _, stop in
            if currentLine == lineNumber {
                lineRange = range
                stop.pointee = true
            }
            currentLine += 1
        }

        if lineNumber <= currentLine {
            let cursorRange = NSRange(location: lineRange.location, length: 0)
            textView.setSelectedRange(cursorRange)
            textView.scrollRangeToVisible(cursorRange)
        }
    }

    // MARK: - Page Setup & Print

    func pageSetup() {
        let printInfo = NSPrintInfo.shared
        let pageSetup = NSPageLayout()
        pageSetup.runModal(with: printInfo)
    }

    func printDocument() {
        let printOp = NSPrintOperation(view: textView)
        printOp.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return promptSaveIfNeeded()
    }

    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: NotepadWindowController.savedFrameKey)
        delegate?.windowControllerDidClose(self)
    }

    func windowDidResize(_ notification: Notification) {
        if wordWrapEnabled {
            textView.textContainer?.size = NSSize(width: scrollView.contentSize.width,
                                                   height: CGFloat.greatestFiniteMagnitude)
        }
    }
}

// MARK: - NSTextViewDelegate

extension NotepadWindowController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        markEdited()
        updateStatusBar()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        updateStatusBar()
    }
}
