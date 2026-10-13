# Illustrated prototype completion screen

PrototypeComplete now displays the supplied completion artwork after the ending.

Source: C:/Users/Owner/Downloads/Red Riding Hood_ The Silent Keep (3).png
Project asset: assets/cutscenes/ending/completion/prototype_complete.png

The original PNG is copied unchanged. Its title, message, and button label are already part of the artwork. Godot adds a transparent Button over the illustrated Return to Title area, with subtle hover, pressed, and keyboard/controller focus styles.

Presentation preserves aspect ratio, fits the entire image, and letterboxes when necessary. The hit area follows the same scaling and centering on resize. Inspector controls on PrototypeComplete are completion_artwork and return_button_rect (source-image pixels).

The existing 0.8-second reveal, completion music, confirmation sound, Escape handling, and GameSession title transition remain in use. The focused button accepts normal ui_accept keyboard/controller input. The ending sequence itself was not changed.

Backup: .godot/local_backups/completion-art-20261014-003338/
Godot asset import completed successfully. No gameplay or interaction tests were run for this change.