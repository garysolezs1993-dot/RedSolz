extends Node2D

const INTERACTION_RANGE_X := 220.0
const INTERACTION_RANGE_Y := 240.0

@export_file("*.tscn") var next_scene_path := "res://scenes/stage2_boss.tscn"

var player: Node2D
var prompt: Label
var fade_overlay: ColorRect
var gate_phase := 0.0
var message_timer := 0.0
var transitioning := false
var prompt_alpha := 0.0
var player_in_range := false
var motes: Array[Vector2] = []

func _ready() -> void:
	z_index = 8
	var rng := RandomNumberGenerator.new()
	rng.seed = 74921
	for index in range(8):
		motes.append(Vector2(rng.randf_range(-50.0, 50.0), rng.randf_range(-110.0, 20.0)))
	_build_prompt()
	_build_fade_overlay()
	queue_redraw()

func _process(delta: float) -> void:
	gate_phase += delta
	for index in range(motes.size()):
		var mote := motes[index]
		mote.y += (12.0 + float(index % 4) * 3.0) * delta
		mote.x += sin(gate_phase * 0.7 + float(index)) * 7.0 * delta
		if mote.y > 28.0:
			mote.y = -120.0
			mote.x = sin(float(index) * 2.3) * 52.0
		motes[index] = mote
	queue_redraw()

	if player == null or not is_instance_valid(player):
		player = null
		if get_parent() != null and get_parent().get_parent() != null:
			player = get_parent().get_parent().get_node_or_null("Player") as Node2D
		if player == null:
			player = get_tree().get_first_node_in_group("player") as Node2D
	var in_range := false
	if player != null and is_instance_valid(player):
		var offset := player.global_position - global_position
		in_range = absf(offset.x) <= INTERACTION_RANGE_X and absf(offset.y) <= INTERACTION_RANGE_Y
	player_in_range = in_range
	if in_range:
		prompt_alpha = move_toward(prompt_alpha, 1.0, delta * 4.0)
		if message_timer > 0.0:
			message_timer = maxf(0.0, message_timer - delta)
			if message_timer <= 0.0:
				prompt.text = "[↑] Enter the Moon Gate"
		elif not transitioning and (
			Input.is_action_just_pressed("interact")
			or Input.is_action_just_pressed("ui_accept")
			or Input.is_action_just_pressed("ui_up")
		):
			_enter_gate()
	else:
		prompt_alpha = move_toward(prompt_alpha, 0.0, delta * 4.0)
		message_timer = 0.0
		if not transitioning:
			prompt.text = "[↑] Enter the Moon Gate"
	prompt.modulate.a = prompt_alpha

func _build_prompt() -> void:
	prompt = Label.new()
	prompt.name = "InteractionPrompt"
	prompt.text = "[↑] Enter the Moon Gate"
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -76.0
	prompt.offset_bottom = -36.0
	prompt.position.x = 0.0
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color(0.97, 0.88, 0.84, 1.0))
	prompt.add_theme_color_override("font_outline_color", Color(0.025, 0.012, 0.035, 1.0))
	prompt.add_theme_constant_override("outline_size", 4)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.modulate.a = 0.0
	var prompt_layer := CanvasLayer.new()
	prompt_layer.name = "GatePromptLayer"
	prompt_layer.layer = 20
	add_child(prompt_layer)
	prompt_layer.add_child(prompt)

func _build_fade_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	fade_overlay = ColorRect.new()
	fade_overlay.name = "SceneFade"
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.visible = false
	layer.add_child(fade_overlay)

func _enter_gate() -> void:
	var packed_stage: PackedScene = null
	if ResourceLoader.exists(next_scene_path):
		packed_stage = load(next_scene_path) as PackedScene
	if packed_stage == null:
		prompt.text = "Stage 2 is not yet available."
		message_timer = 2.5
		return
	transitioning = true
	if player != null:
		get_tree().root.set_meta("stage_transition_health", int(player.get("current_health")))
	prompt.text = "The forest gives way..."
	fade_overlay.visible = true
	var fade := create_tween()
	fade.tween_property(fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	fade.tween_callback(_change_scene.bind(packed_stage))

func _change_scene(packed_stage: PackedScene) -> void:
	get_tree().change_scene_to_packed(packed_stage)

func _draw() -> void:
	var pulse := 0.5 + sin(gate_phase * 1.4) * 0.5
	var portal_color := Color(0.61, 0.16, 0.25, 0.12 + pulse * 0.08)
	draw_circle(Vector2(0.0, -22.0), 78.0 + pulse * 4.0, portal_color)
	draw_circle(Vector2(0.0, -22.0), 54.0 + pulse * 2.0, Color(0.48, 0.12, 0.23, 0.08 + pulse * 0.06))
	# Old stone arch, matching the first map's ruin palette.
	draw_rect(Rect2(-96.0, -56.0, 22.0, 166.0), Color("33303a"), true)
	draw_rect(Rect2(74.0, -56.0, 22.0, 166.0), Color("33303a"), true)
	draw_rect(Rect2(-104.0, -66.0, 30.0, 14.0), Color("49424c"), true)
	draw_rect(Rect2(74.0, -66.0, 30.0, 14.0), Color("49424c"), true)
	draw_line(Vector2(-88.0, -57.0), Vector2(0.0, -132.0), Color("393541"), 16.0, true)
	draw_line(Vector2(0.0, -132.0), Vector2(88.0, -57.0), Color("393541"), 16.0, true)
	draw_rect(Rect2(-57.0, -31.0, 114.0, 141.0), Color(0.065, 0.035, 0.07, 0.94), true)
	draw_rect(Rect2(-2.0, -14.0, 4.0, 112.0), Color(0.55, 0.19, 0.29, 0.42 + pulse * 0.2), true)
	draw_circle(Vector2(0.0, -18.0), 6.0 + pulse, Color(0.82, 0.29, 0.36, 0.55 + pulse * 0.25))
	for index in range(motes.size()):
		var mote := motes[index]
		var alpha := 0.3 + (sin(gate_phase * 1.7 + float(index)) + 1.0) * 0.18
		draw_circle(mote, 1.5 if index % 3 == 0 else 1.0, Color(0.86, 0.32, 0.4, alpha))
	if prompt_alpha > 0.05:
		draw_arc(Vector2(0.0, -22.0), 86.0, PI, TAU, 24, Color(0.78, 0.27, 0.34, prompt_alpha * 0.34), 2.0, true)
