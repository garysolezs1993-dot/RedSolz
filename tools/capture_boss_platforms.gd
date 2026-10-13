extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://presentation_boss_platform_capture.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_TWO
	session.checkpoint_position = Vector2(70, 485)
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	change_scene_to_file(session.STAGE_TWO)
	await frames(20)
	# This tool reviews the arena artwork rather than the narrative sequence.
	var intro := current_scene.get_node_or_null("BossIntroCutscene")
	if intro != null:
		intro.skip()
	await frames(2)
	var player := current_scene.get_node("Player") as CharacterBody2D
	var boss := current_scene.get_node("Stage2BossLayout/CursedWolfBoss") as CharacterBody2D
	boss.set_physics_process(false)
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	boss.velocity = Vector2.ZERO
	boss.position = Vector2(1860, 500)
	boss.reset_physics_interpolation()
	for entry in [["entrance", Vector2(220, 485)], ["arena", Vector2(1720, 485)]]:
		player.position = entry[1]
		player.reset_physics_interpolation()
		var camera := player.get_node("Camera2D") as Camera2D
		camera.reset_smoothing()
		camera.force_update_scroll()
		await frames(10)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/previews/boss_platforms_" + str(entry[0]) + ".png")
	print("BOSS PLATFORM PREVIEWS: 2")
	current_scene.queue_free()
	await frames(3)
	quit()
