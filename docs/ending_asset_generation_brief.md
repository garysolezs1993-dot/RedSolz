# Asset generation brief — original Cursed Wolf ending

## Story and scope

The original ending is restored. Its story is:

**Defeat/collapse → Red approaches → brief sibling lucidity → Keep threatens Red → brother shields her → final words → lily/moonlight → Guardian → both face the Keep.**

At zero HP the Wolf is defeated and weakened, not narratively dead yet. His final death occurs after he protects Red. This distinction should be visible in the artwork: his eyes are conscious in the conversation, the sacrifice costs his remaining strength, and the farewell leads into the spiritual transformation.

Recognition and childhood memory already belong to the boss intro. New ending versions of those shots are not required. The ending should continue that story, rather than repeat the reveal.

## What can already be reused

- Existing Cursed Wolf collapse/death frames.
- Red's movement, idle and crouch poses.
- Existing Wolf pounce pose for the brief protection movement.
- Boss arena forest/ruins background.
- Existing dialogue labels, fades, camera transitions and screen shake.
- Existing breathing and ending music.
- Existing Prototype Complete screen and Return to Title button.

No additional frame-by-frame character animation is required for the first art pass. Individual still panels replace the emotional prototype shots. Missing panels retain the original in-engine staging.

## Deliverables at a glance

Recommended complete illustration set: **eight individual landscape PNG panels** matching the eight active slots. Six new illustrations are the main priorities; the Keep reaction and lily insert can use existing visuals initially.

| Priority | Filename | Story purpose |
| --- | --- | --- |
| High | ending_01_lucidity.png | Quiet sibling reunion with the conscious, wounded Wolf |
| Optional initially | ending_02_keep_reacts.png | The Keep notices them and sends the final threat |
| Highest | ending_03_sacrifice.png | Brother visibly intercepts an attack aimed at Red |
| Highest | ending_04_final_words.png | Grief and protective farewell after the impact |
| Reuse/optional initially | ending_05_white_lily.png | One beautiful enduring lily, intimate visual bridge |
| High | ending_06_guardian_birth.png | Peaceful spiritual continuation after physical death |
| Highest | ending_07_guardian_touch.png | Quiet emotional bond between Red and the Guardian |
| High | ending_08_together.png | They face the still-threatening Keep together |

A separate **Guardian Wolf transparent sprite** is also recommended for the in-engine moments. Optional petal/curse-strike VFX are described below. An illustrated completion-card background is optional and has no dedicated slot in the restored controller.

## References and consistency

Provide the generator with the existing approved images, not just a written description:

1. Approved Red recognition artwork and current Red full-body design.
2. Approved Cursed Wolf/scarf/lily artwork.
3. Approved arena/Silent Keep establishing art.
4. One approved Guardian design once it exists.

Use the same references for every panel. Approve the Guardian's design first and reuse that image as its identity reference for birth, touch and final-wide panels.

Preserve Red's established silver hair, red eyes, red hood/cape, outfit, sword and relative height. Preserve the Cursed Wolf's established fur, anatomy, scarf and flower attachment. Avoid inventing a different wolf or changing Red's outfit between shots.

The Wolf wears **exactly one white lily attached to the red scarf**, in the same location across shots. Keep it pale, beautiful and recognisable, with a subtle moon-blessed glow if needed. Detached petals may appear during the transformation, but do not turn those particles into several additional complete flowers.

Guardian design: the same brother's protective identity, expressed as a calmer noble wolf, silver/moonlit fur, gentle eyes, restrained spiritual glow, the same scarf and one lily. Avoid aggressive curse spikes, grotesque anatomy or visual language suggesting a second boss fight. Do not make the lily/scarf disappear when he becomes the Guardian.

## Shared export rules for all eight panels

