extends Node2D

@export var objective_manager_path := NodePath("../StageObjectives")
@export var visual_scene: PackedScene = preload("res://scenes/moon_wisp_visual.tscn")
@export_range(10, 60, 1) var guidance_cooldown := 26.0
@export_range(6, 30, 1) var inactivity_delay := 14.0
@export_range(1, 8, .1) var travel_duration := 3.4
@export_range(2, 6, .1) var introduction_travel_duration := 3.2
@export_range(.3, 1.5, .05) var camera_return_duration := .55
@export_range(.5, 6, .1) var brief_travel_duration := 3.0
@export_range(.5, 5, .1) var brief_landmark_duration := 3.0
@export_range(.3, 2, .05) var brief_fade_duration := .85
@export_group("First Seal Discovery")
@export var chapel_glimpse_trigger := Rect2(2780, 405, 380, 115)
@export var chapel_glimpse_destination := Vector2(3140, 392)
@export_range(1, 5, .1) var chapel_glimpse_travel_duration := 2.8
@export_range(1, 5, .1) var chapel_glimpse_hover_duration := 2.6
@export_group("White Lily Trail - First Seal Preview")
@export var lily_trail_enabled := true
@export_range(25, 60, 1) var lily_trail_spawn_distance := 32.0
@export_range(.2, 1, .05) var lily_trail_lifetime := .5
@export_range(.05, .5, .05) var lily_trail_fade_duration := .2
@export_range(.01, .15, .005) var lily_trail_scale := .085
@export_range(.05, .65, .05) var lily_trail_opacity := .28
var chapel_glimpse := false
var chapel_glimpse_shown := false
var released_from_seal := false
var wisp_state := "guide_disappear"
var cinematic_active := false
var brief_cue := false
var cinematic_camera: Camera2D
var previous_camera: Camera2D
var previous_pause := false
var camera_return_origin := Vector2.ZERO
var cinematic_route: Array[Vector2] = []
var manager: Node2D
var player: CharacterBody2D
var phase := "hidden"
var elapsed := 0.0
var cooldown := 0.0
var idle_time := 0.0
var last_player_position := Vector2.ZERO
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var visited_regions: Dictionary = {}
var spawn_count := 0
var art: Node2D
const LANDMARKS := [Vector2(2800, 485), Vector2(3080, 437), Vector2(3380, 535), Vector2(5400, 485), Vector2(6520, 535), Vector2(8000, 485), Vector2(9100, 485)]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 7
	manager = get_node_or_null(objective_manager_path)
	if manager != null:
		manager.seal_awakened.connect(_seal_awakened)
	art = visual_scene.instantiate() as Node2D
	art.name = "WispVisual"
	art.lily_trail_enabled = lily_trail_enabled
	art.lily_trail_spawn_distance = lily_trail_spawn_distance
	art.lily_trail_lifetime = lily_trail_lifetime
	art.lily_trail_fade_duration = lily_trail_fade_duration
	art.lily_trail_scale = lily_trail_scale
	art.lily_trail_opacity = lily_trail_opacity
	add_child(art)
	hide()

func _seal_awakened(seal: Node2D, introduction: bool) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	suspend_for_seal()
	if not request_guidance(true):
		return
	# Review the full first-seal route before extending the motif elsewhere.
	art.set_lily_trail_active(introduction and lily_trail_enabled)
	released_from_seal = true
	brief_cue = not introduction
	origin = seal.wisp_release_position()
	global_position = origin
	cinematic_route.assign(seal.guide_route)
	if not cinematic_route.is_empty():
		destination = cinematic_route.back()
	elif seal.guide_target != Vector2.ZERO:
		destination = seal.guide_target
	if introduction:
		_begin_cinematic()
	elif seal.identifier == "oak_moon_seal":
		GameSession.notify("Beyond the bridge, follow the ruins up into the canopy.")

func suspend_for_seal() -> void:
	_end_cinematic()
	_next_phase("hidden")
	hide()
	cooldown = guidance_cooldown

