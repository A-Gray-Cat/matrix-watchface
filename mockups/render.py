#!/usr/bin/env python3
"""Matrix / geek watch-face mockups for Fenix 8 (454x454 AMOLED)."""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

OUT = Path(__file__).parent
SIZE = 454
CX = CY = SIZE // 2
R = SIZE // 2 - 2

# Phosphor — slightly sickly CRT green, heads near-white (Matrix rain, not neon lime)
HEAD = (210, 255, 200)
BRIGHT = (80, 255, 110)
MID = (20, 170, 55)
DIM = (8, 78, 24)
GHOST = (4, 36, 10)
TEXT = (120, 255, 140)
SCRIM = (0, 4, 0)
AOD = (62, 110, 62)
BG = (0, 3, 0)

KATA = list("ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ012345789Z:.=*+")
MENLO = "/System/Library/Fonts/Menlo.ttc"
HIRA = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"

COLS, ROWS = 28, 26

# 4x7 bitmap digits — LED blocks sitting in the rain grid
DIGIT = {
    "0": ["0110", "1001", "1001", "1001", "1001", "1001", "0110"],
    "1": ["0010", "0110", "0010", "0010", "0010", "0010", "0111"],
    "2": ["0110", "1001", "0001", "0010", "0100", "1000", "1111"],
    "3": ["1110", "0001", "0001", "0110", "0001", "0001", "1110"],
    "4": ["0010", "0110", "1010", "1010", "1111", "0010", "0010"],
    "5": ["1111", "1000", "1110", "0001", "0001", "0001", "1110"],
    "6": ["0110", "1000", "1000", "1110", "1001", "1001", "0110"],
    "7": ["1111", "0001", "0010", "0010", "0100", "0100", "0100"],
    "8": ["0110", "1001", "1001", "0110", "1001", "1001", "0110"],
    "9": ["0110", "1001", "1001", "0111", "0001", "0001", "0110"],
    ":": ["00", "10", "10", "00", "10", "10", "00"],
}


def font(path: str, size: int, index: int = 0) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size, index=index)


def circle_mask() -> Image.Image:
    m = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(m).ellipse((1, 1, SIZE - 2, SIZE - 2), fill=255)
    return m


def in_circle(x: int, y: int, pad: int = 10) -> bool:
    return (x - CX) ** 2 + (y - CY) ** 2 <= (R - pad) ** 2


def cell_center(c: int, r: int) -> tuple[int, int]:
    x = int((c + 0.5) * SIZE / COLS)
    y = int((r + 0.5) * SIZE / ROWS)
    return x, y


