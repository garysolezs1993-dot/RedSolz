# Cursed Wolf melee hit detection

## Diagnosis

The boss's visible walk/body spans roughly 140 pixels at the existing 0.35
display scale. Its only damage target was the 52×32 terrain collision box
near its paws. Red's normal swing reaches 49 pixels forward, so it could hit
that box only within about 75 pixels of the boss's center. A swing visually
touching the outer body at 85–105 pixels did no damage. The boss's own slash
can start at 118 pixels. Stationary melee attacks made this mismatch apparent.

## Change

`scenes/cursed_wolf_boss.tscn` now has a separate `Hurtbox` Area2D on enemy
layer 2. Its 128×100 rectangle is centered at (0, −50), covering the wolf's
body above the platform. It has no physical blocking/terrain response.
The existing 52×32 CharacterBody collision, animation scale, attack ranges,
AI, Red's melee reach and 20 damage per swing remain unchanged.

`scripts/damage_hurtbox.gd` resolves the area to its owning character.
`scripts/hitbox.gd` detects both bodies and hurtbox areas, deduplicating hits
by the owning character's instance ID. Overlapping both shapes therefore
still deals one hit per swing. `scripts/crescent_projectile.gd` also resolves
the area to the boss, and its existing impact guard prevents a second hit.
The boss removes the hurtbox from enemy collision queries on death.

## Checks

The actual Stage 2 diagnostic reproduces the old misses at center distances
85 and 105 in both directions. After the change, distances 65, 85 and 105
deal 20 damage; 145 misses. Checks also cover all three ground combo hits,
body/area duplicate prevention, facing away, Crescent damage, unchanged
terrain collision and death disabling the hurtbox.
Close-range normal swings are also checked with boss AI running in both
directions and Red's invulnerability disabled.

Run `tools/tests/test_boss_melee.gd` with `--presentation-test`; `--before-fix`
records the old reach expectation, while `--capture` records rendered poses.
Logs/captures are in `.godot/boss_melee_review/`. The boss AI is frozen for
measured reach checks; these do not guarantee a hit when the live boss dodges
or interrupts Red's attack.

Final headless boss checks: 23 passed, including the live AI swings. The
rendered measured-reach suite passes 21 checks with eight captured poses.
Ground combo (109), air combo (232), Crescent (12), directional (10),
combat/death (25) and retained skills (14) regressions also pass. Existing
test-exit resource cleanup warnings remain; no gameplay script errors appeared.
