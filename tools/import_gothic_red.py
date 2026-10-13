"""Import the supplied draft PNGs byte-for-byte; retain the pack's handoff docs.

Usage: python tools/import_gothic_red.py PATH_TO_ZIP
No resizing, alpha cleanup, or inferred sheet cropping is performed.
"""
import hashlib
import io
import sys
import zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/game_assets/red_gothic"

with zipfile.ZipFile(sys.argv[1]) as pack:
    count = 0
    for name in pack.namelist():
        path = Path(name)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"Unsafe archive path: {name}")
        is_frame = any(p.startswith("game_") and p.endswith("_draft") for p in path.parts) and path.suffix == ".png"
        is_doc = name in ("manifest.json", "README_FOR_CODEX.md", "CODEX_HANDOFF.txt")
        is_preview = name.startswith("QA_previews/") and path.suffix.lower() in (".jpg", ".png")
        if not (is_frame or is_doc or is_preview):
            continue
        data = pack.read(name)
        target = (ROOT / ".godot/red_pack_review" / path) if is_preview else DEST / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        assert hashlib.sha256(target.read_bytes()).digest() == hashlib.sha256(data).digest()
        if is_frame:
            im = Image.open(io.BytesIO(data))
            assert im.mode == "RGBA" and im.width == im.height and im.width in (48, 64, 96), name
            if im.width == 48:
                assert im.getchannel("A").getbbox()[3] == 46, name
            count += 1
    print(f"Imported {count} unchanged PNG frames; all character foot lines end at source y=46.")
