#!/usr/bin/env python3
"""Generate a retro Windows 3.1-style Notepad icon at multiple sizes."""

from PIL import Image, ImageDraw
import os

def draw_notepad_icon(size):
    """Draw a retro notepad icon reminiscent of the classic Windows Notepad."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    s = size / 512.0  # scale factor

    # Slight shadow behind the notepad
    shadow_offset = int(6 * s)
    shadow_coords = [
        int(80*s) + shadow_offset, int(30*s) + shadow_offset,
        int(430*s) + shadow_offset, int(480*s) + shadow_offset
    ]
    draw.rectangle(shadow_coords, fill=(0, 0, 0, 60))

    # Main notepad body - cream/yellow paper
    paper_color = (255, 255, 220)
    paper_left = int(80*s)
    paper_top = int(30*s)
    paper_right = int(430*s)
    paper_bottom = int(480*s)
    draw.rectangle([paper_left, paper_top, paper_right, paper_bottom], fill=paper_color)

    # 3D raised border (Win3.1 style)
    border_w = max(int(3*s), 1)
    # Top/left highlight (white)
    for i in range(border_w):
        draw.line([(paper_left-i, paper_bottom+i), (paper_left-i, paper_top-i)], fill=(255, 255, 255), width=1)
        draw.line([(paper_left-i, paper_top-i), (paper_right+i, paper_top-i)], fill=(255, 255, 255), width=1)
    # Bottom/right shadow (dark gray)
    for i in range(border_w):
        draw.line([(paper_right+i, paper_top-i), (paper_right+i, paper_bottom+i)], fill=(80, 80, 80), width=1)
        draw.line([(paper_right+i, paper_bottom+i), (paper_left-i, paper_bottom+i)], fill=(80, 80, 80), width=1)

    # Blue title bar at top of notepad
    title_top = paper_top
    title_bottom = paper_top + int(45*s)
    title_color = (0, 0, 128)  # Classic dark blue
    draw.rectangle([paper_left, title_top, paper_right, title_bottom], fill=title_color)

    # Title bar text - draw simple pixel "Notepad" text
    text_y = title_top + int(10*s)
    text_x = paper_left + int(15*s)
    text_h = int(22*s)
    text_color = (255, 255, 255)

    # Simple block letters "NOTE" (retro pixel style)
    char_w = int(18*s)
    char_gap = int(4*s)

    def draw_block_char(x, y, ch, h, w):
        """Draw simplified block characters."""
        t = max(int(3*s), 1)  # stroke thickness
        if ch == 'N':
            draw.rectangle([x, y, x+t, y+h], fill=text_color)
            draw.rectangle([x+w-t, y, x+w, y+h], fill=text_color)
            # diagonal
            for i in range(h):
                dx = int(i * w / h)
                draw.rectangle([x+dx, y+i, x+dx+t, y+i+t], fill=text_color)
        elif ch == 'O':
            draw.rectangle([x, y, x+w, y+t], fill=text_color)
            draw.rectangle([x, y+h-t, x+w, y+h], fill=text_color)
            draw.rectangle([x, y, x+t, y+h], fill=text_color)
            draw.rectangle([x+w-t, y, x+w, y+h], fill=text_color)
        elif ch == 'T':
            draw.rectangle([x, y, x+w, y+t], fill=text_color)
            draw.rectangle([x+w//2-t//2, y, x+w//2+t//2+t, y+h], fill=text_color)
        elif ch == 'E':
            draw.rectangle([x, y, x+w, y+t], fill=text_color)
            draw.rectangle([x, y+h//2-t//2, x+w-int(3*s), y+h//2+t//2], fill=text_color)
            draw.rectangle([x, y+h-t, x+w, y+h], fill=text_color)
            draw.rectangle([x, y, x+t, y+h], fill=text_color)
        elif ch == 'P':
            draw.rectangle([x, y, x+t, y+h], fill=text_color)
            draw.rectangle([x, y, x+w, y+t], fill=text_color)
            draw.rectangle([x, y+h//2-t//2, x+w, y+h//2+t//2], fill=text_color)
            draw.rectangle([x+w-t, y, x+w, y+h//2], fill=text_color)
        elif ch == 'A':
            draw.rectangle([x, y, x+w, y+t], fill=text_color)
            draw.rectangle([x, y, x+t, y+h], fill=text_color)
            draw.rectangle([x+w-t, y, x+w, y+h], fill=text_color)
            draw.rectangle([x, y+h//2-t//2, x+w, y+h//2+t//2], fill=text_color)
        elif ch == 'D':
            draw.rectangle([x, y, x+t, y+h], fill=text_color)
            draw.rectangle([x, y, x+w-int(5*s), y+t], fill=text_color)
            draw.rectangle([x, y+h-t, x+w-int(5*s), y+h], fill=text_color)
            # curved right side approximation
            draw.rectangle([x+w-t, y+int(5*s), x+w, y+h-int(5*s)], fill=text_color)
            draw.rectangle([x+w-int(5*s)-t, y, x+w-int(5*s), y+int(5*s)], fill=text_color)
            draw.rectangle([x+w-int(5*s)-t, y+h-int(5*s), x+w-int(5*s), y+h], fill=text_color)

    for i, ch in enumerate("NOTEPAD"):
        draw_block_char(text_x + i * (char_w + char_gap), text_y, ch, text_h, char_w)

    # Lined paper - horizontal blue lines
    line_color = (180, 200, 230)
    content_top = title_bottom + int(15*s)
    line_spacing = int(28*s)
    margin_left = paper_left + int(20*s)
    margin_right = paper_right - int(20*s)

    line_y = content_top
    while line_y < paper_bottom - int(25*s):
        draw.line([(margin_left, line_y), (margin_right, line_y)], fill=line_color, width=max(int(1.5*s), 1))
        line_y += line_spacing

    # Red margin line (classic ruled paper)
    red_margin_x = paper_left + int(55*s)
    draw.line([(red_margin_x, content_top - int(10*s)), (red_margin_x, paper_bottom - int(10*s))],
              fill=(220, 80, 80), width=max(int(2*s), 1))

    # Simulated text scribbles on the lines
    scribble_color = (40, 40, 40)
    scribble_h = max(int(3*s), 1)
    text_left = red_margin_x + int(15*s)

    # Different length "text" blocks on each line
    line_y = content_top
    text_patterns = [0.85, 0.6, 0.75, 0.4, 0.9, 0.55, 0.7, 0.3, 0.65, 0.8, 0.5, 0.45]
    pattern_idx = 0
    while line_y < paper_bottom - int(25*s):
        width_frac = text_patterns[pattern_idx % len(text_patterns)]
        text_width = int((margin_right - text_left) * width_frac)

        # Draw text as small dashes to look like handwriting
        tx = text_left
        while tx < text_left + text_width:
            word_len = int((8 + (pattern_idx * 7 + tx) % 20) * s)
            word_end = min(tx + word_len, text_left + text_width)
            draw.rectangle([tx, line_y - int(8*s), word_end, line_y - int(8*s) + scribble_h], fill=scribble_color)
            tx = word_end + int(6*s)

        line_y += line_spacing
        pattern_idx += 1

    # Pencil laying diagonally across bottom-right
    pencil_color = (220, 180, 50)       # Yellow pencil body
    pencil_dark = (180, 140, 30)        # Darker edge
    pencil_tip = (60, 50, 40)           # Dark tip
    pencil_eraser = (230, 120, 130)     # Pink eraser
    pencil_band = (180, 180, 180)       # Metal band

    # Pencil coordinates (diagonal from bottom-left area to right)
    px1, py1 = int(200*s), int(500*s)   # eraser end
    px2, py2 = int(470*s), int(360*s)   # tip end

    pencil_w = int(18*s)

    # Calculate pencil direction
    import math
    dx = px2 - px1
    dy = py2 - py1
    length = math.sqrt(dx*dx + dy*dy)
    nx = -dy / length * pencil_w / 2  # normal x
    ny = dx / length * pencil_w / 2   # normal y

    # Pencil body polygon
    body_start = 0.12  # where body starts (after eraser)
    body_end = 0.88    # where body ends (before tip)

    bx1 = px1 + dx * body_start
    by1 = py1 + dy * body_start
    bx2 = px1 + dx * body_end
    by2 = py1 + dy * body_end

    body_poly = [
        (bx1 + nx, by1 + ny),
        (bx2 + nx, by2 + ny),
        (bx2 - nx, by2 - ny),
        (bx1 - nx, by1 - ny),
    ]
    draw.polygon(body_poly, fill=pencil_color, outline=pencil_dark)

    # Eraser
    ex1, ey1 = px1, py1
    ex2, ey2 = bx1, by1
    eraser_poly = [
        (ex1 + nx*0.8, ey1 + ny*0.8),
        (ex2 + nx, ey2 + ny),
        (ex2 - nx, ey2 - ny),
        (ex1 - nx*0.8, ey1 - ny*0.8),
    ]
    draw.polygon(eraser_poly, fill=pencil_eraser)

    # Metal band between eraser and body
    band_start = body_start - 0.02
    band_end = body_start + 0.02
    mbx1 = px1 + dx * band_start
    mby1 = py1 + dy * band_start
    mbx2 = px1 + dx * band_end
    mby2 = py1 + dy * band_end
    band_poly = [
        (mbx1 + nx, mby1 + ny),
        (mbx2 + nx, mby2 + ny),
        (mbx2 - nx, mby2 - ny),
        (mbx1 - nx, mby1 - ny),
    ]
    draw.polygon(band_poly, fill=pencil_band)

    # Pencil tip (triangle)
    tip_poly = [
        (bx2 + nx, by2 + ny),
        (px2, py2),
        (bx2 - nx, by2 - ny),
    ]
    draw.polygon(tip_poly, fill=(240, 220, 180))

    # Dark point at very tip
    tip_r = int(4*s)
    draw.ellipse([px2-tip_r, py2-tip_r, px2+tip_r, py2+tip_r], fill=pencil_tip)

    return img


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    icon_dir = os.path.join(script_dir, "MacNotepad", "Resources", "Assets.xcassets", "AppIcon.appiconset")

    sizes = {
        "icon_16x16.png": 16,
        "icon_32x32.png": 32,
        "icon_64x64.png": 64,
        "icon_128x128.png": 128,
        "icon_256x256.png": 256,
        "icon_512x512.png": 512,
        "icon_1024x1024.png": 1024,
    }

    for filename, size in sizes.items():
        print(f"Generating {filename} ({size}x{size})...")
        img = draw_notepad_icon(size)
        img.save(os.path.join(icon_dir, filename))

    print("Done! Icon files generated.")


if __name__ == "__main__":
    main()
