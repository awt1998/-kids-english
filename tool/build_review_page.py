"""Builds a single-file review page where the owner can listen to every word and
sentence and flag anything that sounds wrong. Pictures and audio are embedded,
so the page works on its own.

Run: python3 tool/build_review_page.py OUTPUT.html
"""
import base64
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def data_uri(path: Path, mime: str) -> str:
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def main():
    out = Path(sys.argv[1])
    index = json.loads((ROOT / "assets/content/index.json").read_text(encoding="utf-8"))["units"]
    units = []
    for u in index:
        data = json.loads((ROOT / f"assets/content/units/{u['id']}.json").read_text(encoding="utf-8"))
        units.append({
            "id": u["id"], "ar": u["titleAr"], "en": u["titleEn"],
            "icon": data_uri(ROOT / f"assets/images/ui/unit_{u['id']}.svg", "image/svg+xml"),
            "words": [{
                "id": w["id"], "en": w["en"], "ar": w["ar"],
                "img": data_uri(ROOT / f"assets/images/words/{w['id']}.svg", "image/svg+xml"),
                "audio": data_uri(ROOT / f"assets/audio/en/words/{w['id']}.mp3", "audio/mpeg"),
            } for w in data["words"]],
            "sentences": [{
                "id": s["id"], "en": s["en"], "ar": s["ar"],
                "audio": data_uri(ROOT / f"assets/audio/en/sentences/{s['id']}.mp3", "audio/mpeg"),
            } for s in data.get("sentences", [])],
        })
    template = (Path(__file__).resolve().parent / "review_page_template.html").read_text(encoding="utf-8")
    out.write_text(template.replace("/*__DATA__*/null", json.dumps(units, ensure_ascii=False)), encoding="utf-8")
    words = sum(len(u["words"]) for u in units)
    sentences = sum(len(u["sentences"]) for u in units)
    print(f"{out} — {words} words, {sentences} sentences, {out.stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
