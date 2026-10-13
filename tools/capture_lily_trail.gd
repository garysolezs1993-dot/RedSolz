extends SceneTree

const MOVIE_DIR := "res://.godot/lily_trail_preview/"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOVIE_DIR))
	var session := root.get_node("GameSession")
	session.save_path = "user://lily_trail_capture.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70,485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	root.size = Vector2i(960,540)
	change_scene_to_file(session.STAGE_ONE)
	for index in range(25):
		await process_frame
	var player := current_scene.get_node("Player") as CharacterBody2D
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.position = Vector2(3870,149)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	for index in range(15):
		await process_frame
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	var guide := current_scene.get_node("Stage1Layout/MoonWispGuide")
	current_scene.get_node("Stage1Layout/camp_moon_seal").interact(player)
	var begun := false
	var last_phase := ""
	var movie_frame := 0
	var captured := false
	for index in range(650):
		await process_frame
		if guide.phase != last_phase:
			last_phase = guide.phase
			print("LILY PREVIEW PHASE: ", last_phase)
		begun = begun or guide.phase == "travel"
		if index % 6 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(MOVIE_DIR + "frame_%03d.png" % movie_frame)
			movie_frame += 1
		if guide.phase == "travel" and guide.elapsed >= 1.5 and not captured:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/previews/lily_trail_first_seal.png")
			captured = true
			print("LILY PREVIEW: active=", guide.art.lily_trail_pool.active_count, "; old trail emissions=", guide.art.trail_pool.spawned_count)
		if begun and guide.phase == "hidden":
			print("LILY PREVIEW COMPLETE: frames=", movie_frame, "; paused=", paused, "; remaining lilies=", guide.art.lily_trail_pool.active_count)
			quit()
			return
	push_error("Lily preview did not complete its guidance route")
	quit(1)
