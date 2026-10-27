extends Node

const STAGE_ONE := "res://scenes/main.tscn"
const STAGE_TWO := "res://scenes/stage2_boss.tscn"
const TITLE := "res://scenes/title.tscn"
const OPENING := "res://scenes/OpeningCutscene.tscn"
const PROTOTYPE_COMPLETE := "res://scenes/PrototypeComplete.tscn"
const STAGE_ONE_ARRIVAL := preload("res://scripts/stage1_arrival.gd")
const STAGE_ONE_DEFINITION := preload("res://scripts/stage1_definition.gd")
const INITIAL_POSITION := Vector2(70.0, 485.0)
const DEATH_PRESENTATION := preload("res://scripts/death_presentation.gd")
# Intentional legacy folder identifier: preserve saves from the former title.
# Godot's project-name sanitization replaces ':' with '-' in this directory.
const LEGACY_DATA_FOLDER := "Red Riding Hood- The Silent Keep"

var music_volume := 0.55
var sfx_volume := 0.85
var checkpoint_scene := ""
var checkpoint_position := INITIAL_POSITION
var collected_petals: Array[String] = []
var learned_mechanics: Dictionary = {}
var activated_checkpoints: Dictionary = {}
var stage_objectives: Dictionary = {}
var transitioning := false
var death_in_progress := false
var death_presentation: Node
var pending_spawn := false
var opening_arrival_pending := false
var opening_arrival_active := false
var ending_in_progress := false
var settings_path := "user://audio_settings.cfg"
var save_path := "user://journey.cfg"
var fade_rect: ColorRect
var fade_tween: Tween
var toast: Label
var toast_tween: Tween

func _import_legacy_user_files() -> void:
	# A rename changes the default user:// directory. Copy only missing files;
	# leave the old folder and any newer destination progress untouched.
	var destination := OS.get_user_data_dir()
	var source := destination.get_base_dir().path_join(LEGACY_DATA_FOLDER)
	if source == destination or not DirAccess.dir_exists_absolute(source):
		return
	if DirAccess.make_dir_recursive_absolute(destination) != OK:
		push_warning("Could not create the new save directory. Original saves remain untouched.")
		return
	for file_name: String in ["journey.cfg", "audio_settings.cfg"]:
		var old_file := source.path_join(file_name)
		var new_file := destination.path_join(file_name)
		if FileAccess.file_exists(new_file) or not FileAccess.file_exists(old_file):
			continue
		var error := DirAccess.copy_absolute(old_file, new_file)
		if error != OK:
			push_warning("Could not import existing %s after title update (%d). Original remains untouched." % [file_name, error])

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_cmdline_user_args().has("--presentation-test"):
		settings_path = "user://presentation_test_settings.cfg"
		save_path = "user://presentation_test_journey.cfg"
	else:
		_import_legacy_user_files()
	_load_settings()
	_load_journey()
	_add_menu_controller_bindings()
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0.01, 0.008, 0.02, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_rect)
	toast = Label.new()
	toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast.offset_top = -96.0
	toast.offset_bottom = -60.0
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 17)
	toast.add_theme_color_override("font_outline_color", Color("16121f"))
	toast.add_theme_constant_override("outline_size", 4)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.modulate.a = 0.0
	layer.add_child(toast)
	death_presentation = DEATH_PRESENTATION.new()
	death_presentation.name = "DeathPresentation"
	add_child(death_presentation)

func present_death(player: CharacterBody2D) -> void:
	death_presentation.play(player)

