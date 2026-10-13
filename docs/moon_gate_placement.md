# Moon Gate placement and actor visibility

The distant preview is now fixed at (8980, 300), relative to the existing gate anchor. Its position no longer follows Red. It appears from the quiet eastern descent after Seal 3, fades across the selected viewpoint region, and is suppressed before the real gate frame enters the active camera view. The camera check also accounts for wider cinematic zoom.

Stage1Journey exposes distant_gate_offset, distant_gate_view_region, and distant_gate_opacity for tuning. The view region is relative to the preview's world position.

The playable gate's GateStateVisual now uses an absolute z index of -3. This places the artwork behind Red, other actors, and platform edges, while keeping the gate's prompt and transition CanvasLayers at their existing levels. StageTwoGate exposes gate_art_z_index. Gate scale, alignment, animation states, seal requirements, interaction range, and Stage 2 transition are unchanged.

Backup: .godot/local_backups/gate-placement-20261014-004323/
Godot editor import completed. No gameplay tests or visual playback were run for this change.