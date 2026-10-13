extends SceneTree

# Visual QA at the game's native 960x540 resolution; use --presentation-test.
const DIRECTORY := "res://.godot/red_visual_checks/"

func _initialize() -> void:
	call_deferred("_run")

func wait(seconds: float = .1) -> void:
	await create_timer(seconds).timeout

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIRECTORY + name + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	change_scene_to_file("res://scenes/stage2_boss.tscn")
	await wait(.3)
	var player: CharacterBody2D = current_scene.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector2(1500, 485)
	player.get_node("Camera2D").enabled = false
	var camera := Camera2D.new()
	camera.position = Vector2(1500, 380)
	current_scene.add_child(camera)
	camera.make_current()
	var boss: CharacterBody2D = get_first_node_in_group("boss")
	boss.set_physics_process(false)
	boss.position = Vector2(1780, 500)
	boss.get_node("Visual").play("idle")
	for clip in ["idle", "walk", "run", "dash", "jump", "fall", "land", "recover", "crouch_hold", "crouch_move", "attack_slash", "air_attack_1", "air_attack_2", "air_attack_3", "rising_slash", "downward_slash", "crescent_cast", "hurt", "death", "victory_stage1_bittersweet"]:
		player._cancel_action()
		player.position.y = 425 if clip in ["jump", "fall", "air_attack_1", "air_attack_2", "air_attack_3", "downward_slash"] else 485
		if clip in player.AIR_ATTACKS:
			# This pose-only capture disables physics; mark the requested air step.
			player.air_combo_step = player.AIR_ATTACKS.find(clip) + 1
			var profile: Vector3 = player.ANIMATIONS.AIR_VFX_PROFILES[player.air_combo_step - 1]
			player.vfx_anchor.position = Vector2(profile.x, profile.y)
			player.air_combo_effect.scale = Vector2.ONE * profile.z
		if clip in ["attack_slash", "air_attack_1", "air_attack_2", "air_attack_3", "rising_slash", "downward_slash"]:
			player.action_state = player.Action.ATTACK
			player.attack_animation = clip
			player._configure_attack()
		player._play_visual(clip)
		player.visual.pause()
		player.visual.frame = mini(3, player.visual.sprite_frames.get_frame_count(clip) - 1)
		await wait(.08)
		await capture(clip)
	for clip in ["rising_slash", "downward_slash"]:
		player.position.y = 425 if clip == "downward_slash" else 485
		for index in range(2, 8):
			player._cancel_action()
			player.action_state = player.Action.ATTACK
			player.attack_animation = clip
			player._configure_attack()
			player._play_visual(clip)
			player.visual.pause()
			player.visual.frame = index
			await wait(.04)
			await capture(clip + "_%02d" % index)
	player.position.y = 485
	player.reset_physics_interpolation()
	player._cancel_action()
	player._play_visual("death")
	player.visual.pause()
	for index in range(8):
		player.visual.frame = index
		await wait(.05)
		await capture("death_%02d" % index)
	change_scene_to_file("res://scenes/title.tscn")
	await wait(.6)
	await capture("title")
	change_scene_to_file("res://scenes/game_over.tscn")
	await wait(.6)
	await capture("game_over")
	var session := root.get_node("GameSession")
	for path: String in [session.settings_path, session.save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RED VISUAL CHECKS: 40 native-resolution captures saved")
	quit()
