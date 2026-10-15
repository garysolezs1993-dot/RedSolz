extends SceneTree

const HAZARD = preload("res://scripts/forest_hazard.gd")
const OUT := "res://docs/previews/stage1_hazards/"
var checks := 0
var failures := 0
var session: Node
var red: CharacterBody2D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func capture(label: String, where: Vector2) -> void:
	red.position = where
	red.reset_physics_interpolation()
	var camera := red.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	await frames(4)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "Capture " + label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_hazard_art.cfg"
	session.pending_spawn = false
	session.opening_arrival_pending = false
	session.opening_arrival_active = false
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	var stage := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	red = stage.get_node("Player")
	red.set_physics_process(false)
	red.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	red.get_node("Camera2D").physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for hazard in get_nodes_in_group("forest_hazards"):
		hazard.set_physics_process(false)
		check(hazard.art != null, str(hazard.name) + " has new artwork")
		var legacy := HAZARD.new()
		for property in ["kind", "width", "height", "damage", "warning_time", "rest_time", "active_time", "phase_offset", "fall_distance", "trigger_range"]:
			legacy.set(property, hazard.get(property))
		legacy.use_hazard_art = false
		legacy.position = Vector2(-10000, -10000)
		stage.add_child(legacy)
		legacy.set_physics_process(false)
		check(legacy.polygons == hazard.polygons, str(hazard.name) + " collision polygons unchanged")
		check(legacy.danger.collision_layer == hazard.danger.collision_layer and legacy.danger.collision_mask == hazard.danger.collision_mask, "Collision masks unchanged")
		for state in ["rest", "warning", "active", "recovery"]:
			for item in [legacy, hazard]:
				item.state = state
				item.elapsed = 1.0
				item.age = 0.35
				item.fall_offset = 32.0 if state == "active" else 0.0
				item._update_visual_and_collision()
			check(hazard.danger_enabled == legacy.danger_enabled and hazard.danger.transform == legacy.danger.transform, str(hazard.name) + " retains " + state + " damage/transform")
			red.current_health = 100
			red.invulnerable = 0.0
			red.call("_cancel_action")
			hazard._damage_body(red)
			check(red.current_health == (100 - hazard.damage if hazard.danger_enabled else 100), str(hazard.name) + " correct " + state + " damage")
		legacy.queue_free()
		hazard.state = "rest"
		hazard.age = 0.0
		hazard.fall_offset = 0.0
		hazard._update_visual_and_collision()
		if hazard.kind == 4:
			var resting := hazard.art.resting as Sprite2D
			var active := hazard.art.active.get_child(0) as Sprite2D
			check(resting.offset == active.offset and resting.scale == active.scale, "Root states share ground pivot and scale")
			check(resting.modulate.a == 1.0 and not hazard.art.active.visible, "Rest roots visible and safe")
			for strength in [0.05, 0.5, 1.0]:
				hazard.display_strength = strength
				hazard.art.update_art()
				check(is_equal_approx(hazard.art.active.scale.y, strength), "Root emergence matches collision height")
			hazard._update_visual_and_collision()
		if hazard.kind == 2:
			hazard.state = "active"
			hazard.fall_velocity = 0.0
			for index in range(120):
				hazard._run_branch(1.0 / 60.0)
				hazard.age += 1.0 / 60.0
			check(hazard.state == "rest" and hazard.fall_offset == 0.0, "Branch lands, recovers and resets")
			hazard._update_visual_and_collision()
	red.current_health = 100
	red.invulnerable = 10000.0
	red.call("_cancel_action")
	red.call("_play_visual", "idle")
	await capture("cellar_rest", Vector2(4700, 683))
	for hazard in get_nodes_in_group("forest_hazards"):
		if hazard.kind == 4:
			hazard.state = "active"
			hazard.age = 0.35
			hazard._update_visual_and_collision()
	await capture("cellar_active", Vector2(4700, 683))
	for hazard in get_nodes_in_group("forest_hazards"):
		if hazard.kind == 2:
			hazard.state = "warning"
			hazard._update_visual_and_collision()
		hazard.queue_redraw()
	await capture("creek_warning", Vector2(6120, 485))
	await capture("upper_ruins", Vector2(7260, 273))
	print("HAZARD ART: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
