# Stable prototype snapshot — 2026-10-14

This snapshot preserves the current project on editpower1, including the Stage 1 exploration and Moon Seal progression, combat and animation integrations, opening/boss/ending cinematics, final story panels, completion artwork, lighting, checkpoint interactions, Moon Wisp effects, and gate presentation updates.

## Gameplay settings after debug cleanup

The temporary one-hit damage override has been removed from the player script and Stage 2 scene. Normal outgoing melee, skill and Crescent Slash damage is restored to 20. The F7 boss teleport and its HUD button have also been removed. Reach Stage 2 through the Moon Gate after activating all three seals.

The original archived tag stable-prototype-2026-10-14 and pre-cleanup local backup preserve the earlier debug-enabled snapshot. The follow-up commit on main/editpower1 contains this cleanup.

## Backup and storage

A complete pre-commit local copy, including Git metadata, Godot cache, and previous local backups, was made at:
C:/Users/Public/Godot Project/backups/yuki-solz-stable-2026-10-14-010037/

The GitHub snapshot includes the files governed by the repository's existing .gitignore. Godot's generated .godot directory remains excluded from Git; its contents are in the full local copy. GIF previews are stored with Git LFS. Use Git LFS when cloning to retrieve those preview files.

The source game state has not been retuned for this save. The newest completion-art and gate-placement changes have been imported in Godot but have not received a full gameplay test. Earlier targeted checks and their results are retained in docs.
