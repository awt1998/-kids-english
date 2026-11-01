"""Frames the rendered screens (docs/previews/latest, from `flutter test screenshots
--update-goldens`) into store screenshots with a caption, for each store size.

Run: python3 tool/make_store_screenshots.py   (uses Playwright's Chromium via node)
Output: store/screenshots/<size>/<lang>/NN.png
"""
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "previews" / "latest"
OUT = ROOT / "store" / "screenshots"
FONT_AR = ROOT / "assets" / "fonts" / "BalooBhaijaan2.ttf"

SCENES = [
    ("05-map-after-lesson", "مغامرة ممتعة لتعلّم الإنجليزية", "A fun adventure to learn English"),
    ("03-flashcard", "أكثر من ٤٠٠ كلمة بالصورة والصوت", "400+ words with pictures and sound"),
    ("10-bubbles", "ألعاب تناسب كل عمر من ٣ إلى ١٠", "Games for every age, 3 to 10"),
    ("12-match", "يقرأ ويطابق ويتهجّى", "Read, match and spell"),
    ("15-trace", "يرسم الحروف بإصبعه", "Trace letters with a finger"),
    ("04-celebration", "نجوم وملصقات بلا عقاب على الخطأ", "Stars and stickers, no penalty for mistakes"),
    ("22-child-report", "تقرير واضح للأهل ووقت لعب محدد", "Clear reports and daily time limits"),
]

# name: (width, height, source device)
SIZES = {
    "ios-6.9": (1320, 2868, "phone"),
    "play-phone": (1080, 2160, "phone"),
    "ipad-13": (2752, 2064, "tablet"),
    "play-tablet": (2560, 1600, "tablet"),
}

BACKGROUNDS = ["#FFC93C", "#4CC9F0", "#2EC4B6", "#9B5DE5", "#FF6B6B", "#7BD389", "#FFC93C"]

SHOT_JS = """
const { chromium } = require('playwright');
(async () => {
  const jobs = JSON.parse(require('fs').readFileSync(process.argv[2]));
  const b = await chromium.launch();
  for (const j of jobs) {
    const p = await b.newPage({ viewport: { width: j.w, height: j.h } });
    await p.goto('file://' + j.html);
    await p.evaluate(() => document.fonts.ready);
    await p.waitForTimeout(150);
    await p.screenshot({ path: j.out });
    await p.close();
  }
  await b.close();
})();
"""


def page(w, h, src, caption, color, rtl):
    portrait = h > w
    shot_h = h * (0.74 if portrait else 0.72)
    font = round(w * (0.075 if portrait else 0.042))
    return f"""<html><head><style>
@font-face {{ font-family: Baloo; src: url('file://{FONT_AR}'); }}
body {{ margin:0; width:{w}px; height:{h}px; overflow:hidden; font-family: Baloo, sans-serif;
  background: radial-gradient(circle at 50% 0%, #FFFFFF55 0%, transparent 60%), {color}; }}
.cap {{ position:absolute; top:{round(h*0.035)}px; left:{round(w*0.06)}px; right:{round(w*0.06)}px;
  height:{round(h*(0.17 if portrait else 0.19))}px; display:flex; align-items:center; justify-content:center;
  text-align:center; color:#2B2D42; font-size:{font}px; font-weight:800; line-height:1.15; direction:{'rtl' if rtl else 'ltr'}; }}
img {{ position:absolute; left:50%; bottom:{round(h*0.035)}px; height:{round(shot_h)}px; transform:translateX(-50%);
  border-radius:{round(w*0.04 if portrait else w*0.018)}px; border:{max(6, round(w*0.008))}px solid #FFFFFF;
  box-shadow: 0 {round(w*0.012)}px {round(w*0.04)}px #00000040; }}
</style></head><body><div class="cap">{caption}</div><img src="file://{src}"></body></html>"""


def main():
    jobs = []
    with tempfile.TemporaryDirectory() as tmp:
        for size, (w, h, device) in SIZES.items():
            for lang in ["ar", "en"]:
                out_dir = OUT / size / lang
                out_dir.mkdir(parents=True, exist_ok=True)
                for i, (scene, ar, en) in enumerate(SCENES, 1):
                    src = SRC / f"{device}-{scene}.png"
                    html = Path(tmp) / f"{size}-{lang}-{i}.html"
                    html.write_text(page(w, h, src, ar if lang == "ar" else en, BACKGROUNDS[i - 1], lang == "ar"), encoding="utf-8")
                    jobs.append({"w": w, "h": h, "html": str(html), "out": str(out_dir / f"{i:02d}.png")})
        (Path(tmp) / "jobs.json").write_text(json.dumps(jobs))
        (Path(tmp) / "shot.js").write_text(SHOT_JS)
        subprocess.run(["node", str(Path(tmp) / "shot.js"), str(Path(tmp) / "jobs.json")], check=True)
    print(len(jobs), "store screenshots in", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
