extends SceneTree

const MAP := preload("res://scripts/stage1_definition.gd")
var checks := 0
var failures := 0
var player: CharacterBody2D
var session: Node
var layout: Node2D
var objectives: Node2D
var gate: Node2D
var guide: Node2D

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

func action(key: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = key
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(key: String) -> void:
	action(key, true)
	await frames(3)
	action(key, false)
	await frames(2)
	if key == "interact":
		for seal in get_nodes_in_group("moon_seals"):
			if seal.state == "activating":
				while seal.state == "activating" or seal.release_remaining >= 0:
					await frames(1)

func place(where: Vector2) -> void:
	player._cancel_action()
	player.position = where
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(12)

func bind_stage() -> void:
	player = current_scene.get_node("Player")
	layout = current_scene.get_node("Stage1Layout")
	objectives = layout.get_node("StageObjectives")
	gate = layout.get_node("StageTwoGate")
	guide = layout.get_node("MoonWispGuide")
	for wolf in get_nodes_in_group("enemies"):
		wolf.queue_free()

func hop(target: Vector2) -> void:
	var right := target.x >= player.position.x
	var key := "move_right" if right else "move_left"
	action(key, true)
	action("jump", true)
	await frames(3)
	action("jump", false)
	var landed := false
	for index in range(130):
		await physics_frame
		if (target.x - player.position.x) * (1 if right else -1) <= 3:
			action(key, false)
		if index == 18 and not player.is_on_floor():
			action("jump", true)
		elif index == 21:
			action("jump", false)
		if index > 4 and player.is_on_floor() and absf(player.position.x - target.x) < 20 and player.position.y + 15 <= target.y + 1:
			landed = true
			break
	action(key, false)
	action("jump", false)
	check(landed, "Ordinary jumps reach seal branch: " + str(target))

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_test_moon_seal_progression.cfg"
	check(str(session.save_path).contains("presentation_test"), "Testing uses isolated saves")
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	session.stage_objectives.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(20)
	bind_stage()
	check(get_nodes_in_group("moon_seals").size() == 3 and objectives.required_seal_ids.size() == 3, "Three separate required Moon Seals")
	check(objectives.completed_count() == 0 and not gate.is_unlocked(), "Gate dormant at 0/3")
	check(MAP.WIDTH == 10000 and player.get_node("Camera2D").limit_right == 10000, "Compact hub topology and camera cover 10,000 px")
	check(get_nodes_in_group("forest_checkpoints").size() == 3, "Existing checkpoint count unchanged")
	check(guide.phase == "hidden", "Wisp stays hidden before seal discovery")
	var upper_cue: Vector2 = objectives.guidance_target(Vector2(3080,437))
	check(upper_cue.x > 3080 and upper_cue.y < 400, "Chapel fork guidance climbs toward the next upper landmark")
	await place(Vector2(MAP.GATE_POSITION.x, 485))
	await tap("interact")
	await tap("ui_up")
	check(not gate.transitioning and not gate.is_unlocked(), "E and Up keep the gate locked at 0/3")
	await frames(435)
	var wisp_spawns: int = guide.spawn_count
	await place(Vector2(1100, 485))
	check(not layout.get_node("Promise_1100").activated, "Walking through a lantern never activates it")
	await tap("interact")
	await frames(100)
	check(layout.get_node("Promise_1100").activated and session.checkpoint_position == Vector2(1100, 485), "Lantern still animates, saves and heals through E")
	check(objectives.completed_count() == 0, "Lantern activation is not seal progress")
	var respawn: Vector2 = session.checkpoint_position
	await place(Vector2(3900,149))
	var first := layout.get_node("camp_moon_seal")
	check(not first.activated, "Proximity alone never awakens a seal")
	check(player.get_node("InteractionRouter").select_target() == first.get_node("SealInteraction"), "E router targets the first seal")
	guide.request_guidance(true)
	await frames(75)
	wisp_spawns = guide.spawn_count
	await tap("interact")
	check(first.activated and first.activation_count == 1 and objectives.completed_count() == 1, "First seal registers 1/3")
	check(guide.phase == "swirl" and guide.elapsed < .3, "Scripted first release replaces an existing early-gate cue")
	check(session.toast.text == "Moon Seals awakened: 1/3", "Short temporary progress message")
	check(guide.phase == "swirl" and guide.spawn_count == wisp_spawns + 1, "First seal releases a circling wisp")
	check(guide.destination == MAP.FIRST_WISP_ROUTE.back() and guide.cinematic_active and paused, "First wisp camera tour reveals the cellar entrance safely")
	await frames(490)
	check(not paused and not guide.cinematic_active and player.get_node("Camera2D").is_current(), "Camera tour restores gameplay and Red's camera")
	check(not guide is Area2D and not guide is PhysicsBody2D, "Wisp has no collectible/collision behavior")
	var cellar_cue: Vector2 = objectives.guidance_target(Vector2(3380,485))
	check(cellar_cue.y > 485 and cellar_cue.distance_to(Vector2(3380,485)) < 300, "Missing cellar seal cues the nearby descent, not the objective")
	check(cellar_cue.distance_to(MAP.SEALS[1][1]) > 500, "Cellar guidance leaves exploration within the room to the player")
	await tap("interact")
	check(first.activation_count == 1 and objectives.completed_count() == 1, "Repeated activation cannot advance progress")
	check(session.checkpoint_position == respawn and session.collected_petals.is_empty(), "Seal does not move checkpoint or grant petals")
	await place(Vector2(3400, 485))
	await frames(435)
	check(guide.phase == "hidden" and not guide.visible, "Temporary wisp fades and never follows Red permanently")
	guide.cooldown = 0
	await place(Vector2(2800,485))
	check(guide.phase != "hidden" and guide.visited_regions.has(Vector2(2800,485)), "Entering a useful new section gives a temporary route cue")
	await frames(435)
	guide.cooldown = 0
	guide.idle_time = 0
	await place(Vector2(2400,485))
	await frames(850)
	check(guide.phase != "hidden", "Remaining inactive outside combat can request guidance")
	await place(Vector2(MAP.GATE_POSITION.x, 485))
	await tap("interact")
	await tap("ui_up")
	check(not gate.transitioning and current_scene.scene_file_path == session.STAGE_ONE, "E and Up cannot bypass 1/3 locked gate")
	check(guide.phase != "hidden" and guide.destination.x < player.position.x, "Early gate visit points back toward missing seal region")
	check(session.toast.text.contains("Root Cellar"), "Gate names the next seal region in the chapter order")
	await place(MAP.SEALS[1][1] + Vector2(0,-15))
	await tap("interact")
	check(objectives.completed_count() == 2 and layout.get_node("oak_moon_seal").activated, "Cellar branch awakens seal 2/3")
	check(not gate.is_unlocked() and gate.seal_count == 2, "Gate remains locked at 2/3")
	var return_cue: Vector2 = objectives.guidance_target(Vector2(4900,725))
	check(return_cue.x > 4900 and return_cue.y < 725, "Completed cellar guidance leads up toward its shortcut lift")
	var ruins_cue: Vector2 = objectives.guidance_target(Vector2(6520,485))
	check(ruins_cue.y < 485, "Missing upper-ruins seal cues the upward route above the bridge")
	await place(Vector2(MAP.GATE_POSITION.x, 485))
	await tap("interact")
	check(not gate.transitioning, "Cannot enter gate with only two seals")
	var nearest: Node2D = objectives.missing_seal(player.position)
	check(nearest != null and nearest.identifier == "heartwood_moon_seal", "Target selection skips awakened seals")
	await place(MAP.SEALS[2][1] + Vector2(0,-15))
	await tap("interact")
	check(objectives.completed_count() == 3 and layout.get_node("heartwood_moon_seal").activated, "Upper sanctuary awakens seal 3/3")
	check(gate.is_unlocked() and gate.seal_count == 3 and gate.awakening_pulse > 0, "Third seal awakens the gate")
	var east_exit: Vector2 = objectives.guidance_target(Vector2(7160,665))
	check(east_exit.x > 7160 and east_exit.y < 665, "Side-ruins guidance leaves through the separate eastern stairs")
	check(objectives.guidance_target(Vector2(9500, 485)).x > 9500, "After all seals guidance leads toward the Moon Gate")
	await frames(185)
	check(session.toast.text == "The Moon Gate awakens.", "Gate awakening announcement follows final progress toast")
	check(session.collected_petals.is_empty(), "All seals can be reached with zero optional petals")
	var saved := ConfigFile.new()
	saved.load(session.save_path)
	check(saved.get_value("journey", "stage_objectives", {}).get(session.STAGE_ONE, []).size() == 3, "Seal progress is saved immediately")
	session.stage_objectives.clear()
	session._load_journey()
	check(session.objective_completed(session.STAGE_ONE, "oak_moon_seal"), "Saved seal data loads correctly")
	session.pending_spawn = true
	reload_current_scene()
	await frames(20)
	bind_stage()
	check(absf(player.position.x - respawn.x) < 2 and gate.is_unlocked(), "Checkpoint respawn preserves seal progress and open gate")
	check(layout.get_node("camp_moon_seal").activated and layout.get_node("oak_moon_seal").activated and layout.get_node("heartwood_moon_seal").activated, "All seal visuals restore activated state")
	check(layout.get_node("CellarReturnLift").unlocked, "Cellar shortcut restores its unlocked state after retry")
	check(guide.spawn_count == 0, "Reload does not replay first wisp introduction")
	# Full safe route with ordinary movement/jumps. Combat tested separately.
	await place(Vector2(70, 485))
	action("move_right", true)
	var crossings := [700.0,3180.0,5900.0,6340.0]
	var crossing := 0
	var next_jump := -1
	var max_y := 0.0
	for index in range(5500):
		await physics_frame
		action("ui_cancel", player.lantern_sequence.phase == "waiting")
		if crossing < crossings.size() and player.position.x >= crossings[crossing]:
			action("jump", true)
			next_jump = index + 22
			crossing += 1
		elif index == next_jump:
			action("jump", true)
		else:
			action("jump", false)
		max_y = maxf(max_y, player.position.y)
		if player.position.x >= MAP.GATE_POSITION.x - 40:
			break
	action("move_right", false)
	action("jump", false)
	action("ui_cancel", false)
	check(player.position.x >= MAP.GATE_POSITION.x - 40 and max_y < 550, "Entire expanded main route remains accessible without advanced abilities")
	check(MAP.REWARDS.size() == 6, "Six optional Moon Petals remain unchanged")
	await place(Vector2(MAP.GATE_POSITION.x, 485))
	await tap("ui_up")
	await frames(50)
	check(current_scene.scene_file_path == session.STAGE_TWO, "Unlocked gate preserves Up transition to Stage 2")
	check(session.objective_completed(session.STAGE_ONE, "camp_moon_seal"), "Stage transition retains Stage 1 objective state")
	check(not current_scene.has_node("Stage1Layout"), "No Stage 1 seals/wisps leak into boss stage")
	# Verify previous physical anchors migrate without losing checkpoint/objective history.
	for mapping in [[6500,2800],[10600,9100]]:
		var legacy := ConfigFile.new()
		legacy.set_value("journey", "version", 1)
		legacy.set_value("journey", "scene", session.STAGE_ONE)
		legacy.set_value("journey", "position", Vector2(mapping[0],485))
		legacy.set_value("journey", "activated_checkpoints", {"forest_6500":true})
		legacy.set_value("journey", "stage_objectives", {session.STAGE_ONE:["oak_moon_seal"]})
		legacy.save(session.save_path)
		session._load_journey()
		check(session.checkpoint_position == Vector2(mapping[1],485) and session.has_valid_save(), "Old checkpoint maps to the new junction: " + str(mapping))
		check(session.objective_completed(session.STAGE_ONE,"oak_moon_seal") and session.activated_checkpoints.has("forest_6500"), "Migration preserves seals and lit lantern history")
	# Verify old saves lacking the new field remain compatible.
	var old := ConfigFile.new()
	old.set_value("journey", "version", 1)
	old.set_value("journey", "scene", session.STAGE_ONE)
	old.set_value("journey", "position", respawn)
	old.save(session.save_path)
	session.stage_objectives.clear()
	session._load_journey()
	check(session.stage_objectives.is_empty() and session.has_valid_save(), "Old checkpoint saves load with unawakened seals")
	session.stage_objectives[session.STAGE_ONE] = ["camp_moon_seal"]
	session.start_new_game()
	await frames(60)
	check(session.stage_objectives.is_empty(), "New game clears seal progress")
	print("MOON SEAL PROGRESSION: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
