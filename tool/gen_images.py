"""Draws the pictures we make ourselves (colours, shapes, numbers, letters, days,
months, the family group) as SVG, in the same flat style as Fluent Emoji.

Letters and digits are converted to outlines from the bundled Baloo 2 font, so
the SVGs need no font at runtime.

Run: /opt/tts/venv/bin/python tool/gen_images.py   (needs fonttools)
"""
import json
import math
import re
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets" / "images"

INK = "#2B2D42"
PALETTE = ["#FF6B6B", "#FFC93C", "#2EC4B6", "#4CC9F0", "#9B5DE5", "#7BD389"]
COLORS = {
    "red": "#F23B3B", "blue": "#2F80ED", "green": "#3DBE5A", "yellow": "#FFD43B",
    "orange_color": "#FF8C1A", "purple": "#9B5DE5", "pink": "#FF8FC7", "brown": "#9C6B45",
    "black": "#2B2D42", "white": "#FFFFFF", "gray": "#9AA0A6",
}

_font = instantiateVariableFont(TTFont(ROOT / "assets/fonts/Baloo2.ttf"), {"wght": 800})
_glyphs = _font.getGlyphSet()
_cmap = _font.getBestCmap()


def darker(hex_color, f=0.78):
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (1, 3, 5))
    return "#%02X%02X%02X" % (int(r * f), int(g * f), int(b * f))


def text_path(text, cx, cy, height):
    """SVG path for `text` centred on (cx, cy) with cap height ≈ `height`."""
    units = _font["head"].unitsPerEm
    scale = height / (units * 0.7)
    advance = 0
    parts = []
    bounds = BoundsPen(_glyphs)
    for ch in text:
        name = _cmap[ord(ch)]
        glyph = _glyphs[name]
        glyph.draw(TransformPen(bounds, (1, 0, 0, 1, advance, 0)))
        parts.append((name, advance))
        advance += glyph.width
    x0, y0, x1, y1 = bounds.bounds
    pen = SVGPathPen(_glyphs)
    # Flip y (font units go up) and centre the ink box on (cx, cy).
    tx = cx - (x0 + x1) / 2 * scale
    ty = cy + (y0 + y1) / 2 * scale
    for name, adv in parts:
        _glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, tx + adv * scale, ty)))
    return pen.getCommands()


def svg(body, size=32):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" fill="none">{body}</svg>\n'


def blob(color):
    """A friendly paint splash."""
    outline = ' stroke="#D0D3DA" stroke-width="0.8"' if color == "#FFFFFF" else ""
    pts = []
    for i in range(16):
        a = i / 16 * math.tau
        r = 12 + (2.2 if i % 2 == 0 else -0.6) + 0.8 * math.sin(3 * a)
        pts.append((16 + r * math.cos(a), 16.5 + r * math.sin(a)))
    def mid(a, b):
        return ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)

    start = mid(pts[-1], pts[0])
    d = f"M{start[0]:.2f} {start[1]:.2f} " + " ".join(
        "Q{:.2f} {:.2f} {:.2f} {:.2f}".format(*pts[i], *mid(pts[i], pts[(i + 1) % 16])) for i in range(16)
    ) + " Z"
    shine = '<ellipse cx="11.5" cy="11" rx="3" ry="1.8" fill="#FFFFFF" opacity="0.45" transform="rotate(-30 11.5 11)"/>'
    return svg(f'<path d="{d}" fill="{color}"{outline}/>' + (shine if color != "#FFFFFF" else ""))


def shape(name):
    c = {"circle": "#FF6B6B", "square": "#4CC9F0", "triangle": "#7BD389", "rectangle": "#FFC93C",
         "star": "#FFC93C", "heart": "#FF6B6B", "oval": "#9B5DE5", "diamond": "#2EC4B6"}[name]
    d = darker(c)
    if name == "circle":
        el = f'<circle cx="16" cy="16" r="12" fill="{c}" stroke="{d}" stroke-width="1.5"/>'
    elif name == "square":
        el = f'<rect x="5" y="5" width="22" height="22" rx="2.5" fill="{c}" stroke="{d}" stroke-width="1.5"/>'
    elif name == "rectangle":
        el = f'<rect x="2.5" y="9" width="27" height="14" rx="2.5" fill="{c}" stroke="{d}" stroke-width="1.5"/>'
    elif name == "triangle":
        el = f'<path d="M16 4 L28.5 26.5 L3.5 26.5 Z" fill="{c}" stroke="{d}" stroke-width="1.5" stroke-linejoin="round"/>'
    elif name == "oval":
        el = f'<ellipse cx="16" cy="16" rx="13" ry="9" fill="{c}" stroke="{d}" stroke-width="1.5"/>'
    elif name == "diamond":
        el = f'<path d="M16 3 L27 16 L16 29 L5 16 Z" fill="{c}" stroke="{d}" stroke-width="1.5" stroke-linejoin="round"/>'
    elif name == "star":
        pts = " ".join(f"{16 + (12.5 if i % 2 == 0 else 5.5) * math.sin(i * math.pi / 5):.2f},"
                       f"{17 - (12.5 if i % 2 == 0 else 5.5) * math.cos(i * math.pi / 5):.2f}" for i in range(10))
        el = f'<polygon points="{pts}" fill="{c}" stroke="{d}" stroke-width="1.5" stroke-linejoin="round"/>'
    else:  # heart
        el = (f'<path d="M16 27 C 6 20, 3 14, 6 9 C 9 5, 14 6, 16 10 C 18 6, 23 5, 26 9 C 29 14, 26 20, 16 27 Z" '
              f'fill="{c}" stroke="{d}" stroke-width="1.5" stroke-linejoin="round"/>')
    return svg(el)


