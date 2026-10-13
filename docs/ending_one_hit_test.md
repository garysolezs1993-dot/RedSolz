# Temporary one-hit KO for ending review

Enabled on **Player → Ending Test One Hit Ko** in `scenes/stage2_boss.tscn`.

During this temporary mode, Red's melee attacks, damage-dealing melee skills and Crescent Slash deal **100,000 damage**. One successful hit defeats the current Cursed Wolf and triggers the normal ending. Attack startup, range and collision still apply.

## Preserved original damage

| Attack | Original damage |
| --- | --- |
| Basic ground combo and air combo hits | 20 |
| Rising Slash and Downward Slash | 20 |
| Damage-dealing melee skills | 20 |
| Crescent Slash projectile | 20 |

These values remain in the normal code paths. Crescent's default in `scripts/crescent_projectile.gd` is unchanged. Red's incoming damage and boss attack damage are unchanged. Stage 1 uses the default disabled flag.

To restore normal boss-stage damage, uncheck **Ending Test One Hit Ko** on Stage 2's Player (or set `ending_test_one_hit_ko = false` in the scene). No damage values need to be guessed or re-entered.

Pre-change backup: `.godot/local_backups/ending-one-hit-ko-20261013-211020/`. No gameplay tests were run for this temporary switch.
