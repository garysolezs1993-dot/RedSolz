"""Extract and normalize the supplied Cursed Wolf animation frames."""

from __future__ import annotations

import io
import zipfile
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


ARCHIVE = Path.home() / "Downloads" / "Cursed_Wolf_Boss_Cropped_Animations_For_Codex.zip"
DESTINATION = Path(__file__).resolve().parents[1] / "assets" / "game_assets" / "enemies" / "cursed_wolf_boss"
ANIMATIONS = ("walk", "jump", "attack", "pounce", "howl", "howl_aoe")
CANVAS = (480, 416)
FEET_Y = 390


def remove_edge_connected_checker(image: Image.Image) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA")).copy()
    rgb = rgba[:, :, :3].astype(np.int16)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    luminance = rgb.mean(axis=2)
    # The archive's checkerboard is baked into the RGB pixels. Its neutral grey
    # tiles touch every frame edge; only clear connected grey background.
    candidate = (chroma <= 25) & (luminance >= 68) & (luminance <= 232) & (rgba[:, :, 3] > 0)
    height, width = candidate.shape
    seen = np.zeros((height, width), dtype=np.bool_)
    queue: deque[int] = deque()

    for x in range(width):
        if candidate[0, x]:
            seen[0, x] = True
            queue.append(x)
        if candidate[height - 1, x] and not seen[height - 1, x]:
            seen[height - 1, x] = True
            queue.append((height - 1) * width + x)
    for y in range(height):
        if candidate[y, 0] and not seen[y, 0]:
            seen[y, 0] = True
            queue.append(y * width)
        if candidate[y, width - 1] and not seen[y, width - 1]:
            seen[y, width - 1] = True
            queue.append(y * width + width - 1)

    while queue:
        index = queue.popleft()
        y, x = divmod(index, width)
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < height and 0 <= nx < width and candidate[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                queue.append(ny * width + nx)

    rgba[seen, 3] = 0
    return Image.fromarray(rgba, "RGBA")


def process_frame(source: Image.Image) -> Image.Image:
    cleaned = remove_edge_connected_checker(source)
    alpha = cleaned.getchannel("A")
    bbox = alpha.getbbox()
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    if bbox is None:
        return canvas
    subject = cleaned.crop(bbox)
    # Keep each pose on a shared ground anchor to prevent animation jitter.
    x = (CANVAS[0] - subject.width) // 2
    y = FEET_Y - subject.height
    canvas.alpha_composite(subject, (x, y))
    return canvas


def main() -> None:
    if not ARCHIVE.is_file():
        raise FileNotFoundError(f"Animation archive not found: {ARCHIVE}")
    count = 0
    with zipfile.ZipFile(ARCHIVE) as archive:
        for animation in ANIMATIONS:
            folder = DESTINATION / animation
            folder.mkdir(parents=True, exist_ok=True)
            names = sorted(
                (name for name in archive.namelist() if name.startswith(f"{animation}/") and name.lower().endswith(".png")),
                key=lambda name: int(Path(name).stem.rsplit("_", 1)[1]),
            )
            for name in names:
                with Image.open(io.BytesIO(archive.read(name))) as source:
                    frame = process_frame(source)
                target = folder / Path(name).name
                frame.save(target, optimize=True)
                count += 1
            print(f"{animation}: {len(names)} frames")
    print(f"Prepared {count} transparent, ground-aligned frames at {DESTINATION}")


if __name__ == "__main__":
    main()
