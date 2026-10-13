# Startup boss HP visibility

The Stage 1 screenshot's 33% bar was the scene's BossHP placeholder. It was initially visible, while its visibility update only ran in UI._process. The opening arrival pauses gameplay before that update can hide it.

Changes:
- BossHP starts hidden in both gameplay scenes and UI._ready.
- Stage 1 cannot reveal the boss bar through the gameplay visibility update.
- Scene placeholder maximum values are assigned before their values to avoid clamping against the default maximum.
- Arrival explicitly includes the gameplay UI when hiding/restoring canvas layers.
- Stage detection uses the parent scene path, available during child initialization.

Backup: .godot/local_backups/startup-boss-bar-20261014-002328/

Targeted headless Godot runtime verification: 8 checks passed, including immediate Stage 1 startup, paused arrival, HUD hiding, arrival skip/control restoration, Stage 1 gameplay, Stage 2 intro hiding, and correct boss HP after intro skip. No full visual cutscene playback was performed. The runtime reported the existing Camera2D physics interpolation warning; no script errors occurred.

Verification log: startup_boss_hp_check.log