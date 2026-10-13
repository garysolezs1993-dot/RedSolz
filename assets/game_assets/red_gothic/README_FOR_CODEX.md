# Red Gothic 48x48 — Codex Export Pack

This pack is the cut/transparent export prepared from the approved Red Riding Hood concept sheets.

## Important asset truth
- `source_rgba/` = individually cut PNG frames with the checkerboard/reference background removed and real alpha transparency.
- `game_48x48_draft/` = automatically scaled 48x48 transparent implementation drafts for character animations.
- Effect folders use 64x64 or 96x96 draft canvases so VFX are not forced into Red's 48x48 character canvas.
- The original images were AI concept sheets, not native 48x48 pixel sprites. The 48x48 versions are therefore *draft downscales*, not hand-pixel-clean production art. Use them for prototype implementation and replace/refine later if publishing quality is required.

## Locked character design
Keep Red consistent:
- silver hair
- red eyes
- deep crimson embroidered hood/cape
- small white flower on hood
- dark gothic layered outfit
- leather boots
- petite silhouette
- target character canvas: 48x48
- Cursed Wolf remains larger at 64x64

## Approved idle behavior
Idle must visibly combine:
- gentle breathing
- subtle body rise/settle
- both eyes fully closed for blink (never a wink)
- hair sway
- cape flutter/sway
- smooth return to frame 00

## Folder structure
- `animations/` movement/combat/damage animations
- `skills/crescent_slash/` cast + projectile + impact
- `effects/` separate VFX where the concept sheet provided them
- `interact/` interaction variants cut into separate folders
- `victory/` Stage 1 bittersweet, normal, cheerful
- `reference_sheets/` original full concept sheets
- `QA_previews/` contact sheets for quick visual checking

## Godot implementation guidance
Use numbered files in ascending order (`frame_00.png`, `frame_01.png`, ...).
Keep Red's collision/hurtbox independent from visual cape/hair.
Keep VFX on separate Sprite2D/AnimatedSprite2D nodes.
Do not enlarge Red to match the Cursed Wolf.
Recommended state transitions:
idle <-> run
jump -> fall -> landing_recover -> idle/run
dash -> idle/run
basic_attack -> idle/run
air_attack -> fall
rising_slash -> idle/run
downward_slash -> landing/fall depending on contact
hurt -> recover
death -> game over
crescent_slash/cast spawns projectile separately

Stage 1 victory is deliberately sad/bittersweet because the Cursed Wolf is Red's brother.
Later victory animations can use the normal or cheerful folders.

## Prototype recommendation
For the presentation build, use the provided draft frames if they look acceptable in-game. Do not spend time re-authoring every pixel before the prototype is playable.
For a real publishing pass, redraw/clean the final 48x48 sprites by hand or with a dedicated pixel-art workflow, using `source_rgba/` and the reference sheets as guides.
