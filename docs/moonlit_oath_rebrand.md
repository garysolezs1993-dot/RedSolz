# The Silent Keep: Moonlit Oath — rebranding

Applied 19 October 2026.

## Completed

- [x] Godot project/window name: **The Silent Keep: Moonlit Oath**.
- [x] Main menu and opening title card: **THE SILENT KEEP** / **M O O N L I T  O A T H**, rendered by Godot.
- [x] Retained HUD character labels in both gameplay scenes: **Red**.
- [x] Supplied completion artwork imported at the existing resource path.
- [x] Separate Godot **Return to Title** button with mouse, keyboard and controller focus styling.
- [x] Windows export ProductName and FileDescription set to the new full title.
- [x] Current implementation notes, asset-pack headings and student-guide game references updated.
- [x] Compatibility handling for existing journey and audio settings added.

## Completion artwork

Source: `C:/Users/Owner/Downloads/Moonlit Oath_ The Silent Keep.png`.

Runtime: `assets/cutscenes/ending/completion/prototype_complete.png`.

The supplied PNG was copied unchanged; both files have SHA-256:

`F6392ACE03CB9D33554A605BC36FCC4C395E8C6DCA218B54D9386A0F23AF5492`.

The title and completion message are baked into the supplied image. The Return to Title button is editable Godot UI positioned using source-image rectangle `(1130, 780, 410, 70)`. The whole image is fitted without stretching, and the button follows that fit.

## Existing saves

Changing the project name changes Godot's default user-data directory. Before loading progress/settings, `GameSession` copies missing `journey.cfg` and `audio_settings.cfg` files from the sibling legacy directory `Red Riding Hood- The Silent Keep` into the new directory. Existing destination files take precedence; originals remain untouched. Failed copies emit a warning. The legacy folder name intentionally remains in the script for compatibility.

Presentation captures use the existing `--presentation-test` flag, which bypasses migration and uses separate save/settings filenames. Actual player save migration has not been exercised in this pass.

## Preserved references

Original concept sheets, atlases, storyboard headers, historical previews and imported source-pack provenance retain their original text. These are historical references or dependency filenames rather than current title UI. Gameplay nodes, scripts, animation names and resource paths retain their identities. Story dialogue, panel order, combat and level layout were not edited as part of rebranding.

The previous artwork and changed pre-rebrand source/documents are backed up under `.godot/local_backups/moonlit-oath-rebrand-20261019-203201/`.

## Presentation review

Godot 4.7.2 imported the artwork successfully. Captures from the actual scenes at 960 × 540 were visually inspected for title fit, aspect ratio and button placement:

- [Main menu](previews/moonlit_oath_menu.png)
- [Opening title card](previews/moonlit_oath_opening_title.png)
- [Completion screen](previews/moonlit_oath_completion.png)

The final capture run logged no script errors. No gameplay regression suite or full playthrough was run for this branding change. `git diff --check` reported no whitespace errors.

## Distribution

Existing exported EXE/PCK/ZIP files and external store/repository descriptions have not been updated. Re-export the Windows preset and replace the shared distribution to deliver the new branding. The existing `SilentKeep.exe` output filename can remain; the in-game title and Windows product metadata come from the updated project/preset.
