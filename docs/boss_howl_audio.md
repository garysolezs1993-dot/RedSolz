# Darker boss howl attack

The Cursed Wolf's **howl AOE attack only** now uses
`audio/sfx/boss_howl.wav`, derived from the separate edited preview
`audio/previews/wolf_howl_dark_layered.wav`.

The common wolves still use `audio/sfx/wolf_howl.wav`. Its SHA-256 is unchanged.
The boss's pounce windup also retains its existing sound; no shared sound was
overwritten. The long edited preview and downloaded original remain intact.

## Timing

- Existing wolf/AOE animation: 8 frames at 7 FPS, **1.142857s**.
- Dedicated sound: **1.142854s** (rounded to 48kHz sample boundaries).
- AOE release: frame 4, **0.571429s**.
- Strongest measured 40ms sound region: **0.560s**, near the release frame.
- Start fade: 18ms; final fade: 90ms; final PCM samples are zero.
- Export: stereo 48kHz PCM16, peak **−3dBFS**.

A coherent two-second phrase from the edited recording is fitted to the
animation with pitch-preserving phase-vocoder stretching. The entire long
recording is not sped up sevenfold. Its deeper layers stay low, and an amplitude
swell emphasizes the AOE release. The existing attack animation/FPS, hit timing,
cooldowns and behavior have not been changed.

## Playback and controls

`scripts/cursed_wolf_boss.gd` creates a dedicated child `BossHowlSound` on the
existing **SFX** bus. It starts once in `_begin_howl()`, and stops when the howl
finishes or is interrupted by damage, another animation, or death. Removing
the boss/stage removes its player; pausing the world pauses this sound alongside
the attack animation. Existing SFX volume/mute settings apply.

The boss Inspector exposes **Howl Attack Sound**:

- `boss_howl_sound`: `res://audio/sfx/boss_howl.wav`
- `boss_howl_volume_db`: **−9dB**, independent of common-wolf playback levels.

The processing method is `DarkWolfHowl.FitAttack` in `tools/darken_wolf_howl.cs`.

Godot imported the new sound and script changes without errors. File metadata,
the burst-region timing, final silence and common-sound hash were inspected.
No gameplay tests were run for this integration.

Pre-change boss script and audio-processing tool are backed up at
`.godot/local_backups/boss-howl-audio-20261013-094034/`.
