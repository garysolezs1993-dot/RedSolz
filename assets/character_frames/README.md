# Red Riding Hood — extracted frame assets

Each animation is in its own folder. Every frame is a 64x64 transparent PNG, intended to display as a 32x32 logical sprite at 0.5 scale / 2x source resolution. Frames are numbered from 00.

## Character animations
idle, blink, breath, walk, run, jump, fall, land, crouch, crouch_walk, dash, attack_slash, attack_spin, attack_thrust, attack_air, skill_blood_blossom, skill_wolf_summon, skill_execution, hurt, heavy_hurt, down, death, revive.

## Effects
Separate folders under effects/ contain attack/VFX frames so the character animation does not depend on the VFX being baked into the character sprite.

## Godot import
Use nearest-neighbor filtering. For AnimatedSprite2D, add each numbered PNG in order. Set character node scale to (0.5, 0.5) if using these 64x64 sources as 32x32 logical sprites. Keep the same origin/position for every frame.
