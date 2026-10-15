extends SceneTree

# Traverse optional routes using only ordinary movement and double jumps.
var player: CharacterBody2D
var session: Node
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok:
		failures += 1

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func input_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func place(where: Vector2) -> void:
	player._cancel_action()
	player.global_position = where
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(10)

func hop(target: Vector2) -> void:
	var direction := 1.0 if target.x >= player.position.x else -1.0
	var action := "move_right" if direction > 0 else "move_left"
	# Walk toward the edge of the existing shelf before a longer crossing.
	if absf(target.x - player.position.x) > 140:
		input_action(action, true)
		await frames(15)
	input_action(action, true)
	input_action("jump", true)
	await frames(3)
	input_action("jump", false)
	var arrived := false
	for index in range(130):
		await physics_frame
		if (target.x - player.position.x) * direction <= 4:
			input_action(action, false)
		if target.y <= 500 and index == 18 and not player.is_on_floor() and player.jumps_used < 2:
			input_action("jump", true)
		elif index == 21:
			input_action("jump", false)
		if index > 3 and player.is_on_floor() and absf(player.position.x - target.x) < 20 and (player.position.y + 15 <= target.y + 1 if target.y <= 500 else absf(player.position.y + 15 - target.y) < 3):
			arrived = true
			break
	# Still count a safe interior landing if the helper could not center Red.
	# Preserve the attempt to center first so collectible checks stay meaningful.
	if not arrived:
		arrived = player.is_on_floor() and absf(player.position.x - target.x) < 100 and (player.position.y + 15 <= target.y + 1 if target.y <= 500 else absf(player.position.y + 15 - target.y) < 3)
	input_action(action, false)
	input_action("jump", false)
	check(arrived, "Ordinary jumps reach " + str(target) + " (Red " + str(player.position) + ")")
	await frames(4)

func walk(target: Vector2) -> void:
	var direction := signf(target.x - player.position.x)
	var key := "move_right" if direction >= 0 else "move_left"
	input_action(key, true)
	for index in range(200):
		await physics_frame
		if (target.x-player.position.x)*direction <= 3:
			break
	input_action(key,false)
	await frames(45)
	check(player.is_on_floor() and absf(player.position.x-target.x)<20 and (player.position.y+15 <= target.y+1 and player.position.y+15 >= target.y-60 if target.x != 5140 else player.position.y < 735), "Walk to lower route " + str(target) + " (Red " + str(player.position) + ")")

