RED RIDING HOOD: THE SILENT KEEP
AIR COMBO MASTER PACK

PURPOSE
This pack contains the cleaned character and VFX frames for Red's 3-hit air combo.
Use these assets to implement or replace the current aerial combo sequence.

FOLDER STRUCTURE
Air_Attack_1/Character  -> Air Attack 1 character frames
Air_Attack_1/VFX        -> Air Attack 1 effect frames
Air_Attack_2/Character  -> Air Attack 2 character frames
Air_Attack_2/VFX        -> Air Attack 2 effect frames
Air_Attack_3/Character  -> Air Attack 3 character frames
Air_Attack_3/VFX        -> Air Attack 3 effect frames

IMPORTANT ASSET RULES
- Use the supplied PNG files directly.
- Keep RGBA transparency.
- Do NOT crop, trim, auto-center, or independently resize frames.
- Character and VFX must stay separate.
- Red's character transform is authoritative.
- VFX should follow Red via a fixed VFXAnchor.
- Do not move Red to fit the VFX.
- All files are already normalized to 512x512 canvases.

RECOMMENDED GODOT HIERARCHY
Red
  CharacterSprite
  VFXAnchor
    AirAttackVFX
  AttackHitbox

AIR COMBO FLOW
Air Attack 1 -> Air Attack 2 -> Air Attack 3
Reset combo when Red lands or after Air Attack 3 finishes.

SUGGESTED ROLE OF EACH ATTACK
Air Attack 1: quick horizontal opener.
Air Attack 2: stronger follow-up / reverse or rising slash.
Air Attack 3: descending finisher with the largest VFX.

FRAME SYNCHRONIZATION
Character frame N should initially sync to VFX frame N.
Example:
  air_attack1_character_00.png with air_attack1_vfx_00.png
  ...
  air_attack3_character_07.png with air_attack3_vfx_07.png

SUGGESTED PLAYBACK
Air Attack 1: 10-12 FPS
Air Attack 2: 10-12 FPS
Air Attack 3: 9-11 FPS

SUGGESTED DAMAGE WINDOWS
Air Attack 1: frames 02-04
Air Attack 2: frames 02-04
Air Attack 3: frames 02-05, strongest around 03-04

IMPLEMENTATION NOTES
- Inspect the current player scene and air-combat logic first.
- Make the smallest safe change necessary.
- Keep the aerial combo separate from the ground combo state names.
- If Red lands during Air Attack 1 or 2, either safely end the current air attack or transition into landing recovery.
- Air Attack 3 should normally end the air string.

VERIFY AFTER IMPLEMENTATION
- no black backgrounds
- no white halos
- no neighbor-frame fragments
- no automatic recropping
- no sudden character scaling
- air combo chains correctly from 1 -> 2 -> 3
- combo resets on landing
- VFX follows Red correctly and disappears after playback
- old broken aerial combo assets are no longer referenced
