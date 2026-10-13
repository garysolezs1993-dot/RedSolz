extends SceneTree

# Actual Stage 1 terrain/player. --presentation-test [--capture]
var player: CharacterBody2D
var checks := 0
var failures := 0
var capturing := false
var captures: Array[Dictionary] = []
const OUTPUT := "res://.godot/red_dive_review/"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func input_action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(name: String = "attack") -> void:
	input_action(name, true)
	await wait(.025)
	input_action(name, false)
	await wait(.025)

func reset_player(face: int = 1) -> void:
	for name in ["attack", "jump", "dash", "move_up", "move_down", "move_left", "move_right"]:
		input_action(name, false)
	player._cancel_action()
	player.cooldown = 0
	player.position = Vector2(140, 485)
	player.velocity = Vector2.ZERO
	player.facing = face
	player.visual.flip_h = face < 0
	player.invulnerable = 10
	player.reset_physics_interpolation()
	await wait(.25)
	check(player.is_on_floor() and not player.downward_used_in_air, "Ground contact resets dive allowance")

func until_frame(frame: int) -> void:
	var start := Time.get_ticks_msec()
	while player.attacking and player.visual.frame < frame and Time.get_ticks_msec() - start < 1800:
		await process_frame

func until_air(step: int) -> void:
	var start := Time.get_ticks_msec()
	while player.air_combo_step != step and Time.get_ticks_msec() - start < 1800:
		await process_frame
	check(player.air_combo_step == step, "Air combo reaches step %d" % step)

func until_dive() -> void:
	var start := Time.get_ticks_msec()
	while not (player.attacking and player.attack_animation == "downward_slash") and Time.get_ticks_msec() - start < 1800:
		await process_frame
	check(player.attacking and player.attack_animation == "downward_slash", "Requested input transitions into Downward Slash")

func pose(name: String) -> void:
	if capturing:
		await RenderingServer.frame_post_draw
		# Write PNGs after gameplay checks; compression must not consume recovery.
		captures.append({"name": name, "image": root.get_texture().get_image()})

func finish_dive(expected_y: float, name: String) -> void:
	await until_frame(3)
	check(player.downward_diving and player.velocity.y >= player.downward_dive_speed - 1 and not player.visual.is_playing(), "Strike commits to tunable downward speed and held travel pose")
	check(player.downward_effect.visible and player.downward_effect.frame == 3 and not player.attack_effect.visible and not player.air_combo_effect.visible, "New dive VFX matches its character without old layers")
	var start_x := player.position.x
	input_action("move_right", true)
	await pose(name + "_dive")
	var start := Time.get_ticks_msec()
	var clipped := false
	while not player.downward_impact_active and Time.get_ticks_msec() - start < 2000:
		clipped = clipped or player.position.y > expected_y + .3
		await process_frame
	check(player.is_on_floor() and absf(player.position.y - expected_y) < .5 and not clipped, "Dive lands on the intended surface without floor clipping (%s: y=%.3f, expected=%.3f, crossed=%s)" % [name, player.position.y, expected_y, clipped])
	check(player.downward_impact_active and player.action_state == player.Action.ATTACK_RECOVERY and not player.attacking and not player.hitbox.active and is_zero_approx(player.velocity.y), "Landing stops dive/damage and enters impact recovery")
	check(absf(player.position.x - start_x) < .1 and is_zero_approx(player.velocity.x), "Steering cannot override dive motion")
	check(player.combo_step == 0 and player.air_combo_step == 0 and not player.air_combo_buffered and not player.air_combo_buffered_dive and not player.downward_diving, "Impact clears ground/air queues and diving state")
	check(player.downward_effect.frame == player.visual.frame + 4 and player.visual.animation == "downward_impact", "Impact poses 4-7 drive matching VFX frames")
	await pose(name + "_impact")
	await tap("jump")
	# Dash now intentionally cancels recovery; ordinary steering/jump stay locked.
	check(player.action_state == player.Action.ATTACK_RECOVERY and player.is_on_floor() and absf(player.position.x - start_x) < .1, "Impact recovery blocks ordinary movement/jump")
	await wait(player.downward_landing_recovery + .12)
	check(player.action_state == player.Action.NONE and not player.downward_effect.visible and player.position.x > start_x + 1, "Movement resumes after recovery and effect is hidden")
	input_action("move_right", false)

func combo_route(steps: int, launcher: bool, face: int) -> void:
	await reset_player(face)
	if launcher:
		input_action("move_up", true)
		await tap()
		input_action("move_up", false)
		await until_frame(1)
		await tap()
		await until_air(1)
	else:
		await tap("jump")
		if steps > 0:
			await tap()
	if steps == 2:
		await until_frame(2)
		await tap()
		await until_air(2)
	if steps > 0:
		await until_frame(2)
	input_action("move_down", true)
	await tap()
	input_action("move_down", false) # Queued intent survives releasing Down.
	await until_dive()
	check(player.facing == face and player.air_combo_step == 0, "Dive preserves facing and replaces the air finisher")
	await finish_dive(485, "%s_%d_face_%d" % ["launcher" if launcher else "jump", steps, face])

