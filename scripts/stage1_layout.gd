extends Node2D

const WOLF_SCENE: PackedScene = preload("res://scenes/common_wolf.tscn")
const TERRAIN_SCRIPT: Script = preload("res://scripts/terrain_visual.gd")
const GATE_SCRIPT: Script = preload("res://scripts/stage_gate.gd")
const DEFINITION := preload("res://scripts/stage1_definition.gd")
const MAP_WIDTH := DEFINITION.WIDTH
const HAZARD_ROOT := "res://scenes/hazards/"
const CHECKPOINT_SCENE := preload("res://scenes/forest_checkpoint.tscn")
const REWARD_SCENE := preload("res://scenes/forest_reward.tscn")
const SEAL_SCENE := preload("res://scenes/moon_seal.tscn")
var build_offset := Vector2.ZERO
@export var platform_art_enabled := true
@export var environment_art_enabled := true
@export_group("White Lily Trail - First Seal Preview")
@export var lily_trail_enabled := true
@export_range(25, 60, 1) var lily_trail_spawn_distance := 32.0
@export_range(.2, 1, .05) var lily_trail_lifetime := .5
@export_range(.05, .5, .05) var lily_trail_fade_duration := .2
@export_range(.01, .15, .005) var lily_trail_scale := .085
@export_range(.05, .65, .05) var lily_trail_opacity := .28
const PLATFORM_ART := preload("res://scripts/forest_platform_art.gd")

func _ready() -> void:
	preload("res://scripts/stage1_hub_routes.gd").new().build(self)
	_add_encounters()
	_add_forest_challenges()
	_add_objectives()
	_add_stage_gate()
	var journey := Node2D.new()
	journey.name = "Stage1Journey"
	journey.set_script(preload("res://scripts/stage1_journey.gd"))
	add_child(journey)
	if environment_art_enabled:
		var dressing := Node2D.new()
		dressing.name = "Stage1EnvironmentArt"
		dressing.set_script(preload("res://scripts/stage1_environment_art.gd"))
		add_child(dressing)
	var player := get_parent().get_node_or_null("Player") as CharacterBody2D
	if player != null:
		var camera := player.get_node("Camera2D") as Camera2D
		camera.limit_right = int(MAP_WIDTH)
		camera.limit_top = -360
		camera.limit_bottom = 1120
	queue_redraw()

func _build_opening() -> void:
	for shelf in [[310, 470, 170], [460, 430, 180], [610, 470, 170], [780, 440, 200]]:
		_add_platform(shelf[0], shelf[1], shelf[2], 30, int(shelf[0]))
	# Jumping or waiting also works; dash is never mandatory.
	_add_challenge("DashPracticeRoots", "cursed_roots", Vector2(780, 500), {"width": 60.0, "warning_time": 1.1, "rest_time": 3.5, "damage": 6})

func _add_encounters() -> void:
	for marker in DEFINITION.ENCOUNTERS:
		var wolf := WOLF_SCENE.instantiate() as CharacterBody2D
		wolf.name = str(marker[0])
		wolf.position = Vector2(marker[1], marker[2])
		wolf.set("attack_warning_duration", .35 if str(marker[0]) == "LoneWolf" else .3)
		wolf.set("attack_recovery_duration", .85 if str(marker[0]) == "LoneWolf" else .7)
		wolf.set("leash_radius", 170.0 if not str(marker[5]).is_empty() else (280.0 if not bool(marker[3]) else 220.0))
		wolf.set("random_leaps_enabled", bool(marker[4]))
		wolf.set("leap_interval", Vector2(5, 8))
		wolf.set("jump_retry_interval", Vector2(1.6, 2.4))
		wolf.set("encounter_pack", str(marker[5]))
		wolf.set("pack_attack_delay", .45 if str(marker[0]) in ["HeartwoodB", "BurialWolf"] else 0.0)
		if not str(marker[5]).is_empty():
			wolf.set("attack_warning_duration", .4 if str(marker[5]) == "cellar_guardians" else .35)
			wolf.set("attack_recovery_duration", .85 if str(marker[5]) == "cellar_guardians" else .75)
		# Completed guard encounters stay cleared on retry/continue.
		var cleared := false
		for seal_id in DEFINITION.SEAL_GUARDS:
			if DEFINITION.SEAL_GUARDS[seal_id].has(str(marker[0])) and GameSession.objective_completed("res://scenes/main.tscn", seal_id):
				cleared = true
		if cleared:
			wolf.free()
			continue
		# Red's locked combo should not knock its small target beyond hit 2/3.
		wolf.set("melee_knockback_scale", .25)
		wolf.set_meta("optional_encounter", bool(marker[3]))
		add_child(wolf)

