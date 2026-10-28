"""Exports the outline of every letter (A–Z, a–z) from the bundled Baloo 2 font
as SVG path data in a 1000×1000 box, for the letter-tracing game.

Run: /opt/tts/venv/bin/python tool/gen_letter_paths.py   (needs fonttools)
"""
import json
import string
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parent.parent
BOX = 1000
MARGIN = 120


def main():
    font = instantiateVariableFont(TTFont(ROOT / "assets/fonts/Baloo2.ttf"), {"wght": 700})
    glyphs, cmap = font.getGlyphSet(), font.getBestCmap()
    # One scale for all letters so lowercase looks smaller than uppercase, as in writing.
    upper_bounds = BoundsPen(glyphs)
    glyphs[cmap[ord("H")]].draw(upper_bounds)
    cap = upper_bounds.bounds[3] - upper_bounds.bounds[1]
    scale = (BOX - 2 * MARGIN) / (cap * 1.25)
    baseline = BOX - MARGIN - 0.12 * (BOX - 2 * MARGIN)
    out = {}
    for ch in string.ascii_letters:
        g = glyphs[cmap[ord(ch)]]
        b = BoundsPen(glyphs)
        g.draw(b)
        x0, _, x1, _ = b.bounds
        tx = BOX / 2 - (x0 + x1) / 2 * scale
        pen = SVGPathPen(glyphs)
        g.draw(TransformPen(pen, (scale, 0, 0, -scale, tx, baseline)))
        out[ch] = pen.getCommands()
    dest = ROOT / "assets/content/letter_paths.json"
    dest.write_text(json.dumps({"box": BOX, "paths": out}) + "\n", encoding="utf-8")
    print(dest.relative_to(ROOT), len(out), "letters")


if __name__ == "__main__":
    main()
