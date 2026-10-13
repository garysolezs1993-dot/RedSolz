extends SceneTree

# Preview the real death sequence without altering normal gameplay or save data.
# --script res://tools/capture_death_presentation.gd -- --presentation-test
# Optional --airborne captures Red settling onto the platform below her.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var airborne := OS.get_cmdline_user_args().has("--airborne")
	var folder := "res://.godot/death_presentation_air/" if airborne else "res://.godot/death_presentation/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	change_scene_to_file("res://scenes/stage2_boss.tscn")
	await create_timer(.25).timeout
	var player: CharacterBody2D = current_scene.get_node("Player")
	player.position = Vector2(1400, 320 if airborne else 485)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10
	player.reset_physics_interpolation()
	player.get_node("Camera2D").reset_smoothing()
	await create_timer(.08 if airborne else .3).timeout
	player.invulnerable = 0
	player.take_damage(1000)
	var presentation: Node = root.get_node("GameSession/DeathPresentation")
	var log := FileAccess.open(folder + "timeline.txt", FileAccess.WRITE)
	var started := Time.get_ticks_msec()
	var index := 0
	while Time.get_ticks_msec() - started < 6500:
		await create_timer(.08, true, false, true).timeout
		var line := "%dms phase=%s paused=%s transitioning=%s" % [Time.get_ticks_msec() - started, presentation.phase, paused, root.get_node("GameSession").transitioning]
		if is_instance_valid(player):
			line += " position=%s animation=%s frame=%d" % [player.position, player.visual.animation, player.visual.frame]
		log.store_line(line)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder + "%03d_%s.png" % [index, presentation.phase])
		index += 1
		if not presentation.active:
			break
	log.close()
	print("DEATH PREVIEW: ", index, " captures; phase=", presentation.phase, "; paused=", paused)
	print("Scene: ", current_scene.scene_file_path)
	for path: String in [root.get_node("GameSession").settings_path, root.get_node("GameSession").save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()
