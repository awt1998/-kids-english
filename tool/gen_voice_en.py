"""Generates and verifies English audio for every word and sentence.

Voice: Kokoro-82M (Apache-2.0), run locally. Each clip is checked by two
independent speech recognisers (see check_pronunciation.py); if either does
not hear exactly the expected text, other renderings are tried in order
(VARIANTS) and the first one both recognisers agree on is kept. Anything that
never passes is listed at the end and must be fixed with an override in
tool/pronunciation.json:

  {"mouth": {"ipa": "mˈaʊθ"}, "letter_a": {"ipa": "ˈeɪ", "accept": ["a"]}}

  ipa    — phonemes to speak instead of the English text
  text   — different text to speak (e.g. spelling out "T V")
  accept — extra transcriptions that count as correct (homophones)
  voice, speed, form — use exactly this rendering instead of trying VARIANTS

Only missing files are generated; --force regenerates, --only id1,id2 limits.

Setup: see check_pronunciation.py (same venv), plus Kokoro model files in /opt/tts:
  https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0
Run:
  /opt/tts/venv/bin/python tool/gen_voice_en.py
"""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

import check_pronunciation as cp

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio" / "en"
OVERRIDES = Path(__file__).resolve().parent / "pronunciation.json"
REPORT = Path(__file__).resolve().parent / "pronunciation_report.json"

# (voice, speed, text form). Short words sound cleanest said brightly ("Apple!");
# Kokoro adds stray vowels to very short inputs when slowed down.
WORD_VARIANTS = [
    ("af_heart", 1.0, "{W}!"),
    ("af_heart", 1.0, "{W}."),
    ("af_heart", 0.95, "{W}!"),
    ("af_heart", 0.9, "{W}."),
    ("af_bella", 1.0, "{W}!"),
    ("af_bella", 1.0, "{W}."),
]
SENTENCE_VARIANTS = [
    ("af_heart", 0.9, "{w}"),
    ("af_heart", 1.0, "{w}"),
    ("af_bella", 0.9, "{w}"),
]

def text_for(template, text):
    text = text.strip()
    if text[-1] in ".!?":
        return text
    return template.format(w=text, W=text[0].upper() + text[1:])


def render(kokoro, voice, speed, form, text=None, ipa=None):
    if ipa:
        # Keep the variant's closing punctuation so the intonation matches.
        return kokoro.create(ipa + form[-1], voice=voice, speed=speed, is_phonemes=True)
    return kokoro.create(text, voice=voice, speed=speed, lang="en-us")


def trim(samples, sr, pre=0.08, post=0.18, threshold_db=-50):
    """Cuts silence without clipping soft starts like the 'p' in 'pear'."""
    frame = int(sr * 0.01)
    energy = np.array([np.sqrt(np.mean(samples[i:i + frame] ** 2) + 1e-12)
                       for i in range(0, max(1, len(samples) - frame), frame)])
    loud = np.where(20 * np.log10(energy / (energy.max() + 1e-12)) > threshold_db)[0]
    if len(loud) == 0:
        return samples
    start = max(0, loud[0] * frame - int(pre * sr))
    end = min(len(samples), (loud[-1] + 1) * frame + int(post * sr))
    return samples[start:end]


def to_mp3(samples, sr, dest: Path):
    dest.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        sf.write(tmp.name, trim(samples, sr), sr)
        subprocess.run([
            "ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name,
            "-af", "afade=t=in:d=0.01,loudnorm=I=-16:TP=-1.5",
            "-ar", "44100", "-ac", "1", "-b:a", "64k", str(dest),
        ], check=True)


def heard_ok(heard: dict, ok: set) -> bool:
    return all(cp.normalise(h) in ok for h in heard.values())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only")
    args = ap.parse_args()
    only = set(args.only.split(",")) if args.only else None

    overrides = json.loads(OVERRIDES.read_text(encoding="utf-8")) if OVERRIDES.exists() else {}
    report = json.loads(REPORT.read_text(encoding="utf-8")) if REPORT.exists() else {}
    kokoro = Kokoro("/opt/tts/kokoro-v1.0.onnx", "/opt/tts/voices-v1.0.bin")
    recs = cp.recognisers()
    failed = []

    for kind, id_, expected, dest in cp.items():
        if only and id_ not in only:
            continue
        if dest.exists() and not args.force and not only:
            continue
        o = overrides.get(id_, {})
        ok = cp.accepted(id_, expected)
        variants = WORD_VARIANTS if kind == "word" else SENTENCE_VARIANTS
        if "voice" in o:
            # A rendering chosen by hand after testing (see pronunciation.json).
            variants = [(o["voice"], o.get("speed", 1.0), o.get("form", "{W}!"))]
        best = None
        for voice, speed, form in variants:
            samples, sr = render(kokoro, voice, speed, form, text=text_for(form, o.get("text", expected)), ipa=o.get("ipa"))
            with tempfile.TemporaryDirectory() as tmp:
                trial = Path(tmp) / "trial.mp3"
                to_mp3(samples, sr, trial)
                audio = cp.load_audio(trial)
                heard = {n: cp.transcribe(r, audio) for n, r in recs.items()}
                passed = heard_ok(heard, ok)
                if passed or best is None:
                    best = (samples, sr, heard, f"{voice} {speed} {form}")
                if passed:
                    break
        samples, sr, heard, variant = best
        to_mp3(samples, sr, dest)
        report[id_] = {"expected": expected, "variant": variant, "heard": heard, "ok": passed}
        print(("ok  " if passed else "FAIL"), f"{id_:<20} {variant:<22}", heard, flush=True)
        if not passed:
            failed.append(id_)
        REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")

    if failed:
        print(f"\n{len(failed)} still failing, add overrides in {OVERRIDES.name}: {','.join(failed)}")
        raise SystemExit(1)
    print("\nall generated clips verified")


if __name__ == "__main__":
    main()
