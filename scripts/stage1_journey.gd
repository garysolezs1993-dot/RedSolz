extends Node2D

const DEFINITION := preload("res://scripts/stage1_definition.gd")
@export_group("Distant Moon Gate Preview")
@export var distant_gate_offset := Vector2(-860, -90)
# Viewpoint region relative to the fixed preview, along the Seal 3 descent.
@export var distant_gate_view_region := Rect2(-460, -220, 680, 360)
@export_range(0.0, .6, .05) var distant_gate_opacity := .45
var player: CharacterBody2D
var hint: Label
var hint_key := ""
var hint_tween: Tween
var distant_gate: Node2D
var chapel_landmark: Node2D
var seal_story_shown := false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 19
	add_child(layer)
	hint = Label.new()
	hint.name = "ContextualLesson"
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -143
	hint.offset_bottom = -102
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("e2c9ba"))
	hint.add_theme_color_override("font_outline_color", Color("16121e"))
	hint.add_theme_constant_override("outline_size", 4)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.modulate.a = 0.0
	layer.add_child(hint)
	distant_gate = Node2D.new()
	distant_gate.name = "DistantMoonGate"
	distant_gate.set_script(preload("res://scripts/distant_moon_gate.gd"))
	distant_gate.z_index = -5
	distant_gate.position = DEFINITION.GATE_POSITION + distant_gate_offset
	distant_gate.visible = false
	distant_gate.modulate.a = 0.0
	add_child(distant_gate)
	chapel_landmark = Node2D.new()
	chapel_landmark.name = "ChapelMoonLandmark"
	# Keep the earlier discovery crest above the new, taller shrine artwork.
	chapel_landmark.position = Vector2(3900, 29)
	chapel_landmark.set_script(preload("res://scripts/chapel_moon_landmark.gd"))
	chapel_landmark.set("entrance_offset", Vector2(3080, 408) - chapel_landmark.position)
	add_child(chapel_landmark)
	call_deferred("_connect_player")

func _connect_player() -> void:
	if not is_inside_tree():
		return
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player != null:
		player.mechanic_demonstrated.connect(_demonstrated)

func _demonstrated(mechanic: StringName) -> void:
	var key := str(mechanic)
	if GameSession.learned_mechanics.has(key):
		return
	GameSession.learned_mechanics[key] = true
	# Store alongside the existing checkpoint; learning never advances respawn.
	if not GameSession.checkpoint_scene.is_empty():
		GameSession._save_journey()
	if hint_key == key:
		_set_hint("", "")

func lesson_for_position(where: Vector2) -> Array:
	for lesson in DEFINITION.LESSONS:
		if str(lesson[0]) in ["rising_slash", "air_attack"] and where.y > 350:
			continue
		# Cellar entry belongs at the surface; do not show it after descending.
		if str(lesson[0]) == "drop_through" and (where.y > 510 or where.y < 450):
			continue
		if GameSession.learned_mechanics.has(str(lesson[0])) or where.x < float(lesson[1]) or where.x > float(lesson[2]):
			continue
		if not str(lesson[4]).is_empty() and not GameSession.learned_mechanics.has(str(lesson[4])):
			continue
		return lesson
	return []

func _set_hint(key: String, text: String) -> void:
	if hint_key == key:
		return
	if hint_tween != null and hint_tween.is_valid():
		hint_tween.kill()
	hint_key = key
	hint_tween = create_tween()
	if key.is_empty():
		hint_tween.tween_property(hint, "modulate:a", 0.0, .4)
	else:
		hint.text = text
		hint_tween.tween_property(hint, "modulate:a", 1.0, .3)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var lesson := lesson_for_position(player.global_position) if not player.dead else []
	_set_hint(str(lesson[0]), str(lesson[3])) if not lesson.is_empty() else _set_hint("", "")
	if not seal_story_shown and not player.dead and absf(player.global_position.x - 3000) < 170:
		seal_story_shown = true
		var objectives := get_parent().get_node("StageObjectives")
		if objectives.completed_count() == 0:
			GameSession.notify("Three sleeping seals bind the path beneath the crimson moon.")
	_update_distant_gate(delta)

func _update_distant_gate(delta: float) -> void:
	# Only opacity changes with Red's position; the landmark stays in world space.
	var relative_position := player.global_position - distant_gate.global_position
	var region := distant_gate_view_region
	var target_alpha := 0.0
	if region.has_point(relative_position):
		var enter_fade := clampf((relative_position.x - region.position.x) / 100.0, 0.0, 1.0)
		var exit_fade := clampf((region.end.x - relative_position.x) / 220.0, 0.0, 1.0)
		target_alpha = distant_gate_opacity * enter_fade * exit_fade
	# Suppress the preview before the real gate can enter the camera's view,
	# including wider cinematic framing. Leave a margin around its stone frame.
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var half_width := get_viewport().get_visible_rect().size.x / (camera.zoom.x * 2.0)
		if camera.get_screen_center_position().x + half_width >= DEFINITION.GATE_POSITION.x - 160.0:
			distant_gate.modulate.a = 0.0
			distant_gate.hide()
			return
	distant_gate.modulate.a = move_toward(distant_gate.modulate.a, target_alpha, delta * .9)
	distant_gate.visible = distant_gate.modulate.a > .001
