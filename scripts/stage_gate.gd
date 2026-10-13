extends Node2D

const INTERACTION_RANGE_X := 220.0
const INTERACTION_RANGE_Y := 240.0
const GATE_VISUAL := preload("res://scenes/moon_gate_visual.tscn")

@export_file("*.tscn") var next_scene_path := "res://scenes/stage2_boss.tscn"
@export var objective_manager_path: NodePath
var objectives: Node2D
var interaction: Node2D
var seal_count := 0
var required_seals := 0
var awakening_pulse := 0.0
var locked_hint_cooldown := 0.0
var was_near_locked_gate := false
@export_group("Moon Gate Visual")
@export_range(.1, 2.0, .01) var gate_art_scale := .55
@export var gate_floor_offset := Vector2(0, 110)
@export_range(-10, -1, 1) var gate_art_z_index := -3
var progress_art: Node2D

func is_unlocked() -> bool:
	return objective_manager_path.is_empty() or (objectives != null and objectives.is_complete())

func _progress_changed(completed: int, required: int) -> void:
	var changed := completed != seal_count
	seal_count = completed
	required_seals = required
	if changed and completed > 0:
		awakening_pulse = 1.0 if is_unlocked() else .35
		AudioDirector.play_sfx("menu_confirm")
	_update_gate_prompt()

func _update_gate_prompt() -> void:
	if interaction != null:
		interaction.prompt_text = "E / ↑ — Enter the Moon Gate" if is_unlocked() else "E / ↑ — Moon Gate sealed (%d/%d)" % [seal_count, required_seals]
	if progress_art != null:
		progress_art.set_seal_count(seal_count)

func _guide_missing_seal() -> void:
	if locked_hint_cooldown > 0 or objectives == null or player == null:
		return
	locked_hint_cooldown = 8
	var missing: Node2D = objectives.missing_seal(player.global_position)
	if missing != null:
		GameSession.notify("A seal still sleeps in %s." % missing.region_name)
		var guide := get_parent().get_node_or_null("MoonWispGuide")
		if guide != null:
			guide.request_guidance(true)

var player: Node2D
var prompt: Label
var fade_overlay: ColorRect
var message_timer := 0.0
var transitioning := false
var prompt_alpha := 0.0
var player_in_range := false

func _ready() -> void:
	z_index = 8
	progress_art = GATE_VISUAL.instantiate()
	progress_art.name = "GateStateVisual"
	progress_art.position = gate_floor_offset
	progress_art.gameplay_scale = gate_art_scale
	# Keep the full gate behind actors and platform edges. Prompt CanvasLayers
	# retain their own ordering, independently of the gate's artwork.
	progress_art.z_as_relative = false
	progress_art.z_index = gate_art_z_index
	add_child(progress_art)
	_build_prompt()
	_build_fade_overlay()
	interaction = Node2D.new()
	interaction.name = "GateInteraction"
	interaction.set_script(preload("res://scripts/world_interactable.gd"))
	interaction.set("prompt_text", "E / ↑ — Enter the Moon Gate")
	interaction.set("interaction_range", Vector2(INTERACTION_RANGE_X, INTERACTION_RANGE_Y))
	interaction.set("priority", 10)
	add_child(interaction)
	if not objective_manager_path.is_empty():
		objectives = get_node_or_null(objective_manager_path)
		if objectives != null:
			objectives.progress_changed.connect(_progress_changed)
			seal_count = objectives.completed_count()
			required_seals = objectives.required_seal_ids.size()
	_update_gate_prompt()

func _process(delta: float) -> void:
	awakening_pulse = move_toward(awakening_pulse, 0, delta * .6)
	if progress_art != null:
		# Brief progress feedback; dormant has no animated glow or motes.
		progress_art.modulate = Color(1, 1, 1) * (1.0 + awakening_pulse * .12)
		progress_art.modulate.a = 1.0
	locked_hint_cooldown = maxf(0, locked_hint_cooldown - delta)

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
		in_range = in_range and can_interact(player)
	player_in_range = in_range
	if in_range and not is_unlocked() and not was_near_locked_gate:
		_guide_missing_seal()
	was_near_locked_gate = in_range and not is_unlocked()
	if in_range:
		prompt_alpha = move_toward(prompt_alpha, 1.0, delta * 4.0)
		if message_timer > 0.0:
			message_timer = maxf(0.0, message_timer - delta)
			if message_timer <= 0.0:
				prompt.text = "[↑] Enter the Moon Gate"
		elif not transitioning and (
			Input.is_action_just_pressed("ui_accept")
			or Input.is_action_just_pressed("ui_up")
		):
			_enter_gate()
	else:
		prompt_alpha = move_toward(prompt_alpha, 0.0, delta * 4.0)
		message_timer = 0.0
		if not transitioning:
			prompt.text = "[↑] Enter the Moon Gate"
	# E and Up share the interaction router's single prompt.
	prompt.modulate.a = 0.0

func can_interact(body: Node2D) -> bool:
	return not transitioning and not bool(body.get("dead")) and body.get("action_state") in [0, 6]

func interact(_body: Node2D) -> void:
	player = _body
	_enter_gate()

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
	if transitioning:
		return
	if not is_unlocked():
		_guide_missing_seal()
		return
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
		if player.has_method("play_interaction"):
			player.play_interaction("look_around")
	prompt.text = "The forest gives way..."
	fade_overlay.visible = true
	var fade := create_tween()
	fade.tween_property(fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	fade.tween_callback(_change_scene.bind(packed_stage))

func _change_scene(packed_stage: PackedScene) -> void:
	get_tree().change_scene_to_packed(packed_stage)

