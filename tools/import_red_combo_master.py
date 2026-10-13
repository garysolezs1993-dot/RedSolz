"""Import the master combo's individual PNGs without changing their bytes."""
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
            group = f"combo_master/attack_{step}/{kind.lower()}"
            prefix = f"attack{step}" + ("_vfx" if kind == "VFX" else "")
            entries = []
            for index in range(8):
                name = f"Attack_{step}/{kind}/{prefix}_{index:02d}.png"
                data = source.read(name)
                image = Image.open(io.BytesIO(data))
                if image.mode != "RGBA" or image.size != (512, 512):
                    raise ValueError(f"Expected unchanged RGBA 512x512 canvas: {name}")
                if image.getchannel("A").getextrema()[0] != 0:
                    raise ValueError(f"Missing transparent pixels: {name}")
                entries.append((name, data))
            payloads.append((group, entries))

# Validate every frame before writing any project assets.
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
(destination / "combo_master/README_FOR_CODEX.txt").write_bytes(readme)
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("Imported 48 unchanged master combo PNGs across six groups.")
