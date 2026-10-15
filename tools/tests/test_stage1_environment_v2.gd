extends SceneTree

const OUT := "res://docs/previews/stage1_environment_v2/"
const SCENE_PATH := "res://scenes/main.tscn"
var checks := 0
var failures := 0
var red: CharacterBody2D
var layout: Node2D
var session: Node
var physics_reference: Array[String] = []
var used_sources: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func stable_path(node: Node) -> String:
	var parts: Array[String] = []
	var cursor := node
	while cursor != layout:
		var part := str(cursor.name)
		if part.begins_with("@"):
			part = "%s[%d]" % [cursor.get_class(), cursor.get_index()]
		parts.push_front(part)
		cursor = cursor.get_parent()
	return "/".join(parts)

func physics_signature(node: Node, result: Array[String]) -> void:
	if node is CollisionShape2D:
		var shape := node as CollisionShape2D
		var size := str(shape.shape.size) if shape.shape is RectangleShape2D else str(shape.shape.get_class())
		result.append("%s:%s:%s:%s:%s:%s" % [stable_path(shape), shape.transform, size, shape.disabled, shape.one_way_collision, shape.one_way_collision_margin])
	if node is CollisionObject2D:
		result.append("%s:%s:%s:%s" % [stable_path(node), node.get_class(), node.collision_layer, node.collision_mask])
	if node is StaticBody2D:
		result.append("%s:%s" % [stable_path(node), node.transform])
	if node is AnimatableBody2D:
		result.append("%s:%s:%s:%s:%s" % [stable_path(node), node.get("origin"), node.get("travel"), node.get("width"), node.get("period")])
	for child in node.get_children():
		physics_signature(child, result)

func inspect_sprites(node: Node) -> void:
	check(not node is CollisionObject2D and not node is CollisionShape2D, str(node.name) + " remains decorative")
	if node is Sprite2D:
		check(node.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, str(node.name) + " uses nearest filtering")
		check(is_equal_approx(absf(node.scale.x), absf(node.scale.y)), str(node.name) + " uses uniform scale")
		if node.has_meta("source_file"):
			used_sources[node.get_meta("source_file")] = true
		elif node.texture is AtlasTexture:
			used_sources[(node.texture as AtlasTexture).atlas.resource_path.get_file()] = true
	for child in node.get_children():
		inspect_sprites(child)

func setup(use_kit: bool) -> void:
	session.pending_spawn = false
	session.opening_arrival_pending = false
	session.opening_arrival_active = false
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.learned_mechanics.clear()
	session.collected_petals.clear()
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	# Load after autoloads enter the tree; preloading from SceneTree's script
	# would compile player scripts before their GameSession singleton exists.
	var packed := load(SCENE_PATH) as PackedScene
	var stage := packed.instantiate()
	stage.get_node("Stage1Layout").set("environment_art_enabled", use_kit)
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	red = stage.get_node("Player")
	red.set_physics_process(false)
	red.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	red.get_node("Camera2D").physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	red.invulnerable = 10000.0
	layout = stage.get_node("Stage1Layout")
	layout.get_node("MoonWispGuide").set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for platform in get_nodes_in_group("forest_platforms"):
		platform.set_physics_process(false)
		platform.position = platform.origin
		platform.reset_physics_interpolation()
	await frames(2)

func capture(name: String, where: Vector2, offset := Vector2.ZERO) -> void:
	red.call("_cancel_action")
	red.call("_play_visual", "idle")
	red.position = where
	red.velocity = Vector2.ZERO
	red.reset_physics_interpolation()
	var camera := red.get_node("Camera2D") as Camera2D
	camera.offset = offset
	camera.reset_smoothing()
	camera.force_update_scroll()
	await frames(10)
	await RenderingServer.frame_post_draw
	if name.begins_with("lift_"):
		print("LIFT_CAPTURE_POSE ", name, " requested=", where, " actual=", red.global_position, " visual=", red.get_node("Visual").global_position, " camera=", root.get_camera_2d().get_screen_center_position())
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Captured " + name)
	camera.offset = Vector2.ZERO

