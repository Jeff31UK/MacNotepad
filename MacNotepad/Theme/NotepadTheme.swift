import Cocoa

enum NotepadTheme {
    static let statusBarHeight: CGFloat = 22
    static let sunkenBorderWidth: CGFloat = 1

    /// Draw a Win3.1-style sunken (inset) 3D border
    static func drawSunkenBorder(in rect: NSRect) {
        let path = NSBezierPath()

        // Dark top-left edges
        NotepadColors.buttonShadow.setStroke()
        path.move(to: NSPoint(x: rect.minX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - 1))
        path.line(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        path.lineWidth = sunkenBorderWidth
        path.stroke()

        // Light bottom-right edges
        let lightPath = NSBezierPath()
        NotepadColors.buttonHighlight.setStroke()
        lightPath.move(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        lightPath.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY))
        lightPath.line(to: NSPoint(x: rect.minX, y: rect.minY))
        lightPath.lineWidth = sunkenBorderWidth
        lightPath.stroke()
    }

    /// Draw a Win3.1-style raised (outset) 3D border
    static func drawRaisedBorder(in rect: NSRect) {
        let path = NSBezierPath()

        // Light top-left edges
        NotepadColors.buttonHighlight.setStroke()
        path.move(to: NSPoint(x: rect.minX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - 1))
        path.line(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        path.lineWidth = sunkenBorderWidth
        path.stroke()

        // Dark bottom-right edges
        let shadowPath = NSBezierPath()
        NotepadColors.buttonShadow.setStroke()
        shadowPath.move(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        shadowPath.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY))
        shadowPath.line(to: NSPoint(x: rect.minX, y: rect.minY))
        shadowPath.lineWidth = sunkenBorderWidth
        shadowPath.stroke()
    }
}
