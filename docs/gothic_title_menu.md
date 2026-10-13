# Gothic Silent Keep main menu

## Implementation

The title scene now uses a full-screen Control with a covered-aspect TextureRect, a transparent left gradient, and real Godot buttons. The right side remains open for the keep, crimson moon and Red. There is no enclosing opaque menu panel.

Existing systems retained:

- `assets/menu_font.tres`: existing Georgia/serif font resource.
- `scripts/menu_ui.gd`: label and focus-ring helpers; unchanged for other menus.
- `scripts/audio_settings_panel.gd`: existing music/SFX sliders, persisted settings, Escape/Back close and focus restoration.
- `scripts/story_motes.gd`: existing lightweight petals/fog, using calm mode and reduced opacity.
- `scripts/story_music.gd` and AudioDirector: existing title music and quiet hover/confirm sounds.
- GameSession: existing new-game reset, checkpoint validity, Continue, scene fade and save behavior. No gameplay controller changes.

Continue is always visible. Without a valid checkpoint save it is dim, disabled and excluded from keyboard/gamepad navigation. With a valid save it participates normally.

## Timing and tuning

Select `Title` in `scenes/title.tscn` for Inspector controls:

| Control | Default |
| --- | --- |
| Background Image | `res://assets/menu/silent_keep_background.png` |
| Intro Duration | 1.75 seconds |
| Left Scrim Opacity | 0.80 |
| Background Zoom Amount | 0.02 |
| Background Zoom Duration | 16 seconds outward, 16 seconds returning |
| Version Caption | Prototype v0.1 |

`MenuAnimationPlayer` and `BackgroundAnimationPlayer` are built by `scripts/title_screen.gd`, adapting the project's existing script-built menu approach. The intro starts black, fades in the backdrop, then title, subtitle/divider, four staggered buttons and footer. Start receives focus once the intro finishes. Input is ignored during the intro and during departure.

Button focus uses a 0.12-second border/glow and 1.00-to-1.02 scale response. Pressing produces a 0.98-to-1.00 response. Godot draws the restrained corner and diamond ornaments; these are not image assets.

Start/Continue/Quit lock input, show the 0.15-second press response, fade the UI and lower title music while fading to black over a further 0.65 seconds. Start then calls GameSession's new-game flow, whose scene transition takes another 0.32 seconds. Start now loads the placeholder `OpeningCutscene.tscn`, followed by Stage 1 and its arrival shot; see `opening_cutscene.md`. Continue loads the existing saved checkpoint directly. Quit exits normally.

## Artwork provenance

The supplied reference contains baked-in menu text, button rectangles and a decorative enclosing frame. The built-in imagegen tool produced a separate background copy that removes those elements and fills the left side with forest/mist. The original download is untouched. The output was inspected and copied into this project as:

`assets/menu/silent_keep_background.png`

The title background is an illustration, so it uses linear sampling when fitted to different screen sizes. Gameplay pixel-art filtering is unchanged.

Exact edit prompt:

> Use case: precise-object-edit. Asset type: full-screen 16:9 Godot title menu background. Edit target: attached Silent Keep image. Remove ALL baked-in UI from the LEFT half: title text, subtitle, instruction text, four button rectangles/text, glowing button border, ornamental enclosing frame and dividers. Fill that area naturally with the existing dark forest, distant landscape and mist, keeping it subdued for real UI to be overlaid later. Preserve the right-side crimson moon, gothic castle, bridges, fog, foreground steps, Red character, and surrounding trees as faithfully as possible. Preserve the same composition, framing, dark crimson/black/moonlit palette and illustration style. No new characters, no new UI, no text, no borders, no logo, no watermark. Output opaque clean landscape background.

## Backup

The previous working title script and title scene were copied before rebuilding:

`.godot/local_backups/gothic-title-20261013-102702/`

Restore those two files together to return to the previous menu.

## Review captures

- [960×540, Start focused and Continue disabled](previews/title_menu_960_start_focused.png)
- [960×540, Continue enabled](previews/title_menu_960_continue_enabled.png)
- [Settings](previews/title_menu_960_settings.png)
- [1280×720](previews/title_menu_1280x720.png)
- [1920×1080](previews/title_menu_1920x1080.png)

The project uses its existing 960×540 canvas-items scaling. The menu's logical layout stays consistent at the three requested 16:9 window sizes; background aspect is preserved.

Verification scripts use isolated `user://gothic_title_*_verification.cfg` paths. They do not overwrite the player's journey save or write volume settings. `tools/tests/test_gothic_title_menu.gd` checks intro, focus, disabled/enabled Continue, keyboard and gamepad navigation, Settings, resolution bounds, background animation and the real Start/Continue scene transitions. `tools/tests/test_gothic_title_quit.gd` separately checks normal Quit exit. Results are recorded in `docs/title_menu_verification.log` and `docs/title_menu_quit_verification.log`.
