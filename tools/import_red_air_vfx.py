"""Validate replacement air VFX, copy original PNG bytes, and record sources."""
import hashlib
import io
import json
import sys
import zipfile
from pathlib import Path

from PIL import Image

root = Path(__file__).resolve().parents[1]
destination = root / "assets/game_assets/red_gothic_replacements"
archives = [Path(arg) for arg in sys.argv[1:]]
if len(archives) != 3:
    raise SystemExit("Supply the three VFX ZIPs in attack 1, 2, 3 order.")

# Validate the complete set before replacing any active file.
payloads = []
for step, archive in enumerate(archives, 1):
    expected_canvas = 1536
    with zipfile.ZipFile(archive) as source:
        for frame in range(8):
            name = f"air_attack{step}_vfx_{frame:02d}.png"
            data = source.read(name)
            image = Image.open(io.BytesIO(data))
            if image.mode != "RGBA" or image.size != (expected_canvas, expected_canvas):
                raise ValueError(f"Unexpected canvas/mode: {archive.name}/{name}")
            if image.getchannel("A").getextrema()[0] != 0:
                raise ValueError(f"Missing real transparency: {name}")
            payloads.append((step, archive, name, expected_canvas, data))

manifest_path = destination / "source_manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
for step, archive in enumerate(archives, 1):
    group = f"air_combo_master/air_attack_{step}/vfx"
    folder = destination / group
    folder.mkdir(parents=True, exist_ok=True)
    records = []
    for item_step, _, name, canvas, data in payloads:
        if item_step != step:
            continue
        (folder / name).write_bytes(data)
        records.append({"file": name, "source": name,
                        "sha256": hashlib.sha256(data).hexdigest(),
                        "canvas": [canvas, canvas]})
    manifest[group] = {"archive": archive.name, "frames": records}
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("Imported 24 unchanged air VFX PNGs; character PNGs preserved.")
