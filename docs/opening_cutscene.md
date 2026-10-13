# Opening cutscene: eight-panel sibling story (final art)

## Play and review

Run F5, choose **Start Game**, and advance the opening with **Enter / Space / E / controller A** or the Continue button. **Escape / controller Start / controller B** or the Skip button skips the opening.

The opening now uses all eight final images from `silent_keep_opening_cutscene_art_pack.zip`, with the revised narration and dialogue. **Auto Advance is enabled on the scene** for a roughly 43-second opening through the Stage 1 arrival; turn it off to use reader-paced dialogue. The same image remains during each sibling exchange, with gentle motion and 0.4-second artwork crossfades. See [the final artwork integration and complete preview](opening_final_art.md).

Start Game resets a new journey through the existing GameSession flow and loads `scenes/OpeningCutscene.tscn`. Continue and Retry still load gameplay directly. After Panel 8, the existing title card and Stage 1 arrival shot remain: Red enters, says "Hold on... I'm coming.", the normal 1.35 gameplay camera returns, the HUD fades in and player control resumes. Skipping bypasses that arrival shot and restores gameplay directly.

## Storyboard

| Panel | Placeholder composition | Lines |
| --- | --- | --- |
| 01 | Silent Keep, forest and crimson moon | Something had begun stirring beyond the old forest. / Red's brother went to find its source. |
| 02 | Brother preparing to leave, already wearing scarf and lily | There was one person Red trusted more than anyone else — her brother. |
| 03 | Red tries to follow | Red: Then I’m coming with you. / Brother: No. |
| 04 | Sibling exchange, close detail of the existing lily | Red: You always say that. / Brother: And you never listen. / Brother: I’ve still got this, don’t I? / Red: …You kept it? / Brother: Of course. |
| 05 | Brother leaving, Red watching | Brother: Keep the light on for me. / Red: Come back before it burns out. / Brother: Deal. |
| 06 | Red waits beside a dwindling candle | But night deepened... / and he did not return. |
| 07 | Red prepares her sword and cloak | Red: ...You promised. / Red: So I'm coming to find you. |
| 08 | Red entering the forest | Silent establishing shot, then fade to title. |

The lily is an **old childhood keepsake**, attached to the brother's scarf from Panel 2. Red does not give him a new lily during this opening. The scarf/lily close detail is explicitly a look at what he has already kept. No boss reveal is added here.

## Reusable data and future art

Select the root of `scenes/OpeningCutscene.tscn`, expand **Panels**, then the desired resource:

- **Artwork**: optional future Texture2D for that panel.
- **Shot Label**: temporary storyboard label, hidden when final art is present.
- **Placeholder**: selects a simple silhouette composition.
- **Lines**: ordered `OpeningStoryLine` resources, each with **Speaker**, **Text** and optional **Hold Seconds**.
- **Hold Seconds** on the panel: default line duration when automatic playback is enabled. A line's nonzero duration overrides it.
- **Caption** is retained only for compatibility with older single-caption panel resources; the new eight panels use Lines.

Alternatively put `panel_01.png` through `panel_08.png` in `assets/cutscenes/opening/`. The controller finds the matching filename automatically; an explicit Artwork assignment takes precedence. Missing images use the placeholders without resource errors. See that folder's README for the visual brief.

Use separate landscape images, ideally 16:9, without text or borders. Textures preserve aspect ratio using centered rendering and stay within the viewport during their gentle pan/zoom. Dialogue and speaker names are Godot UI, not baked into any image. The final supplied PNGs are now assigned directly; no image pixels were edited. Their hashes match the ZIP.

The root exposes **Panel Art Directory**, **Auto Advance**, **Panel Fade In** (0.4 sec), **Panel Fade Out** (0.65 sec to title) and **Title Hold** (1.8 sec). The script supports reader-paced playback; the final-art scene enables Auto Advance by default. If enabled, the resource reading times drive the same Continue pathway; Continue can still advance early. The title fades automatically. Shared fade/hold helpers remain in `scripts/story_transitions.gd`; the new reusable line data is in `scripts/opening_story_line.gd`.

## Input and handoff

Confirm/interact advance one dialogue line, then move to the next panel after its final line. Held keyboard repeats are ignored. Confirm during a fade is ignored rather than queued. The Continue button is disabled during transitions and hidden during the title card. Skip remains available throughout.

The opening installs its own default Skip bindings so Enter/Space cannot accidentally skip the whole story. Other cutscenes' binding helpers are unchanged. The arrival Skip label now matches Escape/Start/B. Custom Project Settings input actions remain supported.

Skip wakes any pending manual dialogue wait, cancels its active tween, fades to black and calls the existing GameSession handoff. Repeated Skip calls are ignored. The existing arrival controller still restores its camera, UI, actor processing and world pause on completion or Skip.

Audio uses the existing Witch's Lullaby opening context; Stage 1 restores the forest track. No source audio, combat behaviour, stage geometry, boss intro or save format changed. The final art pass also adds a quiet procedural wind/rustle loop, per-shot music ducking and three one-off faint petal fragments; see the final-art guide.

## Earlier placeholder capture and backup (before final art)

Backup before this revision: `.godot/local_backups/opening-eight-panels-20261013-172946/`.

Editor import completed without script errors (`docs/opening_eight_panels_import.log`). A full rendered run (`docs/opening_eight_panels_capture.log`) traversed all eight panels and all 15 lines using alternating Enter input and the Continue button, then the title, arrival dialogue, camera return, HUD reveal and gameplay. With the capture reader advancing every two seconds, it reached gameplay at about 44.5 seconds; actual reading time is controlled by the player.

The capture uses an isolated journey path and mutes audio only in memory, preserving the player's saved journey. No automated tests were added or run for this implementation. Godot's pre-existing camera interpolation warning remains.

- [Panel 1: Silent Keep](previews/opening_panel_1.png)
- [Panel 2: Brother](previews/opening_panel_2.png)
- [Panel 3: Red follows](previews/opening_panel_3.png)
- [Panel 4: Old lily](previews/opening_panel_4_line_4.png)
- [Panel 5: Promise](previews/opening_panel_5.png)
- [Panel 6: Waiting](previews/opening_panel_6.png)
- [Panel 7: Decision](previews/opening_panel_7.png)
- [Panel 8: Forest entry](previews/opening_panel_8.png)
- [Title](previews/opening_title.png)
- [Arrival dialogue](previews/opening_arrival_dialogue.png)
- [Gameplay](previews/opening_gameplay.png)