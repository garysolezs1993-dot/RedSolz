# Ending story artwork slots

The original eight-shot ending is restored. See [the detailed generation brief](../../../../docs/ending_asset_generation_brief.md) for shot descriptions, reusable prompts, export requirements and generation priorities.

The ending uses existing actors and a simple Keep silhouette for its in-engine shots. Six illustrations are assigned explicitly in EndingCutscene.tscn. Sacrifice and farewell use ../final_art_v1; the original Guardian reveal and three newer contact/wide illustrations use the filenames below directly from this directory.

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

Current Guardian images:

- `ending_06_guardian_birth.png`: the original reveal from `../guardian_revision_v2/guardian_birth.png`, shown while Red says “Brother…?”.
- `ending_guardian_approach.png`: source `ChatGPT Image Oct 15, 2026, 01_16_38 AM-1.png`, broad hand contact after the recognition line.
- `ending_07_guardian_touch.png`: source `ChatGPT Image Oct 15, 2026, 01_16_41 AM-2.png`.
- `ending_08_together.png`: source `ChatGPT Image Oct 15, 2026, 01_16_43 AM-3.png`.

All four PNGs are copied unchanged, including the spiritual aura, scarf and lily. The fallen gameplay Wolf glows with lily trails before transitioning into the original Guardian reveal. After Continue, the three new images appear in order. The Guardian's reunion is silent; only Red speaks. Character actions within these illustrated moments are conveyed by the supplied poses, crossfades and gentle zoom, rather than a separate animated Guardian sprite.

The controller also exposes optional **Lily Texture** and **Curse Strike Texture** resources for visual effects. Guardian gameplay mechanics are outside this scene. See `docs/ending_spirit_reunion.md` for the current dialogue and timing.
