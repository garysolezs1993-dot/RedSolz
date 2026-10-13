# Follow-up issues

## Common Wolf falls off platforms/maps while attacking

Reported by the player on 10 October 2026. Requested for follow-up after the
current Red skill visual issues.

- Inspect `scripts/common_wolf.gd` attack lunge, pursuit jumps and landing.
- Check platform-edge safety, map boundaries and recovery if a wolf leaves
  playable terrain.
- Preserve the existing aggressive attack burst and varied chase behavior.
- Reproduce on narrow platforms and near map edges before selecting a fix.

Status: movement safety implemented locally on 11 October 2026.

`scripts/common_wolf.gd` now ignores Red's physics body: bites continue using
the existing timed distance/damage checks. Red shares terrain collision layer 1,
so previously a wolf could collide with her during a lunge or leap.

Patrol, pursuit, separation, lunges and knockback all use `_move_safely()`.
Grounded movement probes ahead of the wolf's feet and stops at unsupported
edges; patrol turns back. Random leaps require a potential landing within
their jump height and a maximum 48px drop. Existing jump and lunge speeds,
attack timing, damage, detection and sound cues are retained.

The last supported position is stored relative to its platform, including
moving platforms. If a missed leap or knockback falls more than 48px below
that support, the wolf returns to it and cancels the lunge. Support is checked
again before recovery, so a collapsed platform cannot leave a floating wolf.
Red's platform collision and exploration routes are unchanged.

Godot editor import completed without script errors. Gameplay reproduction
tests have not been run for this change.
