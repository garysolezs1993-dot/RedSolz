"""Import visually reviewed replacement frames without modifying PNG contents.

Usage: python tools/import_red_replacements.py PATH_TO_OUTER_ZIP
Nested review/problematic sets are deliberately not activated.
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
# archive, original directory, filename prefix, count
SETS = {
    "idle": ("Red_Idle_Approved_8Frames_For_Codex.zip", "Red_Idle_Approved_8Frames/idle", "idle", 8),
    "run": ("Red_Run_Approved_8Frames_For_Codex.zip", "Red_Run_Approved_8Frames/run", "run", 8),
    "jump": ("Red_Jump_Approved_8Frames_For_Codex.zip", "Red_Jump_Approved_8Frames/jump", "jump", 8),
    "fall": ("Red_Fall_Approved_4Frames_For_Codex.zip", "Red_Fall_Approved_4Frames/fall", "fall", 4),
    "landing": ("Red_Landing_Recovery_4Frames_For_Codex.zip", "Red_Landing_Recovery_4Frames/frames", "landing_recovery", 4),
    "dash": ("Red_Dash_Approved_8Frames_For_Codex.zip", "Red_Dash_Approved_8Frames/dash", "dash", 8),
    "air_attack": ("Red_Air_Attack_For_Codex.zip", "Red_Air_Attack_For_Codex/frames", "air_attack", 8),
    "hurt": ("Red_Hurt_Cleaned_For_Codex.zip", "frames", "hurt", 8),
    "crouch": ("Red_Crouch_For_Codex_Download.zip", "Red_Crouch_Transparent_For_Codex_v2/crouch", "crouch", 6),
    "crouch_walk": ("Red_Crouch_For_Codex_Download.zip", "Red_Crouch_Transparent_For_Codex_v2/crouch_walk", "crouch_walk", 8),
    # The supplied rising-slash directory labels are reversed. This is Red.
    "rising_slash": ("red_rising_slash_all_frames.zip", "vfx_frames", "red_rising_slash_vfx", 8),
}

manifest_path = DEST / "source_manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
with zipfile.ZipFile(sys.argv[1]) as outer:
    for group, (archive, directory, prefix, count) in SETS.items():
        inner = zipfile.ZipFile(io.BytesIO(outer.read(archive)))
        folder = DEST / group
        folder.mkdir(parents=True, exist_ok=True)
        entries = []
        first = 1 if group == "rising_slash" else 0
        for index in range(first, first + count):
            source = f"{directory}/{prefix}_{index:02d}.png"
            data = inner.read(source)
            im = Image.open(io.BytesIO(data))
            if im.mode != "RGBA":
                raise ValueError(f"Expected RGBA: {source}")
            target = folder / Path(source).name
            target.write_bytes(data)
            digest = hashlib.sha256(data).hexdigest()
            if hashlib.sha256(target.read_bytes()).hexdigest() != digest:
                raise ValueError(f"Import changed source bytes: {source}")
            entries.append({"file": target.name, "source": source, "sha256": digest, "canvas": list(im.size)})
        manifest[group] = {"archive": archive, "frames": entries}
        for name in inner.namelist():
            if Path(name).name.lower().startswith("readme"):
                (folder / "SOURCE_README.txt").write_bytes(inner.read(name))
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print(f"Imported {sum(len(manifest[group]['frames']) for group in SETS)} unchanged PNGs across {len(SETS)} reviewed groups; retained other imported groups.")