func _add_menu_controller_bindings() -> void:
	# This engine's built-in ui_accept has keyboard bindings only.
	# Extend menu actions without altering Red's gameplay controls.
	var buttons := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B,
		"ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN,
		"ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT}
	for action: String in buttons:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
	for mapping in [["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0],
		["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = int(mapping[1])
		event.axis_value = float(mapping[2])
		if not InputMap.action_has_event(str(mapping[0]), event):
			InputMap.action_add_event(str(mapping[0]), event)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		music_volume = clampf(float(config.get_value("audio", "music", 0.55)), 0.0, 1.0)
		sfx_volume = clampf(float(config.get_value("audio", "sfx", 0.85)), 0.0, 1.0)

func set_audio_volume(channel: String, value: float) -> void:
	if channel == "Music":
		music_volume = clampf(value, 0.0, 1.0)
	else:
		sfx_volume = clampf(value, 0.0, 1.0)
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	if config.save(settings_path) != OK:
		push_warning("Could not save audio settings.")
	AudioDirector.apply_volumes()

func _load_journey() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK or int(config.get_value("journey", "version", 0)) != 1:
		return
	var scene_path := str(config.get_value("journey", "scene", ""))
	var saved_position: Variant = config.get_value("journey", "position", INITIAL_POSITION)
	# Old checkpoint anchors moved with the hub redesign; keep progress and IDs.
	if scene_path == STAGE_ONE and saved_position is Vector2 and int(config.get_value("journey", "stage1_layout_version", 1)) < STAGE_ONE_DEFINITION.LAYOUT_VERSION:
		if saved_position == Vector2(6500, 485):
			saved_position = Vector2(2800, 485)
		elif saved_position == Vector2(10600, 485):
			saved_position = Vector2(9100, 485)
	if not saved_position is Vector2 or not _valid_checkpoint(scene_path, saved_position):
		return
	checkpoint_scene = scene_path
	checkpoint_position = saved_position
	var learned: Variant = config.get_value("journey", "learned_mechanics", {})
	if learned is Dictionary:
		learned_mechanics = learned
	var activated: Variant = config.get_value("journey", "activated_checkpoints", {})
	if activated is Dictionary:
		activated_checkpoints = activated
	var saved_petals: Variant = config.get_value("journey", "petals", [])
	var objectives: Variant = config.get_value("journey", "stage_objectives", {})
	if objectives is Dictionary:
		stage_objectives = objectives
	if saved_petals is Array:
		for entry in saved_petals:
			if entry is String and not collected_petals.has(entry):
				collected_petals.append(entry)

func _valid_checkpoint(scene_path: String, spawn: Vector2) -> bool:
	if scene_path not in [STAGE_ONE, STAGE_TWO] or not ResourceLoader.exists(scene_path):
		return false
	var width := STAGE_ONE_DEFINITION.WIDTH if scene_path == STAGE_ONE else 2800.0
	return is_finite(spawn.x) and is_finite(spawn.y) and spawn.x >= 24.0 and spawn.x <= width - 24.0 and spawn.y >= -200.0 and spawn.y <= 580.0

func has_valid_save() -> bool:
	return _valid_checkpoint(checkpoint_scene, checkpoint_position) and FileAccess.file_exists(save_path)

func set_checkpoint(scene_path: String, spawn: Vector2) -> void:
	if not _valid_checkpoint(scene_path, spawn):
		return
	checkpoint_scene = scene_path
	checkpoint_position = spawn
	_save_journey()

func _save_journey() -> void:
	var config := ConfigFile.new()
	config.set_value("journey", "version", 1)
	config.set_value("journey", "stage1_layout_version", STAGE_ONE_DEFINITION.LAYOUT_VERSION)
	config.set_value("journey", "scene", checkpoint_scene)
	config.set_value("journey", "position", checkpoint_position)
	config.set_value("journey", "petals", collected_petals)
	config.set_value("journey", "learned_mechanics", learned_mechanics)
	config.set_value("journey", "activated_checkpoints", activated_checkpoints)
	config.set_value("journey", "stage_objectives", stage_objectives)
	if config.save(save_path) != OK:
		push_warning("Could not save the checkpoint.")

func start_new_game() -> void:
	collected_petals.clear()
	learned_mechanics.clear()
	activated_checkpoints.clear()
	stage_objectives.clear()
	set_checkpoint(STAGE_ONE, INITIAL_POSITION)
	_clear_transition_health()
	pending_spawn = true
	opening_arrival_pending = false
	transition_to(OPENING)

func finish_opening(skip_arrival: bool = false) -> void:
	# A very early Skip can arrive while the menu's scene fade is settling.
	while transitioning:
		await get_tree().process_frame
	opening_arrival_pending = not skip_arrival
	transition_to(STAGE_ONE)

func continue_game() -> void:
	if not has_valid_save():
		return
	_clear_transition_health()
	if objective_completed(STAGE_TWO, "prototype_complete"):
		pending_spawn = false
		transition_to(PROTOTYPE_COMPLETE)
		return
	pending_spawn = true
	transition_to(checkpoint_scene)

func retry_stage(scene_path: String) -> void:
	if scene_path not in [STAGE_ONE, STAGE_TWO]:
		scene_path = STAGE_ONE
	if checkpoint_scene != scene_path:
		set_checkpoint(scene_path, INITIAL_POSITION)
	_clear_transition_health()
	pending_spawn = true
	transition_to(scene_path)

func prepare_player(player: CharacterBody2D) -> void:
	# Parent's file path is available during child _ready, before current_scene.
	var scene_path: String = player.get_parent().scene_file_path
	if scene_path not in [STAGE_ONE, STAGE_TWO]:
		return
	if pending_spawn and checkpoint_scene == scene_path:
		player.global_position = checkpoint_position
		player.set("current_health", player.get("maximum_health"))
		player.reset_physics_interpolation()
		pending_spawn = false
	elif checkpoint_scene != scene_path:
		set_checkpoint(scene_path, player.global_position)
	get_tree().root.set_meta("retry_scene_path", scene_path)
	if scene_path == STAGE_ONE and opening_arrival_pending:
		opening_arrival_pending = false
		opening_arrival_active = true
		get_tree().paused = true
		var shot := STAGE_ONE_ARRIVAL.new()
		shot.name = "OpeningArrival"
		shot.process_mode = Node.PROCESS_MODE_ALWAYS
		player.get_parent().add_child.call_deferred(shot)
	reveal()

func collect_petal(identifier: String) -> bool:
	if collected_petals.has(identifier):
		return false
	collected_petals.append(identifier)
	_save_journey()
	return true

func objective_completed(stage_path: String, identifier: String) -> bool:
	var entries: Variant = stage_objectives.get(stage_path, [])
	return entries is Array and entries.has(identifier)

func complete_objective(stage_path: String, identifier: String) -> bool:
	if objective_completed(stage_path, identifier):
		return false
	var existing: Variant = stage_objectives.get(stage_path, [])
	var entries: Array = existing.duplicate() if existing is Array else []
	entries.append(identifier)
	stage_objectives[stage_path] = entries
	# Objective autosaves never move the player's respawn anchor.
	_save_journey()
	return true

func _clear_transition_health() -> void:
	if get_tree().root.has_meta("stage_transition_health"):
		get_tree().root.remove_meta("stage_transition_health")

func transition_to(scene_path: String) -> void:
	if transitioning or not ResourceLoader.exists(scene_path):
		return
	transitioning = true
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast.modulate.a = 0.0
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_tween = create_tween().set_ignore_time_scale(true)
	fade_tween.tween_property(fade_rect, "color:a", 1.0, 0.32)
	await fade_tween.finished
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not change scene: %s (%d)" % [scene_path, error])
		transitioning = false
		reveal()
		return
	await get_tree().process_frame
	transitioning = false
	reveal()

func reveal() -> void:
	if fade_rect == null or transitioning:
		return
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_tween = create_tween().set_ignore_time_scale(true)
	fade_tween.tween_property(fade_rect, "color:a", 0.0, 0.45)

func notify(message: String, hold_seconds: float = 2.2) -> void:
	toast.text = message
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast.modulate.a = 0.0
	toast_tween = create_tween()
	toast_tween.tween_property(toast, "modulate:a", 1.0, 0.25)
	toast_tween.tween_interval(hold_seconds)
	toast_tween.tween_property(toast, "modulate:a", 0.0, 0.5)
