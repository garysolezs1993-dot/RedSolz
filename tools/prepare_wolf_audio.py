"""Trim, time-fit, and level the supplied Common Wolf WAV recordings."""

import math
import wave
from pathlib import Path

import numpy as np


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\Owner\Downloads")
DESTINATION = PROJECT / "audio" / "sfx"
RATE = 44100


def read_wav(path):
    with wave.open(str(path), "rb") as wav:
        channels = wav.getnchannels()
        rate = wav.getframerate()
        width = wav.getsampwidth()
        if width != 2:
            raise ValueError(f"{path.name} must be 16-bit PCM WAV")
        samples = np.frombuffer(wav.readframes(wav.getnframes()), dtype="<i2")
        samples = samples.astype(np.float32).reshape(-1, channels) / 32768.0
    if rate != RATE:
        raise ValueError(f"{path.name} is {rate} Hz; expected {RATE} Hz")
    return samples


def phase_vocoder_stretch(samples, target_frames, n_fft=2048, hop=512):
    """Change duration while preserving pitch; intended for the tonal howl."""
    source_frames = len(samples)
    speed = source_frames / target_frames
    analysis_hop = hop * speed
    padded = np.pad(samples, ((n_fft, n_fft), (0, 0)))
    window = np.hanning(n_fft).astype(np.float32)
    positions = np.arange(0.0, source_frames, analysis_hop)
    bins = n_fft // 2 + 1
    omega = 2.0 * np.pi * hop * np.arange(bins) / n_fft
    output = np.zeros((len(positions) * hop + n_fft, samples.shape[1]), dtype=np.float32)
    normalization = np.zeros(len(output), dtype=np.float32)
    previous_phase = None
    accumulated_phase = None

    for frame_index, position in enumerate(positions):
        start = int(round(position)) + n_fft // 2
        frame = padded[start:start + n_fft]
        spectrum = np.fft.rfft(frame * window[:, None], axis=0)
        magnitude = np.abs(spectrum)
        phase = np.angle(spectrum)
        if previous_phase is None:
            accumulated_phase = phase
        else:
            delta = phase - previous_phase - omega[:, None] * speed
            delta = (delta + np.pi) % (2.0 * np.pi) - np.pi
            accumulated_phase += omega[:, None] + delta / speed
        previous_phase = phase
        rebuilt = magnitude * np.exp(1j * accumulated_phase)
        reconstructed = np.fft.irfft(rebuilt, n=n_fft, axis=0).astype(np.float32)
        out_start = frame_index * hop
        output[out_start:out_start + n_fft] += reconstructed * window[:, None]
        normalization[out_start:out_start + n_fft] += window * window

    output /= np.maximum(normalization[:, None], 1e-5)
    offset = n_fft
    stretched = output[offset:offset + target_frames]
    if len(stretched) < target_frames:
        stretched = np.pad(stretched, ((0, target_frames - len(stretched)), (0, 0)))
    return stretched


def fit_peak(samples, target_db=-6.0):
    peak = float(np.max(np.abs(samples)))
    if peak < 1e-8:
        return samples
    target = 10.0 ** (target_db / 20.0)
    return samples * (target / peak)


def fade_edges(samples, fade_in_s=0.015, fade_out_s=0.08):
    result = samples.copy()
    in_frames = min(len(result) // 2, int(RATE * fade_in_s))
    out_frames = min(len(result) // 2, int(RATE * fade_out_s))
    if in_frames:
        result[:in_frames] *= np.linspace(0.0, 1.0, in_frames, dtype=np.float32)[:, None]
    if out_frames:
        result[-out_frames:] *= np.linspace(1.0, 0.0, out_frames, dtype=np.float32)[:, None]
    return result


def save_wav(path, samples):
    pcm = np.clip(samples, -1.0, 1.0)
    pcm = np.round(pcm * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(samples.shape[1])
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())


def main():
    DESTINATION.mkdir(parents=True, exist_ok=True)

    howl = read_wav(SOURCE / "Howl.wav")
    howl = phase_vocoder_stretch(howl, int(RATE * 1.1))
    howl = fade_edges(fit_peak(howl, -6.0), 0.02, 0.10)
    save_wav(DESTINATION / "wolf_howl.wav", howl)

    attack = read_wav(SOURCE / "Attack.wav")
    attack = attack[int(RATE * 2.50):int(RATE * 2.99)]
    attack = fade_edges(fit_peak(attack, -6.0), 0.008, 0.07)
    save_wav(DESTINATION / "wolf_attack.wav", attack)

    huff = read_wav(SOURCE / "Chase Huff.wav")
    huff = huff[int(RATE * 1.50):int(RATE * 2.20)]
    huff = fade_edges(fit_peak(huff, -6.0), 0.015, 0.08)
    save_wav(DESTINATION / "wolf_huff.wav", huff)

    for filename in ("wolf_howl.wav", "wolf_attack.wav", "wolf_huff.wav"):
        with wave.open(str(DESTINATION / filename), "rb") as wav:
            print(f"{filename}: {wav.getnframes() / wav.getframerate():.3f}s, {wav.getframerate()}Hz, {wav.getnchannels()}ch")


if __name__ == "__main__":
    main()
