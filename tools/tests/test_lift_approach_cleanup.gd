extends "res://tools/tests/test_stage1_routes.gd"

func on_surface(surface: float, body_name: String) -> void:
	var touches := false
	for index in range(player.get_slide_collision_count()):
		var body := player.get_slide_collision(index).get_collider()
		if is_instance_valid(body) and str(body.name) == body_name:
			touches = true
	check(player.is_on_floor() and absf(player.position.y + 15.0 - surface) < 3.0 and touches, "Land on " + body_name + " at y=" + str(surface))

func recovery_route() -> void:
	await place(Vector2(5400,845))
	on_surface(860,"ForestFloor_91")
	for target in [Vector2(5480,770),Vector2(5630,680),Vector2(5800,590),Vector2(5800,500)]:
		await hop(target)
		var body := "RootedLedge_6010" if target.y == 770 else ("RootedLedge_6011" if target.y == 680 else ("ForestFloor_92" if target.y == 590 else "ForestFloor_51"))
		on_surface(target.y,body)
	check(player.action_state == player.Action.NONE and not player.dead,"Recovery ends with control restored")

func capture_view(cleaned: bool) -> void:
	var packed := load(session.STAGE_ONE) as PackedScene
	var preview := packed.instantiate()
	preview.get_node("Stage1Layout").lift_approach_cleanup_enabled = cleaned
	root.add_child(preview)
	current_scene = preview
	await frames(8)
	var actor := preview.get_node("Player") as CharacterBody2D
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.position = Vector2(5480,755 if cleaned else 743)
	actor.velocity = Vector2.ZERO
	actor._play_visual("idle")
	actor.reset_physics_interpolation()
	var camera := actor.get_node("Camera2D") as Camera2D
	camera.position.y = 725 - actor.position.y
	camera.reset_smoothing()
	camera.force_update_scroll()
	preview.get_node("CrimsonPetals").set_process(false)
	preview.get_node("CrimsonPetals").hide()
	await frames(6)
	await RenderingServer.frame_post_draw
	var label := "after" if cleaned else "before"
	check(root.get_texture().get_image().save_png("res://docs/previews/lift_approach_" + label + ".png") == OK,"Capture " + label)
	preview.queue_free()
	await frames(3)

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_lift_approach.cfg"
	session.pending_spawn = false
	session.opening_arrival_pending = false
	session.stage_objectives = {}
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70,485)
	await capture_view(false)
	await capture_view(true)
	change_scene_to_file(session.STAGE_ONE)
	await frames(15)
	player = current_scene.get_node("Player")
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await frames(3)
	var layout := current_scene.get_node("Stage1Layout")
	var lift := layout.get_node("CellarReturnLift")
	var count := 0
	for node in layout.get_children():
		if str(node.name).begins_with("RootedLedge_") and node.position.x >= 5300 and node.position.x <= 5760 and node.position.y > 509:
			count += 1
	check(count == 2,"Exactly two staggered recovery ledges")
	check(not lift.unlocked,"Lift starts locked")
	await place(Vector2(5100,725))
	await frames(120)
	check(lift.position.is_equal_approx(lift.origin),"Locked lift stays at cellar floor")
	await recovery_route()
	# Fall from the surface east of the lift and recover safely again.
	await place(Vector2(5450,485))
	input_action("move_down",true)
	input_action("jump",true)
	await frames(3)
	input_action("jump",false)
	input_action("move_down",false)
	await frames(80)
	check(player.is_on_floor() and absf(player.position.y + 15 - 590) < 3,"Missed surface landing catches on lower bridge floor")
	await hop(Vector2(5450,500))
	on_surface(500,"ForestFloor_51")
	# Existing cellar exit remains available before the shortcut unlocks.
	await place(Vector2(3700,725))
	for target in [Vector2(3700,670),Vector2(3540,610),Vector2(3380,550),Vector2(3260,500)]:
		await hop(target)
	check(player.is_on_floor() and player.position.y < 500,"Western cellar exit remains usable with locked lift")
	session.complete_objective(session.STAGE_ONE,"oak_moon_seal")
	layout.get_node("StageObjectives").progress_changed.emit(2,3)
	check(lift.unlocked,"Seal progress unlocks lift")
	await place(Vector2(4950,725))
	for index in range(500):
		if lift.position.y > 730:
			break
		await frames(1)
	await walk(Vector2(5140,740))
	var rode := false
	for index in range(420):
		await frames(1)
		if player.position.y < 510:
			rode = true
			break
	check(rode,"Unlocked lift carries Red to upper landing")
	input_action("move_right",true)
	await frames(55)
	input_action("move_right",false)
	await frames(15)
	on_surface(500,"ForestFloor_51")
	await recovery_route()
	check(not paused and player.action_state == player.Action.NONE,"Both routes finish without paused or stuck states")
	print("LIFT APPROACH: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
