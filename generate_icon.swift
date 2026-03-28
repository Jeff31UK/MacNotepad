#!/usr/bin/env swift

import Cocoa

func drawNotepadIcon(size: Int) -> NSImage {
    let s = CGFloat(size) / 512.0
    let img = NSImage(size: NSSize(width: size, height: size))

    img.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    // Flip to top-left origin
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)

    // Clear
    ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

    // Shadow
    let so = 6 * s
    ctx.setFillColor(NSColor(white: 0, alpha: 0.15).cgColor)
    ctx.fill(CGRect(x: 80*s + so, y: 30*s + so, width: 350*s, height: 450*s))

    // Paper body
    let pl = 80*s, pt = 30*s, pw = 350*s, ph = 450*s
    ctx.setFillColor(NSColor(red: 1, green: 1, blue: 0.86, alpha: 1).cgColor)
    ctx.fill(CGRect(x: pl, y: pt, width: pw, height: ph))

    // 3D border
    let bw = max(3*s, 1)
    // White top/left
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(bw)
    ctx.move(to: CGPoint(x: pl - bw/2, y: pt + ph + bw/2))
    ctx.addLine(to: CGPoint(x: pl - bw/2, y: pt - bw/2))
    ctx.addLine(to: CGPoint(x: pl + pw + bw/2, y: pt - bw/2))
    ctx.strokePath()
    // Dark bottom/right
    ctx.setStrokeColor(NSColor(white: 0.31, alpha: 1).cgColor)
    ctx.move(to: CGPoint(x: pl + pw + bw/2, y: pt - bw/2))
    ctx.addLine(to: CGPoint(x: pl + pw + bw/2, y: pt + ph + bw/2))
    ctx.addLine(to: CGPoint(x: pl - bw/2, y: pt + ph + bw/2))
    ctx.strokePath()

    // Blue title bar
    let tt = pt, tb = pt + 45*s
    ctx.setFillColor(NSColor(red: 0, green: 0, blue: 0.5, alpha: 1).cgColor)
    ctx.fill(CGRect(x: pl, y: tt, width: pw, height: 45*s))

    // Title text "NOTEPAD" as simple block letters
    let tc = NSColor.white.cgColor
    let charH = 20*s
    let stroke = max(3*s, 1)
    let charW = 18*s
    let gap = 4*s
    let textY = tt + 12*s
    let textX = pl + 15*s

    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        ctx.setFillColor(tc)
        ctx.fill(CGRect(x: x, y: y, width: w, height: h))
    }

    func drawChar(_ ch: Character, _ x: CGFloat, _ y: CGFloat) {
        let w = charW, h = charH, t = stroke
        switch ch {
        case "N":
            rect(x, y, t, h); rect(x+w-t, y, t, h)
            for i in stride(from: CGFloat(0), to: h, by: 1) {
                let dx = i * w / h
                rect(x+dx, y+i, t, 1)
            }
        case "O":
            rect(x, y, w, t); rect(x, y+h-t, w, t)
            rect(x, y, t, h); rect(x+w-t, y, t, h)
        case "T":
            rect(x, y, w, t); rect(x+w/2-t/2, y, t, h)
        case "E":
            rect(x, y, w, t); rect(x, y+h/2, w-3*s, t)
            rect(x, y+h-t, w, t); rect(x, y, t, h)
        case "P":
            rect(x, y, t, h); rect(x, y, w, t)
            rect(x, y+h/2, w, t); rect(x+w-t, y, t, h/2+t)
        case "A":
            rect(x, y, w, t); rect(x, y, t, h)
            rect(x+w-t, y, t, h); rect(x, y+h/2, w, t)
        case "D":
            rect(x, y, t, h); rect(x, y, w-5*s, t)
            rect(x, y+h-t, w-5*s, t); rect(x+w-t, y+5*s, t, h-10*s)
        default: break
        }
    }

    for (i, ch) in "NOTEPAD".enumerated() {
        drawChar(ch, textX + CGFloat(i) * (charW + gap), textY)
    }

    // Lined paper
    let contentTop = tb + 15*s
    let lineSpacing = 28*s
    let ml = pl + 20*s, mr = pl + pw - 20*s

    ctx.setStrokeColor(NSColor(red: 0.71, green: 0.78, blue: 0.9, alpha: 1).cgColor)
    ctx.setLineWidth(max(1.5*s, 1))
    var ly = contentTop
    while ly < pt + ph - 25*s {
        ctx.move(to: CGPoint(x: ml, y: ly))
        ctx.addLine(to: CGPoint(x: mr, y: ly))
        ctx.strokePath()
        ly += lineSpacing
    }

    // Red margin line
    let rmx = pl + 55*s
    ctx.setStrokeColor(NSColor(red: 0.86, green: 0.31, blue: 0.31, alpha: 1).cgColor)
    ctx.setLineWidth(max(2*s, 1))
    ctx.move(to: CGPoint(x: rmx, y: contentTop - 10*s))
    ctx.addLine(to: CGPoint(x: rmx, y: pt + ph - 10*s))
    ctx.strokePath()

    // Text scribbles
    let textLeft = rmx + 15*s
    let scribbleH = max(3*s, 1)
    let pats: [CGFloat] = [0.85, 0.6, 0.75, 0.4, 0.9, 0.55, 0.7, 0.3, 0.65, 0.8, 0.5, 0.45]
    ctx.setFillColor(NSColor(white: 0.16, alpha: 1).cgColor)
    ly = contentTop
    var pi = 0
    while ly < pt + ph - 25*s {
        let tw = (mr - textLeft) * pats[pi % pats.count]
        var tx = textLeft
        while tx < textLeft + tw {
            let wl = (8 + CGFloat((pi * 7 + Int(tx)) % 20)) * s
            let we = min(tx + wl, textLeft + tw)
            ctx.fill(CGRect(x: tx, y: ly - 8*s, width: we - tx, height: scribbleH))
            tx = we + 6*s
        }
        ly += lineSpacing
        pi += 1
    }

    // Pencil (diagonal)
    let px1 = 200*s, py1 = 500*s
    let px2 = 470*s, py2 = 360*s
    let pencilW = 18*s
    let dx = px2 - px1, dy = py2 - py1
    let length = sqrt(dx*dx + dy*dy)
    let nx = -dy / length * pencilW / 2
    let ny = dx / length * pencilW / 2

    let bs: CGFloat = 0.12, be: CGFloat = 0.88
    let bx1 = px1 + dx*bs, by1 = py1 + dy*bs
    let bx2 = px1 + dx*be, by2 = py1 + dy*be

    // Body
    ctx.setFillColor(NSColor(red: 0.86, green: 0.71, blue: 0.2, alpha: 1).cgColor)
    ctx.move(to: CGPoint(x: bx1+nx, y: by1+ny))
    ctx.addLine(to: CGPoint(x: bx2+nx, y: by2+ny))
    ctx.addLine(to: CGPoint(x: bx2-nx, y: by2-ny))
    ctx.addLine(to: CGPoint(x: bx1-nx, y: by1-ny))
    ctx.closePath()
    ctx.fillPath()

    // Darker outline
    ctx.setStrokeColor(NSColor(red: 0.71, green: 0.55, blue: 0.12, alpha: 1).cgColor)
    ctx.setLineWidth(max(s, 0.5))
    ctx.move(to: CGPoint(x: bx1+nx, y: by1+ny))
    ctx.addLine(to: CGPoint(x: bx2+nx, y: by2+ny))
    ctx.addLine(to: CGPoint(x: bx2-nx, y: by2-ny))
    ctx.addLine(to: CGPoint(x: bx1-nx, y: by1-ny))
    ctx.closePath()
    ctx.strokePath()

    // Eraser
    ctx.setFillColor(NSColor(red: 0.9, green: 0.47, blue: 0.51, alpha: 1).cgColor)
    ctx.move(to: CGPoint(x: px1+nx*0.8, y: py1+ny*0.8))
    ctx.addLine(to: CGPoint(x: bx1+nx, y: by1+ny))
    ctx.addLine(to: CGPoint(x: bx1-nx, y: by1-ny))
    ctx.addLine(to: CGPoint(x: px1-nx*0.8, y: py1-ny*0.8))
    ctx.closePath()
    ctx.fillPath()

    // Metal band
    let mbs: CGFloat = 0.10, mbe: CGFloat = 0.14
    let mbx1 = px1+dx*mbs, mby1 = py1+dy*mbs
    let mbx2 = px1+dx*mbe, mby2 = py1+dy*mbe
    ctx.setFillColor(NSColor(white: 0.7, alpha: 1).cgColor)
    ctx.move(to: CGPoint(x: mbx1+nx, y: mby1+ny))
    ctx.addLine(to: CGPoint(x: mbx2+nx, y: mby2+ny))
    ctx.addLine(to: CGPoint(x: mbx2-nx, y: mby2-ny))
    ctx.addLine(to: CGPoint(x: mbx1-nx, y: mby1-ny))
    ctx.closePath()
    ctx.fillPath()

    // Tip
    ctx.setFillColor(NSColor(red: 0.94, green: 0.86, blue: 0.71, alpha: 1).cgColor)
    ctx.move(to: CGPoint(x: bx2+nx, y: by2+ny))
    ctx.addLine(to: CGPoint(x: px2, y: py2))
    ctx.addLine(to: CGPoint(x: bx2-nx, y: by2-ny))
    ctx.closePath()
    ctx.fillPath()

    // Dark point
    let tr = 4*s
    ctx.setFillColor(NSColor(red: 0.24, green: 0.2, blue: 0.16, alpha: 1).cgColor)
    ctx.fillEllipse(in: CGRect(x: px2-tr, y: py2-tr, width: tr*2, height: tr*2))

    img.unlockFocus()
    return img
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                pixelsWide: size, pixelsHigh: size,
                                bitsPerSample: 8, samplesPerPixel: 4,
                                hasAlpha: true, isPlanar: false,
                                colorSpaceName: .deviceRGB,
                                bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

let iconDir = "MacNotepad/Resources/Assets.xcassets/AppIcon.appiconset"
let sizes = [
    ("icon_16x16.png", 16),
    ("icon_32x32.png", 32),
    ("icon_64x64.png", 64),
    ("icon_128x128.png", 128),
    ("icon_256x256.png", 256),
    ("icon_512x512.png", 512),
    ("icon_1024x1024.png", 1024),
]

for (name, size) in sizes {
    print("Generating \(name)...")
    let img = drawNotepadIcon(size: size)
    savePNG(img, to: "\(iconDir)/\(name)", size: size)
}
print("Done!")
