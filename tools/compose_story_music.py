"""Compose two original, distinct synthesized scores and quiet UI chimes.

No recordings, third-party samples, or reference-song melodies are used.
Reverb tails are wrapped into the beginning for exact periodic WAV loops.
"""
from pathlib import Path
import math
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def frequency(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def add_note(mix, start, duration, note, gain, instrument, pan=0.0):
    count = int(duration * RATE)
    t = np.arange(count) / RATE
    f = frequency(note)
    p = 2 * math.pi * f * t
    attack = 0.6 if instrument == "strings" else 0.012
    release = min(0.75 if instrument == "strings" else 0.28, duration * 0.3)
    envelope = np.minimum(1, t / attack) * np.minimum(1, (duration - t) / release)
    if instrument == "music_box":
        tone = (np.sin(p) * np.exp(-t * 1.3) + 0.29 * np.sin(p * 2.002) * np.exp(-t * 2.2)
                + 0.12 * np.sin(p * 4.01) * np.exp(-t * 3.4))
    elif instrument == "piano":
        tone = sum(g * np.sin(p * n * (1 + 0.00008 * n * n)) * np.exp(-t * (0.75 + n * 0.18))
                   for n, g in [(1, 1), (2, .40), (3, .18), (4, .10), (6, .035)])
    else:
        vibrato = 0.003 * np.sin(t * 2 * math.pi * 4.8)
        tone = (np.sin(p * 0.9992 + vibrato) + np.sin(p * 1.0008 - vibrato)
                + .20 * np.sin(p * 2) + .09 * np.sin(p * 3)) * 0.43
    signal = tone * envelope * gain
    offset = int(start * RATE)
    # Notes and decays crossing the loop endpoint are mixed into its beginning.
    indices = (np.arange(count) + offset) % len(mix)
    mix[indices, 0] += signal * math.sqrt((1 - pan) / 2)
    mix[indices, 1] += signal * math.sqrt((1 + pan) / 2)


def finish(mix):
    dry = mix.copy()
    for seconds, gain in [(0.13, .11), (.29, .14), (.47, .10), (.73, .08), (1.11, .04)]:
        echo = np.roll(dry, round(seconds * RATE), axis=0)
        mix += echo[:, ::-1] * gain
    # Preserve gentle transients and comfortable master headroom.
    rms = np.sqrt(np.mean(mix ** 2))
    mix *= .16 / max(rms, 1e-9)
    peak = np.max(np.abs(mix))
    mix *= min(1.0, .72 / peak)
    return mix


def write(path, mix):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((np.clip(mix, -1, 1) * 32767).astype("<i2").tobytes())
    print(f"{path.name}: {len(mix)/RATE:.2f}s, stereo PCM, peak {np.max(np.abs(mix)):.3f}")


def witchs_lullaby():
    beat = 60 / 66
    mix = np.zeros((round(24 * 3 * beat * RATE), 2))
    # E minor, a suspended dominant and a small unresolved magical turn.
    chords = [(40, 47, 55, 59), (36, 43, 52, 59), (43, 50, 55, 62), (38, 45, 54, 57),
              (40, 47, 55, 59), (45, 52, 57, 60), (36, 43, 52, 55), (35, 42, 51, 57)]
    motifs = [[76, 71, 79, 78, 76, 71], [76, 79, 83, 79, 76, 74],
              [79, 74, 83, 81, 79, 74], [78, 74, 81, 78, 76, 74],
              [76, 71, 79, 83, 78, 76], [81, 76, 84, 83, 81, 76],
              [79, 76, 83, 79, 76, 71], [78, 75, 83, 81, 78, 75]]
    for bar in range(24):
        start = bar * 3 * beat
        chord = chords[bar % 8]
        for j, note in enumerate(chord):
            add_note(mix, start, 3.6 * beat, note, .032, "strings", (j - 1.5) * .22)
        for j, note in enumerate(motifs[bar % 8]):
            add_note(mix, start + j * .5 * beat, 2.2 * beat, note, .080 if j % 2 == 0 else .060,
                     "music_box", math.sin(j * 1.8) * .32)
        for j in range(3):
            add_note(mix, start + j * beat, 2.8 * beat, chord[j % 4] + 12, .035, "piano", -.16)
    return finish(mix)


def promise_to_rise():
    beat = 60 / 58
    mix = np.zeros((round(16 * 4 * beat * RATE), 2))
    # First phrase in A minor; the second opens toward C major and hope.
    chords = [(45, 52, 60), (41, 48, 57), (48, 55, 64), (43, 50, 59),
              (45, 52, 60), (41, 48, 57), (38, 45, 53), (40, 47, 56),
              (48, 55, 64), (43, 50, 59), (45, 52, 60), (41, 48, 57),
              (41, 48, 57), (43, 50, 59), (48, 55, 64), (40, 47, 56)]
    melodies = [(69, 67, 64), (65, 64, 60), (67, 64, 62), (62, 59, 64),
                (69, 64, 60), (65, 67, 64), (65, 62, 60), (64, 68, 71),
                (72, 71, 67), (71, 69, 67), (69, 72, 76), (72, 69, 65),
                (69, 72, 74), (71, 74, 76), (76, 74, 72), (71, 68, 64)]
    for bar, chord in enumerate(chords):
        start = bar * 4 * beat
        for j, note in enumerate(chord):
            add_note(mix, start, 4.6 * beat, note, .045, "strings", (j - 1) * .3)
        for j in range(4):
            add_note(mix, start + j * beat, 3.2 * beat, chord[j % 3], .09 if j == 0 else .055, "piano", -.24)
        for j, note in enumerate(melodies[bar]):
            add_note(mix, start + [0, 1.5, 3][j] * beat, 2.8 * beat, note, .11, "piano", .22)
    return finish(mix)


def main():
    write(ROOT / "audio/bgm/witchs_lullaby.wav", witchs_lullaby())
    write(ROOT / "audio/bgm/promise_to_rise.wav", promise_to_rise())
    for name, notes in [("menu_hover", [79]), ("menu_confirm", [72, 79])]:
        mix = np.zeros((RATE, 2))
        for i, note in enumerate(notes):
            add_note(mix, .08 * i, .7, note, .20, "music_box")
        write(ROOT / f"audio/sfx/{name}.wav", mix)


if __name__ == "__main__":
    main()
