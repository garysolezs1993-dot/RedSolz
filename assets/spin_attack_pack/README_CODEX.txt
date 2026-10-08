# Red Riding Hood — Attack Spin Codex Assets

This pack contains the cleaned 8-frame spin attack reference.

attack_spin/
  attack_spin_00.png ... attack_spin_07.png
  Complete Red character + slash effect frames.

attack_spin_fx/
  spin_fx_00.png ... spin_fx_07.png
  Slash effect only, intended for a separate AnimatedSprite2D.

Every PNG is 64x64 RGBA and should use nearest-neighbor filtering in Godot.

IMPORTANT:
- One PNG = one frame.
- Do not merge neighboring cells.
- Do not crop the PNGs again.
- Keep the sprite origin consistent.
- The effect-only row should remain a separate VFX animation.
- SOURCE_ATTACK_SPIN_REFERENCE.png is included for visual reference.