def number(n):
    color = PALETTE[(n - 1) % len(PALETTE)]
    digits = f'<path d="{text_path(str(n), 16, 11.5, 13)}" fill="{color}" stroke="{darker(color)}" stroke-width="0.5"/>'
    # Counting dots underneath, in rows of five.
    dots = []
    rows = math.ceil(n / 5)
    r = 1.25 if rows <= 2 else 1.0
    gap = 2 * r + 0.9
    top = 23.5 if rows <= 2 else 21.5
    for i in range(n):
        row, col = divmod(i, 5)
        x = 16 + (col - 2) * gap
        y = top + row * gap
        dots.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r}" fill="{INK}"/>')
    return svg(digits + "".join(dots))


def letter(ch):
    color = PALETTE["abcdefghijklmnopqrstuvwxyz".index(ch) % len(PALETTE)]
    tile = f'<rect x="2" y="2" width="28" height="28" rx="7" fill="{color}"/>'
    glyphs = f'<path d="{text_path(ch.upper() + ch, 16, 16.5, 13)}" fill="#FFFFFF"/>'
    return svg(tile + glyphs)


def calendar(label, color):
    page = (f'<rect x="3" y="5" width="26" height="24" rx="4" fill="#FFFFFF" stroke="#E9DCC0" stroke-width="1"/>'
            f'<path d="M3 9 a4 4 0 0 1 4 -4 h18 a4 4 0 0 1 4 4 v3 h-26 Z" fill="{color}"/>'
            f'<rect x="9" y="2.5" width="2" height="5" rx="1" fill="{INK}"/><rect x="21" y="2.5" width="2" height="5" rx="1" fill="{INK}"/>')
    text = f'<path d="{text_path(label, 16, 20.5, 6.5)}" fill="{INK}"/>'
    return svg(page + text)


def nested(svg_text, x, y, size, prefix):
    """Inlines a 32×32 Fluent SVG at (x, y) scaled to `size`, renaming its ids."""
    inner = re.sub(r"^.*?<svg[^>]*>|</svg>\s*$", "", svg_text, flags=re.S)
    inner = re.sub(r'id="([^"]+)"', rf'id="{prefix}\1"', inner)
    inner = re.sub(r"url\(#([^)]+)\)", rf"url(#{prefix}\1)", inner)
    return f'<g transform="translate({x} {y}) scale({size / 32})">{inner}</g>'


def family():
    words = IMAGES / "words"
    parts = [("dad", 0, 0, 17), ("mom", 15, 0, 17), ("brother", 3, 14, 15), ("sister", 15, 14, 15)]
    return svg("".join(nested((words / f"{w}.svg").read_text(), x, y, s, f"{w}_") for w, x, y, s in parts))


def unit_shapes():
    return svg('<circle cx="10" cy="10" r="7" fill="#FF6B6B"/>'
               '<rect x="16" y="4" width="12" height="12" rx="2" fill="#4CC9F0"/>'
               '<path d="M16 15 L25 29 L7 29 Z" fill="#7BD389" stroke-linejoin="round"/>')


MONTH_COLORS = ["#4CC9F0", "#4CC9F0", "#7BD389", "#7BD389", "#7BD389", "#FFC93C",
                "#FFC93C", "#FFC93C", "#FF8C1A", "#FF8C1A", "#FF8C1A", "#4CC9F0"]


def render(source):
    kind, _, arg = source.removeprefix("own:").partition(":")
    if kind == "color":
        return blob(COLORS[arg])
    if kind == "shape":
        return shape(arg)
    if kind == "number":
        return number(int(arg))
    if kind == "letter":
        return letter(arg)
    if kind == "day":
        return calendar(arg, "#9B5DE5")
    if kind == "month":
        months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return calendar(arg, MONTH_COLORS[months.index(arg)])
    if kind == "family":
        return family()
    if kind == "unit_shapes":
        return unit_shapes()
    raise ValueError(source)


def main():
    sources = json.loads((ROOT / "tool" / "image_sources.json").read_text(encoding="utf-8"))
    for key, source in sources.items():
        if source.startswith("own:"):
            (IMAGES / f"{key}.svg").write_text(render(source), encoding="utf-8")
    print("drawn", sum(s.startswith("own:") for s in sources.values()))


if __name__ == "__main__":
    main()
