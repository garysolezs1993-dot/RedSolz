"""Pack the two approved howl cutout atlases on stable anatomical/ground anchors."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets/game_assets/enemies/cursed_wolf_boss"
SOURCES = ROOT / "howl_sources_v3"
GROUND = 567
# Row-local source pixels, measured at the paws and ellipse CENTER respectively.
PAW_ROWS = [430, 430, 430, 430, 423, 423, 423, 423]
RING_CENTERS = [(233, 350), (232, 354), (207, 350), (213, 348),
                (234, 330), (230, 326), (214, 326), (218, 330)]


def bounds(image):
    return image.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()


def main():
    for layer, filename, canvas_size, scale in (
        ("howl", "wolf_clean.png", (640, 768), (0.95, 0.95)),
        # Spread the supplied tall energy column into a wide ground shockwave.
        # These are constant layer scales, never changed to fit individual frames.
        ("howl_aoe", "aoe_clean.png", (1536, 768), (4.4, 1.25)),
    ):
        atlas = Image.open(SOURCES / filename).convert("RGBA")
        if atlas.getchannel("A").getextrema()[0] != 0:
            raise ValueError(f"{layer}: opaque atlas")
        destination = ROOT / f"{layer}_v3"
        destination.mkdir(exist_ok=True)
        for index in range(8):
            column, row = index % 4, index // 4
            cell = atlas.crop((column * atlas.width // 4, row * atlas.height // 2,
                               (column + 1) * atlas.width // 4, (row + 1) * atlas.height // 2))
            b = bounds(cell)
            if not b or b[0] <= 0 or b[1] <= 0 or b[2] >= cell.width or b[3] >= cell.height:
                raise ValueError(f"{layer} {index}: artwork touches a source boundary")
            if layer == "howl":
                # Midpoint between the seated rear and front paw groups.
                anchor = (b[0] + (b[2] - b[0]) * 0.62, PAW_ROWS[index])
            else:
                anchor = RING_CENTERS[index]
            resized = cell.resize((round(cell.width * scale[0]), round(cell.height * scale[1])),
                                  Image.Resampling.NEAREST)
            x = canvas_size[0] // 2 - round(anchor[0] * scale[0])
            y = GROUND - round(anchor[1] * scale[1])
            b = bounds(resized)
            if x + b[0] < 0 or x + b[2] > canvas_size[0] or y + b[1] < 0 or y + b[3] > canvas_size[1]:
                raise ValueError(f"{layer} {index}: output would clip artwork")
            output = Image.new("RGBA", canvas_size)
            output.alpha_composite(resized, (x, y))
            output.save(destination / f"{layer}_{index:02d}.png")
        print(f"{layer}: eight transparent frames, anchor (canvas center, {GROUND})")


if __name__ == "__main__":
    main()