def apply_circle(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    img.putalpha(circle_mask())
    return img


def scanlines(base: Image.Image, alpha: int = 40) -> Image.Image:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for y in range(0, SIZE, 2):
        d.line((0, y, SIZE, y), fill=(0, 0, 0, alpha))
    # faint phosphor haze
    haze = Image.new("RGBA", base.size, (20, 60, 20, 18))
    out = Image.alpha_composite(base.convert("RGBA"), haze)
    return Image.alpha_composite(out, overlay)


def radial_scrim(max_alpha: int = 200, inner: float = 0.18, outer: float = 0.62) -> Image.Image:
    """Darken the center so overlay text reads over rain."""
    grad = Image.radial_gradient("L").resize((SIZE, SIZE))
    # white at center -> we want high alpha at center
    scrim = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px_g = grad.load()
    px_s = scrim.load()
    for y in range(SIZE):
        for x in range(SIZE):
            # radial_gradient: 255 center, 0 edge
            t = px_g[x, y] / 255.0
            if t <= (1.0 - outer):
                a = 0
            elif t >= (1.0 - inner):
                a = max_alpha
            else:
                span = outer - inner
                a = int(max_alpha * (t - (1.0 - outer)) / span)
            px_s[x, y] = (0, 2, 0, a)
    return scrim


def glyph(ch: str, fnt: ImageFont.FreeTypeFont, fill: tuple, flip: bool) -> Image.Image:
    bbox = fnt.getbbox(ch) or (0, 0, 8, 12)
    w = max(1, bbox[2] - bbox[0] + 2)
    h = max(1, bbox[3] - bbox[1] + 2)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((-bbox[0] + 1, -bbox[1] + 1), ch, font=fnt, fill=fill)
    return ImageOps.mirror(im) if flip else im


def rain_layer(seed: int, *, density: float = 1.0, dim: float = 1.0, heads: bool = True) -> Image.Image:
    """Full-face digital rain. Heads are near-white, trails fall off to ghost green."""
    rng = random.Random(seed)
    rain = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fnt = font(HIRA, 14, 0)
    occupied = {}  # (c,r) -> (ch, dist_from_head)

    for c in range(COLS):
        if rng.random() > density:
            continue
        streams = 2 if rng.random() < 0.75 else 1
        used_heads = []
        for _ in range(streams):
            head = rng.randint(2, ROWS - 1)
            if any(abs(head - h) < 5 for h in used_heads):
                continue
            used_heads.append(head)
            length = rng.randint(9, ROWS)
            for dist in range(length):
                r = head - dist
                if r < 0:
                    break
                occupied[(c, r)] = (rng.choice(KATA), dist)

    for (c, r), (ch, dist) in occupied.items():
        x, y = cell_center(c, r)
        if not in_circle(x, y, 8):
            continue
        if dist == 0 and heads:
            fill = (*HEAD, int(255 * dim))
            do_glow = True
        elif dist == 1:
            fill = (*BRIGHT, int(230 * dim))
            do_glow = True
        elif dist < 4:
            fill = (*MID, int(170 * dim))
            do_glow = False
        elif dist < 8:
            fill = (*DIM, int(120 * dim))
            do_glow = False
        else:
            fill = (*GHOST, int(90 * dim))
            do_glow = False
        g = glyph(ch, fnt, fill, flip=True)
        rain.paste(g, (x - g.width // 2, y - g.height // 2), g)
        if do_glow:
            glow.paste(g, (x - g.width // 2, y - g.height // 2), g)

    glow = glow.filter(ImageFilter.GaussianBlur(radius=3))
    out = Image.new("RGBA", (SIZE, SIZE), (*BG, 255))
    out.alpha_composite(glow)
    out.alpha_composite(rain)
    return out


def glow_text(canvas, xy, text, fnt, color, glow_color, radius=8, anchor="mm"):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text(xy, text, font=fnt, fill=(*glow_color, 255), anchor=anchor)
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius=radius)))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius=max(2, radius // 3))))
    ImageDraw.Draw(canvas).text(xy, text, font=fnt, fill=(*color, 255), anchor=anchor)


def bezel(img: Image.Image) -> Image.Image:
    out = Image.new("RGBA", (SIZE + 72, SIZE + 72), (12, 12, 14, 255))
    ox = oy = 36
    d = ImageDraw.Draw(out)
    d.ellipse((ox - 10, oy - 10, ox + SIZE + 9, oy + SIZE + 9), fill=(28, 28, 30, 255))
    d.ellipse((ox - 4, oy - 4, ox + SIZE + 3, oy + SIZE + 3), fill=(8, 8, 8, 255))
    out.paste(img, (ox, oy), img.split()[-1])
    d.rounded_rectangle(
        (ox + SIZE + 6, oy + SIZE // 2 - 18, ox + SIZE + 22, oy + SIZE // 2 + 18),
        3,
        fill=(50, 50, 52, 255),
    )
    return out


def paint_bar(d: ImageDraw.ImageDraw, x: int, y: int, pct: int, w: int = 92, h: int = 8):
    d.rectangle((x, y - h // 2, x + w, y + h // 2), outline=(*MID, 220), width=1)
    fill_w = int((w - 2) * pct / 100)
    if fill_w > 0:
        d.rectangle((x + 1, y - h // 2 + 1, x + 1 + fill_w, y + h // 2 - 1), fill=(*BRIGHT, 230))


def local_scrim(img: Image.Image, box, alpha: int = 170, radius: int = 10) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, radius, fill=(0, 3, 0, alpha))
    img.alpha_composite(layer)


# --- variants ---------------------------------------------------------------


def render_rain_punch() -> Image.Image:
    """Full rain, time punched through with a center scrim. Most Matrix."""
    img = rain_layer(42, density=1.0)
    img.alpha_composite(radial_scrim(max_alpha=150, inner=0.14, outer=0.55))
    local_scrim(img, (70, 118, 384, 230), alpha=150, radius=12)
    local_scrim(img, (64, 250, 390, 360), alpha=140, radius=10)

    time_f = font(MENLO, 78, 0)
    sec_f = font(MENLO, 20, 0)
    body = font(MENLO, 16, 0)
    tiny = font(MENLO, 12, 0)

    glow_text(img, (CX, 158), "14:32", time_f, TEXT, (20, 140, 40), radius=9)
    d = ImageDraw.Draw(img)
    d.text((CX, 212), ":08", font=sec_f, fill=(*BRIGHT, 230), anchor="mm")
    d.text((CX, 64), "root@fenix8:~# █", font=tiny, fill=(*MID, 230), anchor="mm")

    rows = [
        ("dat", "2026-09-17  THU"),
        ("wx ", "18C  OVC  1013"),
        ("pwr", None),
    ]
    y0 = 272
    for i, (k, v) in enumerate(rows):
        y = y0 + i * 28
        d.text((86, y), k, font=tiny, fill=(*DIM, 255), anchor="lm")
        if v:
            d.text((128, y), v, font=body, fill=(*TEXT, 255), anchor="lm")
        else:
            d.text((128, y), "72%", font=body, fill=(*TEXT, 255), anchor="lm")
            paint_bar(d, 188, y, 72)

    d.text((CX, 400), "epoch 1779138728", font=tiny, fill=(*DIM, 210), anchor="mm")
    return apply_circle(scanlines(img, 36))


def render_crt() -> Image.Image:
    """Operator CRT window sitting in the rain."""
    img = rain_layer(9, density=1.0)

    x0, y0, x1, y1 = 62, 70, 392, 384
    glass = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(glass).rounded_rectangle((x0, y0, x1, y1), 6, fill=(0, 6, 0, 232))
    img.alpha_composite(glass)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((x0, y0, x1, y1), 6, outline=(*MID, 240), width=2)
    d.rectangle((x0 + 2, y0 + 2, x1 - 2, y0 + 26), fill=(0, 32, 10, 245))

    tiny = font(MENLO, 12, 0)
    body = font(MENLO, 15, 0)
    prompt = font(MENLO, 13, 0)
    time_f = font(MENLO, 42, 0)
    d.text((x0 + 12, y0 + 14), "tty1  root@fenix8", font=tiny, fill=(*BRIGHT, 255), anchor="lm")
    d.text((x1 - 14, y0 + 14), "x", font=tiny, fill=(*DIM, 255), anchor="rm")

    glow_text(img, (CX, y0 + 70), "14:32:08", time_f, TEXT, (20, 140, 40), radius=7)

    lines = [
        ("# date", True),
        ("THU  2026-09-17", False),
        ("# wx", True),
        ("18C  OVC  62%RH  1013hPa", False),
        ("# batt", True),
        ("72%  [########..]", False),
        ("#", True),
    ]
    y = y0 + 108
    for text, is_cmd in lines:
        fill = TEXT if is_cmd else BRIGHT
        d.text((x0 + 20, y), text, font=prompt if is_cmd else body, fill=(*fill, 245), anchor="lm")
        y += 22 if is_cmd else 24
    d.text((x0 + 38, y - 22), "█", font=prompt, fill=(*TEXT, 255), anchor="lm")
    return apply_circle(scanlines(img, 40))


def render_hud() -> Image.Image:
    """Geek HUD: corner brackets, METAR, hex battery. Same four fields, nerdier chrome."""
    img = rain_layer(21, density=0.85, dim=0.7)
    img.alpha_composite(radial_scrim(max_alpha=155, inner=0.2, outer=0.68))
    local_scrim(img, (72, 118, 382, 228), alpha=140, radius=12)
    d = ImageDraw.Draw(img)

    inset, arm, w = 54, 40, 3
    c = (*HEAD, 240)
    corners = [
        (inset, inset, 1, 1),
        (SIZE - inset, inset, -1, 1),
        (inset, SIZE - inset, 1, -1),
        (SIZE - inset, SIZE - inset, -1, -1),
    ]
    for x, y, dx, dy in corners:
        d.line((x, y, x + dx * arm, y), fill=c, width=w)
        d.line((x, y, x, y + dy * arm), fill=c, width=w)

    tiny = font(MENLO, 12, 0)
    body = font(MENLO, 16, 0)
    time_f = font(MENLO, 64, 0)
    d.text((CX, 70), "SYS.FENIX8  //  OK", font=tiny, fill=(*MID, 230), anchor="mm")

    glow_text(img, (CX, 160), "14:32", time_f, TEXT, (20, 140, 40), radius=8)
    d.text((CX, 212), ":08", font=font(MENLO, 18, 0), fill=(*BRIGHT, 230), anchor="mm")

    rows = [
        ("DAT", "2026-09-17  THU"),
        ("MET", "18C  OVC  1013"),
        ("PWR", "72%   0x48"),
    ]
    y = 262
    d.line((78, y - 14, 376, y - 14), fill=(*DIM, 180), width=1)
    for k, v in rows:
        d.text((86, y), k, font=tiny, fill=(*DIM, 255), anchor="lm")
        d.text((132, y), v, font=body, fill=(*TEXT, 255), anchor="lm")
        y += 28
    d.text((CX, 392), "epoch 1779138728", font=tiny, fill=(*DIM, 210), anchor="mm")
    return apply_circle(scanlines(img, 32))


def render_codegrid() -> Image.Image:
    """Time as LED pixels in the rain — the code field is the clock."""
    img = rain_layer(3, density=1.0, dim=0.85)
    # Dark plate behind the digits so rain doesn't fill the holes in 4 and 3
    local_scrim(img, (48, 52, 406, 210), alpha=175, radius=12)
    led = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    dled = ImageDraw.Draw(led)
    cw, rh = SIZE / COLS, SIZE / ROWS

    def plot(c: int, r: int) -> None:
        x, y = cell_center(c, r)
        if not in_circle(x, y, 10):
            return
        pad_x, pad_y = cw * 0.14, rh * 0.14
        box = (x - cw / 2 + pad_x, y - rh / 2 + pad_y, x + cw / 2 - pad_x, y + rh / 2 - pad_y)
        dled.rounded_rectangle(box, 2, fill=(*BRIGHT, 255))

    # 14:32 as 4x7, 1-col gaps, centered in 28 columns
    # 4+1+4+1+2+1+4+1+4 = 22 wide, origin col 3
    glyphs = [("1", 3), ("4", 8), (":", 13), ("3", 16), ("2", 21)]
    origin_r = 4
    for ch, origin_c in glyphs:
        for rr, row in enumerate(DIGIT[ch]):
            for cc, bit in enumerate(row):
                if bit == "1":
                    plot(origin_c + cc, origin_r + rr)

    img.alpha_composite(led.filter(ImageFilter.GaussianBlur(radius=3)))
    img.alpha_composite(led)

    local_scrim(img, (50, 268, 404, 392), alpha=155, radius=10)
    d = ImageDraw.Draw(img)
    body = font(MENLO, 15, 0)
    tiny = font(MENLO, 12, 0)
    d.text((CX, 48), "root@fenix8:~#", font=tiny, fill=(*MID, 230), anchor="mm")
    d.text((CX, 286), "2026-09-17  THU  :08", font=body, fill=(*TEXT, 255), anchor="mm")
    d.text((CX, 314), "wx  18C  OVC  1013hPa", font=body, fill=(*TEXT, 255), anchor="mm")
    d.text((CX, 342), "pwr 72%  [########..]", font=body, fill=(*TEXT, 255), anchor="mm")
    d.text((CX, 376), "epoch 1779138728", font=tiny, fill=(*DIM, 230), anchor="mm")
    return apply_circle(scanlines(img, 34))


def render_aod() -> Image.Image:
    """Always-on: sparse rain ghosts + thin time. Must stay dim for AMOLED."""
    img = rain_layer(42, density=0.28, dim=0.22, heads=False)
    time_f = font(MENLO, 48, 0)
    tiny = font(MENLO, 11, 0)
    glow_text(img, (CX + 8, CY - 8), "14:32", time_f, AOD, (12, 28, 12), radius=3)
    d = ImageDraw.Draw(img)
    d.text((CX + 8, CY + 32), "THU 17", font=tiny, fill=(*AOD, 150), anchor="mm")
    return apply_circle(img)


def sheet(faces: list[tuple[str, Image.Image]]) -> Image.Image:
    framed = [(label, bezel(face)) for label, face in faces]
    fw, fh = framed[0][1].size
    gap, label_h, pad = 28, 36, 40
    cols_n = 2
    rows_n = (len(framed) + 1) // 2
    w = pad * 2 + cols_n * fw + (cols_n - 1) * gap
    h = pad * 2 + rows_n * (fh + label_h) + (rows_n - 1) * gap
    out = Image.new("RGB", (w, h), (10, 10, 12))
    d = ImageDraw.Draw(out)
    lab_f = font(MENLO, 16, 0)
    for i, (label, im) in enumerate(framed):
        r, c = divmod(i, cols_n)
        x = pad + c * (fw + gap)
        y = pad + r * (fh + label_h + gap)
        out.paste(im.convert("RGB"), (x, y))
        d.text((x + fw // 2, y + fh + 18), label, font=lab_f, fill=(140, 255, 150), anchor="mm")
    return out


def main() -> None:
    faces = [
        ("1  RAIN  —  code field + punch-through time", render_rain_punch()),
        ("2  CRT  —  operator terminal in the rain", render_crt()),
        ("3  HUD  —  brackets, hex, METAR, epoch", render_hud()),
        ("4  GRID  —  time assembled from the rain", render_codegrid()),
    ]
    aod = render_aod()
    names = ["rain", "crt", "hud", "grid"]
    for (label, face), name in zip(faces, names):
        bezel(face).convert("RGB").save(OUT / f"matrix-{name}.png")
        face.save(OUT / f"matrix-{name}-face.png")
        print("wrote", name, label)
    bezel(aod).convert("RGB").save(OUT / "matrix-aod.png")
    aod.save(OUT / "matrix-aod-face.png")
    sheet(faces).save(OUT / "matrix-sheet.png")
    print("wrote sheet + aod")


if __name__ == "__main__":
    main()