- One clean finished image per file, not a contact sheet, collage, storyboard or sprite sheet.
- Consistent landscape 16:9 framing. Target 1920×1080 if available; otherwise preserve a consistent native landscape size and report the actual dimensions. Do not stretch an image to force the resolution.
- Opaque full-scene PNG illustrations with backgrounds; these are different from transparent sprite/VFX exports.
- No dialogue, captions, title lettering, panel numbers, labels, decorative borders, watermarks or UI baked into the art.
- Match the existing cinematic gothic illustration style and dark crimson/moonlit palette. Keep faces, eyes, scarf/lily and important silhouettes readable.
- Leave visual breathing room near edges. For full-body shots include complete heads, tails, hands and feet. Intentional close-ups are fine, but do not cut through the lily or critical action.
- Keep the bottom roughly 20% relatively quiet so Godot's dialogue can be read. Do not place a face, lily or the sacrifice impact behind the dialogue area.
- Separate any alternative versions into separate files. Use the exact filenames above for approved images.

### Copyable shared prompt prefix

> Create one clean landscape cinematic illustration for The Silent Keep: Moonlit Oath, using the attached approved character and environment references. Match the established character identities, clothing, wolf anatomy, scale relationships and gothic illustration style. Preserve the Wolf's red scarf and exactly one beautiful white lily attached in the reference position. Use a dark crimson and moonlit forest-ruins palette with readable emotional faces and silhouettes. Compose for a 16:9 game cutscene, with quiet space at the bottom for dialogue rendered separately by Godot. No text, dialogue, captions, numbers, borders, collage layout, watermark or UI. This is a single finished shot, not a storyboard or animation sheet.

Append the relevant shot description below. The dialogue listed here is narrative context only and must not be written into the PNG.

## 1. Lucidity — ending_01_lucidity.png

**Composition:** A medium two-shot in the existing moonlit boss ruins. Red is close to the fallen Wolf, at his eye level where possible. His body is wounded/exhausted, but he is breathing and consciously looking at her. His eyes soften enough to suggest recognition. Include the red scarf and single white lily clearly.

**Emotion:** Concern mixed with the familiar warmth of siblings. This is the brief moment when he can speak as her brother. Red should look shaken and hopeful, rather than triumphant or ready to attack.

**Dialogue context:** “...You never listen.” / “You said you'd come back.” / “You kept the light on.” / “Of course I did.”

**Append to the shared prompt:**

> Show Red and the exhausted Cursed Wolf sharing a quiet moment of recognition after battle. He lies on the ruined stone ground, still conscious, looking gently toward her. Red leans close with restrained grief and hope. Make their connection readable in one medium two-shot; preserve his red scarf and single white lily. The curse energy has weakened to a faint crimson glow. He is not dead yet. No attack or transformation is occurring in this shot.

## 2. The Keep reacts — ending_02_keep_reacts.png

**Composition:** The distant Silent Keep framed through broken arches/forest. Its crimson windows or moonlit corruption suddenly intensify. A restrained root-like magical threat begins extending from the Keep's direction toward the arena. Red and Wolf can be small foreground silhouettes, establishing the source and target.

**Emotion:** A final intrusion into their quiet reunion. This should connect the danger to the Keep rather than make the fallen Wolf seem to attack Red again.

**Dialogue context:** “Red... move!”

**Append:**

> Show the distant Silent Keep awakening with hostile crimson energy beyond the same ruined forest arena. Red and the wounded Wolf are small foreground figures, unaware until the threat begins. A root-like crimson curse reaches from the Keep toward their position. Make the source of the danger clear, but reserve the actual interception and impact for the next shot.

**Budget option:** Reuse the existing in-engine Keep/moon silhouette and crimson pulse. This illustration is not essential for the first art delivery.

## 3. Sacrifice — ending_03_sacrifice.png

**Composition:** A strong readable diagonal: curse approaching from the Keep's direction → brother intercepting → Red protected behind him. The weakened Wolf physically puts himself between the attack and Red. Make the impact land on him, with a short crimson-white energy burst. Red recoils or reaches toward him. Both faces/body positions should communicate protection, not a fight between them.

**Emotion:** A desperate final action, using the last of his strength. His scarf and single lily remain visible. Avoid an enormous explosion that hides the protective action.

**Append:**

> Capture the exact moment the weakened Cursed Wolf sacrifices himself to protect Red. A hostile crimson root-like curse strike from the distant Keep is aimed at Red; the Wolf throws himself into its path and takes the impact. Red is clearly behind him, shielded and unharmed. Use a strong readable diagonal composition showing attacker direction, interception and protected Red. Show a controlled crimson-white impact burst on the Wolf, his red scarf and exactly one intact white lily. The Wolf is protecting Red, not attacking her. No text or gore.