func captures(suffix: String) -> void:
	for entry in [
		["chapel", Vector2(3870, 149)],
		["camp", Vector2(2490, 485)],
		["hollow_oak", Vector2(4310, 485)],
		["hollow_entrance", Vector2(3380, 535)],
		["cellar", Vector2(4310, 725)],
		["bridge", Vector2(5600, 409)],
		["burial", Vector2(7120, 665)],
		["upper_ruins", Vector2(7510, 219)],
		["sanctuary", Vector2(8120, 111)],
		["heartwood", Vector2(8430, 485)],
	]:
		await capture(str(entry[0]) + suffix, entry[1])
	var lift := layout.get_node("CellarReturnLift") as AnimatableBody2D
	var review_camera := Camera2D.new()
	review_camera.name = "LiftReviewCamera"
	review_camera.position = Vector2(5140, 620)
	review_camera.zoom = Vector2(1.35, 1.35)
	review_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	current_scene.add_child(review_camera)
	review_camera.make_current()
	for fraction in [0.0, .5, 1.0]:
		var desired_position: Vector2 = lift.origin + lift.travel * fraction
		lift.position = desired_position
		lift.reset_physics_interpolation()
		# AnimatableBody2D applies manual transforms at its next physics sync.
		await frames(2)
		check(lift.position.is_equal_approx(desired_position), "Lift capture reaches requested fraction " + str(fraction))
		await capture("lift_%d%s" % [roundi(fraction * 100), suffix], desired_position + Vector2(0, -15))
	red.get_node("Camera2D").make_current()
	review_camera.queue_free()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_stage1_environment_v2.cfg"
	await setup(false)
	physics_signature(layout, physics_reference)
	physics_reference.sort()
	await captures("_before")
	current_scene.queue_free()
	await frames(4)
	await setup(true)
	var after: Array[String] = []
	physics_signature(layout, after)
	after.sort()
	check(after == physics_reference, "All Stage 1 collision shapes, masks, static bodies and moving-platform parameters match the legacy layout")
	if after != physics_reference:
		var shown := 0
		for entry in after:
			if not physics_reference.has(entry) and shown < 8:
				print("PHYSICS_NEW: ", entry)
				shown += 1
		shown = 0
		for entry in physics_reference:
			if not after.has(entry) and shown < 8:
				print("PHYSICS_OLD: ", entry)
				shown += 1
	var art := layout.get_node("Stage1EnvironmentArt")
	inspect_sprites(art)
	var lift := layout.get_node("CellarReturnLift")
	var lift_art := lift.get_node("CellarLiftArt")
	inspect_sprites(lift_art)
	var rig := layout.get_node("CellarLiftFixedRig")
	inspect_sprites(rig)
	inspect_sprites(layout.get_node("RootedLedge_610/V2RuinSurface"))
	inspect_sprites(layout.get_node("RootedLedge_611/V2RuinSurface"))
	check(rig.get_parent() == layout, "Lift mechanism stays outside the moving body")
	check(lift_art.deck.get_parent() == lift_art, "Only deck is attached to the moving platform")
	check(used_sources.size() == 37, "All 37 supplied v2 assets are represented")
	check(art.z_index < 0 and rig.z_index < 0 and lift_art.z_index < 0, "Dressing and lift art stay behind Red")
	check(art.get_node("CampSupplyCrates").region_rect.end.y == 230 and art.get_node("CampStool").region_rect.end.y == 230, "Camp export strips are excluded only by sprite regions")
	await captures("_after")
	var rig_position: Vector2 = rig.global_position
	for fraction in [0.0, .5, 1.0]:
		lift.position = lift.origin + lift.travel * fraction
		lift.reset_physics_interpolation()
		await frames(5)
		await process_frame
		await RenderingServer.frame_post_draw
		check(rig.global_position == rig_position, "Fixed rig stays stationary at lift fraction " + str(fraction))
		var last_bottom := 0.0
		for index in range(8):
			var chain: Sprite2D = lift_art.chain_sprites[index]
			if not chain.visible:
				continue
			var region := (chain.texture as AtlasTexture).region
			if index > 0:
				check(chain.position.y <= last_bottom + .1, "Chain sections overlap without gaps")
			last_bottom = chain.position.y + region.size.y * chain.scale.y
		check(absf(rig.global_position.y + last_bottom - lift.global_position.y - 2.0) < 1.0, "Chain ends connect to moving deck")
		check(last_bottom > 40.0, "Chains retain length at every stop")
	print("ENVIRONMENT V2 RESULT: ", checks, " checks; ", failures, " failures")
	var output := FileAccess.open(OUT + "test_result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "sources": used_sources.keys(), "collision_entries": after.size()}, "\t"))
	current_scene.queue_free()
	await frames(4)
	quit(0 if failures == 0 else 1)
