import Cocoa

enum NotepadColors {
    // Main background - adapts to system appearance
    static let windowBackground = NSColor.windowBackgroundColor

    // 3D button/border effects
    static let buttonHighlight = NSColor(name: "buttonHighlight") { appearance in
        appearance.isDark ? NSColor(white: 0.45, alpha: 1.0) : NSColor.white
    }
    static let buttonShadow = NSColor(name: "buttonShadow") { appearance in
        appearance.isDark ? NSColor(white: 0.15, alpha: 1.0) : NSColor(white: 0.5, alpha: 1.0)
    }
    static let buttonDarkShadow = NSColor(name: "buttonDarkShadow") { appearance in
        appearance.isDark ? NSColor(white: 0.05, alpha: 1.0) : NSColor(white: 0.25, alpha: 1.0)
    }
    static let buttonFace = NSColor.controlColor

    // Content areas
    static let contentBackground = NSColor.textBackgroundColor
    static let contentText = NSColor.textColor

    // Status bar
    static let statusBarBackground = NSColor.windowBackgroundColor
    static let statusBarText = NSColor.secondaryLabelColor

    // Sunken border (inset panels)
    static let sunkenBorderDark = NSColor.separatorColor
    static let sunkenBorderLight = NSColor(name: "sunkenBorderLight") { appearance in
        appearance.isDark ? NSColor(white: 0.35, alpha: 1.0) : NSColor.white
    }
}

// Helper to detect dark appearance
extension NSAppearance {
    var isDark: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
