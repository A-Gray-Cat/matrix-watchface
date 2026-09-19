#!/usr/bin/env python3
"""Build an original Connect IQ BMFont for SYS.MATRIX rain.

Rasters half-width katakana from the Mac system gothic, mirrors them
(the film-code silhouette), thresholds to 1-bit, and maps the result
onto ASCII a-z0-9 plus a few symbols. Not Norfok, not a shipped TTF.
"""
from __future__ import print_function

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "resources", "fonts")
FONT_PATH = "/System/Library/Fonts/\u30d2\u30e9\u30ae\u30ce\u89d2\u30b4\u30b7\u30c3\u30af W3.ttc"

# ASCII ids the rain field will draw. Order matches KANA.
ASCII = "abcdefghijklmnopqrstuvwxyz0123456789*+$:=#"
KANA = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ"

CELL_W = 13
CELL_H = 20
PAD = 1
ATLAS_W = 256


def load_face(size):
    return ImageFont.truetype(FONT_PATH, size, index=0)


def render_kana(ch, face, src_size=80):
    canvas = Image.new("L", (src_size, src_size), 0)
    draw = ImageDraw.Draw(canvas)
    draw.text((src_size // 8, 0), ch, font=face, fill=255)
    bbox = canvas.getbbox()
    if bbox is None:
        return Image.new("L", (CELL_W - 2, CELL_H - 2), 0)
    glyph = canvas.crop(bbox)
    glyph = ImageOps.mirror(glyph)
    # Light thicken so strokes survive downsample, not a 1-bit smear.
    glyph = glyph.filter(ImageFilter.MaxFilter(3))
    gw, gh = glyph.size
    scale = min(float(CELL_W - 2) / gw, float(CELL_H - 2) / gh)
    nw = max(1, int(round(gw * scale)))
    nh = max(1, int(round(gh * scale)))
    glyph = glyph.resize((nw, nh), Image.Resampling.LANCZOS)
    glyph = glyph.point(lambda p: 255 if p > 70 else 0)
    return glyph


def pack(glyphs):
    x = PAD
    y = PAD
    row_h = CELL_H
    placements = []
    for ch, img in glyphs:
        gw, gh = img.size
        if x + gw + PAD > ATLAS_W:
            x = PAD
            y += row_h + PAD
        placements.append((ch, img, x, y, gw, gh))
        x += gw + PAD
    atlas_h = y + row_h + PAD
    # BMFont / CIQ like power-of-two pages.
    h = 32
    while h < atlas_h:
        h *= 2
    atlas = Image.new("L", (ATLAS_W, h), 0)
    chars = []
    for ch, img, px, py, gw, gh in placements:
        atlas.paste(img, (px, py))
        xoff = (CELL_W - gw) // 2
        yoff = (CELL_H - gh) // 2
        chars.append(
            {
                "id": ord(ch),
                "x": px,
                "y": py,
                "width": gw,
                "height": gh,
                "xoffset": xoff,
                "yoffset": yoff,
                "xadvance": CELL_W,
            }
        )
    return atlas, chars


def write_fnt(path, page_name, atlas, chars):
    lines = [
        'info face="MatrixRain" size={size} bold=0 italic=0 charset="" unicode=1 '
        "stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing={pad},{pad} outline=0".format(
            size=CELL_H, pad=PAD
        ),
        "common lineHeight={lh} base={base} scaleW={w} scaleH={h} pages=1 packed=0 "
        "alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0".format(
            lh=CELL_H, base=CELL_H - 2, w=atlas.size[0], h=atlas.size[1]
        ),
        'page id=0 file="{page}"'.format(page=page_name),
        "chars count={n}".format(n=len(chars)),
    ]
    for c in chars:
        lines.append(
            "char id={id:<3} x={x:<4} y={y:<4} width={width:<4} height={height:<4} "
            "xoffset={xoffset:<4} yoffset={yoffset:<4} xadvance={xadvance:<4} page=0  chnl=15".format(
                **c
            )
        )
    with open(path, "w") as fh:
        fh.write("\n".join(lines) + "\n")


def preview(glyphs, path):
    cols = 14
    rows = (len(glyphs) + cols - 1) // cols
    scale = 6
    im = Image.new("RGB", (cols * CELL_W * scale, rows * CELL_H * scale), (0, 0, 0))
    draw = ImageDraw.Draw(im)
    for i, (ch, g) in enumerate(glyphs):
        cx = (i % cols) * CELL_W
        cy = (i // cols) * CELL_H
        cell = Image.new("L", (CELL_W, CELL_H), 0)
        gw, gh = g.size
        cell.paste(g, ((CELL_W - gw) // 2, (CELL_H - gh) // 2))
        rgb = ImageOps.colorize(cell, (0, 0, 0), (0, 255, 65))
        rgb = rgb.resize((CELL_W * scale, CELL_H * scale), Image.Resampling.NEAREST)
        im.paste(rgb, (cx * scale, cy * scale))
        draw.text((cx * scale + 1, cy * scale + 1), ch, fill=(80, 80, 80))
    im.save(path)


def rain_sheet(glyphs, path, size=454, cols=32, rows=21):
    """Rough high-power face preview so we can judge density."""
    by_ch = {ch: g for ch, g in glyphs}
    im = Image.new("RGB", (size, size), (0, 0, 0))
    col_w = size / float(cols)
    row_h = size / float(rows)
    import random

    rng = random.Random(7)
    charset = ASCII
    for c in range(cols):
        head = rng.randint(0, rows)
        trail = 8 + rng.randint(0, 10)
        for d in range(trail):
            row = head - d
            if row < 0:
                continue
            ch = charset[(c * 13 + row * 7) % len(charset)]
            g = by_ch[ch]
            cell = Image.new("L", (CELL_W, CELL_H), 0)
            gw, gh = g.size
            cell.paste(g, ((CELL_W - gw) // 2, (CELL_H - gh) // 2))
            if d == 0:
                rgb = ImageOps.colorize(cell, (0, 0, 0), (200, 255, 200))
            elif d == 1:
                rgb = ImageOps.colorize(cell, (0, 0, 0), (0, 255, 65))
            elif d < 4:
                rgb = ImageOps.colorize(cell, (0, 0, 0), (20, 170, 55))
            else:
                rgb = ImageOps.colorize(cell, (0, 0, 0), (8, 78, 24))
            x = int((c + 0.5) * col_w - CELL_W / 2)
            y = int((row + 0.5) * row_h - CELL_H / 2)
            im.paste(rgb, (x, y), cell)
    # time overlay
    d = ImageDraw.Draw(im)
    try:
        tf = ImageFont.truetype(
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(size * 0.22)
        )
        bf = ImageFont.truetype(
            "/System/Library/Fonts/Supplemental/Arial.ttf", int(size * 0.045)
        )
    except Exception:
        tf = ImageFont.load_default()
        bf = tf
    cx = size // 2
    d.text((cx, int(size * 0.34)), "1915", font=tf, fill=(120, 255, 140), anchor="mm")
    d.text((cx, int(size * 0.48)), "42", font=bf, fill=(0, 255, 65), anchor="mm")
    d.text((cx, int(size * 0.12)), "root@fenix8:~#", font=bf, fill=(0, 255, 65), anchor="mm")
    im.save(path)


def main():
    assert len(ASCII) <= len(KANA), (len(ASCII), len(KANA))
    if not os.path.exists(FONT_PATH):
        raise SystemExit("missing Hiragino at %s" % FONT_PATH)
    face = load_face(72)
    glyphs = []
    for i, ch in enumerate(ASCII):
        glyphs.append((ch, render_kana(KANA[i], face)))
    os.makedirs(OUT_DIR, exist_ok=True)
    atlas, chars = pack(glyphs)
    png_name = "matrix_rain.png"
    atlas.save(os.path.join(OUT_DIR, png_name))
    write_fnt(os.path.join(OUT_DIR, "matrix_rain.fnt"), png_name, atlas, chars)
    preview(glyphs, os.path.join(ROOT, "mockups", "v4-glyphs.png"))
    rain_sheet(glyphs, os.path.join(ROOT, "mockups", "v4-rain.png"))
    print("wrote", os.path.join(OUT_DIR, png_name), atlas.size, "glyphs", len(chars))


if __name__ == "__main__":
    main()
