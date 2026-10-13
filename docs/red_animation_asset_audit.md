# Red animation asset audit

Inspected 10 October 2026. This audit leaves character assets and gameplay unchanged.

## What is wrong

The main problem is the supplied sheet extraction, followed by inconsistent drawing/placement and detail lost during downscaling. Increasing Red's display scale will not restore missing pixels.

I reviewed all 28 character groups frame by frame and compared their PNG bytes with `Red_Gothic_48x48_Fully_Exported_For_Codex.zip`. The imported character PNGs match the ZIP. Godot loads their complete textures; character scale stays at 1 with a shared position and zero sprite offset.

No character draft has nontransparent pixels touching its 48x48 canvas border. That does **not** mean it is uncut: the larger source can be clipped before it is resized and padded into the final canvas.

### Concrete examples

| Animation | Finding | First action |
| --- | --- | --- |
| Jump | Frames 03 and 04 have straight cuts through the top of the hood. The full reference sheet contains the missing hood. Exported source frame 03 also contains a piece of the next pose and its numbered label. | Extract the complete poses again from the original sheet. |
| Interactions | Look-around, pickup, chest, cheer, point, look-up and talk include partial characters, neighboring poses, or hard cuts through Red. These are not usable isolated character frames. | Re-extract by actual pose boundaries; verify each pose individually. |
| Idle/run/dash | Several frames contain disconnected vertical strips beside Red. Dash poses also have abruptly cut edges. | Remove sheet/neighbor contamination during extraction, then review the actual cape silhouette. |
| Air attack / downward attack | Horizontal guide remnants appear above or below Red in several frames. | Export character-only layers without sheet decorations. |
| Crouch / crouch walk / other transitions | Character placement and proportions vary between groups. Some reduction in height is an intentional pose change, so total bounding-box height alone cannot diagnose scale. | Compare head size, torso proportions and body anchor against the approved idle. |

The jump manifest uses the sheet rectangle `(0, 45, 1536, 320)`. The tallest hood rises above y=45, so that row cut removes it. Eight equal-width slices also fail where hair/capes cross those slice boundaries. The row includes labels beneath the poses. A fixed grid splitter is unsuitable for this irregular concept sheet.

### Preview evidence

The following previews enlarge the supplied PNGs with nearest-neighbor sampling. Labels, box outlines and the green reference line are diagnostic overlays outside the source artwork.

- [Movement frames](red_animation_review/movement.png)
- [Interaction frames](red_animation_review/interactions.png)

## Separate implementation limitations

Character frames are loaded whole, but the current integration crops some **effect** display regions to hide numbers and guide lines baked into the effect drafts. Those crops can also trim genuine sparks or arc edges. Clean effect exports would allow removing those regions.

Ordinary hurt intentionally uses source frames 00–03; knockback uses all eight. Walk and run share the run cycle. The three ground combo steps share one basic attack cycle. These are playback/art-coverage choices, distinct from missing body pixels.

The earlier automated checks established gameplay behavior. They did not establish visual quality. I should have caught the broken pose extractions before describing the pack as fully integrated.

## Best next step

Request a corrected export of **jump and interactions first**, using the original reference sheets. Much of the missing artwork still exists there. Approve one repaired cycle before exporting the rest. Regenerate only poses that cannot be isolated or whose anatomy/design still changes after extraction.

The pack README explicitly calls the 48x48 frames automatic draft downscales from concept art, rather than finished native pixel sprites. For crisp final art, author and clean the pixels at the actual game resolution.

## Copyable brief for ChatGPT: repair the export first

```text
Please audit and repair my Red Gothic animation export using the original
reference sheets. Do not redesign Red or regenerate the entire pack first.

Known defects:
- Jump frame_03 and frame_04 lose the top of the hood.
- Several interaction frames contain half of Red or pieces of adjacent poses.
- Some frames retain numbered circles, guide lines, or stray vertical strips.
- Character proportions and placement fluctuate between animation groups.

Do not split irregular concept sheets into equal-width cells. Inspect each
complete pose and extract it individually, including the entire hood, hair,
hands, boots and cape. Exclude all neighboring characters, labels, ground
guides and unrelated props. Preserve intended hair/cape strands.

Use the approved idle as the character reference: silver hair, red eyes,
crimson hood/cape, white flower, dark gothic outfit and leather boots.
Maintain the same head size, torso proportions, palette and drawing style.

Export each character frame on an identical transparent 48x48 canvas.
Use one consistent scale across the character pack. Do not resize each pose
independently to fill its own bounding box. For grounded poses, align the
actual planted soles to the same ground line (source y=46), with the body
center near x=24. Keep a transparent safety margin.

Airborne poses need a consistent body origin; do not force every tucked leg
or particle to the ground line. Godot handles the jump's world movement.
Do not use labels or stray pixels to calculate the character anchor.

Keep large slash arcs, dust, petals and projectiles in separate 64x64 or
96x96 transparent effect layers with documented matching anchors. Never
shrink Red to accommodate an oversized effect. Keep props separate too.

Deliver clean individual PNGs using the existing folder names, frame counts
and frame_00.png naming. Real alpha transparency; no baked checkerboard,
text, numbered badges, guide lines or fragments from neighboring poses.
Include a separate fixed-scale preview sheet and looping preview.

Start with the eight jump frames for approval. Inspect them at native size
and at 4x nearest-neighbor zoom. Confirm no missing anatomy, no contamination,
stable character proportions and smooth frame-to-frame motion. If a pose
cannot be recovered, identify it specifically before generating a replacement.
```

If replacement generation is required, add:

```text
Create one coherent native 48x48 pixel-art animation cycle from the approved
master sprite. Animate the same character rather than inventing a new drawing
for every frame. Keep the pixel grid, palette, head size and body proportions
consistent. Use crisp pixel clusters, not a detailed illustration automatically
downscaled to 48x48. Preserve the agreed canvas, anchors and separate VFX layers.
Show this one cycle for approval before producing other animations.
```