**Highest-priority action panel.** Generate and approve this early; the story depends on its clarity.

## 4. Final words — ending_04_final_words.png

**Composition:** Close/medium two-shot after the sacrifice. Red kneels/crouches beside him, her hand near his head, scarf or shoulder. He lies still and fading, with one eye gently open. Use their eyelines to connect them. Keep the lily beautiful and readable. Leave room below for several short dialogue lines.

**Emotion:** Red's shock turns into grief; he is relieved that she is safe. This happens before the Guardian exists. Avoid blood-heavy imagery or a happy reunion expression.

**Dialogue context:** “See...?” / “I came back.” / “Idiot...” / “Take care of it for me.”

**Append:**

> Show the quiet aftermath of the brother's sacrifice in the same ruins. Red crouches beside the fallen Wolf, fighting tears and reaching gently toward him. He looks toward her with fading awareness and relief that she survived. His red scarf and one white lily are intact. The hostile curse energy has fallen quiet. This is their final farewell before his body fades; no Guardian is visible yet. Intimate bittersweet composition with space below for dialogue added later.

## 5. White lily — ending_05_white_lily.png

**Composition:** An intimate close-up of the single lily on the scarf, with a little dark fur and soft moonlight. The bloom remains whole. A few separate pale petal fragments/light motes may drift nearby, but no second complete flower.

**Emotion:** A quiet pause and visual bridge between physical loss and spiritual continuation. Gentle, enduring and beautiful.

**Append:**

> Create an intimate close-up of exactly one beautiful white lily still attached to the brother's red scarf, resting against dark wolf fur. Preserve the flower attachment from the reference. Soft moonlight and a restrained pale glow suggest that this symbol endures as the curse fades. The flower is intact, not rotten or wilted. No additional complete lilies, no text, and no dramatic explosion.

**Budget option:** Reuse the existing approved boss-intro scarf/lily close-up if its identity and framing fit. No second recognition or childhood-memory scene is required.

## 6. Guardian birth — ending_06_guardian_birth.png

**Composition:** The cursed body dissolves into soft moonlight and detached petal fragments. The Guardian's calm silhouette emerges from the same area, keeping a clear visual relationship to the fallen brother. This is a transitional image of one spirit changing form, not two separate wolves fighting or standing side by side as new enemies.

**Emotion:** Grief becoming protective presence. Restrained silver-white/moon-blue light replaces aggressive crimson energy. Keep some sorrow in the atmosphere.

**Append:**

> Show a peaceful spiritual transition in the moonlit ruins: the fallen Cursed Wolf dissolves into soft pale particles and detached petals, and his calm Guardian Wolf form emerges from that same fading presence. Make this read as the brother's protective spirit continuing, not a resurrection into another boss form. Use the approved Guardian design, keeping the same scarf and one white lily. Restrained silver/moon-blue glow, noble posture and gentle eyes; no violent mutation or horror anatomy.

## 7. Guardian touch — ending_07_guardian_touch.png

**Composition:** Red extends a hand; the Guardian gently touches it with his muzzle or rests his head close to her fingers. Show Red's expression and the Guardian's eyes, scarf/lily. Keep the contact readable and avoid hands disappearing into fur or another incorrect limb.

**Emotion:** Quiet reassurance, grief and tenderness. Red understands that his protective presence remains, without suggesting that everything has been fixed.

**Append:**

> Show Red and the approved Guardian Wolf sharing a quiet, bittersweet moment in the ruins. Red extends one hand and the calm Guardian gently touches her fingers with his muzzle. Her silver hair, red hood and tearful restrained expression remain consistent with the reference. The Guardian has gentle eyes, the brother's red scarf and exactly one white lily. Their contact is clearly visible and anatomically clean. Soft moonlight, subtle spiritual glow, no aggressive pose, no fully cheerful resolution.

**Highest-priority emotional panel.** It establishes why the Guardian matters after the sacrifice.

## 8. Together — ending_08_together.png

**Composition:** A wide rear or three-quarter view of Red and Guardian standing together in the foreground, looking toward the distant Silent Keep. Keep them smaller than the environment but immediately recognisable. Use the same ruined arches/forest and crimson moon geography established in the intro. The Keep remains ominous; a softer silver light around them suggests a new bond.

