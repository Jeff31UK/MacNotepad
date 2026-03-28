import Cocoa

protocol GoToLinePanelDelegate: AnyObject {
    func goToLine(_ lineNumber: Int)
}

class GoToLinePanel {
    weak var delegate: GoToLinePanelDelegate?

    func show(relativeTo window: NSWindow) {
        let alert = NSAlert()
        alert.messageText = "Go To Line"
        alert.informativeText = "Line number:"
        alert.addButton(withTitle: "Go To")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.font = NotepadFonts.menuFont
        input.placeholderString = "Line number"
        alert.accessoryView = input

        alert.beginSheetModal(for: window) { [weak self] response in
            if response == .alertFirstButtonReturn {
                if let lineNumber = Int(input.stringValue), lineNumber > 0 {
                    self?.delegate?.goToLine(lineNumber)
                } else {
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Go To Line"
                    errorAlert.informativeText = "Invalid line number."
                    errorAlert.alertStyle = .warning
                    errorAlert.runModal()
                }
            }
        }

        // Focus the text field after the sheet appears
        DispatchQueue.main.async {
            input.selectText(nil)
            window.makeFirstResponder(input)
        }
    }
}
