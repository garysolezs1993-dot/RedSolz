extends SceneTree

var checks := 0
var failures := 0
var player: CharacterBody2D
var session: Node
var layout: Node2D
var guide: Node2D

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

func input(key: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = key
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(key: String) -> void:
	input(key, true)
	await frames(2)
	input(key, false)
	await frames(2)

func place(seal: Node2D, distance: float) -> void:
	player._cancel_action()
	player.position = seal.position + Vector2(distance, -15)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(15)

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_moon_seal_flow.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(25)
	player = current_scene.get_node("Player")
	layout = current_scene.get_node("Stage1Layout")
	guide = layout.get_node("MoonWispGuide")
	var sample := layout.get_node("camp_moon_seal").art as AnimatedSprite2D
	for clip: String in ["dormant", "interact_ready", "activating", "activated_idle"]:
		var count := 1 if clip == "dormant" else (5 if clip == "activated_idle" else 8)
		check(sample.sprite_frames.get_frame_count(clip) == count, clip + " contains every supplied frame")
		check(sample.sprite_frames.get_animation_loop(clip) == (clip in ["interact_ready", "activated_idle"]), clip + " has the correct loop mode")
		for index in range(count):
			var texture := sample.sprite_frames.get_frame_texture(clip, index)
			check(texture != null and not texture is AtlasTexture and texture.resource_path.begins_with("res://assets/game_assets/moon_seal/"), clip + str(index) + " uses a complete new source PNG")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	# Later seals retain order and guardian checks.
	var second := layout.get_node("oak_moon_seal")
	await place(second, -45)
	await tap("interact")
	check(second.state == "interact_ready" and not second.activated, "Later seal cannot bypass order")
	check(session.toast.text.contains("Broken Chapel"), "Missing first seal remains explained")
	for seal_id: String in ["camp_moon_seal", "oak_moon_seal", "heartwood_moon_seal"]:
		var seal := layout.get_node(seal_id)
		await place(seal, -100)
		check(seal.state == "dormant" and seal.art.animation == "dormant" and not seal.art.is_playing(), seal_id + " static dormant state")
		check(seal.spirit.visible and seal.spirit.modulate.a < .3, seal_id + " subtle dormant spirit")
		check(not seal.spirit.trail_enabled and seal.spirit.trail_pool == null, seal_id + " hover has no strong trail or unused pool")
		var dormant_opacity: float = seal.spirit.modulate.a
		await place(seal, -45)
		check(seal.state == "interact_ready" and seal.art.animation == "interact_ready", seal_id + " entering range uses interaction set")
		check(seal.spirit.modulate.a > dormant_opacity, seal_id + " interaction spirit is brighter")
		check(not seal.activated, seal_id + " proximity does not activate")
		var ready_frames: Dictionary = {}
		for index in range(90):
			await physics_frame
			ready_frames[seal.art.frame] = true
		check(ready_frames.size() == 8, seal_id + " interaction loop plays every frame without restart")
		await place(seal, -100)
		check(seal.state == "dormant", seal_id + " leaving range restores dormant state")
		await place(seal, -45)
		if seal.living_guard_count() > 0:
			await tap("interact")
			check(seal.state != "activating" and not seal.activated and session.toast.text.contains("guardians"), seal_id + " living guards block activation")
			for name: String in seal.guard_names:
				layout.get_node(name).queue_free()
			await frames(3)
		if seal_id == "camp_moon_seal":
			# Damage aborts without saving, and restores ordinary controls.
			await tap("interact")
			await frames(15)
			player.invulnerable = 0
			player.take_damage(1)
			check(not seal.activated and seal.state != "activating" and player.seal_interaction == null, "Damage safely cancels uncommitted activation")
			Engine.time_scale = 1
			await frames(40)
			await place(seal, -45)
		var position_before := player.position
		var guide_spawns: int = guide.spawn_count
		await tap("interact")
		check(seal.state == "activating" and seal.wisp_state == "seal_react", seal_id + " E starts shrine and Wisp reaction")
		check(player.seal_interaction == seal and player.action_state == player.Action.INTERACT, seal_id + " owns player interaction lock")
		check(not seal.activated and guide.spawn_count == guide_spawns, seal_id + " no early save or guide release")
		var seen: Dictionary = {}
		var reaction_positions: Array[Vector2] = []
		input("move_right", true)
		for index in range(70):
			if index in [5, 20, 35]:
				input("jump", true)
				input("attack", true)
				input("dash", true)
				input("interact", true)
			else:
				input("jump", false)
				input("attack", false)
				input("dash", false)
				input("interact", false)
			await physics_frame
			seen[seal.art.frame] = true
			reaction_positions.append(seal.spirit.position)
			check(absf(player.position.x - position_before.x) < .1 and player.is_on_floor(), seal_id + " activation keeps Red grounded and stationary")
		input("move_right", false)
		input("jump", false)
		input("attack", false)
		input("dash", false)
		check(reaction_positions[15].distance_to(reaction_positions[45]) > 10, seal_id + " spirit circles then approaches rune")
		check(not seal.spirit.visible, seal_id + " spirit merges at surge frames")
		for index in range(18):
			await physics_frame
			if seal.state == "activating":
				seen[seal.art.frame] = true
		check(seen.size() == 8, seal_id + " all eight activation frames play")
		check(seal.activated and seal.activation_count == 1 and seal.state == "activated_idle", seal_id + " completes exactly once into idle loop")
		check(seal.art.animation == "activated_idle" and seal.art.is_playing(), seal_id + " completed shrine loops permanently")
		check(not seal.spirit.visible and player.seal_interaction == null, seal_id + " local spirit stops and lock clears")
		check(session.objective_completed(session.STAGE_ONE, seal_id), seal_id + " completion is saved after animation")
		check(guide.spawn_count == guide_spawns, seal_id + " short post-activation delay precedes release")
		await frames(35)
		check(guide.spawn_count == guide_spawns + 1 and guide.released_from_seal, seal_id + " releases one guide spirit")
		check(guide.origin.distance_to(seal.wisp_release_position()) < 1, seal_id + " guide emerges from the shrine rune")
		check(guide.cinematic_active == seal.full_cinematic and paused == seal.full_cinematic, seal_id + " configured camera behavior")
		check(guide.art.use_lily_trail == seal.full_cinematic, seal_id + " lily preview is limited to the first-seal cinematic")
		var guide_states: Dictionary = {guide.wisp_state: true}
		var max_trails := 0
		var duration := 0
		while guide.phase != "hidden" and duration < 540:
			await physics_frame
			duration += 1
			guide_states[guide.wisp_state] = true
			var guide_pool: Node2D = guide.art.lily_trail_pool if guide.art.use_lily_trail else guide.art.trail_pool
			if is_instance_valid(guide_pool):
				for trail in guide_pool.slots:
					if trail.get("active", false):
						max_trails = maxi(max_trails, 1)
		check(guide.phase == "hidden" and not guide.visible and not paused, seal_id + " guide disappears and control returns")
		check(guide_states.has("guide_move") and guide_states.has("guide_arrive") and guide_states.has("guide_disappear"), seal_id + " runs all guide states")
		check(max_trails > 0, seal_id + " movement emits lingering trail instances")
		var idle_frames: Dictionary = {}
		for index in range(65):
			await physics_frame
			idle_frames[seal.art.frame] = true
		check(idle_frames.size() == 5 and not seal.spirit.visible, seal_id + " all completed-idle frames loop without a local Wisp")
		if seal.full_cinematic:
			check(duration < 360 and player.get_node("Camera2D").is_current(), "First cinematic fits six seconds and restores Red's camera")
		if seal_id == "heartwood_moon_seal":
			check(guide.destination.x > seal.position.x and layout.get_node("StageTwoGate").is_unlocked(), "Final Wisp indicates the open Moon Gate")
		await tap("interact")
		check(seal.activation_count == 1, seal_id + " repeated E cannot reactivate")
	# Save/retry restores all completed loops without orbiters or release replays.
	reload_current_scene()
	await frames(25)
	layout = current_scene.get_node("Stage1Layout")
	guide = layout.get_node("MoonWispGuide")
	for seal in get_nodes_in_group("moon_seals"):
		check(seal.activated and seal.state == "activated_idle" and not seal.spirit.visible and seal.release_remaining < 0, "Saved completed shrine restores quietly: " + seal.identifier)
	check(guide.spawn_count == 0, "Reload never replays a release")
	print("MOON SEAL FLOW: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
