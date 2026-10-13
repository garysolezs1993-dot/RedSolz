extends SceneTree

# Compare the real scene with and without visual dressing; isolated user save.
var player: CharacterBody2D
var checks := 0
var failures := 0
var images: Dictionary = {}
var capture_enabled := false
var art_count := 0
var area_styles := {}
var used_textures := {}
var invalid_art := []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(name: String) -> void:
	action(name, true)
	await frames(3)
	action(name, false)
	await frames(2)

func place(where: Vector2) -> void:
	for name in ["attack", "dash", "jump", "move_right", "move_left", "move_up", "move_down"]:
		action(name, false)
	player._cancel_action()
	player.position = where
	player.velocity = Vector2.ZERO
	player.invulnerable = 1000
	player.cooldown = 0
	player.dash_cooldown_remaining = 0
	player.reset_physics_interpolation()
	await frames(8)

func spawn(art: bool) -> void:
	var session := root.get_node("GameSession")
	session.pending_spawn = false
	session.checkpoint_scene = ""
	session.activated_checkpoints.clear()
	session.learned_mechanics.clear()
	session.collected_petals.clear()
	var stage := load("res://scenes/main.tscn").instantiate() as Node2D
	stage.get_node("Stage1Layout").platform_art_enabled = art
	root.add_child(stage)
	current_scene = stage
	# Manual instantiation selects current_scene after _ready; mirror the HUD
	# setup that normal change_scene_to_file performs with Main already selected.
	stage.get_node("UI/HUD/Controls").hide()
	var hud := stage.get_node("UI")
	if hud.exploration_label == null:
		hud._add_boss_test_button()
		hud._add_exploration_label()
	await frames(15)
	player = stage.get_node("Player")

func collision_snapshot(node: Node, output: Dictionary) -> void:
	if node is CollisionShape2D and (node.get_parent() is StaticBody2D or node.get_parent() is AnimatableBody2D):
		var size: Vector2 = node.shape.size if node.shape is RectangleShape2D else Vector2.ZERO
		var body := node.get_parent() as Node2D
		var origin: Vector2 = body.origin if body is AnimatableBody2D else body.global_position
		var key := body.get_class() + str(origin) + ":shape" + str(node.get_index())
		output[key] = [node.position, size, node.one_way_collision, node.one_way_collision_margin, node.disabled]
	if node is StaticBody2D or node is AnimatableBody2D:
		# Moving platforms' live phase and wolves' randomized patrols aren't
		# authored terrain changes. Compare platform origins and local shapes.
		var origin: Vector2 = node.origin if node is AnimatableBody2D else node.global_position
		output[node.get_class() + str(origin) + ":body"] = [origin, node.collision_layer, node.collision_mask]
	for child in node.get_children():
		collision_snapshot(child, output)

func review_art(node: Node) -> void:
	if str(node.name).begins_with("GothicPlatformArt"):
		art_count += 1
		area_styles[node.area_style] = true
		if not node.get_meta("visual_only", false) or node.get_child_count() == 0:
			invalid_art.append(str(node.get_path()))
		for child in node.get_children():
			if child is CollisionObject2D or child is CollisionShape2D:
				invalid_art.append("Dressing collision: " + str(child.get_path()))
			if child is Sprite2D:
				used_textures[child.texture.resource_path] = true
				if child.scale.x != child.scale.y or child.region_enabled or child.scale.x < .15 or child.scale.x > .95:
					invalid_art.append("Distorted/cropped/excessive scale: " + str(child.get_path()))
		var body := node.get_parent() as Node2D
		var collider := body.get_child(0) as CollisionShape2D
		if collider != null:
			var expected_top: float = collider.position.y - collider.shape.size.y * .5
			if absf(node.surface_y - expected_top) > .01:
				invalid_art.append("Surface misalignment: " + str(node.get_path()))
	if node is StaticBody2D and (str(node.name).begins_with("ForestFloor") or str(node.name).begins_with("RootedLedge")):
		if node.get_node_or_null("GothicPlatformArt") == null:
			invalid_art.append("Undressed surface: " + str(node.get_path()))
	if node is AnimatableBody2D and node.is_in_group("forest_platforms"):
		if not node.use_gothic_art:
			invalid_art.append("Undressed moving/crumbling platform: " + str(node.get_path()))
	for child in node.get_children():
		review_art(child)

