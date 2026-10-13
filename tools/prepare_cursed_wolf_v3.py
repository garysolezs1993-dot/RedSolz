"""Pack approved transparent atlases; retain alpha and one scale per animation."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets/game_assets/enemies/cursed_wolf_boss"
CANVAS = (640, 512)
GROUND = 439
# Anatomical paw rows, excluding energy/dust beneath the feet. Row-local pixels.
PAW_ROWS = {
    "walk": [384, 383, 384, 384, 326, 327, 327, 327],
    "jump": [430, 431, 434, 416, 289, 322, 323, 321],
    "pounce": [422, 422, 424, 399, 291, 326, 328, 322],
    "attack": [467, 468, 473, 475, 328, 333, 333, 334],
}


def visible_bounds(image):
    return image.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()


def main():
    for name, paw_rows in PAW_ROWS.items():
        atlas = Image.open(ROOT / "animation_sources_v3" / f"{name}_clean.png").convert("RGBA")
        if atlas.getchannel("A").getextrema()[0] != 0:
            raise ValueError(f"{name}: source is not transparent")
        first = atlas.crop((0, 0, atlas.width // 4, atlas.height // 2))
        first_bounds = visible_bounds(first)
        # Match the existing walk's 408-source-pixel resting silhouette width.
        # Fixed for the entire track: never shrink a jump or attack to fit its box.
        scale = 408 / (first_bounds[2] - first_bounds[0])
        destination = ROOT / f"{name}_v3"
        destination.mkdir(exist_ok=True)
        for index, paw_row in enumerate(paw_rows):
            column, row = index % 4, index // 4
            cell = atlas.crop((column * atlas.width // 4, row * atlas.height // 2,
                               (column + 1) * atlas.width // 4, (row + 1) * atlas.height // 2))
            bounds = visible_bounds(cell)
            if not bounds or bounds[0] <= 0 or bounds[1] <= 0 or bounds[2] >= cell.width or bounds[3] >= cell.height:
                raise ValueError(f"{name} {index}: visible artwork touches the cell boundary")
            # Pixel-preserving nearest-neighbor packing; do not threshold the alpha.
            size = (round(cell.width * scale), round(cell.height * scale))
            frame = cell.resize(size, Image.Resampling.NEAREST)
            scaled_bounds = visible_bounds(frame)
            x = round(CANVAS[0] / 2 - (scaled_bounds[0] + scaled_bounds[2]) / 2)
            y = GROUND - round(paw_row * scale)
            if (x + scaled_bounds[0] < 0 or x + scaled_bounds[2] > CANVAS[0]
                    or y + scaled_bounds[1] < 0 or y + scaled_bounds[3] > CANVAS[1]):
                raise ValueError(f"{name} {index}: output would clip visible artwork")
            output = Image.new("RGBA", CANVAS)
            output.alpha_composite(frame, (x, y))
            output.save(destination / f"{name}_{index:02d}.png")
        print(f"{name}: 8 frames, fixed scale {scale:.4f}, ground row {GROUND}")


if __name__ == "__main__":
    main()
