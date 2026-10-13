extends SceneTree

const EXPECTED_PATHS := {
	2: "moonlit_wolf_with_crimson_lily.png",
	3: "moonlit_recognition_in_the_crimson_forest.png",
	4: "golden_lily_in_the_ruined_garden.png",
	6: "moonlit_wolf_and_crimson_hood.png",
	7: "crimson_moon_wolf_showdown.png",
}
var checks := 0
var failures := 0
var session: Node
var stage: Node
var intro: Node
var player: CharacterBody2D
var boss: CharacterBody2D
var expected_health := 0
var expected_player_health := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func frames(count: int) -> void:
	for index in range(count):
		await process_frame

func fresh_stage() -> void:
	change_scene_to_file(session.STAGE_TWO)
	await frames(20)
	stage = current_scene
	intro = stage.get_node("BossIntroCutscene")
	player = stage.get_node("Player")
	boss = stage.get_node("Stage2BossLayout/CursedWolfBoss")
	expected_health = boss.get("health")
	expected_player_health = player.get("current_health")

func trigger_intro() -> void:
	player.global_position = Vector2(float(intro.get("trigger_x")) + 10, 485)
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await frames(3)

func wait_phase(target: String) -> bool:
	for index in range(1900):
		if not is_instance_valid(intro) or not intro.is_inside_tree():
			return false
		if intro.get("phase") == target:
			return true
		await process_frame
	return false

func handoff(label: String) -> void:
	check(not paused, label + ": gameplay unpaused")
	check(stage.get_node_or_null("BossIntroCutscene") == null, label + ": cinematic UI/controller removed")
	check(root.get_camera_2d() == player.get_node("Camera2D"), label + ": gameplay camera restored")
	check(stage.get_node("UI/HUD").visible and is_equal_approx(stage.get_node("UI/HUD").modulate.a, 1), label + ": HUD visible at full opacity")
	var bar := stage.get_node("UI/HUD/BossHP") as ProgressBar
	check(bar.visible and is_equal_approx(bar.modulate.a, 1), label + ": boss HP visible at full opacity")
	check(is_equal_approx(bar.max_value, float(boss.get("maximum_health"))) and is_equal_approx(bar.value, float(expected_health)), label + ": boss HP initialized")
	var opening_grace := stage.get_node_or_null("BossOpeningGrace")
	var ai_ready := boss.process_mode == Node.PROCESS_MODE_INHERIT or (opening_grace != null and boss.process_mode == Node.PROCESS_MODE_DISABLED)
	check(ai_ready and boss.collision_layer == 2 and boss.get_node("Hurtbox").collision_layer == 2, label + ": boss body/hurtbox restored, AI ready or holding opening grace")
	check(boss.get("health") == expected_health and player.get("current_health") == expected_player_health, label + ": no cinematic damage or health reset")
	check(not stage.get_meta("boss_intro_pending"), label + ": intro gate cleared")
	check(player.get("action_state") == 0 and is_equal_approx(player.global_position.y, 485), label + ": Red idle on solid floor")
	check(root.get_node("AudioDirector").current_context == "stage_two", label + ": combat music context restored")
	check(player.get_node("Visual").process_mode == Node.PROCESS_MODE_INHERIT, label + ": animation processing restored")

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://boss_intro_final_art_test.cfg"
	session.checkpoint_scene = session.STAGE_TWO
	session.checkpoint_position = Vector2(70, 485)
	session.pending_spawn = false
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	await fresh_stage()
	check(not paused and intro.get("phase") == "waiting", "Entrance remains playable before the trigger")
	check(not stage.get_node("UI/HUD/BossHP").visible, "Boss HUD hidden before intro")
	for index in range(8):
		var texture: Texture2D = intro.get("panel_textures")[index]
		if EXPECTED_PATHS.has(index):
			check(texture != null and texture.resource_path.ends_with(EXPECTED_PATHS[index]), "Correct final texture at slot " + str(index + 1))
		else:
			check(texture == null, "In-engine fallback retained at slot " + str(index + 1))
	await trigger_intro()
	var seen: Dictionary = {}
	var seen_art: Dictionary = {}
	var brother_seen := false
	var run_seen := false
	for index in range(1900):
		await process_frame
		if stage.get_node_or_null("BossIntroCutscene") == null:
			break
		var phase: String = intro.get("phase")
		if not seen.has(phase):
			seen[phase] = true
			check(paused and boss.process_mode == Node.PROCESS_MODE_DISABLED, phase + ": world/AI locked")
			if phase != "hud_reveal":
				check(not stage.get_node("UI/HUD").visible, phase + ": gameplay HUD hidden")
		var shot: int = intro.get("current_shot")
		var artwork: TextureRect = intro.get("artwork")
		if EXPECTED_PATHS.has(shot) and artwork.visible and not seen_art.has(shot):
			seen_art[shot] = true
			check(artwork.texture.resource_path.ends_with(EXPECTED_PATHS[shot]), "Displayed artwork matches slot " + str(shot + 1))
			check(not intro.get("placeholder").visible and not intro.get("panel_note").visible, "Final art hides placeholder at slot " + str(shot + 1))
			check(artwork.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Aspect preserved at slot " + str(shot + 1))
		if intro.get("dialogue").text == "...Brother?":
			brother_seen = true
		if intro.get("dialogue").text == "Run.":
			run_seen = true
	check(seen_art.size() == 5, "All five final illustrations displayed during full run")
	check(brother_seen and run_seen, "Both dialogue lines rendered separately")
	check(seen.has("boss_title") and seen.has("hud_reveal"), "Boss title precedes HUD handoff")
	await frames(3)
	handoff("Watched")
	for target in ["waiting", "entry", "silent_wolf", "lily", "recognition", "memory", "brother", "wolf_turn", "run", "curse_takeover", "return_camera", "boss_title", "hud_reveal"]:
		await fresh_stage()
		if target != "waiting":
			await trigger_intro()
			check(await wait_phase(target), "Reached Skip phase " + target)
		if target == "run":
			var event := InputEventKey.new()
			event.keycode = KEY_ESCAPE
			event.pressed = true
			Input.parse_input_event(event)
		elif target == "curse_takeover":
			var event := InputEventJoypadButton.new()
			event.button_index = JOY_BUTTON_START
			event.pressed = true
			Input.parse_input_event(event)
		elif target == "memory":
			(intro.get("skip_button") as Button).pressed.emit()
		else:
			intro.call("skip")
		if is_instance_valid(intro):
			intro.call("skip") # repeated requests must not duplicate handoff.
		await frames(4)
		handoff("Skip " + target)
	# The final skipped fight must accept ordinary movement, basic attack and dash.
	var starting_x := player.global_position.x
	Input.action_press("move_right")
	await frames(15)
	Input.action_release("move_right")
	check(player.global_position.x > starting_x + 5, "Movement works after Skip")
	await frames(15)
	Input.action_press("attack")
	await frames(2)
	Input.action_release("attack")
	check(player.get("attacking"), "Basic attack works after Skip")
	Input.action_press("dash")
	await frames(2)
	Input.action_release("dash")
	check(float(player.get("dash_timer")) > 0, "Dash cancellation works after Skip")
	print("BOSS INTRO FINAL ART: ", checks, " checks; ", failures, " failures")
	quit(0 if failures == 0 else 1)
