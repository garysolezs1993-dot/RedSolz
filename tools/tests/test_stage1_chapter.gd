extends SceneTree

# Actual Stage 1 scene/controller/terrain. Isolated journey save, never real saves.
# --script res://tools/tests/test_stage1_chapter.gd -- --presentation-test [--capture]
const MAP := preload("res://scripts/stage1_definition.gd")
var player: CharacterBody2D
var layout: Node2D
var journey: Node2D
var session: Node
var checks := 0
var failures := 0
var shots: Dictionary = {}
var capturing := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", description)
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

func tap(action: String) -> void:
	input_action(action, true)
	await frames(3)
	input_action(action, false)
	await frames(2)

func place(where: Vector2) -> void:
	for action in ["attack", "dash", "move_left", "move_right", "move_up", "move_down", "jump", "interact", "crescent_slash"]:
		input_action(action, false)
	player._cancel_action()
	player.cooldown = 0
	player.dash_cooldown_remaining = 0
	player.crescent_cooldown_remaining = 0
	player.invulnerable = 10000
	player.global_position = where
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await frames(8)

func capture(label: String) -> void:
	if not capturing:
		return
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await frames(3)
	await process_frame
	await RenderingServer.frame_post_draw
	shots[label] = root.get_texture().get_image()

func _run() -> void:
	capturing = OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_test_stage1_chapter.cfg"
	check(str(session.save_path).contains("presentation_test"), "Isolated test save")
	session.checkpoint_scene = "res://scenes/main.tscn"
	session.checkpoint_position = Vector2(70, 485)
	session.pending_spawn = false
	session.learned_mechanics.clear()
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	session.stage_objectives.clear()
	change_scene_to_file("res://scenes/main.tscn")
	await frames(15)
	player = current_scene.get_node("Player")
	layout = current_scene.get_node("Stage1Layout")
	journey = layout.get_node("Stage1Journey")
	# Section 1: opening, safety, and geometry configuration.
	check(player.is_on_floor(), "Opening spawn stands on the main floor")
	check(player.get_node("Camera2D").limit_right == int(MAP.WIDTH), "Camera follows chapter width")
	check(current_scene.get_node("ForestEnvironment").world_width == MAP.WIDTH, "Environment covers the chapter")
	check(not current_scene.get_node("UI/HUD/Controls").visible, "Stage 1 has no full control dump")
	var wolves := get_nodes_in_group("enemies")
	check(wolves.size() == 8, "Eight deliberately placed wolves, including one optional canopy encounter")
	for wolf in wolves:
		check(wolf.global_position.x > 1250, "Quiet opening has no wolf: " + wolf.name)
		wolf.set_physics_process(false)
	check(get_nodes_in_group("forest_checkpoints").size() == 3, "Three meaningful checkpoints")
	await capture("01_quiet_opening")
	await place(Vector2(770, 485))
	await capture("02_dash_crossing")
	await tap("dash")
	check(session.learned_mechanics.has("dash"), "An accepted dash teaches dash")
	# Section 2: E interactions, one-time heal, save and retry.
	var checkpoint := layout.get_node("Promise_1100")
	await place(Vector2(1100, 485))
	player.current_health = 30
	await frames(20)
	check(not checkpoint.activated and player.current_health == 30, "Walking through a checkpoint never activates or heals")
	check(session.checkpoint_position == Vector2(70, 485), "Walking past keeps existing respawn")
	var router := player.get_node("InteractionRouter")
	check(router.select_target() == checkpoint.get_node("CheckpointInteraction"), "Router chooses nearby checkpoint")
	await capture("03_checkpoint_prompt")
	await tap("interact")
	await frames(90) # Lantern saves on hand contact, then finishes its overlap.
	check(checkpoint.activated and player.current_health == 100, "E activates and heals once")
	check(session.checkpoint_position == Vector2(1100, 485), "E saves the correct respawn")
	player.current_health = 50
	await frames(50)
	await tap("interact")
	check(player.current_health == 50 and router.select_target() == null, "Repeated E cannot farm healing")
	check(session.activated_checkpoints.has("forest_1100"), "Activation history is stored")
	# Section 3: lessons respond to execution, not crossing a coordinate or invalid input.
	session.learned_mechanics.clear()
	await place(Vector2(1390, 485))
	await frames(25)
	check(journey.hint_key == "attack", "Basic combat hint appears before the first wolf")
	player.cooldown = 2
	await tap("attack")
	check(not session.learned_mechanics.has("attack"), "Rejected attack does not dismiss the lesson")
	await place(Vector2(2200, 485))
	check(not session.learned_mechanics.has("attack"), "Passing the lesson does not mark it complete")
	await place(Vector2(1390, 485))
	check(journey.hint_key == "attack", "Unlearned hint returns when revisiting")
	await tap("attack")
	await frames(17)
	check(session.learned_mechanics.has("attack"), "Real active melee frames complete the attack hint")
	await place(Vector2(3560, 293))
	check(journey.hint_key == "rising_slash", "Chapel introduces Rising Slash")
	await capture("04_broken_chapel")
	input_action("move_up", true)
	await tap("attack")
	input_action("move_up", false)
	await frames(16)
	check(session.learned_mechanics.has("rising_slash") and player.velocity.y < 0, "Actual launcher ascent completes Rising Slash hint")
	await tap("attack")
	await frames(16)
	check(session.learned_mechanics.has("air_attack") and player.air_combo_step > 0, "Air follow-up completes the aerial lesson")
	input_action("move_down", true)
	await tap("attack")
	input_action("move_down", false)
	await frames(80)
	check(session.learned_mechanics.has("downward_slash") and player.is_on_floor(), "Launcher → air attack → Downward Slash lands cleanly")
	await place(Vector2(3810, 300))
	await frames(2)
	input_action("move_down", true)
	await tap("attack")
	input_action("move_down", false)
	await frames(80)
	check(player.is_on_floor() and not player.attacking, "Standalone airborne Downward Slash remains usable")
	await place(Vector2(5440, 409))
	player.facing = 1
	player.visual.flip_h = false
	var creek_wolf := layout.get_node("CreekWolf")
	var creek_health: int = creek_wolf.health
	await capture("05_creek_ranged_lesson")
	await tap("crescent_slash")
	await frames(80)
	check(session.learned_mechanics.has("crescent"), "Projectile release completes Crescent hint")
	check(creek_wolf.health == creek_health - 20, "Creek practice ledge aligns Crescent with the distant wolf")
	# Sections 4/5: wolf warning, punish window, containment and pack staggering.
	var lone := layout.get_node("LoneWolf")
	await place(Vector2(1540, 485))
	lone.position = Vector2(1600, 500)
	lone.velocity = Vector2.ZERO
	lone.pursuing = true
	lone.is_howling = false
	lone.visual.flip_h = true
	lone.attack_cooldown = 0
	lone.set_physics_process(true)
	await frames(3)
	check(lone.attack_warning_remaining > 0 and lone.attack_elapsed == 0 and is_zero_approx(lone.velocity.x), "First wolf visibly warns before moving")
	await capture("06_lone_wolf_warning")
	await frames(66)
	check(lone.attack_recovery_remaining > 0 and is_zero_approx(lone.velocity.x), "Wolf stops for its punish window after the lunge")
	lone.set_physics_process(false)
	# Real basic combat must remain useful while attacks lock Red's movement.
	await place(Vector2(1555, 485))
	player.invulnerable = 0
	player.current_health = 100
	player.facing = 1
	player.visual.flip_h = false
	lone.position = Vector2(1600, 500)
	lone.velocity = Vector2.ZERO
	lone.health = lone.maximum_health
	lone.pursuing = true
	lone.is_howling = false
	lone.attack_elapsed = 0
	lone.attack_recovery_remaining = 0
	lone.attack_cooldown = 0
	lone.visual.flip_h = true
	lone.set_physics_process(true)
	await tap("attack")
	await frames(16)
	await tap("attack")
	await frames(17)
	await tap("attack")
	await frames(50)
	check(not is_instance_valid(lone) or lone.dead, "Stationary three-hit ground combo can defeat the real introductory wolf")
	if is_instance_valid(lone):
		print("INTRO COMBAT: HP=", lone.health, " wolf=", lone.position, " Red=", player.position)
	check(player.current_health == 100, "The introductory wolf provides a safe melee punish opportunity")
	if is_instance_valid(lone):
		lone.set_physics_process(false)
	# Remaining containment check uses the camp wolf, since the first was defeated.
	lone = layout.get_node("CampWolf")
	await place(Vector2(2700, 485))
	lone.pursuing = true
	lone.set_physics_process(true)
	await frames(100)
	check(not lone.pursuing and lone.position.x <= 2630, "Wolf stays within its encounter instead of following into a quiet section")
	lone.set_physics_process(false)
	var first := layout.get_node("HeartwoodA")
	var second := layout.get_node("HeartwoodB")
	await place(Vector2(4165, 725))
	for wolf in [first, second]:
		wolf.position.y = 740
		wolf.pursuing = true
		wolf.is_howling = false
		wolf.attack_cooldown = 0
		wolf.visual.flip_h = wolf.position.x > player.position.x
		wolf.set_physics_process(true)
	var concurrent := false
	var saw_first := false
	var saw_second := false
	for index in range(600):
		await physics_frame
		var first_active: bool = first.attack_elapsed > 0 or first.attack_warning_remaining > 0
		var second_active: bool = second.attack_elapsed > 0 or second.attack_warning_remaining > 0
		concurrent = concurrent or first_active and second_active
		saw_first = saw_first or first.attack_elapsed > 0
		saw_second = saw_second or second.attack_elapsed > 0
	check(not concurrent and saw_first and saw_second, "Both cellar guardians attack, with no simultaneous windup/lunge")
	await capture("07_heartwood_test")
	for wolf in [first, second]:
		wolf.set_physics_process(false)
	await place(Vector2(9100, 485))
	first.pursuing = true
	second.pursuing = true
	first.set_physics_process(true)
	second.set_physics_process(true)
	await frames(160)
	check(not first.pursuing and not second.pursuing and second.position.x <= 4490, "Cellar guardians stay in their guarded room")
	first.set_physics_process(false)
	second.set_physics_process(false)
	# Sections 6/7: retained exploration, main-route traversal and actual stage transition.
	for wolf in wolves:
		if is_instance_valid(wolf):
			wolf.queue_free()
	await frames(3)
	await place(Vector2(4300, 485))
	input_action("move_down", true)
	await tap("jump")
	input_action("move_down", false)
	await frames(65)
	check(player.position.y > 550 and player.position.y < 850, "Root bridge still permits entry into the cellar")
	await capture("08_root_cellar")
	await place(Vector2(5060, 235))
	await frames(10)
	check(player.is_on_floor(), "Hollow Oak crown still has a supported reward ledge")
	await capture("09_hollow_oak_destination_glimpse")
	await place(Vector2(7340, 341))
	check(player.is_on_floor(), "Burial reward route retains its landing shelf")
	await capture("10_burial_route")
	await place(Vector2(8640, 293))
	check(journey.distant_gate.visible, "Moon Gate silhouette is visible before reaching the gate")
	check(MAP.REWARDS.size() == 6, "All six moon petals retain their identifiers")
	await place(Vector2(70, 485))
	player.current_health = 100
	player.invulnerable = 0
	input_action("move_right", true)
	var max_y := 0.0
	var crossings := [700.0,3180.0,5900.0,6340.0]
	var crossing := 0
	var next_jump := -1
	if capturing:
		Engine.time_scale = 3.0
	for index in range(5500):
		await physics_frame
		if player.lantern_sequence.phase == "waiting":
			input_action("ui_cancel", true)
		else:
			input_action("ui_cancel", false)
		if crossing < crossings.size() and player.position.x >= crossings[crossing]:
			input_action("jump", true)
			next_jump = index + 22
			crossing += 1
		elif index == next_jump:
			input_action("jump", true)
		else:
			input_action("jump", false)
		max_y = maxf(max_y, player.position.y)
		if player.position.x >= MAP.GATE_POSITION.x - 40:
			break
	input_action("move_right", false)
	input_action("ui_cancel", false)
	input_action("jump", false)
	Engine.time_scale = 1.0
	check(player.position.x >= MAP.GATE_POSITION.x - 40 and max_y < 550, "Full main route is traversable without dash, launcher or advanced combos")
	check(player.current_health == 100, "Main-route hazards can all be avoided with ordinary movement and jumping")
	await capture("11_moon_gate")
	await place(Vector2(9100, 485))
	await tap("interact")
	await frames(90)
	check(session.checkpoint_position == Vector2(9100, 485), "Final quiet checkpoint saves before the boss")
	# All activation states survive reloading; new-game clearing is separate.
	session.pending_spawn = true
	reload_current_scene()
	await frames(15)
	player = current_scene.get_node("Player")
	layout = current_scene.get_node("Stage1Layout")
	check(absf(player.position.x - 9100) < 1, "Retry spawns at the chosen final checkpoint")
	check(layout.get_node("Promise_1100").activated and layout.get_node("Promise_10600").activated, "Activated lanterns remain lit after retry")
	check(session.learned_mechanics.has("attack"), "Demonstrated lessons remain learned after retry")
	# Progression is covered in its own suite; prepare all three seals for this
	# chapter's gate/transition regression instead of bypassing the new lock.
	for marker in MAP.SEALS:
		var seal := layout.get_node(str(marker[0]))
		for guard_name in seal.guard_names:
			var guard := layout.get_node_or_null(NodePath(guard_name))
			if guard != null:
				guard.take_damage(1000)
		await place(marker[1] + Vector2(0, -15))
		await tap("interact")
		if str(marker[0]) == "camp_moon_seal":
			await frames(490)
	await place(Vector2(MAP.GATE_POSITION.x, 485))
	await tap("interact")
	await frames(50)
	check(current_scene.scene_file_path == "res://scenes/stage2_boss.tscn", "E at the real Moon Gate loads the boss stage")
	for label in shots:
		shots[label].save_png("res://.godot/stage1_chapter_review/" + label + ".png")
	print("STAGE 1 CHAPTER: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
