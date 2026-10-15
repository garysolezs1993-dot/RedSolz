# Red's gameplay HUD

The shared `scripts/ui.gd` applies the HUD in Stage 1 and Stage 2.

## Artwork

Original PNGs from `silent_keep_hud_assets_for_codex.zip` are copied unchanged to
`assets/ui/red_hud/`. AtlasTexture regions ignore transparent canvas padding in
Godot. Each region preserves the artwork's aspect ratio.

- Silver/crimson health frame with a separate Godot health fill and dark well.
- Lily/crescent crest beside the frame, replacing the large character heading.
- Dash and Crescent icons at 40 px, using linear texture filtering.
- HP numbers, input labels, and cooldown seconds remain separate Godot labels.
- Ready abilities have bright icons. Unavailable abilities dim, with remaining
  cooldown time or `LAND FIRST` when the air dash needs landing to reset.

The actual HP bar remains at `UI/HUD/HP`, its text at `UI/HUD/HPLabel`, and all
new visuals are children of HUD so existing cinematic fades hide them together.
Boss health, input rules, damage values, and cooldown durations are unchanged.

## Feedback and tuning

The UI node exposes:

- `low_health_threshold`: 0.25; mild frame tint pulse below this fraction.
- `damage_trail_delay`: 0.35 seconds before lost HP begins catching up.
- `damage_trail_speed`: 65 HP per second for the delayed segment.

Healing updates both health segments immediately. Death stops the low-health
pulse. Existing checkpoint and respawn behavior continues to supply HP values.

## Backup

Previous UI script:
`.godot/local_backups/red-hud-20261015-193954/ui.gd`.

## Sizing correction

TextureRect expansion policy must be set before assigning the high-resolution
texture, and its final size must be set after adding the node. Otherwise the
initial native texture minimum can enlarge the rectangle permanently. Progress
bar styles are likewise applied before setting their final 10 px height.

Rendered previews from the actual scenes after this correction:

- [Stage 1](previews/red_hud_stage1.png)
- [Stage 2](previews/red_hud_stage2.png)

Both scenes report a 320 × 67 px frame, 44 × 66 px crest and 255 × 10 px
health fill. These captures check layout; they are not a full combat playtest.
