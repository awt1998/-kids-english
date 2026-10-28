"""Composes the quiet background loop for the menus and the map (never during play).

A soft kalimba-like melody on a C-major pentatonic scale over a warm pad,
written so the end flows back into the start. We own it outright.

Run: python3 tool/gen_music.py   (needs numpy)
"""
import wave
from pathlib import Path

import numpy as np

SR = 22050
BPM = 76
BEAT = 60 / BPM
BARS = 8
LENGTH = BARS * 4 * BEAT
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "music" / "calm_loop.wav"

NOTE = {"C4": 261.63, "D4": 293.66, "E4": 329.63, "G4": 392.0, "A4": 440.0,
        "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99,
        "C3": 130.81, "F3": 174.61, "G3": 196.0, "A3": 220.0}

# (beat, note, beats) — a gentle question-and-answer phrase, two times.
MELODY = [
    (0, "E5", 1), (1, "G5", 1), (2, "E5", 1), (3, "D5", 1),
    (4, "C5", 2), (6, "D5", 1), (7, "E5", 1),
    (8, "G4", 1), (9, "A4", 1), (10, "C5", 1), (11, "D5", 1),
    (12, "E5", 3),
    (16, "D5", 1), (17, "E5", 1), (18, "G5", 1), (19, "E5", 1),
    (20, "D5", 2), (22, "C5", 1), (23, "A4", 1),
    (24, "G4", 1), (25, "A4", 1), (26, "C5", 1), (27, "D5", 1),
    (28, "C5", 3),
]
CHORDS = [["C3", "E4", "G4"], ["A3", "C4", "E4"], ["F3", "A4", "C5"], ["G3", "D4", "G4"]]


def kalimba(freq, dur):
    t = np.arange(int(SR * dur)) / SR
    tone = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * freq * 3.9 * t) * np.exp(-12 * t)
    return tone * np.exp(-3.2 * t) * np.minimum(1, t / 0.005)


def pad(freqs, dur):
    t = np.arange(int(SR * dur)) / SR
    tone = sum(np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2.003 * t) for f in freqs)
    env = np.minimum(1, t / 0.8) * np.minimum(1, (dur - t) / 0.8)
    return tone * env / len(freqs)


def main():
    n = int(SR * LENGTH)
    # Render twice the length and keep the second half, so tails that spill
    # past the end are already present at the start: a seamless loop.
    track = np.zeros(2 * n + SR * 4)
    for rep in range(2):
        base = rep * LENGTH
        for beat, note, beats in MELODY:
            s = kalimba(NOTE[note], beats * BEAT + 1.5)
            i = int(SR * (base + beat * BEAT))
            track[i:i + len(s)] += 0.35 * s
        for bar in range(BARS):
            s = pad([NOTE[x] for x in CHORDS[bar % 4]], 4 * BEAT + 0.8)
            i = int(SR * (base + bar * 4 * BEAT))
            track[i:i + len(s)] += 0.12 * s
    loop = track[n:2 * n].copy()
    loop = np.tanh(loop * 1.2)
    loop = loop / np.max(np.abs(loop)) * 0.5
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((loop * 32767).astype(np.int16).tobytes())
    print(f"{OUT.relative_to(OUT.parents[3])}: {LENGTH:.1f}s, {OUT.stat().st_size / 1e6:.2f} MB")


if __name__ == "__main__":
    main()
