# Red Riding Hood — CLEAN / CODEX-READY FRAME ASSETS

This pack is rebuilt from the supplied atlas with animation cells separated instead of blindly taking 64px chunks.

## Critical fix
The attack animations previously contained fragments of adjacent frames. The attack PNGs here keep the primary character/effect component only, so one file cannot accidentally contain half of its neighbor.

`attack_air/attack_air_05.png` is a clean duplicate of frame 04 because the source atlas's final air-slash cell is effect-only. The slash effect should be handled separately in Godot.

## Rules
- Every PNG is exactly 64x64.
- One PNG = one animation frame.
- Numeric ordering is explicit: `00`, `01`, `02`, ...
- Use nearest-neighbor filtering.
- Do NOT feed the original atlas to Codex for animation import.
- Import each folder independently into an AnimatedSprite2D / SpriteFrames.

Suggested FPS:
- idle: 8
- walk/run: 10
- jump/fall: 8
- attack: 12
- skills: 10