**Emotion:** A continuing journey, grief carried forward, and companionship. Neither a victory celebration nor a complete resolution of the curse.

**Dialogue context:** “The curse remains.” / “And the Silent Keep still waits.”

**Append:**

> Create the final wide shot of Red and the approved Guardian Wolf standing together in the ruined moonlit forest, facing the distant Silent Keep beneath the crimson moon. Show their silhouettes from behind or three-quarter rear view, recognisable red cape and scarf, and the Guardian's single white lily where visible. The Keep remains threatening, while soft silver moonlight connects the pair. This is a bittersweet promise of the journey ahead, not a triumphant final victory. Leave quiet lower space for ending text added by Godot.

## Separate in-engine Guardian sprite

**Suggested filename:** `guardian_wolf_idle.png`.

This is separate from the illustrated panels. It improves the world-space spirit visible between panels and in the final arena shot.

- One full-body side-view wolf, facing **right** in the base export; Godot flips it for left-facing moments.
- Transparent RGBA PNG, no background, floor shadow card, text or painted rectangle.
- Match the approved Guardian design and the game's sprite style.
- Noble, relaxed posture; gentle eyes; same red scarf and one white lily.
- Keep the entire tail, ears, muzzle, feet and any subtle glow inside the canvas with transparent padding.
- Use the existing `walk_v3/walk_00.png` as the size/layout reference. Its canvas is **640×512**. Preserve that canvas and match its foot line instead of tightly cropping the Guardian.
- Match the visible body's height and footprint to that reference. Tune gameplay display in Godot after export, rather than resizing separate poses independently.

Only one static sprite is needed now; the prototype uses fades, gentle movement and flipping. A future Guardian idle animation can be added later if desired, but is not needed to finish this ending. Assign the static sprite to **Guardian Texture** on the restored ending root.

## Optional VFX assets

### Curse strike

One transparent crimson root/tendril or energy-lance image, full shape with padded edges. Match the Keep's corruption palette and show a clear travel/impact direction. No Red/Wolf/background baked in. The restored root supports **Curse Strike Texture**; a texture's framing and display offset should be checked during import. The existing code-drawn strike is enough initially, so a sprite sheet is unnecessary.

### Detached petal / moonlight fragment

One transparent white petal fragment or soft light mote, not a complete lily or a cluster of flowers. If replacing the current **Lily Texture** particle input, supply a small padded square canvas around 64×64 so the existing .055 particle scale does not turn it into an oversized blossom. It is spawned repeatedly for a brief drift/fade. Any exact display scale still needs visual tuning in Godot.

### Optional completion card background

One quiet landscape ruins/moon image with generous central empty space for the existing title, Prototype Complete text and Return to Title button. No baked words or buttons. This would need a small later completion-screen texture hookup; it is not one of the restored eight ending slots.

## Generation order

1. Approve a consistent Guardian character design using the existing Wolf as reference.
2. Generate sacrifice, final words and Guardian touch first.
3. Generate lucidity, Guardian birth and together using those approved identities.
4. Reuse the Keep reaction and lily insert initially, or generate their dedicated panels last.
5. Export the separate Guardian sprite if in-engine moments need the final design.
6. Add optional VFX only after reviewing the complete illustrated sequence.

## Review before delivery

Check each PNG individually at full size:

- Character identity and relative sizes match neighbouring shots.
- The sacrifice visibly shields Red and the curse strikes the brother.
- The lucidity shot is conscious; farewell is after sacrifice; Guardian appears only afterward.
- Exactly one complete lily on the Wolf/Guardian, consistent scarf/attachment.
- Clean hands/paws/eyes and no unexpected duplicate limbs/figures.
- No baked text, panel numbers, contact-sheet borders, neighbouring poses or cut-off critical details.
- Good lower dialogue space and consistent landscape composition.
- Sprite/VFX files have actual alpha transparency; black/checkerboard backgrounds are not painted into them.

Package the approved individual files in a ZIP. Put optional transparent sprites/VFX in a separate folder from the full-scene panels. Include a short README listing filenames, dimensions and which shots are approved. This asset brief prepares generation only; no new artwork has been generated yet.
