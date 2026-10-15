# Stage 1 environment pack review

Reviewed 2026-10-14. This is an asset and integration-brief inspection. No gameplay scenes, collision, controllers or source artwork were changed. Both ZIPs were extracted into an isolated `.godot/asset_reviews/` directory for inspection.

Subsequent update: the user chose v2 and its visual integration is now implemented. See [integration notes and gameplay previews](stage1_environment_v2_integration.md). The findings below record the earlier asset review.

## Brief

The attached text proposes integrating v2 as visual dressing while preserving existing collision, enemies, checkpoints, Moon Seals, Moon Gate, tutorials, routes and lift movement. That scope is appropriate. The fixed beam/frame and moving deck must stay separate. Art placement should be reviewed in gameplay screenshots before any geometry change.

The latest user request was to check the text and assets. The proposed integration and final playthrough in the attachment have not been performed by this review.

## Independent file checks

- Both packs contain the same 37 PNG filenames, plus a README and validation JSON.
- All 37 v2 PNGs have a genuine alpha channel, transparent pixels and opaque pixels. None has nonzero alpha touching its outside canvas edge.
- Decoded dimensions and full nonzero-alpha bounds match all entries in v2's supplied validation JSON.
- Visual inspection on checkerboard backgrounds did not show full rectangular black backgrounds or baked labels/text. Straight dark base strips on two camp assets are a separate concern below.
- The pack's dimensions and filenames differ from the earlier local asset brief in several places. For example, the supplied lift deck is 512 x 256, whereas the local brief specified 512 x 128. These larger canvases can be supported by Godot scale and offsets, but cannot reuse the suggested pivots blindly.
- Transparent margins prove only that the current pixels fit inside the canvas. They do not prove that the original artwork was exported at correct proportions, that shapes were not cropped before padding, or that a tile is seamless.

Machine-readable checks: [independent validation](previews/environment_asset_review/independent_validation.json).

## Visual findings and recommended handling

| Asset / group | Finding | Recommended handling |
|---|---|---|
| Chapel back wall, arch, fallen bell, rubble | Cohesive gothic silhouettes; no obvious cut edges in inspected views. | Suitable for a Chapel placement preview behind Red and the existing Moon Shrine, using uniform scale. |
| `chapel_pillar_left.png`, `chapel_pillar_right.png` | v2 appears strongly elongated relative to v1. Left visible bounds changed from 197 x 307 to 215 x 915; right changed from 223 x 294 to 225 x 920. Carved details and stone segments look stretched. | Prefer the v1 versions at preserved proportions or request fresh proportional exports. Do not stretch the PNG in Godot to fit a pillar height. |
| `chapel_torn_banner.png` | v2 visible height increased from 312 to 921 while width stayed around 220. The hanging hardware and cloth appear vertically distorted. | Prefer v1 or request a new naturally long banner with preserved ornament proportions. A tall canvas should be filled with padding, not by stretching artwork. |
| `cellar_lift_deck.png` | A useful separate deck, but its visible standing surface is around the middle of a 512 x 256 canvas, with perspective depth and end fittings. It does not match the earlier y=32 contact anchor specification. | Set a new Godot visual offset/contact line and uniform scale around the existing 220-pixel collision. Align chain ends to visible fittings. Keep current movement and collision. |
| `cellar_lift_top_beam.png`, `cellar_lift_side_frame.png` | Separate parts are suitable for fixed scenery, but anchors must be measured from the art. | Keep them outside the moving platform node. Mount the top assembly above the upper stop so chains do not collapse to zero length. |
| `cellar_lift_chain_tile.png` | v2 is a longer chain, but it is not a seamless full-canvas tile: visible rows run from y=8 to y=233 inclusive on a 256-pixel-high canvas. Whole-image repetition introduces 30 transparent rows per repeat. | Use overlapping chain segments or a tested Godot texture region/repeat interval. A genuine seamless vertical re-export is preferable if a repeatable tile is required. Preserve source PNGs. |
| Hollow Oak, branch and root | The new main Oak gives a complete tree silhouette with a visible hollow; branch/root parts are useful supporting pieces. | Suitable as a landmark. Preserve the actual cellar entrance and avoid placing opaque trunk pixels over navigation cues or Red. |
| Cellar large/medium roots | Useful hanging and winding forms. | Place against ceilings/corners, with no new collision. Keep enough air around the playable route. |
| `cellar_root_stalactite.png` | The object reads partly like a very elongated carved stone/wood structure with dangling vines, rather than a purely organic hanging root. | Optional use behind routes; consider a dedicated organic root replacement if this silhouette feels architectural in the cellar. |
| Bridge main / segment | Clear ruined crossing, with a visibly sagging deck and perspective. | Use as dressing alongside/below the existing flat walkable collision. Do not imply the curved painted surface changes the standing line. |
| Burial props | Useful grave silhouettes and variation; some have coarse or soft details compared with the Chapel art. | Use in small irregular clusters at modest gameplay size. Avoid enlarging the softer props. |
| `camp_crates.png`, `camp_stool.png` | Straight, dark horizontal base strips remain underneath the artwork. They look like export/base remnants and may appear as unwanted bars on terrain. | Request clean re-exports without the strips, or use deliberate Godot texture regions after reviewing the cut. The README's divider-removal claim does not eliminate this visual issue. |
| Camp tent, lantern and fire | Suitable camp props. The tent already contains bright lanterns, and the fire is a single still image. | Use restrained lighting. A lit static flame may be acceptable for a prototype, but a flame loop or separate flame layer would look better in a later pass. |
| Ruin arch / wall | Useful as upper-route background silhouettes. | Suitable for visual dressing. |
| Ruin column, platform and ledge; several camp/burial props | Some look resampled or softer than other kit pieces. Nearest filtering does not restore detail already blurred in the source. | Keep these small, prefer current finished terrain for playable surfaces, and judge them at actual camera scale. |

## Recommendation

Use v2 as the main candidate set while retaining v1 for comparison and the less distorted Chapel pillar/banner options. Most landmarks can proceed to placement previews; the entire pack does not need regeneration. Resolve the three Chapel proportions and two camp base strips first if clean source exports are available. Chain continuity and deck alignment can also be addressed in Godot without changing the PNGs or lift physics.

## Preview sheets

These sheets show existing source pixels on checkerboards. Transparent padding is omitted only in the diagnostic thumbnail views to make each object easier to inspect; source files are untouched.

- [v1/v2 comparison](previews/environment_asset_review/v1_v2_comparison.png)
- [Chapel](previews/environment_asset_review/v2_chapel.png)
- [Lift](previews/environment_asset_review/v2_lift.png)
- [Oak, roots and bridge](previews/environment_asset_review/v2_landmarks.png)
- [Burial and camp](previews/environment_asset_review/v2_burial_camp.png)
- [Upper ruins](previews/environment_asset_review/v2_ruins.png)

## Suggested correction request

> Please re-export only the Chapel left pillar, Chapel right pillar, Chapel torn banner, camp crates and camp stool. Preserve the original object's width-to-height proportions. Place it on the required transparent canvas using padding; do not stretch it independently in X and Y to fill the canvas. Remove the straight dark divider/base strips underneath the crates and stool while preserving the actual legs and object edges. Export clean individual RGBA PNGs with the same filenames, no text, no labels and no opaque background. For the optional chain replacement, export a vertical tile whose chain links connect at the top and bottom with no transparent gap in the repeat direction. Keep Chapel carving, stone and crimson foliage style consistent with the back wall and arch.
