#!/usr/bin/env python3
"""Four ways to lift text off the rain — no big shadowy plate."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from render import (  # noqa: E402
    BRIGHT,
    CX,
    CY,
    DIM,
    MID,
    SIZE,
    TEXT,
    apply_circle,
    bezel,
    font,
    glow_text,
    rain_layer,
    scanlines,
)

OUT = Path(__file__).parent
MENLO = "/System/Library/Fonts/Menlo.ttc"


def ui_fonts():
    return {
        "time": font(MENLO, 92, 1),
        "body": font(MENLO, 18, 0),
        "tiny": font(MENLO, 14, 0),
    }


def draw_ui(img: Image.Image, *, halo: bool = False, bars: bool = False) -> None:
    f = ui_fonts()
    d = ImageDraw.Draw(img)

    def text(xy, s, fnt, fill, anchor="mm"):
        if bars:
            bbox = d.textbbox(xy, s, font=fnt, anchor=anchor)
            pad = 6
            d.rounded_rectangle(
                (bbox[0] - pad, bbox[1] - 3, bbox[2] + pad, bbox[3] + 3),
                4,
                fill=(0, 0, 0, 230),
            )
        if halo:
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)):
                d.text((xy[0] + dx, xy[1] + dy), s, font=fnt, fill=(0, 0, 0, 255), anchor=anchor)
        d.text(xy, s, font=fnt, fill=fill, anchor=anchor)

    if halo:
        glow_text(img, (CX, 158), "04:03", f["time"], TEXT, (0, 0, 0), radius=2)
        # extra black ring so digits punch
        for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
            d.text((CX + dx, 158 + dy), "04:03", font=f["time"], fill=(0, 0, 0, 255), anchor="mm")
        d.text((CX, 158), "04:03", font=f["time"], fill=(*TEXT, 255), anchor="mm")
    else:
        glow_text(img, (CX, 158), "04:03", f["time"], TEXT, (20, 140, 40), radius=8)

    text((CX, 58), "root@fenix8:~#", f["body"], (*BRIGHT, 255))
    text((CX, 218), ":10", f["body"], (*BRIGHT, 230))
    text((CX, 278), "THU  2026-09-17", f["body"], (*TEXT, 255))
    text((CX, 308), "70F  BKN", f["body"], (*TEXT, 255))
    text((CX, 338), "93%", f["body"], (*TEXT, 255))
    text((CX, 400), "epoch 1779138728", f["body"], (*MID, 230))


def knockout_ellipse(img: Image.Image, rx: float, ry: float) -> None:
    """Erase rain inside an ellipse — hole, not a drawn box."""
    px = img.load()
    rx2, ry2 = rx * rx, ry * ry
    for y in range(SIZE):
        for x in range(SIZE):
            if ((x - CX) ** 2) / rx2 + ((y - CY) ** 2) / ry2 <= 1.0:
                a = px[x, y][3] if len(px[x, y]) == 4 else 255
                if a:
                    px[x, y] = (0, 3, 0, 255)


def dim_center(img: Image.Image, inner=0.22, outer=0.55, keep=0.22) -> None:
    """Keep rain but crush its brightness toward the middle."""
    px = img.load()
    rmax = SIZE / 2
    for y in range(SIZE):
        for x in range(SIZE):
            dx, dy = x - CX, y - CY
            t = (dx * dx + dy * dy) ** 0.5 / rmax  # 0 center, 1 edge
            if t >= outer:
                continue
            if t <= inner:
                k = keep
            else:
                k = keep + (1.0 - keep) * (t - inner) / (outer - inner)
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * k), int(g * k), int(b * k), a)


def rain_sides_only() -> Image.Image:
    img = rain_layer(42, density=1.0)
    px = img.load()
    left, right = int(SIZE * 0.22), int(SIZE * 0.78)
    for y in range(SIZE):
        for x in range(left, right):
            px[x, y] = (0, 3, 0, 255)
    return img


def sheet(faces: list[tuple[str, Image.Image]]) -> Image.Image:
    framed = [(label, bezel(face)) for label, face in faces]
    fw, fh = framed[0][1].size
    gap, label_h, pad = 28, 48, 40
    cols_n, rows_n = 2, 2
    w = pad * 2 + cols_n * fw + (cols_n - 1) * gap
    h = pad * 2 + rows_n * (fh + label_h) + (rows_n - 1) * gap
    out = Image.new("RGB", (w, h), (10, 10, 12))
    d = ImageDraw.Draw(out)
    lab_f = ImageFont.truetype(MENLO, 15)
    for i, (label, im) in enumerate(framed):
        r, c = divmod(i, cols_n)
        x = pad + c * (fw + gap)
        y = pad + r * (fh + label_h + gap)
        out.paste(im.convert("RGB"), (x, y))
        d.text((x + fw // 2, y + fh + 22), label, font=lab_f, fill=(140, 255, 150), anchor="mm")
    return out


def main() -> None:
    # 1 halo
    a = rain_layer(42, density=1.0)
    draw_ui(a, halo=True)
    a = apply_circle(scanlines(a, 28))

    # 2 hole
    b = rain_layer(42, density=1.0)
    knockout_ellipse(b, rx=SIZE * 0.38, ry=SIZE * 0.42)
    draw_ui(b)
    b = apply_circle(scanlines(b, 28))

    # 3 tight bars
    c = rain_layer(42, density=1.0)
    draw_ui(c, bars=True)
    c = apply_circle(scanlines(c, 28))

    # 4 dim center (rain still there, quieter)
    d = rain_layer(42, density=1.0)
    dim_center(d, inner=0.18, outer=0.52, keep=0.18)
    draw_ui(d, halo=True)
    d = apply_circle(scanlines(d, 28))

    faces = [
        ("A  HALO  —  black outline on glyphs, rain stays", a),
        ("B  HOLE  —  rain skipped in the middle, no box", b),
        ("C  BARS  —  tight black strip behind each line", c),
        ("D  DIM   —  rain stays, just quieter under text", d),
    ]
    names = ["halo", "hole", "bars", "dim"]
    for (label, face), name in zip(faces, names):
        bezel(face).convert("RGB").save(OUT / f"vis-{name}.png")
        print("wrote", name)
    sheet(faces).save(OUT / "vis-sheet.png")
    print("wrote vis-sheet.png")


if __name__ == "__main__":
    main()