func _add_collision_box(node_name: String, box_position: Vector2, box_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = box_position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_stage_gate() -> void:
	var gate := Node2D.new()
	gate.name = "StageTwoGate"
	gate.position = DEFINITION.GATE_POSITION
	gate.set_script(GATE_SCRIPT)
	gate.set("next_scene_path", "res://scenes/stage2_boss.tscn")
	gate.set("objective_manager_path", NodePath("../StageObjectives"))
	add_child(gate)
	var guide := Node2D.new()
	guide.name = "MoonWispGuide"
	guide.set_script(preload("res://scripts/moon_wisp_guide.gd"))
	for property: String in ["lily_trail_enabled", "lily_trail_spawn_distance", "lily_trail_lifetime", "lily_trail_fade_duration", "lily_trail_scale", "lily_trail_opacity"]:
		guide.set(property, get(property))
	add_child(guide)

func _add_objectives() -> void:
	var objectives := Node2D.new()
	objectives.name = "StageObjectives"
	objectives.set_script(preload("res://scripts/stage_objective_manager.gd"))
	var ids: Array[String] = []
	for marker in DEFINITION.SEALS:
		ids.append(str(marker[0]))
	objectives.set("required_seal_ids", ids)
	add_child(objectives)
	for marker in DEFINITION.SEALS:
		var seal := SEAL_SCENE.instantiate() as Node2D
		seal.name = str(marker[0])
		seal.position = marker[1]
		seal.set("identifier", str(marker[0]))
		seal.set("region_name", str(marker[2]))
		seal.set("full_cinematic", str(marker[0]) == "camp_moon_seal")
		if str(marker[0]) == "camp_moon_seal":
			seal.guide_route.assign(DEFINITION.FIRST_WISP_ROUTE)
		elif str(marker[0]) == "heartwood_moon_seal":
			seal.guide_route.assign([Vector2(8520, 208), Vector2(8710, 308), Vector2(8950, 428)])
		var guards: Array[String] = []
		for guard in DEFINITION.SEAL_GUARDS[str(marker[0])]:
			guards.append(str(guard))
		seal.set("guard_names", guards)
		add_child(seal)

func _add_ground(center_x: float, surface_y: float, width: float, depth: float, variant: int, can_drop: bool = false) -> void:
	var body := StaticBody2D.new()
	body.name = "ForestFloor_%02d" % variant
	if can_drop:
		body.add_to_group("drop_through_platform")
	body.position = Vector2(center_x, surface_y + depth * 0.5) + build_offset
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, depth)
	collision.shape = shape
	# Main paths can be reached from beneath; the lowest catch floor stays solid.
	collision.one_way_collision = variant != 91
	collision.one_way_collision_margin = 8.0
	body.add_child(collision)
	var visual := Node2D.new()
	visual.name = "MossAndStoneVisual"
	visual.set_script(TERRAIN_SCRIPT)
	visual.set("dimensions", Vector2(width, depth))
	visual.set("variant", variant)
	visual.set("surface_y", -depth * 0.5)
	body.add_child(visual)
	_apply_platform_art(body, visual, center_x + build_offset.x, surface_y + build_offset.y, width, depth, variant, -depth * .5)
	add_child(body)

func _add_platform(center_x: float, surface_y: float, width: float, depth: float, variant: int) -> void:
	var body := StaticBody2D.new()
	body.name = "RootedLedge_%02d" % variant
	body.position = Vector2(center_x, surface_y + 9.0) + build_offset
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 18.0)
	collision.shape = shape
	# Ledges are top-only: Red can jump up through them instead of hitting a wall.
	collision.one_way_collision = true
	collision.one_way_collision_margin = 8.0
	body.add_child(collision)
	var visual := Node2D.new()
	visual.name = "UnevenRockVisual"
	visual.set_script(TERRAIN_SCRIPT)
	visual.set("dimensions", Vector2(width, depth))
	visual.set("variant", variant)
	visual.set("surface_y", -9.0)
	body.add_child(visual)
	_apply_platform_art(body, visual, center_x + build_offset.x, surface_y + build_offset.y, width, depth, variant, -9.0)
	add_child(body)

func _apply_platform_art(body: StaticBody2D, legacy: Node2D, center_x: float, top_y: float, width: float, depth: float, variant: int, local_surface: float) -> void:
	if not platform_art_enabled:
		return
	legacy.hide()
	var left := center_x - width * .5
	var right := center_x + width * .5
	var cuts: Array[float] = [left]
	# Split only the artwork when one collider spans several named areas.
	for boundary in PLATFORM_ART.AREA_BOUNDARIES:
		if boundary > left + 150 and boundary < right - 150:
			cuts.append(boundary)
	cuts.append(right)
	for index in range(cuts.size() - 1):
		var segment_left := cuts[index]
		var segment_right := cuts[index + 1]
		var segment_center := (segment_left + segment_right) * .5
		var art := Node2D.new()
		art.name = "GothicPlatformArt" if index == 0 else "GothicPlatformArt_%d" % index
		art.set_script(PLATFORM_ART)
		art.set("dimensions", Vector2(segment_right - segment_left, depth))
		art.set("surface_y", local_surface)
		art.set("variant", variant + index)
		art.set("area_style", PLATFORM_ART.style_at(segment_center, top_y))
		art.set("compact_surface", top_y > 500)
		art.position.x = segment_center - center_x
		body.add_child(art)