func ground_lock(face: int) -> void:
	await reset_player(face)
	player.velocity.x = 180 * face
	await tap()
	var anchor_x := player.position.x
	var steering := "move_right" if face > 0 else "move_left"
	input_action(steering, true)
	for step in range(1, 4):
		await until_frame(2)
		check(player.combo_step == step and absf(player.position.x - anchor_x) < .1 and is_zero_approx(player.velocity.x), "Ground step %d stops carried momentum and held input" % step)
		if step < 3:
			await tap()
			var start := Time.get_ticks_msec()
			while player.combo_step == step and Time.get_ticks_msec() - start < 1500:
				await process_frame
	while player.attacking:
		await process_frame
	check(player.action_state == player.Action.ATTACK_RECOVERY and absf(player.position.x - anchor_x) < .1, "Ground finisher enters stationary recovery")
	await wait(.10)
	check(absf(player.position.x - anchor_x) < .1 and player.action_state == player.Action.ATTACK_RECOVERY, "Ground movement stays locked through post-animation recovery")
	await wait(.3)
	check(player.action_state == player.Action.NONE and (player.position.x - anchor_x) * face > 1, "Ground movement returns after recovery")
	input_action(steering, false)

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_red_downward_slash.cfg"
	capturing = OS.get_cmdline_user_args().has("--capture")
	change_scene_to_file("res://scenes/main.tscn")
	await wait(.4)
	player = current_scene.get_node("Player")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	AudioServer.set_bus_mute(0, true)
	for index in range(8):
		var character: Texture2D = player.visual.sprite_frames.get_frame_texture("downward_slash", index)
		var effect: Texture2D = player.downward_effect.sprite_frames.get_frame_texture("downward_slash", index)
		check(not character is AtlasTexture and not effect is AtlasTexture and character.get_size() == Vector2(1536, 1536) and effect.get_size() == Vector2(1536, 1536), "Full separate source character/VFX canvases %02d" % index)
	for face in [1, -1]:
		await combo_route(0, false, face)
		await combo_route(1, false, face)
		await combo_route(2, false, face)
		await combo_route(1, true, face)
		await combo_route(2, true, face)
		await ground_lock(face)
	# Land on a raised one-way stage platform, not the ground beneath it.
	await reset_player()
	player.position = Vector2(460, 300)
	await wait(.035)
	input_action("move_down", true)
	await tap()
	input_action("move_down", false)
	await finish_dive(415, "platform")
	# Collision sweeps must work at a larger tunable speed and low tick rate.
	await reset_player()
	player.downward_dive_speed = 1100
	Engine.physics_ticks_per_second = 10
	player.position = Vector2(460, 260)
	await wait(.12)
	input_action("move_down", true)
	# Keep this input down through at least one deliberately slow physics tick.
	input_action("attack", true)
	await wait(.11)
	input_action("attack", false)
	input_action("move_down", false)
	await finish_dive(415, "fast_platform")
	Engine.physics_ticks_per_second = 60
	player.downward_dive_speed = 700
	# Missing terrain has a bounded attack duration and returns control.
	await reset_player()
	player.position.y = -2000
	await wait(.035)
	player.downward_max_dive_time = .1
	input_action("move_down", true)
	await tap()
	input_action("move_down", false)
	await wait(.6)
	check(player.action_state == player.Action.NONE and not player.downward_diving and not player.downward_effect.visible, "No-contact safety timeout prevents a stuck dive")
	player.downward_max_dive_time = 2
	await reset_player()
	player.position.y = 200
	await wait(.035)
	input_action("move_down", true)
	await tap()
	input_action("move_down", false)
	await until_frame(3)
	player.invulnerable = 0
	player.take_damage(8, -180)
	check(player.action_state == player.Action.HURT and not player.downward_diving and not player.downward_effect.visible and not player.hitbox.active, "Hurt interrupts the dive and its effect/damage")
	await wait(.06)
	check(player.velocity.y < 0 and player.velocity.x < 0, "Hurt knockback overrides attack motion locks")
	await reset_player()
	player.position.y = 200
	await wait(.035)
	input_action("move_down", true)
	await tap()
	input_action("move_down", false)
	player.invulnerable = 0
	player.take_damage(1000)
	check(player.dead and not player.downward_diving and not player.downward_effect.visible and not player.hitbox.active, "Death clears the dive and recovery state")
	for capture in captures:
		capture.image.save_png(OUTPUT + capture.name + ".png")
	print("DOWNWARD CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
