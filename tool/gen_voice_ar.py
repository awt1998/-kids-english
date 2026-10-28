"""Arabic spoken instructions with ElevenLabs (paid plan = commercial licence).

The API key is read from the environment variable ELEVENLABS_API_KEY; it is
never written to disk or printed.

1) Pick a voice: list candidate Arabic voices and render two short samples
   with each, in both styles (Gulf dialect and simple MSA):
     python3 tool/gen_voice_ar.py samples OUT_DIR
2) Generate every prompt with the chosen voice and style:
     python3 tool/gen_voice_ar.py generate --voice VOICE_ID --style gulf|msa [--force]

Text lives in assets/content/prompts_ar.json; audio goes to assets/audio/ar/<id>.mp3.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROMPTS = ROOT / "assets" / "content" / "prompts_ar.json"
OUT = ROOT / "assets" / "audio" / "ar"
API = "https://api.elevenlabs.io"
MODEL = "eleven_multilingual_v2"
# Warm and steady, a little expressive: friendly for small children without shouting.
SETTINGS = {"stability": 0.55, "similarity_boost": 0.8, "style": 0.25, "use_speaker_boost": True, "speed": 0.92}
SAMPLE_IDS = ["welcome", "listen_and_choose"]


def key():
    k = os.environ.get("ELEVENLABS_API_KEY")
    if not k:
        sys.exit("ELEVENLABS_API_KEY is not set (add it in the environment settings).")
    return k


def request(path, body=None, query=None):
    url = API + path + ("?" + urllib.parse.urlencode(query) if query else "")
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method="POST" if data else "GET",
                                 headers={"xi-api-key": key(), "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def tts(voice_id, text, dest: Path):
    audio = request(f"/v1/text-to-speech/{voice_id}", {"text": text, "model_id": MODEL, "voice_settings": SETTINGS},
                    {"output_format": "mp3_44100_128"})
    dest.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".mp3") as tmp:
        Path(tmp.name).write_bytes(audio)
        # Same loudness as the English clips, mono, small.
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-af", "loudnorm=I=-16:TP=-1.5",
                        "-ar", "44100", "-ac", "1", "-b:a", "64k", str(dest)], check=True)


def candidate_voices(limit=8):
    """Arabic voices from the shared library (Gulf/Saudi accents first) plus our own voices."""
    found = []
    for accent in ["saudi", "gulf", "emirati", "kuwaiti", "standard", None]:
        q = {"language": "ar", "page_size": 30, "sort": "usage_character_count_7d"}
        if accent:
            q["accent"] = accent
        try:
            data = json.loads(request("/v1/shared-voices", query=q))
        except Exception as e:  # accent filter not recognised, etc.
            print("  (lookup failed for", accent, ":", e, ")")
            continue
        for v in data.get("voices", []):
            if v["voice_id"] not in {f["voice_id"] for f in found}:
                found.append({"voice_id": v["voice_id"], "name": v.get("name"), "accent": v.get("accent"),
                              "gender": v.get("gender"), "age": v.get("age"), "use_case": v.get("use_case"),
                              "public_owner_id": v.get("public_owner_id")})
        if len(found) >= limit:
            break
    return found[:limit]


def add_to_library(v):
    """Shared voices must be added to the account before they can speak."""
    request(f"/v1/voices/add/{v['public_owner_id']}/{v['voice_id']}", {"new_name": f"Labeeb {v['name']}"[:40]})


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("samples")
    s.add_argument("out")
    g = sub.add_parser("generate")
    g.add_argument("--voice", required=True)
    g.add_argument("--style", choices=["gulf", "msa"], required=True)
    g.add_argument("--force", action="store_true")
    args = ap.parse_args()
    prompts = json.loads(PROMPTS.read_text(encoding="utf-8"))["prompts"]

    if args.cmd == "samples":
        out = Path(args.out)
        voices = candidate_voices()
        (out / "voices.json").parent.mkdir(parents=True, exist_ok=True)
        (out / "voices.json").write_text(json.dumps(voices, ensure_ascii=False, indent=1), encoding="utf-8")
        for i, v in enumerate(voices, 1):
            try:
                add_to_library(v)
            except Exception as e:
                print("  could not add", v["name"], e)
            for p in [p for p in prompts if p["id"] in SAMPLE_IDS]:
                for style in ["gulf", "msa"]:
                    dest = out / f"{i:02d}-{style}-{p['id']}.mp3"
                    try:
                        tts(v["voice_id"], p[style], dest)
                    except Exception as e:
                        print("  failed", dest.name, e)
            print(f"{i:02d} {v['name']} ({v['accent']}, {v['gender']}, {v['age']})")
        return

    for p in prompts:
        dest = OUT / f"{p['id']}.mp3"
        if dest.exists() and not args.force:
            continue
        tts(args.voice, p[args.style], dest)
        print("ok", p["id"])


if __name__ == "__main__":
    main()