func _add_forest_challenges() -> void:
	for marker in DEFINITION.CHECKPOINTS:
		var x: float = marker[1]
		var checkpoint := CHECKPOINT_SCENE.instantiate() as Node2D
		checkpoint.position = Vector2(x, 500)
		checkpoint.name = "Promise_" + str(marker[0]).trim_prefix("forest_")
		checkpoint.set("identifier", str(marker[0]))
		add_child(checkpoint)
	for marker in DEFINITION.REWARDS:
		var reward := REWARD_SCENE.instantiate() as Node2D
		reward.position = marker[1]
		reward.set("identifier", marker[0])
		add_child(reward)

func exploration_status(where: Vector2) -> String:
	var region := "Quiet Forest Entrance"
	if where.x >= 8900:
		region = "Moon Gate Approach"
	elif where.x >= 8000:
		region = "Upper Sanctuary" if where.y < 250 else "Heartwood Clearing"
	elif where.x >= 6400:
		region = "Optional Burial Ruins" if where.y > 550 else ("Upper Forest Ruins" if where.y < 350 else "Burial Trail")
	elif where.x >= 5400:
		region = "Ruined Bridge / Winding Creek"
	elif where.x >= 3330 and where.y > 550:
		region = "Root Cellar"
	elif where.x >= 3000 and where.x <= 4400 and where.y < 350:
		region = "Broken Chapel"
	elif where.x >= 3500:
		region = "Hollow Oak Canopy" if where.y < 350 else "Hollow Oak Trail"
	elif where.x >= 2700:
		region = "Forest Crossroads"
	elif where.x >= 2300:
		region = "Abandoned Camp"
	elif where.x >= 1250:
		region = "Lone Wolf Clearing"
	elif where.x >= 640:
		region = "Fallen Root Crossing"
	var discovered := 0
	for reward in DEFINITION.REWARDS:
		if GameSession.collected_petals.has(str(reward[0])):
			discovered += 1
	return "%s   |   Moon petals %d/%d" % [region, discovered, DEFINITION.REWARDS.size()]

func _add_challenge(node_name: String, scene_name: String, spawn: Vector2, properties: Dictionary) -> void:
	var packed := load(HAZARD_ROOT + scene_name + ".tscn") as PackedScene
	var challenge := packed.instantiate() as Node2D
	challenge.name = node_name
	challenge.position = spawn + build_offset
	for property in properties:
		challenge.set(property, properties[property])
	if scene_name in ["moving_platform", "crumbling_platform"]:
		challenge.set("use_gothic_art", platform_art_enabled)
		challenge.set("art_area_style", PLATFORM_ART.style_at(challenge.position.x, challenge.position.y))
	add_child(challenge)

func _draw() -> void:
	# Scenery has no collision and no permanent control instructions.
	if environment_art_enabled:
		_draw_gate_story_token()
		return
	draw_set_transform(Vector2(160, -288))
	for x in [3660.0, 3890.0, 4060.0, 4230.0]:
		draw_rect(Rect2(x, 335, 22, 165), Color("302d39"))
		draw_rect(Rect2(x - 5, 329, 32, 10), Color("49414b"))
	draw_line(Vector2(3670, 336), Vector2(3780, 244), Color("393542"), 14)
	draw_line(Vector2(3780, 244), Vector2(3900, 336), Color("393542"), 14)
	draw_set_transform(Vector2.ZERO)
	# Empty camp, claw marks, and cold fire remnants.
	draw_rect(Rect2(2490, 477, 32, 23), Color("594035"))
	for offset in range(3):
		draw_line(Vector2(2495 + offset * 8, 480), Vector2(2491 + offset * 8, 492), Color("aa7c70"), 2)
	draw_line(Vector2(2360, 498), Vector2(2390, 468), Color("47342e"), 4)
	draw_line(Vector2(2390, 468), Vector2(2420, 498), Color("47342e"), 4)
	for x in [2380.0, 2400.0]:
		draw_line(Vector2(x - 8, 494), Vector2(x + 10, 498), Color("392c34"), 4)
	_draw_gate_story_token()

func _draw_gate_story_token() -> void:
	# Abandoned scarf and a pale flower quietly echo the cursed guardian.
	draw_rect(Rect2(9200, 496, 25, 3), Color("6b273d"))
	for petal in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		draw_rect(Rect2(Vector2(9210, 491) + petal, Vector2(2, 2)), Color("d5cbc7"))
