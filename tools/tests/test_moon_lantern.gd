extends SceneTree

# Isolated save. Full controller/scene, including each placed checkpoint.
var player: CharacterBody2D
var session: Node
var checks := 0
var failures := 0
var captures: Dictionary = {}
var capture_enabled := false

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
	await frames(2)
	action(name, false)
	await frames(2)

func place(position: Vector2) -> void:
	for name in ["interact", "move_right", "move_left", "jump", "dash", "attack", "crescent_slash", "ui_cancel"]:
		action(name, false)
	player._cancel_action()
	player.global_position = position
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await frames(6)

func screenshot(name: String) -> void:
	if not capture_enabled:
		return
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await RenderingServer.frame_post_draw
	captures[name] = root.get_texture().get_image()

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_moon_lantern.cfg"
	capture_enabled = OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	session = root.get_node("GameSession")
	check(str(session.save_path).contains("presentation_test"), "User save is isolated")
	session.pending_spawn = false
	session.checkpoint_scene = ""
	session.activated_checkpoints.clear()
	change_scene_to_file("res://scenes/main.tscn")
	await frames(20)
	player = current_scene.get_node("Player")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)
	var sequence: Node = player.lantern_sequence
	var camera: Camera2D = player.get_node("Camera2D")
	var lanterns := get_nodes_in_group("forest_checkpoints")
	check(lanterns.size() == 3, "All three Stage 1 lanterns use the shared implementation")
	for index in range(lanterns.size()):
		var lantern: Node2D = lanterns[index]
		var spawn := lantern.global_position + Vector2(0, -15)
		await place(spawn + Vector2(-90, 0))
		player.current_health = 30
		var old_checkpoint: Vector2 = session.checkpoint_position
		await place(spawn + Vector2(-18 if index != 1 else 36, 0))
		check(sequence.phase == "waiting" and player.action_state == player.Action.INTERACT, "Lantern %d enters waiting pose" % index)
		check(player.visual.animation == "lantern_interact" and player.visual.frame == 1 and not player.visual.is_playing(), "Frame 01 is held, not autoplayed")
		check(player.facing == (1 if index != 1 else -1), "Red faces the lantern from either side")
		await frames(180 if index == 0 else 35)
		check(not lantern.activated and player.current_health == 30 and session.checkpoint_position == old_checkpoint, "Proximity never activates, heals or saves")
		check(camera.zoom.is_equal_approx(Vector2(1.55, 1.55)), "Cinematic zoom reaches 1.55 smoothly")
		var held: Vector2 = player.global_position
		for name in ["move_right", "jump", "attack", "dash", "crescent_slash"]:
			await tap(name)
		check(player.global_position.distance_to(held) < 1 and player.visual.frame == 1, "Waiting pose ignores movement and combat")
		await screenshot("lantern_%d_waiting" % index)
		if index == 0:
			await tap("ui_cancel")
			check(sequence.phase == "idle" and player.action_state == player.Action.NONE, "Escape cancels waiting pose")
			await frames(30)
			check(camera.zoom.is_equal_approx(Vector2(1.35, 1.35)), "Escape restores the gameplay zoom")
			check(not lantern.activated and sequence.phase == "idle", "Cancellation does not immediately trap Red again")
			action("move_left", true)
			await frames(35)
			action("move_left", false)
			check(player.global_position.x < held.x - 40, "Red can walk away after cancelling")
			await place(spawn + Vector2(-18, 0))
			check(sequence.phase == "waiting", "Leaving and returning offers the preview again")
		action("interact", true)
		await frames(2)
		check(sequence.phase == "lighting" and player.visual.frame == 2, "E continues at frame 02")
		check(not lantern.activated and not lantern.activation_playing, "Checkpoint waits for the hand-contact frame")
		action("interact", false)
		var watchdog := 0
		while player.visual.frame < 4 and watchdog < 60:
			await frames(1)
			watchdog += 1
		check(lantern.activated and lantern.activation_playing and lantern.visual.frame == 0, "Red frame 04 starts lantern activation frame 00")
		check(player.current_health == 100 and session.checkpoint_position.is_equal_approx(spawn), "Contact heals once and saves the safe respawn")
		check(session.activated_checkpoints.has(lantern.identifier), "Activated history is persisted")
		await screenshot("lantern_%d_contact" % index)
		for name in ["move_left", "jump", "attack", "dash", "interact"]:
			await tap(name)
		check(sequence.phase == "lighting" and player.action_state == player.Action.INTERACT, "Confirmed interaction ignores normal controls and repeated E")
		await frames(70)
		check(sequence.phase == "idle" and player.action_state == player.Action.NONE, "Sequence completes and unlocks controls")
		check(lantern.visual.animation == "active" and lantern.visual.is_playing(), "Activation transitions into the five-frame idle loop")
		check(lantern.activation_count == 1, "Large activation plays exactly once")
		await screenshot("lantern_%d_active" % index)
		await frames(30)
		check(camera.zoom.is_equal_approx(Vector2(1.35, 1.35)), "Successful lighting restores 1.35 gameplay zoom")
		player.current_health = 44
		await tap("interact")
		check(player.current_health == 44 and lantern.activation_count == 1 and sequence.phase == "idle", "Returning to a lit lantern cannot heal or replay")
		check(player.get_node("InteractionRouter").select_target() == null, "Lit lantern no longer offers the lighting prompt")
	# Use a fresh scene to cover cancellation and restoration on forced states.
	session.activated_checkpoints.clear()
	session.checkpoint_scene = ""
	change_scene_to_file("res://scenes/main.tscn")
	await frames(15)
	player = current_scene.get_node("Player")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)
	sequence = player.lantern_sequence
	var lantern: Node2D = get_nodes_in_group("forest_checkpoints")[0]
	var spawn := lantern.global_position + Vector2(0, -15)
	await place(spawn + Vector2(-18, 0))
	player.global_position.x -= 100
	await frames(4)
	check(sequence.phase == "idle" and not lantern.activated, "Leaving range cancels safely without saving")
	await place(spawn + Vector2(-18, 0))
	player.invulnerable = 0
	player.take_damage(8)
	check(sequence.phase == "idle" and player.action_state == player.Action.HURT and not lantern.activated, "Damage interrupts waiting and clears the lock")
	await frames(70)
	await place(spawn + Vector2(-100, 0))
	await place(spawn + Vector2(-18, 0))
	await tap("interact")
	player.invulnerable = 0
	player.take_damage(8)
	check(sequence.phase == "idle" and not lantern.activated and not lantern.interaction_busy, "Damage before contact cancels the activation attempt")
	await frames(70)
	await place(spawn + Vector2(-100, 0))
	await place(spawn + Vector2(-18, 0))
	await tap("interact")
	await frames(20)
	player.invulnerable = 0
	player.take_damage(8)
	await frames(70)
	check(sequence.phase == "idle" and lantern.activated and lantern.visual.animation == "active", "Damage after contact keeps the saved lantern and completes its idle transition")
	var retry_position: Vector2 = session.checkpoint_position
	session.pending_spawn = true
	change_scene_to_file("res://scenes/main.tscn")
	await frames(20)
	player = current_scene.get_node("Player")
	check(player.global_position.distance_to(retry_position) < 1 and player.current_health == 100, "Retry restores the lit checkpoint with full HP")
	check(get_nodes_in_group("forest_checkpoints")[0].visual.animation == "active", "Reload uses active idle without replaying activation")
	session.activated_checkpoints.clear()
	session.checkpoint_scene = ""
	change_scene_to_file("res://scenes/main.tscn")
	await frames(15)
	player = current_scene.get_node("Player")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)
	await place(Vector2(1082, 485))
	sequence = player.lantern_sequence
	session.transitioning = true
	await frames(3)
	check(sequence.phase == "idle" and player.action_state == player.Action.NONE, "Scene-transition flag releases the interaction state")
	session.transitioning = false
	await place(Vector2(1000, 485))
	await place(Vector2(1082, 485))
	player.invulnerable = 0
	player.take_damage(1000)
	check(sequence.phase == "idle" and player.dead and player.action_state == player.Action.DEAD, "Death clears the interaction before its presentation takes over")
	await frames(3)
	root.get_node("GameSession/DeathPresentation")._finish()
	for name in captures:
		captures[name].save_png("res://.godot/moon_lantern_review/" + name + ".png")
	print("MOON LANTERN: ", checks, " checks, ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(0 if failures == 0 else 1)
