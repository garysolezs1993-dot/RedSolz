"""Split the transparent death atlas without rescaling or clipping the wolf."""

from pathlib import Path

from PIL import Image


DESTINATION = Path(__file__).resolve().parents[1] / "assets/game_assets/enemies/cursed_wolf_boss/death"
CANVAS = (480, 416)
GROUND_ROW = 389  # Matches the existing walk frames and boss sprite origin.


def main() -> None:
    atlas = Image.open(DESTINATION / "death_source_clean.png").convert("RGBA")
    for index in range(8):
        column, row = index % 4, index // 4
        frame = atlas.crop((
            column * atlas.width // 4,
            row * atlas.height // 2,
            (column + 1) * atlas.width // 4,
            (row + 1) * atlas.height // 2,
        ))
        bounds = frame.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
        if bounds is None:
            raise ValueError(f"Death frame {index} is empty")
        if bounds[0] == 0 or bounds[1] == 0 or bounds[2] == frame.width or bounds[3] == frame.height:
            raise ValueError(f"Death frame {index} touches its atlas boundary")
        x = (CANVAS[0] - frame.width) // 2
        y = GROUND_ROW - (bounds[3] - 1)
        if bounds[0] + x < 0 or bounds[2] + x > CANVAS[0] or bounds[1] + y < 0:
            raise ValueError(f"Death frame {index} would be clipped")
        canvas = Image.new("RGBA", CANVAS)
        canvas.alpha_composite(frame, (x, y))
        canvas.save(DESTINATION / f"death_{index:02d}.png")
        print(f"death_{index:02d}: ground row {GROUND_ROW}, bounds {canvas.getbbox()}")


if __name__ == "__main__":
    main()
