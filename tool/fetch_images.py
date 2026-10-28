"""Downloads word/unit pictures from Microsoft Fluent Emoji (MIT licence, Flat style).

tool/image_sources.json maps "<folder>/<id>" to either a Fluent emoji name
(e.g. "Red apple") or "own:..." for pictures drawn by tool/gen_images.py.
Existing files are kept; pass --force to download again.

Run: python3 tool/fetch_images.py
"""
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = "https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/"


def candidates(name: str):
    folder = urllib.parse.quote(name)
    file = name.lower().replace(" ", "_")
    yield f"{BASE}{folder}/Flat/{urllib.parse.quote(file)}_flat.svg"
    # People and hands come in skin tones; "Default" is the neutral yellow one.
    yield f"{BASE}{folder}/Default/Flat/{urllib.parse.quote(file)}_flat_default.svg"


def main():
    force = "--force" in sys.argv
    sources = json.loads((ROOT / "tool" / "image_sources.json").read_text(encoding="utf-8"))
    missing = []
    for key, source in sources.items():
        if source.startswith("own:"):
            continue
        dest = ROOT / "assets" / "images" / f"{key}.svg"
        if dest.exists() and not force:
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        for url in candidates(source):
            try:
                with urllib.request.urlopen(url, timeout=30) as r:
                    dest.write_bytes(r.read())
                print("ok", key)
                break
            except Exception:
                continue
        else:
            missing.append(f"{key} ({source})")
    if missing:
        print("NOT FOUND:\n  " + "\n  ".join(missing))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
