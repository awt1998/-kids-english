"""Synthesises the app's sound effects from scratch (so we own them outright).

Run: python3 tool/gen_sfx.py   (needs numpy + ffmpeg)
"""
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "sfx"


def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def bell(freq, dur, decay=6.0, amp=0.5):
    x = t(dur)
    tone = (np.sin(2 * np.pi * freq * x) + 0.35 * np.sin(2 * np.pi * freq * 2 * x)
            + 0.12 * np.sin(2 * np.pi * freq * 3.01 * x))
    env = np.exp(-decay * x) * np.minimum(1, x / 0.004)
    return amp * tone * env


def place(track, sound, at):
    i = int(at * SR)
    end = min(len(track), i + len(sound))
    track[i:end] += sound[: end - i]


def save(name, sig):
    sig = sig / max(1e-9, np.max(np.abs(sig))) * 0.8
    pcm = (sig * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        with wave.open(tmp.name, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name,
                        "-b:a", "96k", str(OUT / f"{name}.mp3")], check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(7)

    # Soft "pop" for taps.
    x = t(0.08)
    f = np.linspace(500, 950, len(x))
    save("tap", np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-40 * x))

    # Card flip: short airy whoosh.
    x = t(0.25)
    noise = rng.standard_normal(len(x))
    noise = np.convolve(noise, np.ones(12) / 12, mode="same")
    save("flip", noise * np.sin(np.pi * x / 0.25) ** 2 * 0.6)

    # Correct: two bright rising bells.
    s = np.zeros(int(SR * 0.7))
    place(s, bell(1318.5, 0.6), 0)
    place(s, bell(1760, 0.6), 0.11)
    save("correct", s)

    # Try again: friendly wobbly "boing", never sad or harsh.
    x = t(0.4)
    f = 420 - 120 * x / 0.4 + 18 * np.sin(2 * np.pi * 14 * x)
    save("try_again", np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-5 * x) * np.minimum(1, x / 0.01))

    # Star earned: high shimmering ding.
    s = bell(2093, 0.8, decay=5) + bell(2637, 0.8, decay=6, amp=0.3)
    save("star", s)

    # Celebration: rising arpeggio plus sparkles.
    s = np.zeros(int(SR * 1.8))
    for i, fr in enumerate([523.25, 659.25, 783.99, 1046.5, 1318.5]):
        place(s, bell(fr, 1.0, decay=4), i * 0.1)
    for _ in range(14):
        place(s, bell(rng.uniform(2500, 4200), 0.25, decay=18, amp=0.15), rng.uniform(0.5, 1.5))
    save("celebrate", s)


if __name__ == "__main__":
    main()
