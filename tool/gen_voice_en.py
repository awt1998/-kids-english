"""Generates English pronunciation audio for every word in assets/content/units.

Uses Kokoro-82M (Apache-2.0, commercial use allowed) running locally.
Only missing files are generated; pass --force to regenerate everything.

Setup (once):
  python3 -m venv /opt/tts/venv && /opt/tts/venv/bin/pip install kokoro-onnx soundfile
  download kokoro-v1.0.onnx and voices-v1.0.bin from
  https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0 into /opt/tts
Run:
  /opt/tts/venv/bin/python tool/gen_voice_en.py
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import soundfile as sf
from kokoro_onnx import Kokoro

ROOT = Path(__file__).resolve().parent.parent
UNITS = ROOT / "assets" / "content" / "units"
OUT = ROOT / "assets" / "audio" / "en" / "words"
MODEL_DIR = Path("/opt/tts")

VOICE = "af_heart"
SPEED = 0.8  # a little slower than normal speech, for children


def to_mp3(samples, sr, dest: Path):
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        sf.write(tmp.name, samples, sr)
        # Trim leading/trailing silence, keep a tiny lead-in so playback never clips.
        subprocess.run([
            "ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name,
            "-af", "silenceremove=start_periods=1:start_threshold=-45dB,"
                   "areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
                   "adelay=60,apad=pad_dur=0.15,loudnorm=I=-16",
            "-ar", "44100", "-ac", "1", "-b:a", "64k", str(dest),
        ], check=True)


def main():
    force = "--force" in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    kokoro = Kokoro(str(MODEL_DIR / "kokoro-v1.0.onnx"), str(MODEL_DIR / "voices-v1.0.bin"))
    made = 0
    for unit_file in sorted(UNITS.glob("*.json")):
        for word in json.loads(unit_file.read_text(encoding="utf-8"))["words"]:
            dest = OUT / f"{word['id']}.mp3"
            if dest.exists() and not force:
                continue
            samples, sr = kokoro.create(word["en"], voice=VOICE, speed=SPEED, lang="en-us")
            to_mp3(samples, sr, dest)
            made += 1
            print("generated", dest.relative_to(ROOT))
    print(f"done: {made} new file(s)")


if __name__ == "__main__":
    main()
