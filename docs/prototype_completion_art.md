# Illustrated prototype completion screen

PrototypeComplete displays the supplied The Silent Keep: Moonlit Oath artwork after the ending.

Source: C:/Users/Owner/Downloads/Moonlit Oath_ The Silent Keep.png
Project asset: assets/cutscenes/ending/completion/prototype_complete.png

The new PNG is copied unchanged. Its title and completion message are baked into the artwork. Godot renders a separate Return to Title button in the lower-right area, with hover, pressed, and keyboard/controller focus styles. The source-coordinate button rectangle is (1130, 780, 410, 70).

Presentation preserves aspect ratio, fits the entire image, and letterboxes when necessary. The hit area follows the same scaling and centering on resize. Inspector controls on PrototypeComplete are completion_artwork and return_button_rect (source-image pixels).

The existing 0.8-second reveal, completion music, confirmation sound, Escape handling, and GameSession title transition remain in use. The focused button accepts normal ui_accept keyboard/controller input. The ending sequence itself was not changed.

Rebranding backup: .godot/local_backups/moonlit-oath-rebrand-20261019-203201/.
See [rebranding notes](moonlit_oath_rebrand.md) for the current implementation and validation scope.
