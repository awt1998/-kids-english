"""Turns the owner's recording of the Arabic prompts into clean app clips.

The owner reads the sentences of assets/content/prompts_ar.json in order, with
a short pause between them, into ONE file. This script finds the pauses,
lets you map segments to prompts (a sentence said with an inner pause comes
out as two segments: join them with --join), then cleans each clip:
high-pass for hum, gentle noise reduction, trimmed silence, short fades, and
the same loudness as the English audio.

  python3 tool/import_recordings_ar.py RECORDING.mp3 --list
  python3 tool/import_recordings_ar.py RECORDING.mp3 --join 15,16
"""
import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROMPTS = ROOT / "assets" / "content" / "prompts_ar.json"
OUT = ROOT / "assets" / "audio" / "ar"
PAUSE_INSIDE_JOINED = 0.3  # seconds kept between the two halves of a joined sentence


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True, check=True).stdout
    return float(out)


def segments(path, noise_db=-35, min_pause=0.6):
    log = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af",
                          f"silencedetect=noise={noise_db}dB:d={min_pause}", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r"silence_start: ([0-9.]+)", log)]
    ends = [float(x) for x in re.findall(r"silence_end: ([0-9.]+)", log)]
    segs, prev = [], 0.0
    for s, e in zip(starts, ends):
        segs.append((prev, s))
        prev = e
    segs.append((prev, duration(path)))
    return [(a, b) for a, b in segs if b - a > 0.25]


def clean(src, parts, dest):
    """Cuts `parts` (start, end) from src, joins them, and cleans the result."""
    pre, post = 0.06, 0.15
    trims = []
    for i, (a, b) in enumerate(parts):
        start = max(0, a - pre)
        trims.append(f"[0:a]atrim={start:.3f}:{b + post:.3f},asetpts=PTS-STARTPTS[p{i}]")
    gap = f"aevalsrc=0:d={PAUSE_INSIDE_JOINED}:s=48000[gap]" if len(parts) > 1 else None
    chain = "".join(f"[p{i}]" + ("[gap]" if gap and i == 0 else "") for i in range(len(parts)))
    n = len(parts) + (1 if gap else 0)
    graph = ";".join(trims + ([gap] if gap else []) + [
        f"{chain}concat=n={n}:v=0:a=1[j]",
        "[j]highpass=f=80,afftdn=nf=-30,afade=t=in:d=0.015,areverse,afade=t=in:d=0.04,areverse,"
        "loudnorm=I=-16:TP=-1.5[out]",
    ])
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-filter_complex", graph, "-map", "[out]",
                    "-ar", "44100", "-ac", "1", "-b:a", "64k", str(dest)], check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("recording")
    ap.add_argument("--list", action="store_true", help="only print the segments found")
    ap.add_argument("--join", action="append", default=[], help="segment numbers spoken as one sentence, e.g. 15,16")
    args = ap.parse_args()
    segs = segments(args.recording)
    if args.list:
        for i, (a, b) in enumerate(segs, 1):
            print(f"{i:2d}  {a:6.2f}–{b:6.2f}  ({b - a:.2f}s)")
        return

    joined = [sorted(int(x) for x in j.split(",")) for j in args.join]
    groups, i = [], 1
    while i <= len(segs):
        group = next((j for j in joined if j[0] == i), [i])
        groups.append([segs[k - 1] for k in group])
        i = group[-1] + 1
    prompts = json.loads(PROMPTS.read_text(encoding="utf-8"))["prompts"]
    if len(groups) != len(prompts):
        raise SystemExit(f"{len(groups)} sentences found but {len(prompts)} prompts expected; use --list and --join")
    OUT.mkdir(parents=True, exist_ok=True)
    for prompt, parts in zip(prompts, groups):
        dest = OUT / f"{prompt['id']}.mp3"
        clean(args.recording, parts, dest)
        print(f"{dest.relative_to(ROOT)}  {duration(dest):.2f}s  {prompt['gulf']}")


if __name__ == "__main__":
    main()
