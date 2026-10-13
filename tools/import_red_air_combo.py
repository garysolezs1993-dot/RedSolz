"""Validate and copy the air combo's PNGs byte-for-byte; preserve provenance."""
import hashlib
import io
import json
import sys
import zipfile
from pathlib import Path

from PIL import Image

root = Path(__file__).resolve().parents[1]
destination = root / "assets/game_assets/red_gothic_replacements"
archive = Path(sys.argv[1])
payloads = []
with zipfile.ZipFile(archive) as source:
    readme = source.read("README_FOR_CODEX.txt")
    for step in range(1, 4):
        for kind in ["Character", "VFX"]:
            group = f"air_combo_master/air_attack_{step}/{kind.lower()}"
            prefix = f"air_attack{step}_{'character' if kind == 'Character' else 'vfx'}"
            entries = []
            for index in range(8):
                name = f"Air_Attack_{step}/{kind}/{prefix}_{index:02d}.png"
                data = source.read(name)
                image = Image.open(io.BytesIO(data))
                if image.mode != "RGBA" or image.size != (512, 512):
                    raise ValueError(f"Expected RGBA 512x512: {name}")
                if image.getchannel("A").getextrema()[0] != 0:
                    raise ValueError(f"Missing transparency: {name}")
                entries.append((name, data))
            payloads.append((group, entries))

manifest_path = destination / "source_manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
for group, entries in payloads:
    folder = destination / group
    folder.mkdir(parents=True, exist_ok=True)
    records = []
    for name, data in entries:
        target = folder / Path(name).name
        target.write_bytes(data)
        records.append({"file": target.name, "source": name,
                        "sha256": hashlib.sha256(data).hexdigest(), "canvas": [512, 512]})
    manifest[group] = {"archive": archive.name, "frames": records}
(destination / "air_combo_master/README_FOR_CODEX.txt").write_bytes(readme)
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("Imported 48 unchanged air combo PNGs.")
