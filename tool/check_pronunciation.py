"""Checks that every English audio file says exactly what it should.

Two independent speech recognisers (Whisper small.en and NVIDIA Parakeet, both
run locally through sherpa-onnx) listen to each file. A word passes only when
BOTH hear the expected text. It also prints the phonemes the voice used so a
person can review them.

Setup (once, models come from the sherpa-onnx GitHub releases):
  /opt/tts/venv/bin/pip install sherpa-onnx cmudict
  cd /opt/asr && for m in sherpa-onnx-whisper-small.en sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8; do
    curl -sSfL https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$m.tar.bz2 | tar xj; done
Run:
  /opt/tts/venv/bin/python tool/check_pronunciation.py [--only id1,id2] [--json report.json]
"""
import argparse
import json
import re
import subprocess
from pathlib import Path

import numpy as np
import sherpa_onnx

ROOT = Path(__file__).resolve().parent.parent
UNITS = ROOT / "assets" / "content" / "units"
AUDIO = ROOT / "assets" / "audio" / "en"
ASR = Path("/opt/asr")

NUMBER_WORDS = {
    "0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six",
    "7": "seven", "8": "eight", "9": "nine", "10": "ten", "11": "eleven", "12": "twelve",
    "13": "thirteen", "14": "fourteen", "15": "fifteen", "16": "sixteen", "17": "seventeen",
    "18": "eighteen", "19": "nineteen", "20": "twenty",
}


OVERRIDES = Path(__file__).resolve().parent / "pronunciation.json"

# Homophones the recognisers may legitimately write instead of the expected text.
HOMOPHONES = {"pear": {"pair"}, "sun": {"son"}, "eight": {"ate"}, "bee": {"be", "b"},
              "two": {"to", "too"}, "four": {"for"}, "one": {"won"}, "no": {"know"},
              "sea": {"see", "c"}, "flower": {"flour"}, "tea": {"t"}, "deer": {"dear"},
              "eye": {"i"}, "meat": {"meet"}, "hi": {"high"}, "write": {"right"}, "beetle": {"beatle"},
              "fire truck": {"firetruck"}, "peas": {"p's"}}


def accepted(id_: str, expected: str) -> set:
    """Every normalised transcription that counts as saying `expected`."""
    overrides = json.loads(OVERRIDES.read_text(encoding="utf-8")) if OVERRIDES.exists() else {}
    extra = set(overrides.get(id_, {}).get("accept", [])) | HOMOPHONES.get(expected.lower(), set())
    return {normalise(expected)} | {normalise(a) for a in extra}


def normalise(text: str) -> str:
    text = text.lower().replace("’", "'")
    text = re.sub(r"[^a-z0-9' ]+", " ", text)
    words = [NUMBER_WORDS.get(w, w) for w in text.split()]
    return " ".join(words)


def load_audio(path: Path) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", "16000", "-"],
        check=True, capture_output=True,
    ).stdout
    samples = np.frombuffer(raw, dtype=np.float32)
    # Recognisers do better with a little silence around very short clips.
    pad = np.zeros(8000, dtype=np.float32)
    return np.concatenate([pad, samples, pad])


def recognisers():
    w = ASR / "sherpa-onnx-whisper-small.en"
    p = ASR / "sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8"
    return {
        "whisper": sherpa_onnx.OfflineRecognizer.from_whisper(
            encoder=str(w / "small.en-encoder.int8.onnx"),
            decoder=str(w / "small.en-decoder.int8.onnx"),
            tokens=str(w / "small.en-tokens.txt"),
            language="en", task="transcribe", num_threads=4,
        ),
        "parakeet": sherpa_onnx.OfflineRecognizer.from_transducer(
            encoder=str(p / "encoder.int8.onnx"), decoder=str(p / "decoder.int8.onnx"),
            joiner=str(p / "joiner.int8.onnx"), tokens=str(p / "tokens.txt"),
            model_type="nemo_transducer", num_threads=4,
        ),
    }


def transcribe(rec, samples):
    stream = rec.create_stream()
    stream.accept_waveform(16000, samples)
    rec.decode_stream(stream)
    return stream.result.text.strip()


def items():
    """Yields (kind, id, expected text, audio path) for every word and sentence."""
    for unit_file in sorted(UNITS.glob("*.json")):
        data = json.loads(unit_file.read_text(encoding="utf-8"))
        for w in data["words"]:
            yield "word", w["id"], w["en"], AUDIO / "words" / f"{w['id']}.mp3"
        for s in data.get("sentences", []):
            yield "sentence", s["id"], s["en"], AUDIO / "sentences" / f"{s['id']}.mp3"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="comma-separated ids")
    ap.add_argument("--json", help="write a full report here")
    args = ap.parse_args()
    only = set(args.only.split(",")) if args.only else None

    recs = recognisers()
    report, failures = [], []
    for kind, id_, expected, path in items():
        if only and id_ not in only:
            continue
        if not path.exists():
            failures.append(id_)
            print(f"MISSING  {id_}: {path.relative_to(ROOT)}")
            continue
        samples = load_audio(path)
        heard = {name: transcribe(r, samples) for name, r in recs.items()}
        ok = all(normalise(h) in accepted(id_, expected) for h in heard.values())
        report.append({"kind": kind, "id": id_, "expected": expected, "heard": heard, "ok": ok})
        if not ok:
            failures.append(id_)
        mark = "ok  " if ok else "FAIL"
        print(f"{mark} {id_:<18} expected={expected!r:<28} " + "  ".join(f"{k}={v!r}" for k, v in heard.items()))

    if args.json:
        Path(args.json).write_text(json.dumps(report, ensure_ascii=False, indent=1))
    print(f"\n{len(report) - len([f for f in failures if f in {r['id'] for r in report}])}/{len(report)} passed")
    if failures:
        print("failed:", ",".join(failures))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