func _begin_cinematic() -> void:
	if cinematic_route.is_empty():
		cinematic_route.assign(preload("res://scripts/stage1_definition.gd").FIRST_WISP_ROUTE)
	destination = cinematic_route.back()
	previous_camera = get_viewport().get_camera_2d()
	if previous_camera == null:
		return
	previous_pause = get_tree().paused
	cinematic_camera = Camera2D.new()
	cinematic_camera.name = "WispCamera"
	cinematic_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	cinematic_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cinematic_camera.top_level = true
	cinematic_camera.position = previous_camera.get_screen_center_position()
	cinematic_camera.zoom = previous_camera.zoom
	add_child(cinematic_camera)
	cinematic_camera.make_current()
	player.velocity = Vector2.ZERO
	player.get_node("InteractionRouter").prompt.hide()
	cinematic_active = true
	get_tree().paused = true

func _route_position(progress: float) -> Vector2:
	var points: Array[Vector2] = [origin]
	points.append_array(cinematic_route)
	var distance := 0.0
	for index in range(points.size() - 1):
		distance += points[index].distance_to(points[index + 1])
	var remaining := distance * clampf(progress, 0, 1)
	for index in range(points.size() - 1):
		var length := points[index].distance_to(points[index + 1])
		if remaining <= length:
			return points[index].lerp(points[index + 1], remaining / maxf(length, .001))
		remaining -= length
	return points.back()

func _end_cinematic() -> void:
	if not cinematic_active:
		return
	cinematic_active = false
	if is_instance_valid(previous_camera) and previous_camera.is_inside_tree() and not GameSession.death_in_progress:
		previous_camera.make_current()
		previous_camera.reset_smoothing()
	if is_instance_valid(cinematic_camera):
		cinematic_camera.queue_free()
	cinematic_camera = null
	if not GameSession.death_in_progress:
		get_tree().paused = previous_pause
	brief_cue = false

func _input(event: InputEvent) -> void:
	if cinematic_active:
		if event.is_action_pressed("ui_cancel"):
			_next_phase("hidden")
			hide()
			_end_cinematic()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	_end_cinematic()

func request_guidance(force: bool = false) -> bool:
	if not is_instance_valid(player) or player.dead or manager == null:
		return false
	if phase != "hidden" or (cooldown > 0 and not force):
		return false
	origin = player.global_position + Vector2(0, -28)
	brief_cue = false
	chapel_glimpse = false
	released_from_seal = false
	cinematic_route.clear()
	destination = manager.guidance_target(player.global_position)
	global_position = origin
	elapsed = 0
	_next_phase("swirl")
	art.play_appearance()
	cooldown = guidance_cooldown
	idle_time = 0
	spawn_count += 1
	art.set_lily_trail_active(false)
	modulate.a = 0
	show()
	return true

