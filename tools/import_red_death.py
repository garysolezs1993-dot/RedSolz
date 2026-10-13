"""Import the eight supplied death PNGs unchanged and record their source.

Usage: python tools/import_red_death.py PATH_TO_ZIP
"""
import hashlib
import io
import json
import sys
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/game_assets/red_gothic_replacements"
archive = Path(sys.argv[1])
frames = []
with zipfile.ZipFile(archive) as source:
    # Validate the complete set before writing any project assets.
    payloads = []
    for index in range(8):
        name = f"death_{index:02d}.png"
        data = source.read(name)
        image = Image.open(io.BytesIO(data))
        if image.mode != "RGBA" or image.size != (512, 512):
            raise ValueError(f"Expected a 512x512 RGBA frame: {name}")
        payloads.append((name, data))

    folder = DEST / "death"
    folder.mkdir(parents=True, exist_ok=True)
    for name, data in payloads:
        target = folder / name
        target.write_bytes(data)
        digest = hashlib.sha256(data).hexdigest()
        if hashlib.sha256(target.read_bytes()).hexdigest() != digest:
            raise ValueError(f"Import changed source bytes: {name}")
        frames.append({"file": name, "source": name, "sha256": digest, "canvas": [512, 512]})

manifest_path = DEST / "source_manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
manifest["death"] = {"archive": archive.name, "frames": frames}
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("Imported eight unchanged death PNGs; retained the existing source manifest entries.")
