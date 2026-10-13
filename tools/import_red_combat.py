"""Copy the numbered combat PNGs unchanged; record archive paths and hashes.

Usage: python tools/import_red_combat.py BASIC_ATTACK_ZIP CRESCENT_ZIP
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
SETS = [
    ("basic_attack", sys.argv[1], "", "attack", 0),
    ("crescent_character", sys.argv[2], "character/", "crescent_slash_character_fixed", 1),
    ("crescent_vfx", sys.argv[2], "vfx/", "crescent_slash_vfx_fixed", 1),
    ("crescent_projectile", sys.argv[2], "projectile/", "crescent_slash_projectile_fixed", 1),
]
payloads = []
for group, archive, directory, prefix, first in SETS:
    with zipfile.ZipFile(archive) as source:
        entries = []
        for index in range(first, first + 8):
            name = f"{directory}{prefix}_{index:02d}.png"
            data = source.read(name)
            image = Image.open(io.BytesIO(data))
            if image.mode != "RGBA":
                raise ValueError(f"Expected RGBA: {name}")
            entries.append((name, data, list(image.size)))
        payloads.append((group, Path(archive).name, entries))

manifest_path = DEST / "source_manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
for group, archive, entries in payloads:
    folder = DEST / group
    folder.mkdir(parents=True, exist_ok=True)
    records = []
    for name, data, canvas in entries:
        target = folder / Path(name).name
        target.write_bytes(data)
        records.append({"file": target.name, "source": name,
                        "sha256": hashlib.sha256(data).hexdigest(), "canvas": canvas})
    manifest[group] = {"archive": archive, "frames": records}
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("Imported 32 unchanged combat PNGs across four groups.")