func capture(label: String) -> void:
	if not capture_enabled:
		return
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await frames(3)
	await RenderingServer.frame_post_draw
	images[label] = root.get_texture().get_image()

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_platform_art_sample.cfg"
	capture_enabled = OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	check(str(root.get_node("GameSession").save_path).contains("presentation_test"), "Real journey save is isolated")
	await spawn(false)
	var old_collision := {}
	collision_snapshot(current_scene.get_node("Stage1Layout"), old_collision)
	await place(Vector2(200, 485))
	await capture("entrance_before")
	current_scene.queue_free()
	await frames(4)
	await spawn(true)
	var new_collision := {}
	collision_snapshot(current_scene.get_node("Stage1Layout"), new_collision)
	if old_collision != new_collision:
		for key in old_collision:
			if not new_collision.has(key) or old_collision[key] != new_collision[key]:
				print("COLLISION DIFFERENCE: ", key, " before=", old_collision[key], " after=", new_collision.get(key))
	check(old_collision == new_collision, "Every Stage 1 terrain collider, origin, layer and one-way setting is unchanged")
	check(player.get_node("Camera2D").zoom == Vector2(1.35, 1.35), "Gameplay camera retains 1.35 zoom")
	review_art(current_scene.get_node("Stage1Layout"))
	check(invalid_art.is_empty(), "Every surface uses whole, uniformly scaled, collision-free art on its original ground line: " + str(invalid_art))
	check(art_count >= 100, "All Stage 1 fixed, moving, crumbling and safety surfaces are dressed (%d helpers)" % art_count)
	check(area_styles.size() == 9, "Entrance, camp, chapel, creek, Oak, Cellar, burial, Heartwood and gate have area profiles")
	check(used_textures.size() >= 20, "Reusable kit varies platform and decoration assets (%d textures)" % used_textures.size())
	for path in used_textures:
		check(not path.contains("separated_ledge_pair"), "No neighboring ledges in runtime asset: " + path.get_file())
	await place(Vector2(200, 485))
	await capture("entrance_after")
	action("move_right", true)
	await frames(110)
	action("move_right", false)
	check(player.position.x > 470 and player.is_on_floor() and absf(player.position.y - 485) < 1, "Red walks across the dressed floor without snagging or falling")
	await place(Vector2(210, 485))
	action("move_right", true)
	await tap("jump")
	await frames(33)
	action("move_right", false)
	await frames(25)
	check(player.is_on_floor() and player.position.y <= 455.1 and player.position.x > 280, "Normal jump reaches the original raised ledge")
	await capture("entrance_ledge")
	await place(Vector2(100, 485))
	await tap("dash")
	await frames(14)
	check(player.position.x > 145 and player.is_on_floor(), "Dash crosses the dressed surface")
	await place(Vector2(460, 415))
	action("move_up", true)
	await tap("attack")
	action("move_up", false)
	await frames(16)
	check(player.velocity.y < 0 and player.position.y < 400, "Rising Slash passes through decorative roots")
	await tap("attack")
	check(player.air_combo_step == 1, "Rising Slash can still launch into air combat")
	await frames(15)
	action("move_down", true)
	await tap("attack")
	action("move_down", false)
	await frames(85)
	check(player.is_on_floor() and player.action_state == player.Action.NONE, "Downward Slash lands and exits its state on the dressed ledge")
	await place(Vector2(200, 575))
	action("move_right", true)
	await frames(65)
	action("move_right", false)
	check(player.position.x > 340 and player.is_on_floor() and player.position.y < 610, "Lower safety route remains walkable")
	for name in images:
		images[name].save_png("res://.godot/platform_kit_review/" + name + ".png")
	print("PLATFORM ART FULL STAGE: ", checks, " checks, ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(0 if failures == 0 else 1)

