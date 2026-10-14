# Removed temporary one-hit ending test

The one-hit test was removed on 2026-10-14. Its exported player flag, Stage 2 scene setting, and outgoing damage overrides no longer exist.

Original damage is restored:

| Attack | Damage |
| --- | --- |
| Basic ground and air combo hits | 20 |
| Rising Slash and Downward Slash | 20 |
| Damage-dealing melee skills | 20 |
| Crescent Slash projectile | 20 |

Red's incoming damage and boss attack damage were not retuned. The F7 boss teleport, HUD shortcut button and control-list hint were removed at the same time. Reach the boss through the normal Moon Gate progression.

Historical backup: .godot/local_backups/ending-one-hit-ko-20261013-211020/
The archived stable-prototype-2026-10-14 tag preserves the earlier debug-enabled snapshot; the subsequent main commit removes those features.