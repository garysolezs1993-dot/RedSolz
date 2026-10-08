"""Create the original, looping Stage 2 boss theme as a PCM WAV asset."""

from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "audio" / "bgm" / "alpha_wolf_boss_theme.wav"
RATE = 22050
BPM = 76.0
BEAT = 60.0 / BPM
BAR = BEAT * 4.0
BAR_COUNT = 24
TAIL = 2.5
TOTAL = BAR * BAR_COUNT + TAIL
SAMPLES = int(TOTAL * RATE)
MIX = np.zeros((SAMPLES, 2), dtype=np.float64)


CHORDS = [
    ("Dm", [146.83, 174.61, 220.00]),
    ("Bb", [116.54, 146.83, 174.61]),
    ("F", [87.31, 110.00, 130.81]),
    ("C", [130.81, 164.81, 196.00]),
    ("Dm", [146.83, 174.61, 220.00]),
    ("Bb", [116.54, 146.83, 174.61]),
    ("Gm", [98.00, 116.54, 146.83]),
    ("A", [110.00, 138.59, 164.81]),
]


def env(length: int, attack: float, release: float, curve: float = 1.0) -> np.ndarray:
    t = np.arange(length, dtype=np.float64) / RATE
    result = np.ones(length, dtype=np.float64)
    a = min(length, int(attack * RATE))
    r = min(length, int(release * RATE))
    if a:
        result[:a] = np.linspace(0.0, 1.0, a, endpoint=False) ** curve
    if r:
        result[-r:] *= np.linspace(1.0, 0.0, r) ** curve
    return result


def add_tone(start: float, duration: float, frequency: float, amplitude: float,
             kind: str, pan: float = 0.0, attack: float = 0.02,
             release: float = 0.2, detune: float = 0.0) -> None:
    first = max(0, int(start * RATE))
    last = min(SAMPLES, first + int(duration * RATE))
    n = last - first
    if n <= 0:
        return
    t = np.arange(n, dtype=np.float64) / RATE
    phase = t * (2.0 * math.pi * frequency)
    if kind == "pad":
        signal = (np.sin(phase) + 0.28 * np.sin(phase * 2.0) +
                  0.12 * np.sin(phase * 3.0) + 0.45 * np.sin(phase * (1.0 + detune))) / 1.85
        e = env(n, attack, release, 1.25)
    elif kind == "bell":
        signal = (np.sin(phase) + 0.48 * np.sin(phase * 2.01) +
                  0.20 * np.sin(phase * 3.92) + 0.10 * np.sin(phase * 6.1))
        e = np.exp(-t * 3.2) * env(n, 0.006, min(0.12, duration * 0.2), 0.8)
    elif kind == "bass":
        signal = np.sin(phase) + 0.18 * np.sin(phase * 2.0)
        e = env(n, 0.015, min(0.11, duration * 0.3), 1.0)
    elif kind == "drum":
        sweep = 85.0 * np.exp(-t * 8.0) + 38.0
        phase = 2.0 * math.pi * np.cumsum(sweep) / RATE
        signal = np.sin(phase) + 0.08 * np.random.default_rng(first).standard_normal(n)
        e = np.exp(-t * 5.2)
    else:
        return
    signal *= e * amplitude
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    MIX[first:last, 0] += signal * left
    MIX[first:last, 1] += signal * right


def note_frequency(midi: int) -> float:
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def main() -> None:
    global MIX
    rng = np.random.default_rng(29417)
    motif = [62, 65, 69, 72, 69, 65, 64, 62]
    for bar_index in range(BAR_COUNT):
        chord_name, chord = CHORDS[bar_index % len(CHORDS)]
        bar_start = bar_index * BAR
        build = min(1.0, 0.36 + bar_index / 23.0 * 0.42)

        # Wide, slow string-like chord bed with a low fifth underneath.
        for index, hz in enumerate(chord):
            add_tone(bar_start, BAR * 0.98, hz, 0.085 * build,
                     "pad", pan=(-0.42, 0.0, 0.42)[index], attack=0.65,
                     release=0.48, detune=0.003 if index != 1 else -0.002)
        add_tone(bar_start, BAR * 0.96, chord[0] / 2.0, 0.075 * build,
                 "pad", pan=0.0, attack=0.9, release=0.55, detune=-0.0015)

        # A fragile high-register motif becomes more insistent during the fight.
        if bar_index % 2 == 0:
            for step in range(4):
                midi = motif[(bar_index + step * 2) % len(motif)]
                start = bar_start + step * BEAT
                amp = 0.12 + 0.06 * build
                add_tone(start, BEAT * 0.88, note_frequency(midi), amp,
                         "bell", pan=(-0.3 if step % 2 == 0 else 0.3), release=0.13)

        # Low heartbeat-like drums gradually rise from sparse to forceful.
        if bar_index >= 3:
            for beat_index in (0, 2) if bar_index < 8 else (0, 1, 2, 3):
                level = 0.12 + 0.08 * build
                add_tone(bar_start + beat_index * BEAT, 0.42, 55.0, level,
                         "drum", pan=0.0)
        if bar_index % 4 == 3:
            # Quiet, breathy metallic wash made from a brief filtered-noise bed.
            hit = bar_start + BAR - 0.12
            n = int(0.65 * RATE)
            first = int(hit * RATE)
            last = min(SAMPLES, first + n)
            noise = rng.standard_normal(last - first)
            noise = np.convolve(noise, np.ones(18) / 18.0, mode="same")
            fade = np.exp(-np.arange(last - first) / (RATE * 0.24))
            wash = noise * fade * (0.024 + 0.024 * build)
            MIX[first:last, 0] += wash * 0.72
            MIX[first:last, 1] += wash

        # A restrained pulsing low note keeps the boss encounter moving.
        if bar_index >= 8:
            root = chord[0] / 2.0
            add_tone(bar_start, BEAT * 0.65, root, 0.10 * build, "bass", pan=-0.08)
            add_tone(bar_start + 2 * BEAT, BEAT * 0.65, root, 0.085 * build, "bass", pan=0.08)

    # Gentle stereo echoes add depth while leaving room for combat sound effects.
    dry = MIX.copy()
    for delay, amount, swap in ((0.19, 0.13, True), (0.37, 0.075, False), (0.61, 0.035, True)):
        offset = int(delay * RATE)
        if swap:
            MIX[offset:, 0] += dry[:-offset, 1] * amount
            MIX[offset:, 1] += dry[:-offset, 0] * amount
        else:
            MIX[offset:] += dry[:-offset] * amount

    # Smooth the final tail and leave ample headroom for in-game mixing.
    tail_len = int(TAIL * RATE)
    MIX[-tail_len:] *= np.linspace(1.0, 0.0, tail_len)[:, None]
    peak = float(np.max(np.abs(MIX)))
    if peak > 0.88:
        MIX *= 0.88 / peak
    pcm = np.clip(MIX * 32767.0, -32768, 32767).astype("<i2")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())
    print(f"Wrote {OUT} ({TOTAL:.1f}s, {RATE} Hz stereo)")


if __name__ == "__main__":
    main()
