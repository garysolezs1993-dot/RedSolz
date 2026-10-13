extends SceneTree

const MAP := preload("res://scripts/stage1_definition.gd")
var session: Node
var player: CharacterBody2D
var layout: Node2D
var objectives: Node2D
var guide: Node2D
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

func bind() -> void:
	player = current_scene.get_node("Player")
	layout = current_scene.get_node("Stage1Layout")
	objectives = layout.get_node("StageObjectives")
	guide = layout.get_node("MoonWispGuide")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)

func place(where: Vector2) -> void:
	player._cancel_action()
	player.position = where
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(12)

func basic_combo(guard_name: String) -> void:
	var wolf := layout.get_node(guard_name) as CharacterBody2D
	await place(wolf.position + Vector2(-45, -15))
	player.facing = 1
	player.visual.flip_h = false
	await tap("attack")
	await frames(16)
	await tap("attack")
	await frames(17)
	await tap("attack")
	await frames(50)
	check(not is_instance_valid(wolf) or wolf.dead, "Real C combo defeats a seal guardian: " + guard_name)

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_test_seal_encounters.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(20)
	bind()
	var first := layout.get_node("camp_moon_seal")
	var second := layout.get_node("oak_moon_seal")
	var third := layout.get_node("heartwood_moon_seal")
	var camera := player.get_node("Camera2D") as Camera2D
	var zoom := camera.zoom
	check(first.guard_names.is_empty(), "Discovery seal has no mandatory guard")
	check(second.living_guard_count() == 2 and third.living_guard_count() == 2, "Later seals each track exactly their two guards")
	check(get_nodes_in_group("enemies").size() == 8, "Enemy count stays at eight instead of adding spam")
	check(MAP.SEALS[2][1].y < MAP.SEALS[0][1].y and MAP.SEALS[1][1].y > 500, "Progression goes up, down, then back up")
	await place(second.position + Vector2(0, -15))
	await tap("interact")
	check(not second.activated and session.toast.text.contains("Broken Chapel"), "Early cellar visit explains the first seal prerequisite")
	check(not objectives.awaken(second), "Direct manager activation cannot bypass prerequisites")
	await place(first.position + Vector2(0, -15))
	await tap("interact")
	check(first.activated and guide.cinematic_active and paused, "First activation pauses combat for the full camera tour")
	check(root.get_camera_2d() == guide.cinematic_camera, "Wisp camera takes over without editing Red's camera")
	var red_position := player.position
	var wolf_position: Vector2 = layout.get_node("HeartwoodA").position
	action("move_right", true)
	await frames(190)
	action("move_right", false)
	check(player.position == red_position and layout.get_node("HeartwoodA").position == wolf_position, "Player and encounter positions stay frozen during introduction")
	check(guide.global_position.distance_to(red_position) > 250, "Wisp genuinely travels along the return/descent landmarks")
	check(guide.destination == MAP.FIRST_WISP_ROUTE.back() and guide.destination.distance_to(second.position) > 1000, "Tour reveals the entrance, leaving the protected seal to discovery")
	await frames(310)
	check(not paused and not guide.cinematic_active and camera.is_current(), "Natural cinematic ending restores world and camera")
	check(camera.zoom == zoom and camera.offset == Vector2.ZERO, "Gameplay zoom and camera offset are unchanged")
	await place(second.position + Vector2(0, -15))
	await tap("interact")
	check(not second.activated and session.toast.text.contains("2 remaining"), "Seal 2 refuses activation while both guardians live")
	check(second.get_node("SealInteraction").prompt_text.contains("guardians"), "Guard lock is visible in the interaction prompt")
	await basic_combo("HeartwoodA")
	await place(second.position + Vector2(0, -15))
	await tap("interact")
	check(second.living_guard_count() == 1 and not second.activated, "Defeating one guard does not clear the encounter")
	layout.get_node("HeartwoodB").take_damage(1000)
	await tap("interact")
	check(second.activated and layout.get_node("CellarReturnLift").unlocked, "Both defeated guardians permit the seal and unlock its shortcut")
	check(guide.brief_cue and not guide.cinematic_active and not paused and camera.is_current(), "Seal 2 only emits a brief cue with no camera takeover")
	await frames(460)
	check(guide.phase == "hidden", "Second cue finishes after its slower flight and longer landmark linger")
	await place(third.position + Vector2(0, -15))
	await tap("interact")
	check(not third.activated and third.living_guard_count() == 2, "Seal 3 requires its sanctuary encounter")
	await place(Vector2(8130, 111))
	var left_guard := layout.get_node("ChapelWolf") as CharacterBody2D
	var right_guard := layout.get_node("BurialWolf") as CharacterBody2D
	for wolf in [left_guard, right_guard]:
		wolf.pursuing = true
		wolf.is_howling = false
		wolf.attack_cooldown = 0
		wolf.visual.flip_h = wolf.position.x > player.position.x
		wolf.set_physics_process(true)
	var concurrent := false
	var left_attacked := false
	var right_attacked := false
	for index in range(600):
		await physics_frame
		var left_active: bool = left_guard.attack_elapsed > 0 or left_guard.attack_warning_remaining > 0
		var right_active: bool = right_guard.attack_elapsed > 0 or right_guard.attack_warning_remaining > 0
		concurrent = concurrent or left_active and right_active
		left_attacked = left_attacked or left_guard.attack_elapsed > 0
		right_attacked = right_attacked or right_guard.attack_elapsed > 0
	check(not concurrent and left_attacked and right_attacked, "Both final guardians attack with staggered windups and lunges")
	for wolf in [left_guard, right_guard]:
		wolf.set_physics_process(false)
		wolf.position = Vector2(wolf.patrol_origin_x, 126)
		wolf.velocity = Vector2.ZERO
	await basic_combo("ChapelWolf")
	await place(third.position + Vector2(0, -15))
	await tap("interact")
	check(not third.activated and third.living_guard_count() == 1, "Final seal stays locked with one guardian left")
	layout.get_node("BurialWolf").take_damage(1000)
	var spawns: int = guide.spawn_count
	await tap("interact")
	check(third.activated and layout.get_node("StageTwoGate").is_unlocked(), "Final encounter unlocks the Moon Gate")
	check(guide.spawn_count == spawns + 1 and not paused and guide.brief_cue, "Final awakening releases a Moon Gate cue without another camera tour")
	await frames(190)
	check(session.toast.text == "The Moon Gate awakens.", "Gate awakening announces the payoff")
	var peaceful := true
	for wolf in get_nodes_in_group("enemies"):
		peaceful = peaceful and wolf.position.x < 8540
	for hazard in get_nodes_in_group("forest_hazards"):
		peaceful = peaceful and hazard.position.x < 8540
	check(peaceful, "No encounter or hazard follows the final sanctuary")
	# Save/retry restores seal and encounter state, never the cinematic.
	session.stage_objectives.clear()
	session._load_journey()
	reload_current_scene()
	await frames(20)
	bind()
	check(objectives.completed_count() == 3 and guide.spawn_count == 0 and not paused, "Saved progress reloads without replaying the introduction")
	check(not layout.has_node("HeartwoodA") and not layout.has_node("BurialWolf"), "Completed seal guard rooms remain cleared after retry")
	check(get_nodes_in_group("enemies").size() == 4, "Only the four unlinked encounters respawn")
	# Skip and interrupted scene cleanup must both release the world pause.
	session.stage_objectives.clear()
	reload_current_scene()
	await frames(20)
	bind()
	await place(MAP.SEALS[0][1] + Vector2(0, -15))
	await tap("interact")
	await tap("ui_cancel")
	check(not paused and not guide.cinematic_active and player.get_node("Camera2D").is_current(), "Escape safely skips the introduction")
	session.stage_objectives.clear()
	reload_current_scene()
	await frames(20)
	bind()
	await place(MAP.SEALS[0][1] + Vector2(0, -15))
	await tap("interact")
	change_scene_to_file(session.STAGE_TWO)
	await frames(20)
	check(not paused and not current_scene.has_node("Stage1Layout"), "Scene interruption cleans up the cinematic pause and camera")
	print("SEAL ENCOUNTERS: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
