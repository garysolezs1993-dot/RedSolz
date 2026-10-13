# Cursed Wolf death animation

Source reference: `Cursed_Wolf_Boss_Death_Codex_Assets.zip`, supplied by the user.
Its PNGs contain an opaque black backdrop and sheet borders. The built-in
imagegen tool produced a transparent cutout sheet based on those eight poses.
These are edited cutouts, not pixel-identical copies of the opaque originals.

`death_source_clean.png` is the selected transparent atlas. `death_00.png`
through `death_07.png` are the game frames, extracted without rescaling by
`tools/prepare_cursed_wolf_death.py`. Each uses a 480x416 canvas, matching the
existing walk frames, with visible ground contact at row 389. No visible
silhouette touches the atlas cell edges. Original references remain in the ZIP.

Playback: 8 frames, 6 FPS, no loop, 0.75 seconds of final-pose hold, then a
0.65-second fade. An airborne boss lands before the collapse starts. Runtime
controls are exported in the boss script under **Death Animation**.

## Final imagegen prompt

Precisely repair image 1 as a game sprite atlas; image 2 is the original death-pose reference. Keep the same eight death poses and same wolf character. CRITICAL FIX: SHRINK EACH POSE WITHIN ITS OWN CELL TO 70% OF CURRENT SIZE, so every silhouette AND red ember fits entirely inside its own equal rectangular cell with a generous transparent moat around it. Output wide 2:1 canvas, exactly FOUR equal columns by TWO equal rows. Every cell is square; wolf body center must be centered within that cell. NOTHING may touch or cross a cell edge; minimum 40 transparent pixels margin around each wolf and all particles in each cell (at 2048x1024 size). ALL EIGHT figures must be smaller with generous padding, never spanning the neighboring cell. Same character scale for all frames, same source ground line in every cell at 80% of cell height; feet lie on that baseline. Sequence across top then bottom: wounded standing, weakening standing, knees buckling, front body lowering, collapse, lying with a little crimson energy, lying with energy fading, still dead lying with nearly all energy gone. Correct final cell (frame07) to have only faint residual embers, matching image2, no flame plume. Preserve dark fur including black outlines opaque, crimson cracks, red scarf and white flower. Real alpha transparent PNG background, no painted checkerboard, no text, no labels, no borders. Do not add any visual guides. The transparent gutters are absolutely required because each frame is extracted independently in code.
