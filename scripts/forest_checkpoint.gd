extends Node2D

@export var identifier := "forest_checkpoint"
@export var lantern_camera_zoom := Vector2(1.55, 1.55)
@export_range(.1, 2, .05) var lantern_zoom_in_duration := .4
@export_range(.1, 2, .05) var lantern_zoom_out_duration := .35
@export_range(0, 24, 1) var maximum_alignment := 16.0
@export_range(10, 80, 1) var alignment_speed := 40.0
@export_range(4, 16, .5) var activation_fps := 10.0
@export_range(2, 10, .5) var active_idle_fps := 4.0
@export var art_scale := .06
@export_group("Moon Lantern Lighting")
@export_range(0, 2, .05) var active_glow_energy := .38
@export_range(0, 2, .05) var active_core_energy := .25
@export_range(.5, 2, .05) var glow_size := 1.0
var activated := false
var interaction_busy := false
var activation_playing := false
var activation_count := 0
var visual: AnimatedSprite2D
var interaction: Node2D
var crimson_light: PointLight2D
var core_light: PointLight2D
var lighting_elapsed := 0.0
const INTERACTABLE := preload("res://scripts/world_interactable.gd")
const ART_ROOT := "res://assets/game_assets/moon_lantern/"
const ACTIVATION_GROUND := [1183.0, 1170.0, 1160.0, 1164.0, 1187.0, 1210.0, 1158.0, 1203.0]
const IDLE_GROUND := [1204.0, 1205.0, 1205.0, 1174.0, 1174.0]

func _ready() -> void:
	add_to_group("forest_checkpoints")
	var scene := _stage_scene()
	activated = scene != null and GameSession.checkpoint_scene == scene.scene_file_path and GameSession.checkpoint_position.distance_to(global_position + Vector2(0, -15)) < 2.0
	activated = activated or GameSession.activated_checkpoints.has(identifier)
	visual = AnimatedSprite2D.new()
	visual.name = "LanternVisual"
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Draw after the terrain, with Red still rendered in front. A negative
	# layer hid the tall lantern behind the low shelf at the middle checkpoint.
	visual.z_index = 0
	visual.scale = Vector2.ONE * art_scale
	visual.sprite_frames = _make_frames()
	visual.frame_changed.connect(_place_art)
	visual.animation_finished.connect(_activation_finished)
	add_child(visual)
	if activated:
		visual.play("active")
	else:
		visual.animation = "activation"
		visual.frame = 0
	_place_art()
	_add_lighting()
	interaction = Node2D.new()
	interaction.name = "CheckpointInteraction"
	interaction.set_script(INTERACTABLE)
	interaction.set("prompt_text", "E — Light Moon Lantern")
	interaction.set("interaction_range", Vector2(32, 20))
	interaction.position = Vector2(10, -15)
	add_child(interaction)

func _add_lighting() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, .22, .60, 1])
	gradient.colors = PackedColorArray([Color(1, 1, 1, .9), Color(1, 1, 1, .6), Color(1, 1, 1, .16), Color(1, 1, 1, 0)])
	var glow := GradientTexture2D.new()
	glow.width = 256
	glow.height = 256
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(.5, .5)
	glow.fill_to = Vector2(.5, 0)
	glow.gradient = gradient
	crimson_light = _make_light("CrimsonGlow", glow, Color(1, .38, .42), glow_size)
	core_light = _make_light("WarmCore", glow, Color(1, .82, .62), glow_size * .45)
	_update_lighting()

func _make_light(node_name: String, texture: Texture2D, tint: Color, size: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = node_name
	light.texture = texture
	light.position = Vector2(8, -43)
	light.texture_scale = size
	light.color = tint
	# Light local terrain/actors, leaving the distant parallax and HUD alone.
	light.range_z_min = -2
	light.range_z_max = 3
	light.energy = 0
	add_child(light)
	return light

func _process(delta: float) -> void:
	lighting_elapsed += delta
	_update_lighting()

func _update_lighting() -> void:
	if crimson_light == null:
		return
	var strength := .035 # A faint dormant ember; it is not a lit checkpoint.
	if activated:
		strength = .97 + .025 * sin(lighting_elapsed * 2.1 + global_position.x) + .015 * sin(lighting_elapsed * 5.3)
		if activation_playing:
			var progress := (float(visual.frame) + visual.frame_progress) / 7.0
			# Build into the animation's middle burst, then settle into the idle glow.
			strength = smoothstep(0.0, .45, progress) + .45 * sin(PI * clampf((progress - .20) / .80, 0, 1))
	crimson_light.energy = active_glow_energy * strength
	core_light.energy = active_core_energy * strength

func _make_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for entry in [["activation", "activation/lantern_activate", 8, activation_fps, false], ["active", "active/lantern_active_idle", 5, active_idle_fps, true]]:
		frames.add_animation(entry[0])
		frames.set_animation_speed(entry[0], entry[3])
		frames.set_animation_loop(entry[0], entry[4])
		for index in range(entry[2]):
			frames.add_frame(entry[0], load(ART_ROOT + entry[1] + "_%02d.png" % index))
	return frames

func _stage_scene() -> Node:
	var ancestor := get_parent()
	while ancestor != null:
		if not ancestor.scene_file_path.is_empty():
			return ancestor
		ancestor = ancestor.get_parent()
	return get_tree().current_scene

func _place_art() -> void:
	var lines: Array = IDLE_GROUND if visual.animation == "active" else ACTIVATION_GROUND
	visual.position = Vector2(0, (627.0 - float(lines[visual.frame])) * art_scale)
	visual.reset_physics_interpolation()

func in_interaction_range(player: Node2D) -> bool:
	var offset := player.global_position - interaction.global_position
	return absf(offset.x) <= interaction.interaction_range.x and absf(offset.y) <= interaction.interaction_range.y

func can_interact(player: Node2D) -> bool:
	if activated or interaction_busy:
		return false
	var blocked: WeakRef = player.lantern_sequence.suppressed
	return blocked == null or blocked.get_ref() != self

func preview_interaction(player: Node2D) -> void:
	if can_interact(player):
		player.lantern_sequence.preview(self)

func interact(player: Node2D) -> void:
	if not can_interact(player):
		return
	preview_interaction(player)
	if player.lantern_sequence.phase != "waiting" or player.lantern_sequence.lantern != self:
		return
	interaction_busy = true
	player.lantern_sequence.confirm(self)

func ignite(player: Node2D) -> void:
	if activated or not interaction_busy or player.dead:
		return
	activated = true
	activation_playing = true
	activation_count += 1
	visual.play("activation", 1.0)
	visual.set_frame_and_progress(0, 0.0)
	_update_lighting()
	GameSession.activated_checkpoints[identifier] = true
	player.current_health = player.maximum_health
	player.health_updated.emit(player.current_health, player.maximum_health)
	var scene := _stage_scene()
	if scene != null and not scene.scene_file_path.is_empty():
		GameSession.set_checkpoint(scene.scene_file_path, global_position + Vector2(0, -15))
	GameSession.notify("A quiet promise. Moon Lantern lit.")
	AudioDirector.play_sfx("menu_confirm")

func _activation_finished() -> void:
	if visual.animation == "activation" and activated:
		activation_playing = false
		visual.play("active")

func end_interaction() -> void:
	interaction_busy = false
