extends Node

# The world pauses; this persistent controller, Red's Visual and our camera run.
@export_range(1.0, 2.0, 0.05) var zoom_multiplier := 1.5
@export var focus_duration := 0.3
@export var final_pose_hold := 0.4
@export var fog_cover_duration := 0.85
@export var fog_reveal_duration := 1.0

const FOG_SHADER := preload("res://shaders/death_fog.gdshader")
const GAME_OVER := "res://scenes/game_over.tscn"
var active := false
var phase := "idle"
var player: CharacterBody2D
var camera: Camera2D
var fog: ColorRect
var fog_material: ShaderMaterial
var stage_hud: CanvasLayer
var hud_was_visible := true
var prior_pause := false
var visual_mode: ProcessMode
var body_interpolation_mode: PhysicsInterpolationMode
var previous_camera: Camera2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.name = "DeathFog"
	layer.layer = 125
	add_child(layer)
	fog = ColorRect.new()
	fog.name = "Fog"
	fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog.color = Color.WHITE
	fog_material = ShaderMaterial.new()
	fog_material.shader = FOG_SHADER
	fog.material = fog_material
	fog.visible = false
	layer.add_child(fog)

func _tween() -> Tween:
	return create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)

func _landing_position(red: CharacterBody2D) -> Vector2:
	if red.is_on_floor():
		return red.global_position
	# Snapshot the terrain before pausing. Only terrain layer 1 is considered.
	# Tweening the defeated body then needs no live enemy/world simulation.
	var feet := red.global_position + Vector2(0, 14)
	var query := PhysicsRayQueryParameters2D.create(feet, feet + Vector2(0, 1600), 1, [red.get_rid()])
	var contact := red.get_world_2d().direct_space_state.intersect_ray(query)
	if not contact.is_empty():
		var ground: Vector2 = contact["position"]
		return Vector2(red.global_position.x, maxf(red.global_position.y, ground.y - 15))
	return red.global_position

func play(red: CharacterBody2D) -> void:
	if active:
		return
	active = true
	player = red
	var landing := _landing_position(red)
	prior_pause = get_tree().paused
	visual_mode = red.visual.process_mode
	body_interpolation_mode = red.physics_interpolation_mode
	red.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	red.visual.process_mode = Node.PROCESS_MODE_ALWAYS
	GameSession.death_in_progress = true
	GameSession.transitioning = true
	if GameSession.fade_tween != null and GameSession.fade_tween.is_valid():
		GameSession.fade_tween.kill()
	GameSession.fade_rect.color.a = 0.0
	GameSession.fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if GameSession.toast_tween != null and GameSession.toast_tween.is_valid():
		GameSession.toast_tween.kill()
	GameSession.toast.modulate.a = 0.0
	stage_hud = red.get_parent().get_node_or_null("UI") as CanvasLayer
	if stage_hud != null:
		hud_was_visible = stage_hud.visible
		stage_hud.visible = false
	previous_camera = get_viewport().get_camera_2d()
	camera = Camera2D.new()
	camera.name = "DeathCamera"
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position = previous_camera.get_screen_center_position() if previous_camera != null else red.global_position
	camera.zoom = previous_camera.zoom if previous_camera != null else Vector2.ONE
	add_child(camera)
	camera.make_current()
	get_tree().paused = true
	AudioDirector.fade_for_death(0.8)
	fog.visible = true
	fog.mouse_filter = Control.MOUSE_FILTER_STOP
	fog_material.set_shader_parameter("progress", 0.0)
	if landing.y > red.global_position.y + 1.0:
		phase = "settling"
		red._play_visual("fall")
		var distance := landing.y - red.global_position.y
		var settling_time := clampf(sqrt(2.0 * distance / red.GRAVITY), 0.1, 0.8)
		var settle := _tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		settle.tween_property(red, "global_position", landing, settling_time)
		await settle.finished
		if not _player_available():
			return
		red.reset_physics_interpolation()
	phase = "focus"
	red._play_visual("death")
	red.visual.pause()
	var focus := _tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	focus.tween_property(camera, "position", red.global_position + Vector2(0, -6), focus_duration)
	focus.tween_property(camera, "zoom", camera.zoom * zoom_multiplier, focus_duration)
	await focus.finished
	if not _player_available():
		return
	phase = "collapse"
	red.visual.play("death")
	await red.visual.animation_finished
	if not _player_available():
		return
	phase = "hold"
	await get_tree().create_timer(final_pose_hold, true, false, true).timeout
	if not _player_available():
		return
	phase = "cover"
	var cover := _tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cover.tween_method(_set_fog_progress, 0.0, 1.0, fog_cover_duration)
	await cover.finished
	if not _player_available():
		return
	# Both scenes are hidden under fully opaque fog when the swap happens.
	var stage := get_tree().current_scene
	var retry_path := stage.scene_file_path if stage != null and not stage.scene_file_path.is_empty() else GameSession.STAGE_ONE
	get_tree().root.set_meta("retry_scene_path", retry_path)
	red.player_died.emit()
	phase = "reveal"
	camera.free()
	camera = null
	var error := get_tree().change_scene_to_file(GAME_OVER)
	if error != OK:
		push_error("Could not show Game Over: %d" % error)
		_finish()
		GameSession.reveal()
		return
	await get_tree().process_frame
	get_tree().paused = false
	var reveal := _tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reveal.tween_method(_set_fog_progress, 1.0, 0.0, fog_reveal_duration)
	await reveal.finished
	fog.visible = false
	phase = "menu"
	var game_over := get_tree().current_scene
	if game_over != null and game_over.has_method("reveal_death_menu"):
		await game_over.reveal_death_menu()
	_finish()

func _set_fog_progress(value: float) -> void:
	fog_material.set_shader_parameter("progress", value)

func _player_available() -> bool:
	if is_instance_valid(player) and player.is_inside_tree():
		return true
	_finish()
	return false

func _process(_delta: float) -> void:
	# An external scene replacement must never leave the next scene paused.
	if active and phase not in ["reveal", "menu"] and not is_instance_valid(player):
		_finish()

func _finish() -> void:
	if is_instance_valid(player):
		player.visual.process_mode = visual_mode
		player.physics_interpolation_mode = body_interpolation_mode
	if is_instance_valid(stage_hud):
		stage_hud.visible = hud_was_visible
	if is_instance_valid(camera):
		camera.queue_free()
	if is_instance_valid(previous_camera):
		previous_camera.make_current()
	camera = null
	player = null
	stage_hud = null
	fog.visible = false
	_set_fog_progress(0.0)
	get_tree().paused = prior_pause
	GameSession.transitioning = false
	GameSession.death_in_progress = false
	active = false
	phase = "idle"
