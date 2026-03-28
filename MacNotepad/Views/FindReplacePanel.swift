import Cocoa

protocol FindReplacePanelDelegate: AnyObject {
    func findNext(searchText: String, matchCase: Bool, searchDown: Bool)
    func replace(searchText: String, replacementText: String, matchCase: Bool, searchDown: Bool)
    func replaceAll(searchText: String, replacementText: String, matchCase: Bool)
}

class FindReplacePanel {
    private var panel: NSPanel?
    private var findField: NSTextField!
    private var replaceField: NSTextField!
    private var replaceLabel: NSTextField!
    private var replaceButton: NSButton!
    private var replaceAllButton: NSButton!
    private var matchCaseCheck: NSButton!
    private var directionUp: NSButton!
    private var directionDown: NSButton!
    private var isReplaceMode = false

    weak var delegate: FindReplacePanelDelegate?

    func showFind(relativeTo window: NSWindow) {
        isReplaceMode = false
        showPanel(relativeTo: window)
    }

    func showReplace(relativeTo window: NSWindow) {
        isReplaceMode = true
        showPanel(relativeTo: window)
    }

    func findNext() {
        guard let text = findField?.stringValue, !text.isEmpty else { return }
        let matchCase = matchCaseCheck?.state == .on
        let searchDown = directionDown?.state == .on
        delegate?.findNext(searchText: text, matchCase: matchCase, searchDown: searchDown)
    }