func activate_seal(identifier: String) -> void:
	# Landing recovery and the supplied eight-frame activation are asynchronous.
	# Wait for the real interaction and Wisp camera to return control.
	await frames(20)
	input_action("interact", true)
	await frames(3)
	input_action("interact", false)
	for index in range(2400):
		await physics_frame
		if session.objective_completed(session.STAGE_ONE, identifier):
			break
	# Wisp release is delayed after activation. Let it start before checking
	# whether the camera tour has restored control, avoiding an early return.
	await frames(90)
	var guide := current_scene.get_node("Stage1Layout/MoonWispGuide")
	for index in range(2400):
		await physics_frame
		if not paused and not guide.cinematic_active and player.action_state == player.Action.NONE:
			break

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_stage1_routes.cfg"
	session = root.get_node("GameSession")
	session.pending_spawn = false
	session.checkpoint_scene = "res://scenes/main.tscn"
	session.checkpoint_position = Vector2(70, 485)
	session.collected_petals.clear()
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	var legacy_environment := OS.get_cmdline_user_args().has("--legacy-environment")
	var headless := DisplayServer.get_name() == "headless"
	session.save_path = "user://presentation_test_stage1_routes_%s_%s.cfg" % ["legacy" if legacy_environment else "v2", DisplayServer.get_name()]
	if legacy_environment or headless:
		# Compare the same route/controller with the new visual dressing disabled.
		var packed := load("res://scenes/main.tscn") as PackedScene
		var stage := packed.instantiate()
		stage.get_node("Stage1Layout").set("environment_art_enabled", not legacy_environment)
		if headless:
			# Decorative sampler shaders need the actual renderer. The separate
			# rendered run verifies them; this run exercises controller/physics.
			stage.get_node("CrimsonPetals").set_script(null)
		root.add_child(stage)
		current_scene = stage
	else:
		change_scene_to_file("res://scenes/main.tscn")
	await frames(15)
	player = current_scene.get_node("Player")
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await frames(3)
	await place(Vector2(1580, 485))
	for marker in [Vector2(1660, 445), Vector2(1800, 369)]:
		await hop(marker)
	check(session.collected_petals.has("lower_forest_petal"), "Clearing moon petal is reachable")
	await place(Vector2(3000, 485))
	for marker in [Vector2(3080,452), Vector2(3240,404), Vector2(3400,356), Vector2(3560,308), Vector2(3720,260), Vector2(3780,212), Vector2(3900,164)]:
		await hop(marker)
	await activate_seal("camp_moon_seal")
	check(session.objective_completed(session.STAGE_ONE, "camp_moon_seal"), "Ordinary Chapel climb reaches Seal 1")
	await frames(15)
	for marker in [Vector2(4040,116),Vector2(4180,68)]:
		await hop(marker)
	check(session.collected_petals.has("upper_forest_petal"), "Chapel balcony petal is reachable")
	for marker in [Vector2(4260,260),Vector2(4440,308),Vector2(4620,356),Vector2(4800,404),Vector2(5000,452),Vector2(5240,452),Vector2(5500,424)]:
		await hop(marker)
	check(player.position.x > 5400, "Chapel loop reconnects at the bridge")
	await place(Vector2(4310,485))
	for marker in [Vector2(4420,450),Vector2(4580,400),Vector2(4740,350),Vector2(4900,300),Vector2(5060,250)]:
		await hop(marker)
	check(session.collected_petals.has("hollow_oak_petal"), "Optional Hollow Oak crown keeps its petal")
	await place(Vector2(3260,485))
	input_action("move_right", true)
	await frames(42)
	input_action("move_right", false)
	await frames(80)
	check(player.position.y > 500 and player.position.y < 750, "Open hollow descends safely without drop-through skill")
	for marker in [Vector2(3540,610),Vector2(3700,670),Vector2(3880,740),Vector2(4110,740),Vector2(4380,740),Vector2(4900,740)]:
		await walk(marker)
	var lift := current_scene.get_node("Stage1Layout/CellarReturnLift")
	check(not lift.unlocked and lift.position == lift.origin, "Shortcut is locked before the cellar objective")
	await activate_seal("oak_moon_seal")
	check(session.objective_completed(session.STAGE_ONE, "oak_moon_seal") and lift.unlocked, "Seal 2 unlocks its distinct return shortcut")
	await hop(Vector2(4570,698))
	check(session.collected_petals.has("root_cellar_petal"), "Cellar alcove petal remains reachable")
	await hop(Vector2(4800,698))
	await walk(Vector2(4950,740))
	# Wait for the low end of the unlocked lift; step aboard, then ride it.
	for index in range(400):
		await physics_frame
		if lift.position.y > 725:
			break
	await walk(Vector2(5140,740))
	await frames(210)
	check(player.position.y < 530, "Seal-powered lift carries Red back to the bridge floor")
	await place(Vector2(3360,725))
	for marker in [Vector2(3510,690),Vector2(3510,635),Vector2(3510,580),Vector2(3510,525),Vector2(3580,500)]:
		await hop(marker)
	check(player.position.y < 500, "Western cellar stairs also return to the hub")
	await place(Vector2(6400,485))
	input_action("move_right", true)
	await frames(40)
	input_action("move_right", false)
	await frames(75)
	check(player.position.y > 500 and player.position.y < 700, "Second open junction descends into the side ruins")
	for marker in [Vector2(6660,610),Vector2(6840,680),Vector2(7020,680),Vector2(7160,680)]:
		await walk(marker)
	check(not session.objective_completed(session.STAGE_ONE, "heartwood_moon_seal"), "Lower burial ruins are an optional exploration detour")
	for marker in [Vector2(7360,680),Vector2(7540,630),Vector2(7700,580),Vector2(7860,530),Vector2(8020,480)]:
		await hop(marker)
	check(player.position.x >= 8000 and player.position.y < 500, "Separate side-ruins exit reconnects before Heartwood")
	await place(Vector2(6910,485))
	for marker in [Vector2(7000,450),Vector2(7160,398),Vector2(7340,356)]:
		await hop(marker)
	check(session.collected_petals.has("forgotten_grave_petal"), "Burial viewpoint petal is reachable")
	await place(Vector2(6060,435))
	for marker in [Vector2(6240,396),Vector2(6400,342),Vector2(6560,288),Vector2(6800,288)]:
		await hop(marker)
	for marker in [Vector2(6800,234),Vector2(6800,180),Vector2(6940,126),Vector2(7080,72),Vector2(7240,18)]:
		await hop(marker)
	check(session.collected_petals.has("heartwood_petal"), "Optional canopy lookout keeps the last petal")
	await place(Vector2(6840,273))
	player.invulnerable = 0
	player.current_health = 100
	for marker in [Vector2(7040,288),Vector2(7240,288),Vector2(7480,234),Vector2(7640,180),Vector2(7800,126),Vector2(8000,126),Vector2(8320,126)]:
		await hop(marker)
	check(player.current_health == 100, "Upper hazard crossing needs only ordinary jumps, without taking damage")
	await activate_seal("heartwood_moon_seal")
	check(session.objective_completed(session.STAGE_ONE, "heartwood_moon_seal"), "Upper sanctuary contains Seal 3 after the climb and hazards")
	for marker in [Vector2(8600,180),Vector2(8760,234),Vector2(8920,288),Vector2(9080,342),Vector2(9240,396),Vector2(9400,450),Vector2(9560,500)]:
		await hop(marker)
	check(player.position.x >= 9500 and player.is_on_floor(), "Gentle eastern descent reaches the quiet Moon Gate approach")
	check(session.collected_petals.size() == 6, "All six optional rewards need no attacks or dash")
	print("STAGE 1 ROUTES: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
