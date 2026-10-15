# Stage 1 environment asset brief

This brief replaces the remaining programmer-drawn scenery in Stage 1 with small, reusable art kits. The current terrain collision, platform art, Moon Shrine, Moon Seals, Moon Lantern checkpoints, hazards and interaction logic remain authoritative.

## Shared art direction and export rules

- Side-on 2D platformer pixel art matching the existing gothic forest platform kit.
- Dark cool grey stone, weathered near-black wood, muted iron, moss, crimson foliage and restrained moonlit highlights.
- Transparent RGBA PNG, one usable object per file, with no text, labels, UI, characters or full-screen background.
- Keep a consistent pixel grain and crisp silhouette at gameplay size. Do not mix painted high-resolution concept art with the current pixel-art terrain.
- Keep 16-32 pixels of transparent safety padding around complete objects so branches, cloth and rubble are not clipped.
- Export every part on a stable canvas and do not tightly recrop individual animation or variant frames.
- Do not bake glow, particles, runes, lighting or shadows over Red into the PNG. Godot controls these effects.
- Do not include walkable floors in decorative back-wall art. Existing Godot collision remains the source of truth.
- Generate and approve the chapel back wall first, then use it as the style reference for the remaining props.

## Priority 1: Broken Chapel kit

The chapel currently uses simple rectangle pillars and thick line arches. The existing Moon Shrine at the seal is finished and should remain visible as the focal interactable.

| Filename | Suggested canvas | Purpose and composition |
|---|---:|---|
| `broken_chapel_back_wall.png` | 768 x 512 | Wide ruined wall with a broken roof silhouette and one large arched opening. Mostly visual background; open central negative space must frame the existing Moon Shrine. |
| `broken_chapel_arch.png` | 512 x 512 | Freestanding cracked gothic arch, front-facing, broken at one upper corner, with roots and a little crimson ivy. |
| `broken_chapel_pillar_01.png` | 256 x 512 | Tall intact-but-cracked chapel pillar with a readable capital and broken base stones. |
| `broken_chapel_pillar_02.png` | 256 x 512 | More damaged matching pillar for variation. |
| `broken_chapel_fallen_bell.png` | 256 x 256 | Tarnished iron chapel bell lying among a few stones and roots. |
| `broken_chapel_rubble_01.png` | 256 x 128 | Low non-walkable cluster of broken masonry, safe to place along platform edges. |
| `broken_chapel_rubble_02.png` | 256 x 128 | Second rubble silhouette with smaller stones and a snapped carved piece. |
| `broken_chapel_torn_banner.png` | 128 x 256 | Narrow faded crimson chapel banner with no readable symbol or text, designed to hang from a wall. |

### Copyable ChatGPT prompt: Broken Chapel

> Create a modular environment asset kit for a side-view 2D gothic pixel-art platformer. Match the attached gameplay screenshot and attached existing forest-platform sample for pixel density, edge sharpness, palette and lighting. The location is a ruined moon chapel in a dark crimson forest: cool grey cracked stone, near-black weathered wood, exposed roots, restrained moss, and small accents of deep crimson ivy. It must feel abandoned, sacred and readable during gameplay.
>
> First generate only `broken_chapel_back_wall.png` on a 768 x 512 transparent RGBA canvas. Show a wide ruined chapel wall, a broken roof silhouette and one large gothic arched opening. Leave clear open negative space in the middle for an existing crescent Moon Shrine that will be placed separately in Godot. Keep the wall behind the player and do not include a floor, platform, character, shrine, Moon Seal, UI, text, particles, baked glow or full landscape background. Keep every stone edge inside 24 pixels of transparent safety padding. True side-on game asset, crisp pixel art, one object only.
>
> After I approve the back wall, create separate transparent PNG files in exactly the same style: `broken_chapel_arch.png` 512 x 512, `broken_chapel_pillar_01.png` 256 x 512, `broken_chapel_pillar_02.png` 256 x 512, `broken_chapel_fallen_bell.png` 256 x 256, `broken_chapel_rubble_01.png` 256 x 128, `broken_chapel_rubble_02.png` 256 x 128, and `broken_chapel_torn_banner.png` 128 x 256. One isolated usable object per PNG. No contact sheet and no labels baked into the images. Export the original PNG files together in a ZIP.

## Priority 2: Root Cellar lift kit

The current lift is a generic 220-pixel platform plus two procedural cable lines. At the upper stop those lines collapse to almost zero length, and there is no top beam or pulley, so it does not read as a complete mechanism. Artwork should be modular because the deck moves while the top mechanism stays fixed.

