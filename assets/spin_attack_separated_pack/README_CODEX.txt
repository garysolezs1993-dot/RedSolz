# Red — Attack Spin Assets for Codex

attack_spin/ = 8 complete character+attack frames.
spin_fx/ = 8 separate slash/effect frames.
Every exported frame is exactly 64x64 RGBA PNG with actual alpha transparency.
The baked checkerboard from the generated reference has been removed.

Godot: use nearest-neighbor filtering.
Codex: import each numbered PNG as one frame; do not crop, merge, or use the source sheet as the animation.