    private func showPanel(relativeTo window: NSWindow) {
        if let existing = panel {
            updateLayout()
            existing.makeKeyAndOrderFront(nil)
            findField.selectText(nil)
            return
        }

        // Use a generous content height; position controls relative to bottom
        let panelWidth: CGFloat = 420
        let findContentHeight: CGFloat = 100
        let replaceContentHeight: CGFloat = 135
        let contentHeight = isReplaceMode ? replaceContentHeight : findContentHeight

        let panelRect = NSRect(x: 0, y: 0, width: panelWidth, height: contentHeight)
        let p = NSPanel(contentRect: panelRect,
                        styleMask: [.titled, .closable],
                        backing: .buffered, defer: false)
        p.title = isReplaceMode ? "Replace" : "Find"
        p.isFloatingPanel = true
        p.becomesKeyOnlyIfNeeded = true
        p.isReleasedWhenClosed = false
        p.center()

        // Build UI inside a container that sits within the content layout rect
        let container = NSView(frame: .zero)
        p.contentView = container

        // Position everything from the bottom up so nothing touches the title bar
        // Bottom row: Match case + Direction box (y = 8)
        // Row above: Find what label + field + Find Next button
        // Row above that (replace mode): Replace with label + field
        // Buttons on right: Find Next, Cancel, Replace, Replace All

        let bottomY: CGFloat = 8
        let row1Y: CGFloat = bottomY + 55   // Find what row
        let row2Y: CGFloat = row1Y + 32     // Replace with row (only in replace mode)

        let labelX: CGFloat = 12
        let fieldX: CGFloat = 100
        let fieldW: CGFloat = 195
        let btnX: CGFloat = 310
        let btnW: CGFloat = 95

        // Find label + field
        let findLabel = NSTextField(labelWithString: "Find what:")
        findLabel.frame = NSRect(x: labelX, y: row1Y + 2, width: 85, height: 17)
        findLabel.font = NotepadFonts.menuFont
        container.addSubview(findLabel)

        findField = NSTextField(frame: NSRect(x: fieldX, y: row1Y, width: fieldW, height: 22))
        findField.font = NotepadFonts.menuFont
        container.addSubview(findField)

        // Find Next button (aligned with find field row)
        let findNextBtn = NSButton(title: "Find Next", target: self, action: #selector(findNextClicked))
        findNextBtn.frame = NSRect(x: btnX, y: row1Y - 3, width: btnW, height: 28)
        findNextBtn.bezelStyle = .push
        findNextBtn.keyEquivalent = "\r"
        container.addSubview(findNextBtn)

        // Replace label + field
        replaceLabel = NSTextField(labelWithString: "Replace with:")
        replaceLabel.frame = NSRect(x: labelX, y: row2Y + 2, width: 85, height: 17)
        replaceLabel.font = NotepadFonts.menuFont
        container.addSubview(replaceLabel)

        replaceField = NSTextField(frame: NSRect(x: fieldX, y: row2Y, width: fieldW, height: 22))
        replaceField.font = NotepadFonts.menuFont
        container.addSubview(replaceField)

        // Cancel button (below Find Next)
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelBtn.frame = NSRect(x: btnX, y: row1Y - 35, width: btnW, height: 28)
        cancelBtn.bezelStyle = .push
        cancelBtn.keyEquivalent = "\u{1b}"
        container.addSubview(cancelBtn)

        // Replace button
        replaceButton = NSButton(title: "Replace", target: self, action: #selector(replaceClicked))
        replaceButton.frame = NSRect(x: btnX, y: row1Y - 67, width: btnW, height: 28)
        replaceButton.bezelStyle = .push
        container.addSubview(replaceButton)

        // Replace All button
        replaceAllButton = NSButton(title: "Replace All", target: self, action: #selector(replaceAllClicked))
        replaceAllButton.frame = NSRect(x: btnX, y: row1Y - 99, width: btnW, height: 28)
        replaceAllButton.bezelStyle = .push
        container.addSubview(replaceAllButton)

        // Match case checkbox
        matchCaseCheck = NSButton(checkboxWithTitle: "Match case", target: nil, action: nil)
        matchCaseCheck.frame = NSRect(x: labelX, y: bottomY, width: 110, height: 20)
        matchCaseCheck.font = NotepadFonts.menuFont
        container.addSubview(matchCaseCheck)

        // Direction radio buttons
        let dirBox = NSBox(frame: NSRect(x: 140, y: bottomY - 3, width: 140, height: 45))
        dirBox.title = "Direction"
        dirBox.titleFont = NotepadFonts.menuFont

        directionUp = NSButton(radioButtonWithTitle: "Up", target: nil, action: nil)
        directionUp.frame = NSRect(x: 10, y: 3, width: 50, height: 18)
        directionUp.font = NotepadFonts.menuFont
        dirBox.addSubview(directionUp)

        directionDown = NSButton(radioButtonWithTitle: "Down", target: nil, action: nil)
        directionDown.frame = NSRect(x: 65, y: 3, width: 60, height: 18)
        directionDown.font = NotepadFonts.menuFont
        directionDown.state = .on
        dirBox.addSubview(directionDown)

        container.addSubview(dirBox)

        panel = p

        updateLayout()
        p.makeKeyAndOrderFront(nil)
        findField.selectText(nil)
    }

    private func updateLayout() {
        let showReplace = isReplaceMode
        replaceLabel?.isHidden = !showReplace
        replaceField?.isHidden = !showReplace
        replaceButton?.isHidden = !showReplace
        replaceAllButton?.isHidden = !showReplace
        panel?.title = showReplace ? "Replace" : "Find"

        let contentHeight: CGFloat = showReplace ? 135 : 100
        if let panel = panel {
            var frame = panel.frame
            let oldHeight = frame.size.height
            // contentRect gives us just the content area size for the desired content height
            let newFrame = NSWindow.contentRect(forFrameRect: frame, styleMask: panel.styleMask)
            let titleBarHeight = frame.size.height - newFrame.size.height
            let newTotalHeight = contentHeight + titleBarHeight
            frame.origin.y -= (newTotalHeight - oldHeight)
            frame.size.height = newTotalHeight
            panel.setFrame(frame, display: true, animate: false)
        }
    }

    @objc private func findNextClicked() {
        findNext()
    }

    @objc private func replaceClicked() {
        guard let search = findField?.stringValue, !search.isEmpty else { return }
        let replacement = replaceField?.stringValue ?? ""
        let matchCase = matchCaseCheck?.state == .on
        let searchDown = directionDown?.state == .on
        delegate?.replace(searchText: search, replacementText: replacement, matchCase: matchCase, searchDown: searchDown)
    }

    @objc private func replaceAllClicked() {
        guard let search = findField?.stringValue, !search.isEmpty else { return }
        let replacement = replaceField?.stringValue ?? ""
        let matchCase = matchCaseCheck?.state == .on
        delegate?.replaceAll(searchText: search, replacementText: replacement, matchCase: matchCase)
    }

    @objc private func cancelClicked() {
        panel?.close()
    }
}
