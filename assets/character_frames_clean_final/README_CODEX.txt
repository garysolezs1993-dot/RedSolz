# Red — CLEAN Codex-ready frames

Source: the supplied `image(3).png` atlas.

## Rules
- Every animation frame is a separate PNG.
- Every frame is exactly 64×64.
- Every frame is RGBA with transparent background.
- Each frame is tightly isolated so neighboring-frame fragments are excluded.
- The character is placed on a consistent 64×64 canvas with a common bottom baseline.
- Pixel art is kept nearest-neighbor.
- `SOURCE_ATLAS_ORIGINAL.png` is the original source.
- `SOURCE_ATLAS_TRANSPARENT.png` is the original atlas with the dark background removed.
- `PREVIEW.png` is a quick verification sheet.

## Important source limitation
The generated atlas contains labels such as `IDLE (8)` and `ATTACK 4 - AIR SLASH (6)`, but several labeled counts do not match the number of actually drawn poses in the supplied image. This pack does NOT invent missing artwork. It exports only complete visible frames recoverable from the source.

Exported frame counts:
{
  "idle": 5,
  "blink": 3,
  "breath": 4,
  "walk": 8,
  "run": 6,
  "jump": 5,
  "fall": 3,
  "land": 3,
  "crouch": 4,
  "crouch_walk": 5,
  "dash": 3,
  "attack_slash": 5,
  "attack_spin": 6,
  "attack_thrust": 4,
  "attack_air": 6,
  "skill_blood_blossom": 8,
  "skill_wolf_summon": 6,
  "skill_execution": 8,
  "hurt": 5,
  "heavy_hurt": 4,
  "revive": 5,
  "down": 4,
  "death": 4
}

## Codex instruction
Use only the numbered PNGs inside each animation folder. Do not crop, resize, merge, infer, or reconstruct frames from the source atlas. `walk/walk_03.png` is a complete isolated walk pose.
