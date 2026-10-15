# Story text revision — 2026-10-14

Approved text pass connecting the opening, Moon Seal objective, Keep attack, and Guardian ending.

Updated on 2026-10-15 with the user's silent Guardian reunion and new glowing artwork. See [the current ending flow](ending_spirit_reunion.md).

Backup of all five changed scene/script files before editing:
`.godot/local_backups/story-text-revision-20261014-232926/`

Backup before the follow-up Guardian dialogue change:
`.godot/local_backups/guardian-reunion-dialogue-20261014-233735/`

## Implemented text

Opening, first panel:

> A crimson light had begun stirring within the Silent Keep.
> Red's brother went into the forest to find its source.

First shrine approach:

> Awaken the three Moon Seals, and the Moon Gate shall open.

The existing shrine explanation now appears beside the first shrine, within 180px horizontally and 65px vertically of Red's standing position. It waits for Red to stand on a platform with no current action, appears once per stage visit while no seals have been completed, and holds for four seconds. Walking on the lower route beneath the shrine does not trigger it.

After Seal 3:

> The Moon Gate awakens.

After that message has finished:

> Far beyond the forest, a crimson light answered.

The gate unlock is immediate, as before. The new narration follows the existing delayed announcement, with 3.2 seconds between messages. It holds for four seconds and is suppressed during death or scene transitions.

Brother's farewell:

> Keep the lily safe.

Guardian reveal:

> Red: Brother…?

Guardian emotional/touch panel:

> Red: …You don’t remember me, do you?

The Guardian stays silent. After a quiet pause, the new wide panel shows him beside Red, facing the Keep:

> Red: …Still protecting me.
> Red: Come on.
> Red: This time… we go together.

These lines use the existing dialogue presentation and Continue/Skip controls. Red's invitation answers the opening, where her brother refuses to let her accompany him. Her question expresses uncertainty about the spirit's memories; he does not resume human speech. This replaces the earlier version where Brother answered her.

Final wide shot, two successive captions:

> The curse remains.

> And the Silent Keep still waits.

Their light/promise exchange and “See...? / I came back.” remain the emotional callbacks. Artwork and combat are unaffected by this text pass.

## Verification

- Full rendered opening playback reached normal Stage 1 gameplay with HUD visible, camera zoom 1.35, and player control restored.
- Full rendered ending playback completed the existing phase order, reached the completion screen, and returned to title with the tree unpaused and ending state cleared.
- Runtime probe passed all 11 checks: correct shrine proximity, lower-route exclusion, one-time display, text width, seal completion and the ordered gate/Keep messages.
- No script or shader errors in the final playback/probe logs.
- Guardian dialogue follow-up: full rendered ending completed and returned to title. Both new lines were captured with the correct speaker labels and Continue enabled; neither line clips at 960x540. Log: `.godot/guardian_reunion_capture.log`.

Previews:

- [Opening narration](previews/opening_panel_1_line_1.png)
- [Red calls to the silent Guardian](previews/ending_spirit_recognition.png)
- [The hand-touch reunion](previews/ending_spirit_hand_touch.png)
- [Facing the Keep together](previews/ending_spirit_together.png)