| Filename | Required canvas | Purpose and alignment |
|---|---:|---|
| `cellar_lift_deck.png` | 512 x 128 | Moving wood-and-iron deck. Flat walkable top from source x=36 to x=476 at y=32. Visual pivot at (256,32). Two chain eyelets centered near source x=102 and x=410. At 0.5 Godot scale this matches the existing 220-pixel collision width and chain positions. |
| `cellar_lift_top_beam.png` | 512 x 128 | Static timber/iron mounting beam with two pulleys aligned to source x=102 and x=410. No moving deck included. |
| `cellar_lift_chain_tile.png` | 32 x 128 | Straight vertical chain/rope segment that tiles seamlessly top-to-bottom. Transparent left and right; end links must meet when repeated. |
| `cellar_lift_side_frame.png` | 256 x 512 | Optional ruined shaft frame or guide rail that can sit behind the moving deck without creating a fake walkable surface. |

When the lift art is integrated, the static top beam should be positioned above the upper landing so some chain remains visible at the top stop. That placement change belongs in Godot; it should not be faked inside the moving deck PNG.

### Copyable ChatGPT prompt: Root Cellar lift

> Create four separate transparent RGBA pixel-art assets for a side-view gothic forest platformer lift. Match the attached gameplay screenshot and existing mossy stone platform sample. Materials: weathered black-brown timber, muted iron, small moss patches, a few thin crimson roots, cool moonlit edge highlights. The mechanism must look old but structurally readable. Do not draw a complete combined elevator scene because the deck moves separately in Godot.
>
> 1. `cellar_lift_deck.png`, exactly 512 x 128. A flat wood-and-iron moving platform. The walkable top must be a straight horizontal line from x=36 to x=476 at y=32. Use pivot/contact point (256,32). Put two clear chain eyelets near x=102 and x=410. All decorative depth hangs below y=32. Do not curve or slope the walkable top.
> 2. `cellar_lift_top_beam.png`, exactly 512 x 128. A static ruined timber-and-iron beam with two pulleys aligned at x=102 and x=410. No lift deck.
> 3. `cellar_lift_chain_tile.png`, exactly 32 x 128. One straight vertical chain segment, seamless when repeated vertically. Transparent at the left and right; top and bottom links must connect.
> 4. `cellar_lift_side_frame.png`, exactly 256 x 512. One optional ruined shaft support/guide rail for the background, with no floor.
>
> True side-on pixel art, crisp silhouette, consistent pixel size across all four files. No character, UI, text, labels, full background, baked glow, particles or perspective floor. Export each asset as its own PNG and place the four original files in a ZIP.

## Priority 3: other visible placeholder replacements

These can follow after the chapel and lift are approved. The existing platform kit can be reused around them.

| Area | Suggested assets | What they replace |
|---|---|---|
| Hollow Oak | `hollow_oak_trunk.png` 512 x 768; `hollow_oak_branch_01.png` and `_02.png` 512 x 256 | Broad line-drawn trunk, hollow and branch shapes. Keep trunk and branches separate for composition. |
| Root Cellar | `cellar_root_beam_01.png` 512 x 128; `cellar_hanging_roots.png` 512 x 256; `cellar_exit_frame.png` 256 x 512 | Angular ceiling/root lines and the diagonal exit markers. The exit frame is scenery; it must not imply a usable ladder unless ladder logic is added later. |
| Creek / ruined bridge | `creek_water_strip.png` 1024 x 192; `ruined_bridge_post_01.png` 128 x 256; `broken_railing_01.png` 512 x 128 | Flat water rectangle, reflection lines and simple bridge posts. Water motion and reflections can remain Godot effects. |
| Burial grounds | Two or three `gravestone_*.png` files at 128 x 192 and `collapsed_crypt_arch.png` 384 x 256 | Rectangles, circles and cross lines used as gravestones/crypt. |
| Camp | `abandoned_crate.png` 192 x 192; `cold_campfire.png` 256 x 128; `broken_shelter.png` 512 x 256 | Box, log and triangular shelter drawings. |
| Heartwood | `heartwood_trunk.png` 768 x 768 plus two separate branch silhouettes | Thick procedural trunk and branch lines. Keep combat space and platform edges unobstructed. |
| Upper ruins | `upper_ruin_pillar_01.png`, `_02.png` 256 x 512; `upper_ruin_arch.png` 512 x 512 | Rectangle pillars and thick arch lines near Moon Seal 3. Reuse approved chapel stone style with slightly harsher damage. |

## Keep as engine effects or gameplay geometry

- Hazard warning lines and exclamation marks are readable attack telegraphs. New thorn or falling-branch art must align to the existing hitboxes and must not hide those warnings.
- Lantern glows, Moon Seal runes, Wisp trails, petal drift, water shimmer and curse particles should remain engine effects.
- Existing gothic terrain platforms already have a full modular art kit. Generate landmark props rather than another complete platform set.
- World labels and tutorial text should remain Godot text so wording and localization can change later.
