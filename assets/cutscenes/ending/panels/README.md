# Ending story artwork slots

The original eight-shot ending is restored. See [the detailed generation brief](../../../../docs/ending_asset_generation_brief.md) for shot descriptions, reusable prompts, export requirements and generation priorities.

The ending currently stages existing actors, a simple Keep silhouette and a silver wolf visual placeholder. Five final story images are now assigned explicitly in EndingCutscene.tscn from ../final_art_v1; matching filenames below remain optional fallback names. The pack includes an additional alternate farewell image.

Optional standalone panels, in sequence:

1. `ending_01_lucidity.png`: wounded wolf recognizes Red; scarf/lily visible.
2. `ending_02_keep_reacts.png`: distant Keep/moon reaction; curse remains.
3. `ending_03_sacrifice.png`: brother shields Red from the Keep's strike.
4. `ending_04_final_words.png`: safe Red with the weakened wolf.
5. `ending_05_white_lily.png`: white lily glowing, soft moonlight.
6. `ending_06_guardian_birth.png`: wolf dissolves, silver Guardian appears.
7. `ending_07_guardian_touch.png`: calm Guardian touches Red's hand.
8. `ending_08_together.png`: wide view of Red and Guardian facing the Keep.

Use clean individual landscape PNGs, no captions/dialogue/borders. Godot renders all text separately and preserves aspect ratio. Explicit Inspector texture assignments override these filenames. Missing artwork keeps the in-engine prototype shot.

`scenes/EndingCutscene.tscn` also exposes optional **Guardian Texture**, **Lily Texture** and **Curse Strike Texture**, with gameplay-display scale controls. These create visual sprites only, without collision or combat behaviour. The default Guardian is a shader-recoloured wolf silhouette; final Guardian gameplay mechanics are outside this scene.
