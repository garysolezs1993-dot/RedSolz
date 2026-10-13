RED RIDING HOOD: THE SILENT KEEP
MASTER 3-HIT COMBO ASSET PACK

PURPOSE
This pack contains the cleaned character and VFX frames for Red's 3-hit ground combo.
Use these assets to replace the older problematic combo animation/VFX assets.

FOLDER STRUCTURE
Attack_1/Character  -> Attack 1 character frames
Attack_1/VFX        -> Attack 1 effect frames

Attack_2/Character  -> Attack 2 character frames
Attack_2/VFX        -> Attack 2 effect frames

Attack_3/Character  -> Attack 3 character frames
Attack_3/VFX        -> Attack 3 effect frames

IMPORTANT ASSET RULES
- Use the supplied PNG files directly.
- Keep RGBA transparency.
- Do NOT crop, trim, auto-center, or independently resize frames.
- Do NOT bake VFX into Red's character sprite.
- Character and VFX should use separate nodes/resources.
- Red's character transform is authoritative.
- VFX follows Red via a fixed VFXAnchor.
- Do not move Red to fit the VFX.
- Prefer one consistent VFX position/scale/rotation for each attack sequence.
- Prioritize visual alignment on strike frames 02-04.

RECOMMENDED GODOT HIERARCHY
Red
  CharacterSprite
  VFXAnchor
    AttackVFX
  AttackHitbox

COMBO FLOW
First press       -> Attack 1
Buffered press    -> Attack 2
Buffered press    -> Attack 3
No further input  -> return to idle after current attack
Attack 3          -> always recover to idle after finisher

FRAME TIMING
Character frame N should initially sync to VFX frame N.

Attack 1
  00 startup
  01 wind-up
  02 slash begins
  03 main hit
  04 follow-through
  05 late follow-through
  06 recovery
  07 return/chain-ready

Attack 2
  00 transition from Attack 1
  01 wind-up
  02 reverse slash begins
  03 main reverse hit
  04 follow-through
  05 late follow-through
  06 recovery
  07 chain-ready / return

Attack 3
  00 finisher startup
  01 heavy wind-up
  02 strike begins
  03 strongest impact
  04 heavy follow-through
  05 settling follow-through
  06 recovery
  07 final recovery

RECOMMENDED STARTING PLAYBACK
Attack 1: 10-12 FPS
Attack 2: 10-12 FPS
Attack 3: 9-11 FPS

RECOMMENDED DAMAGE WINDOWS
Attack 1: around frames 02-04
Attack 2: around frames 02-04
Attack 3: around frames 02-04, strongest feedback around 03

VFX GUIDANCE
Attack 1 should be the smallest/quickest effect.
Attack 2 should be broader and stronger than Attack 1.
Attack 3 should be the largest and most dramatic finisher.

CODEX IMPLEMENTATION RULE
Inspect the existing player scene, animation resources, combo/state-machine code,
hitboxes, and VFX setup first. Make the smallest safe changes necessary.
Do not rebuild unrelated gameplay systems.

VERIFY AFTER IMPLEMENTATION
- no black backgrounds
- no white halos
- no neighboring-frame fragments
- no automatic recropping
- no sudden character scaling
- Red remains grounded consistently
- VFX follows Red correctly
- VFX disappears after playback
- Attack 1 -> Attack 2 -> Attack 3 chains correctly
- Attack 3 returns to idle
- existing hitboxes/damage logic still works
- old broken combo assets are no longer referenced