func request_chapel_glimpse() -> bool:
	# One short cue before the fork; it neither activates a seal nor takes the camera.
	if chapel_glimpse_shown or manager == null or manager.completed_count() != 0:
		return false
	if not is_instance_valid(player) or player.dead or player.action_state != 0 or not player.is_on_floor():
		return false
	if not chapel_glimpse_trigger.has_point(player.global_position):
		return false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and not bool(enemy.get("dead")) and enemy.global_position.distance_to(player.global_position) < 360:
			return false
	if not request_guidance():
		return false
	chapel_glimpse = true
	chapel_glimpse_shown = true
	origin = player.global_position + Vector2(60, -36)
	global_position = origin
	destination = chapel_glimpse_destination
	return true

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player == null:
			return
		last_player_position = player.global_position
	if player.dead or GameSession.death_in_progress or GameSession.transitioning:
		_end_cinematic()
		_next_phase("hidden")
		hide()
		return
	if get_tree().paused and not cinematic_active:
		return
	cooldown = maxf(0, cooldown - delta)
	if phase == "hidden":
		_try_context_guidance(delta)
		last_player_position = player.global_position
		return
	elapsed += delta
	var previous_position := global_position
	match phase:
		"swirl":
			modulate.a = minf(1, elapsed * 3)
			global_position = origin + Vector2(cos(elapsed * TAU) * 22, sin(elapsed * TAU) * 12)
			if elapsed >= (.35 if chapel_glimpse or released_from_seal else (.3 if brief_cue else 1.0)):
				_next_phase("pause")
		"pause":
			modulate.a = 1.0
			global_position = origin + Vector2(signf(destination.x - origin.x) * 32, -7)
			if elapsed >= (.2 if chapel_glimpse else (.15 if brief_cue or released_from_seal else .6)):
				origin = global_position
				_next_phase("travel")
		"travel":
			var duration := introduction_travel_duration if cinematic_active else (chapel_glimpse_travel_duration if chapel_glimpse else (brief_travel_duration if brief_cue else travel_duration))
			var progress := smoothstep(0, 1, elapsed / duration)
			global_position = _route_position(progress) if cinematic_active or (released_from_seal and not cinematic_route.is_empty()) else origin.lerp(destination, progress)
			global_position.y += sin(elapsed * 3) * 4
			if cinematic_active:
				cinematic_camera.global_position = cinematic_camera.global_position.lerp(global_position + Vector2(0, 35), minf(1, delta * 5))
			if elapsed >= duration:
				_next_phase("landmark")
		"landmark":
			global_position = destination + Vector2(0, sin(elapsed * 3) * 4)
			if elapsed >= (chapel_glimpse_hover_duration if chapel_glimpse else (brief_landmark_duration if brief_cue else (.5 if released_from_seal else .8))):
				_next_phase("fade")
		"fade":
			var duration := brief_fade_duration if brief_cue else .7
			if elapsed >= duration and art.arrival_complete:
				hide()
				if cinematic_active:
					camera_return_origin = cinematic_camera.global_position
					_next_phase("camera_return")
				else:
					_next_phase("hidden")
		"camera_return":
			cinematic_camera.global_position = camera_return_origin.lerp(previous_camera.get_screen_center_position(), smoothstep(0, 1, elapsed / camera_return_duration))
			if elapsed >= camera_return_duration:
				_end_cinematic()
				_next_phase("hidden")
	if phase == "travel":
		art.face_travel(global_position - previous_position)
	elif cinematic_active and phase in ["swirl", "pause", "landmark"]:
		cinematic_camera.global_position = cinematic_camera.global_position.lerp(global_position + Vector2(0, 35), minf(1, delta * 5))
	last_player_position = player.global_position

func _next_phase(next: String) -> void:
	phase = next
	elapsed = 0
	if next == "hidden":
		chapel_glimpse = false
		released_from_seal = false
	wisp_state = {"swirl": "guide_spawn", "pause": "guide_spawn", "travel": "guide_move", "landmark": "guide_arrive"}.get(next, "guide_disappear")
	match next:
		"swirl", "pause", "landmark":
			art.play_state("idle")
		"travel":
			art.face_travel(destination - origin)
			art.play_state("move")
		"fade":
			modulate.a = 1.0
			art.play_state("arrive", brief_fade_duration if brief_cue else .7)
		"hidden", "camera_return":
			art.deactivate()

func _try_context_guidance(delta: float) -> void:
	for seal in get_tree().get_nodes_in_group("moon_seals"):
		if seal.state == "activating" or seal.release_remaining >= 0:
			idle_time = 0
			return
	if manager == null or player.action_state != 0:
		idle_time = 0
		return
	if manager.completed_count() == 0:
		# Preserve the full first-seal cinematic for activation. The earlier glimpse
		# just points at the upper entrance while Red remains free to move.
		request_chapel_glimpse()
		idle_time = 0
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.global_position.distance_to(player.global_position) < 360:
			idle_time = 0
			return
	for landmark in LANDMARKS:
		if player.global_position.distance_to(landmark) < 110 and not visited_regions.has(landmark) and cooldown <= 0:
			visited_regions[landmark] = true
			request_guidance()
			return
	idle_time = idle_time + delta if player.global_position.distance_to(last_player_position) < 1 else 0
	if idle_time >= inactivity_delay:
		request_guidance()

