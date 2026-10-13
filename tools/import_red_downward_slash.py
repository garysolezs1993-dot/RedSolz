"""Copy reviewed Downward Slash frames unchanged and record their provenance."""
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
    for kind, prefix in [("Character", "downward_slash"), ("VFX", "downward_slash_vfx")]:
        for index in range(8):
            name = f"{kind}/{prefix}_{index:02d}.png"
            data = source.read(name)
            image = Image.open(io.BytesIO(data))
            if image.mode != "RGBA" or image.size != (1536, 1536):
                raise ValueError(f"Expected full RGBA 1536px canvas: {name}")
            if image.getchannel("A").getextrema()[0] != 0:
                raise ValueError(f"Missing transparency: {name}")
            payloads.append((kind.lower(), name, data))

manifest_path = destination / "source_manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
for kind in ["character", "vfx"]:
    group = "downward_master/" + kind
    folder = destination / group
    folder.mkdir(parents=True, exist_ok=True)
    records = []
    for entry_kind, name, data in payloads:
        if entry_kind == kind:
            target = folder / Path(name).name
            target.write_bytes(data)
            records.append({"file": target.name, "source": name,
                            "canvas": [1536, 1536],
                            "sha256": hashlib.sha256(data).hexdigest()})
    manifest[group] = {"archive": archive.name, "frames": records}
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("Imported 16 unchanged Downward Slash PNGs.")
