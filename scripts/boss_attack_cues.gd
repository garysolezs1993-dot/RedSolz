extends Node2D

@export var cues_enabled := true
@export_range(0.1, 0.8, .05) var cue_opacity := .6
var boss: CharacterBody2D
var cue := ""
var progress := 0.0
var facing := 1.0
var clock := 0.0

func _ready() -> void:
	boss = get_parent() as CharacterBody2D
	z_index = 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit

func _process(delta: float) -> void:
	clock += delta
	cue = ""
	if not cues_enabled or not is_instance_valid(boss) or boss.dead or get_tree().paused or GameSession.transitioning or GameSession.ending_in_progress or boss.process_mode == Node.PROCESS_MODE_DISABLED:
		hide()
		return
	facing = -1.0 if boss.visual.flip_h else 1.0
	match boss.state:
		"slash":
			if not boss.damage_applied and boss.state_timer > .36:
				cue = "slash"
				progress = clampf((.68 - boss.state_timer) / .32, 0, 1)
		"pounce_windup":
			cue = "pounce"
			facing = boss.pounce_direction
			progress = clampf((.38 - boss.state_timer) / .38, 0, 1)
		"howl_aoe":
			if not boss.damage_applied:
				cue = "howl"
				progress = clampf((boss.visual.frame + boss.visual.frame_progress) / boss.HOWL_RELEASE_FRAME, 0, 1)
		"recovery":
			cue = "recovery"
	visible = not cue.is_empty()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO)
	var warning := Color(.96, .72, .47, cue_opacity * lerpf(.5, 1.0, progress))
	match cue:
		"slash":
			draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
			_arc(Vector2(0, -32), boss.SLASH_RANGE, -.33, .33, warning)
		"pounce":
			var start := Vector2(24 * facing, -7)
			var end := Vector2(148 * facing, -7)
			_stroke(start, end, warning)
			_stroke(end, end + Vector2(-12 * facing, -6), warning)
			_stroke(end, end + Vector2(-12 * facing, 6), warning)
		"howl":
			# The bracket marks the existing horizontal grounded-damage range.
			_stroke(Vector2(-235, -3), Vector2(235, -3), warning)
			for side in [-1, 1]:
				_stroke(Vector2(side * 235, -3), Vector2(side * 235, -14), warning)
		"recovery":
			var moonlight := Color(.65, .81, .87, cue_opacity * (.65 + .15 * sin(clock * 5)))
			_arc(Vector2(0, -4), 22, PI, TAU, moonlight)

func _stroke(start: Vector2, end: Vector2, color: Color) -> void:
	draw_line(start, end, Color(.025,.015,.025,color.a), 4.0, true)
	draw_line(start, end, color, 2.0, true)

func _arc(center: Vector2, radius: float, start: float, end: float, color: Color) -> void:
	draw_arc(center, radius, start, end, 20, Color(.025,.015,.025,color.a), 4.0, true)
	draw_arc(center, radius, start, end, 20, color, 2.0, true)
