# Opening panel artwork slots

The supplied eight final images are now stored unchanged in `final_art_v1/` and assigned directly in `OpeningCutscene.tscn`. To replace an active panel, change its Artwork resource in the Inspector. The optional filename fallback for unassigned panels remains:

1. `panel_01.png`: Silent Keep / forest / crimson moon.
2. `panel_02.png`: Brother preparing to leave, already wearing his red scarf and old white lily.
3. `panel_03.png`: Red tries to follow him.
4. `panel_04.png`: Sibling exchange, lily clearly visible on his scarf.
5. `panel_05.png`: Promise and farewell.
6. `panel_06.png`: Red waits beside a dwindling light.
7. `panel_07.png`: Red takes her sword/cloak and decides to leave.
8. `panel_08.png`: Red entering the forest path.

Use matching landscape canvases (16:9 recommended), without borders, captions or dialogue. Godot renders the text separately. Avoid placing important details at extreme edges because the opening uses aspect-preserving centered rendering to retain the complete images on other screen ratios.

Each `OpeningStoryPanel` resource also has an optional **Artwork** texture; an explicitly assigned texture takes priority over the matching filename. Missing files use the code-drawn placeholder.

The lily is an old childhood keepsake. This opening does not show Red giving him a new flower. Boss-intro artwork and dialogue are separate.
