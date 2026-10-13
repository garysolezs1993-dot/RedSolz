# Dash and Crescent cooldowns

## Current rules

- L / Shift dash: 1.5s cooldown, counted from dash startup.
- One airborne dash is available until Red actually lands. Landing restores
  the air allowance, but does not reset the timed cooldown.
- Ground/air attacks and their recovery can still be cancelled into dash
  when both its cooldown and airborne allowance permit it.
- Dash retains 0.7s invulnerability, its original speed and terrain collisions.
- R Crescent Slash: independent 3.0s cooldown, spent when casting starts.
- Taking damage or cancelling attacks does not clear either ability cooldown.
- Normal basic attacks stay free; their existing attack recovery is separate.

The HUD displays ready/countdown labels below HP in both stages. Once the
timed dash cooldown ends, an exhausted air dash instead displays
`LAND TO REFILL`. Death hides readiness. Holding either key does not repeat
the ability automatically; an unavailable press is ignored rather than queued.

## Tuning and implementation

Select Player in the inspector or edit `scripts/red.gd`:

| Export | Default |
| --- | --- |
| `dash_cooldown_duration` | 1.5s |
| `crescent_cooldown_duration` | 3.0s |

`dash_cooldown_remaining`, `crescent_cooldown_remaining` and `air_dash_used`
are runtime state. They are intentionally excluded from `_cancel_action()`.
`_begin_dash()` checks availability before cancelling the attack; a rejected
dash therefore does not interrupt combat or grant an iframe. `_start_skill()`
guards and spends Crescent's timer at cast startup, before projectile release.

Timers advance with gameplay physics time, including existing hitstop, and
freeze while gameplay is paused. A newly spawned Player starts with abilities
ready. These values are not added to checkpoint saves. `scripts/ui.gd` reuses
the existing HUD palette and inserts one compact ability status row.

Godot's headless editor import completed without script errors. These changes
have not been play-tested yet. Earlier combat test totals in
the integration notes describe the preceding versions.
