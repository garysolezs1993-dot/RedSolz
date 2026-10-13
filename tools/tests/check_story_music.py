"""Technical PCM/loop checks; these do not replace a listening review."""
from pathlib import Path
import json
import wave
import numpy as np

root = Path(__file__).resolve().parents[2]
report = {}
for name in ["witchs_lullaby", "promise_to_rise"]:
    with wave.open(str(root / f"audio/bgm/{name}.wav"), "rb") as source:
        assert source.getnchannels() == 2 and source.getsampwidth() == 2
        rate = source.getframerate()
        data = np.frombuffer(source.readframes(source.getnframes()), dtype="<i2").reshape(-1, 2) / 32768.0
    peak = float(np.max(np.abs(data)))
    seam_step = float(np.max(np.abs(data[0] - data[-1])))
    nearby_step = float(np.max(np.abs(np.diff(np.concatenate([data[-4410:], data[:4410]]), axis=0))))
    assert peak < .73, "Unexpected clipping/headroom change"
    assert seam_step < .015 and seam_step <= nearby_step, "Unexpected discontinuity at loop boundary"
    report[name] = {"seconds": round(len(data) / rate, 3), "sample_rate": rate,
                    "channels": 2, "peak": round(peak, 5), "rms": round(float(np.sqrt(np.mean(data ** 2))), 5),
                    "loop_boundary_sample_step": round(seam_step, 6), "nearby_max_sample_step": round(nearby_step, 6)}
output = root / ".godot/presentation_checks/music_report.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
