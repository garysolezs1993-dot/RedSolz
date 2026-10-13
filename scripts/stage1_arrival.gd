extends Node

const TRANSITIONS := preload("res://scripts/story_transitions.gd")
const UI := preload("res://scripts/menu_ui.gd")
@export var entry_duration := 1.4
@export var dialogue_hold := 2.5
@export var return_duration := 1.0
var player: CharacterBody2D
var normal_camera: Camera2D
var camera: Camera2D
var visual: AnimatedSprite2D
var dialogue: Label
var skip_button: Button
var active_tween: Tween
var saved_hud: Array[Dictionary] = []
var visual_mode: ProcessMode
var interpolation_mode: PhysicsInterpolationMode
var active := true
var phase := "starting"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TRANSITIONS.install_skip_action()
	player = get_parent().get_node("Player") as CharacterBody2D
	visual = player.get_node("Visual") as AnimatedSprite2D
	normal_camera = player.get_node("Camera2D") as Camera2D
	visual_mode = visual.process_mode
	interpolation_mode = player.physics_interpolation_mode
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visual.process_mode = Node.PROCESS_MODE_ALWAYS
	_hide_stage_ui(get_parent())
	camera = Camera2D.new()
	camera.name = "OpeningArrivalCamera"
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position = Vector2(370, 365)
	camera.zoom = Vector2(1.55, 1.55)
	camera.limit_left = normal_camera.limit_left
	camera.limit_right = normal_camera.limit_right
	camera.limit_top = normal_camera.limit_top
	camera.limit_bottom = normal_camera.limit_bottom
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	layer.name = "ArrivalDialogue"
	layer.layer = 105
	add_child(layer)
	dialogue = UI.label("Hold on... I'm coming.", 23, Color("f0e0d7"))
	dialogue.name = "RedDialogue"
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.add_theme_color_override("font_outline_color", Color("100b16"))
	dialogue.add_theme_constant_override("outline_size", 5)
	layer.add_child(dialogue)
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue.offset_top = -110
	dialogue.offset_bottom = -55
	dialogue.modulate.a = 0
	skip_button = Button.new()
	skip_button.text = "Skip opening  ·  Esc / Start / B"
	skip_button.add_theme_font_size_override("font_size", 12)
	skip_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	layer.add_child(skip_button)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -300
	skip_button.offset_right = -24
	skip_button.offset_top = -34
	skip_button.offset_bottom = -12
	skip_button.pressed.connect(skip)
	call_deferred("_play_shot")

func _hide_stage_ui(node: Node) -> void:
	for child in node.get_children():
		if child == self:
			continue
		# Always include gameplay UI, independently of its canvas layer number.
		if child is CanvasLayer and (child == get_parent().get_node_or_null("UI") or child.layer >= 1):
			var colors: Array[Dictionary] = []
			for item in child.get_children():
				if item is Control:
					colors.append({"control": item, "modulate": item.modulate})
			saved_hud.append({"layer": child, "visible": child.visible, "colors": colors})
			child.hide()
		_hide_stage_ui(child)

func _play_shot() -> void:
	phase = "establish"
	active_tween = TRANSITIONS.hold(self, .9)
	await active_tween.finished
	phase = "entry"
	player.set("facing", 1)
	visual.flip_h = false
	player.call("_play_visual", "run")
	var destination := player.global_position + Vector2(90, 0)
	active_tween = TRANSITIONS.fade(self, player, ^"global_position", destination, entry_duration)
	await active_tween.finished
	player.velocity = Vector2.ZERO
	player.call("_play_visual", "idle")
	phase = "dialogue"
	active_tween = TRANSITIONS.fade(self, dialogue, ^"modulate:a", 1.0, .30)
	await active_tween.finished
	active_tween = TRANSITIONS.hold(self, dialogue_hold)
	await active_tween.finished
	active_tween = TRANSITIONS.fade(self, dialogue, ^"modulate:a", 0.0, .35)
	await active_tween.finished
	phase = "return_camera"
	var half_view := get_viewport().get_visible_rect().size / (normal_camera.zoom * 2)
	var target := normal_camera.global_position + normal_camera.offset
	target.x = clampf(target.x, normal_camera.limit_left + half_view.x, normal_camera.limit_right - half_view.x)
	target.y = clampf(target.y, normal_camera.limit_top + half_view.y, normal_camera.limit_bottom - half_view.y)
	active_tween = TRANSITIONS.fade(self, camera, ^"position", target, return_duration)
	active_tween.parallel().tween_property(camera, "zoom", normal_camera.zoom, return_duration)
	await active_tween.finished
	phase = "reveal_hud"
	_switch_camera_back()
	active_tween = TRANSITIONS.hold(self, .65)
	for entry in saved_hud:
		var layer := entry["layer"] as CanvasLayer
		if not is_instance_valid(layer) or not entry["visible"]:
			continue
		layer.show()
		for child in layer.get_children():
			if child is Control:
				var alpha: float = child.modulate.a
				child.modulate.a = 0
				active_tween.parallel().tween_property(child, "modulate:a", alpha, .65)
	await active_tween.finished
	_finish()

func _switch_camera_back() -> void:
	if is_instance_valid(normal_camera):
		normal_camera.make_current()
		normal_camera.reset_smoothing()
		normal_camera.force_update_scroll()

func _input(event: InputEvent) -> void:
	if active and event.is_action_pressed("skip_opening") and not event.is_echo():
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	if not active:
		return
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	_finish()

func _finish() -> void:
	if not active:
		return
	active = false
	phase = "finished"
	_switch_camera_back()
	for entry in saved_hud:
		var layer := entry["layer"] as CanvasLayer
		if is_instance_valid(layer):
			layer.visible = entry["visible"]
			# A skipped HUD fade must restore every control's original opacity.
			for color_entry in entry["colors"]:
				var control := color_entry["control"] as Control
				if is_instance_valid(control):
					control.modulate = color_entry["modulate"]
	if is_instance_valid(player):
		player.velocity = Vector2.ZERO
		player.call("_cancel_action")
		player.call("_play_visual", "idle")
		player.physics_interpolation_mode = interpolation_mode
		visual.process_mode = visual_mode
		player.reset_physics_interpolation()
	GameSession.opening_arrival_active = false
	GameSession.notify("Find your brother.")
	get_tree().paused = false
	queue_free()

func _exit_tree() -> void:
	# Changing scenes during the shot must never leave the next scene paused.
	if active:
		GameSession.opening_arrival_active = false
		get_tree().paused = false
