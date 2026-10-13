extends SceneTree

# Run with --script res://tools/tests/test_presentation.gd -- --presentation-test.
# Separate user:// test files keep the player's settings and checkpoint untouched.
var failures := 0
var checks := 0
var session: Node
var audio: Node
const STAGE_ONE_MAP := preload("res://scripts/stage1_definition.gd")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	print("PASS: " if condition else "FAIL: ", message)
	if not condition:
		failures += 1

func wait(seconds: float = 0.1) -> void:
	await create_timer(seconds).timeout

func input_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(action: String) -> void:
	input_action(action, true)
	await wait(0.05)
	input_action(action, false)
	await wait(0.05)

func tap_controller(index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	Input.parse_input_event(event)
	await wait(.05)
	event = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = false
	Input.parse_input_event(event)
	await wait(.05)

func scene_is(path: String) -> bool:
	return current_scene != null and current_scene.scene_file_path == path

func button(node_name: String) -> Button:
	return current_scene.find_child(node_name, true, false) as Button

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://.godot/presentation_checks/" + name + ".png")

func place(player: CharacterBody2D, where: Vector2) -> void:
	player.global_position = where
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()

func clear_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_presentation.cfg"
	session = root.get_node("GameSession")
	audio = root.get_node("AudioDirector")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/presentation_checks"))
	check(str(session.save_path).contains("presentation_test"), "Isolated test save files")
	session.checkpoint_scene = ""
	if FileAccess.file_exists(session.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(session.save_path))
	check(not session.has_valid_save(), "Continue rejects missing save")
	check(not session._valid_checkpoint("res://scenes/title.tscn", Vector2(70, 485)), "Continue rejects non-stage scenes")
	check(not session._valid_checkpoint(session.STAGE_ONE, Vector2(NAN, 485)), "Continue rejects invalid coordinates")
	change_scene_to_file("res://scenes/title.tscn")
	await wait(1)
	check(button("ContinueGame") == null, "Continue hidden without save")
	check(root.gui_get_focus_owner() == button("StartGame"), "Start has initial focus")
	await tap_controller(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner() == button("Settings"), "Controller D-pad navigates menu")
	await tap_controller(JOY_BUTTON_A)
	var controller_settings: Control = current_scene.find_child("AudioSettings", true, false)
	check(controller_settings.visible, "Controller A opens Settings")
	controller_settings.close()
	button("StartGame").grab_focus()
	await tap("ui_down")
	check(root.gui_get_focus_owner() == button("Settings"), "Keyboard down selects Settings")
	await tap("ui_accept")
	var settings: Control = current_scene.find_child("AudioSettings", true, false)
	check(settings.visible and root.gui_get_focus_owner() == settings.music_slider, "Keyboard accept opens Settings")
	settings.music_slider.value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music slider independently mutes music")
	settings.music_slider.value = 55
	settings.sfx_slider.value = 61
	var config := ConfigFile.new()
	config.load(session.settings_path)
	check(is_equal_approx(float(config.get_value("audio", "sfx")), .61), "Audio settings persist to disk")
	session.music_volume = .1
	session.sfx_volume = .1
	session._load_settings()
	check(is_equal_approx(session.music_volume, .55) and is_equal_approx(session.sfx_volume, .61), "Saved audio levels reload correctly")
	await capture("settings")
	await tap("ui_cancel")
	check(not settings.visible and root.gui_get_focus_owner() == button("Settings"), "Back restores menu focus")
	button("StartGame").grab_focus()
	await capture("title")
	await tap("ui_accept")
	await wait(1)
	check(scene_is(session.STAGE_ONE), "Start loads Stage 1")
	check(audio.current_context == "stage_one", "Stage 1 requests gameplay score")
	check(audio.music_player.playing and audio.music_player.stream.resource_path.ends_with("silent_forest_theme.wav"), "Only persistent music player plays stage music")
	check(not current_scene.get_node("AudioManager/Music").playing, "Scene-local music is stopped")
	check(get_nodes_in_group("forest_hazards").size() == 8, "Six existing chapter hazards and two upper-ruins hazards")
	check(get_nodes_in_group("forest_platforms").size() == 5, "Two moving and three optional crumbling platforms placed")
	check(get_nodes_in_group("forest_checkpoints").size() == 3, "Three meaningful chapter checkpoints placed")
	clear_enemies()
	await wait(.1)
	var player: CharacterBody2D = current_scene.get_node("Player")
	# Isolated fixtures cover retained hazard types without adding them to Stage 1.
	var test_layout := current_scene.get_node("Stage1Layout")
	test_layout._add_challenge("RegressionSpikes", "ground_spikes", Vector2(355, 500), {})
	# Keep this hazard fixture away from the new automatic waiting-pose range.
	test_layout._add_challenge("RegressionRetractable", "retractable_spikes", Vector2(1915, 500), {})
	# A clear fixture lane avoids the hub's real upper-branch ledges.
	test_layout._add_challenge("RegressionFerry", "moving_platform", Vector2(1180, 455), {"travel": Vector2(240, 0), "width": 150.0})
	test_layout._add_challenge("RegressionFerrySpikes", "ground_spikes", Vector2(1315, 500), {"width": 90.0})
	# Real collision: jump out from below the former solid ceiling.
	place(player, Vector2(2400, 575))
	await wait(.15)
	await tap("jump")
	await wait(.18)
	await tap("jump")
	await wait(.6)
	check(player.global_position.y < 500 and player.is_on_floor(), "Double jump returns from safety floor through main floor")
	# Introduction spikes: ordinary jump from the left, existing overhead ledge is safe.
	place(player, Vector2(291, 485))
	player.current_health = 100
	player.invulnerable = 0
	await wait(.12)
	input_action("move_right", true)
	await tap("jump")
	await wait(.66)
	input_action("move_right", false)
	check(player.global_position.x > 388 and player.current_health == 100, "Intro spikes avoidable with existing jump")
	# Actual hazard hit and dash immunity.
	var spikes: Node2D = current_scene.get_node("Stage1Layout/RegressionSpikes")
	place(player, Vector2(355, 485))
	player.invulnerable = 0
	await wait(.12)
	check(player.current_health < 100, "Visible spike collider damages Red and updates health")
	await wait(.55)
	place(player, Vector2(322, 485))
	player.current_health = 100
	player.invulnerable = 0
	player.cooldown = 0
	player.facing = 1
	await wait(.1)
	await tap("dash")
	check(player.invulnerable > .5, "Dash retains 0.7 second invulnerability")
	await wait(.22)
	print("DASH DETAIL: player=", player.global_position, " health=", player.current_health, " iframe=", player.invulnerable)
	check(player.current_health == 100 and player.global_position.x > 385, "Dash crosses spikes without damage")
	check(spikes.danger.get_child(0).polygon == spikes.polygons[0], "Spike collision uses the exact drawn polygon")
	# Predictable warning, synchronized visual/collision height, and safe waiting window.
	var roots: Node2D = current_scene.get_node("Stage1Layout/DashPracticeRoots")
	roots.elapsed = roots.rest_time - .1
	place(player, Vector2(2385, 485))
	await wait(.2)
	check(roots.state == "warning" and not roots.danger_enabled, "Cursed root warning precedes danger")
	await wait(roots.warning_time + .12)
	check(roots.state == "active" and roots.danger_enabled and is_equal_approx(roots.danger.scale.y, roots.display_strength), "Root collision rises with visible geometry")
	await wait(roots.active_time + .1)
	check(not roots.danger_enabled, "Root collision switches off when roots withdraw")
	var retract: Node2D = current_scene.get_node("Stage1Layout/RegressionRetractable")
	retract.elapsed = 0
	place(player, Vector2(1860, 485))
	player.current_health = 100
	player.invulnerable = 0
	await wait(.1)
	input_action("move_right", true)
	await wait(.85)
	input_action("move_right", false)
	check(player.global_position.x > 1955 and player.current_health == 100, "Retractable spikes can be walked across during safe rest")
	place(player, Vector2(1985, 485))
	await wait(.15)
	player.current_health = 100
	player.invulnerable = 0
	input_action("move_right", true)
	await tap("jump")
	await wait(.22)
	await tap("jump")
	await wait(.65)
	input_action("move_right", false)
	check(player.global_position.x > 2096 and player.current_health == 100, "Thorn vines avoidable with existing double jump")
	var branch: Node2D = current_scene.get_node("Stage1Layout/CampFallingBranch")
	place(player, Vector2(2250, 485))
	branch.state = "rest"
	branch.age = branch.rest_time
	await wait(.12)
	check(branch.state == "warning" and not branch.danger_enabled, "Branch shakes before becoming dangerous")
	place(player, Vector2(2330, 485))
	player.current_health = 100
	await wait(1.8)
	check(player.current_health == 100, "Walking away during branch warning avoids damage")
	# One-way crumbling platform: lands, warns, disappears and returns.
	var crumble: AnimatableBody2D = current_scene.get_node("Stage1Layout/ChapelCrumblingShelf")
	place(player, crumble.origin + Vector2(0, -35))
	await wait(.32)
	check(crumble.state == "warning", "Landing starts crumble warning")
	await wait(crumble.collapse_delay + .1)
	check(crumble.state == "collapsed" and crumble.shape.disabled, "Crumbling platform removes collision after warning")
	place(player, Vector2(3500, 485))
	await wait(crumble.respawn_delay + .1)
	check(crumble.state == "stable" and not crumble.shape.disabled, "Crumbling platform safely respawns")
	var ferry: AnimatableBody2D = current_scene.get_node("Stage1Layout/RegressionFerry")
	ferry.elapsed = 0.0
	await wait(.03)
	place(player, ferry.global_position + Vector2(0, -16))
	await wait(.3)
	var old_x := player.global_position.x
	var old_offset := player.global_position.x - ferry.global_position.x
	await wait(.5)
	check(absf(player.global_position.x - old_x) > 4 and absf(player.global_position.x - ferry.global_position.x - old_offset) < 6, "Moving platform carries Red")
	player.current_health = 100
	player.invulnerable = 0
	await wait(1.65)
	check(player.global_position.x > 1373 and player.current_health == 100, "Moving ferry safely carries Red over the test spike bed")
	await tap("move_down") # Ordinary crouch preserves movement; explicit S+Space follows.
	input_action("move_down", true)
	await tap("jump")
	input_action("move_down", false)
	await wait(.2)
	check(player.global_position.y > 450, "S+Space drops through moving platform")
	# Checkpoint save, HUD, actual death animations and Try Again flow.
	var checkpoint_position := Vector2(float(STAGE_ONE_MAP.CHECKPOINT_X[0]), 485)
	place(player, checkpoint_position)
	player.current_health = 40
	await wait(.15)
	check(player.current_health == 40, "Checkpoint does not heal on contact")
	await tap("interact")
	await wait(1.6) # Explicit lighting sequence saves at contact, not key-down.
	check(session.checkpoint_position.is_equal_approx(checkpoint_position) and player.current_health == 100, "E saves safe checkpoint position and heals Red")
	await capture("stage1_root_passage")
	player.invulnerable = 0
	player.take_damage(100)
	await wait(5.2)
	check(scene_is("res://scenes/game_over.tscn"), "Lethal damage reaches Game Over after Red's animations")
	check(audio.current_context == "game_over" and audio.music_player.stream.resource_path.ends_with("promise_to_rise.wav"), "Death replaces gameplay music with separate Game Over track")
	check(session.toast.modulate.a == 0, "Checkpoint toast does not leak into Game Over")
	await capture("game_over")
	check(root.gui_get_focus_owner() == button("TryAgain"), "Try Again has initial focus")
	await tap("ui_accept")
	await wait(1)
	check(scene_is(session.STAGE_ONE), "Try Again reloads current stage")
	player = current_scene.get_node("Player")
	check(absf(player.global_position.x - checkpoint_position.x) < 2 and player.current_health == 100, "Retry restores checkpoint with full HP")
	clear_enemies()
	await wait(.1)
	# Gate remains usable through the original Up Arrow route.
	for marker in STAGE_ONE_MAP.SEALS:
		place(player, marker[1] + Vector2(0, -15))
		await wait(.15)
		await tap("interact")
		if str(marker[0]) == "camp_moon_seal":
			await wait(8)
	place(player, Vector2(STAGE_ONE_MAP.GATE_POSITION.x, 485))
	player.current_health = 72
	await wait(.2)
	await tap("ui_up")
	await wait(1)
	check(scene_is(session.STAGE_TWO), "Up Arrow at Moon Gate still reaches Stage 2")
	player = current_scene.get_node("Player")
	check(player.current_health == 72, "Gate preserves carried health")
	check(session.checkpoint_scene == session.STAGE_TWO, "Stage 2 entry becomes a valid Continue checkpoint")
	check(audio.current_context == "stage_two", "Stage 2 retains its boss score")
	player.invulnerable = 0
	player.take_damage(100)
	await wait(5.2)
	await tap("ui_down")
	check(root.gui_get_focus_owner() == button("ReturnToTitle"), "Game Over navigation selects Return to Title")
	await tap("ui_accept")
	await wait(1)
	check(scene_is(session.TITLE) and audio.current_context == "title", "Return to Title restores menu and menu music")
	check(audio.music_player.stream.resource_path.ends_with("witchs_lullaby.wav"), "Title uses its own distinct score")
	check(audio.music_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and audio.music_player.stream.loop_end > 10000, "Menu score has valid full-track loop points")
	check(button("ContinueGame") != null, "Continue is visible with saved progress")
	button("ContinueGame").pressed.emit()
	await wait(1)
	check(scene_is(session.STAGE_TWO), "Continue reloads saved Stage 2")
	check(current_scene.get_node("Player").current_health == 100, "Continue restores full health")
	for path: String in [session.settings_path, session.save_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PRESENTATION CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
