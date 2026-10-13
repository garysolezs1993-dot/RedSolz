extends SceneTree

# --script res://tools/tests/check_red_idle_grounding.gd -- --presentation-test
# With a renderer, also captures all eight poses in the real Stage 1.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(.3).timeout
	var player: CharacterBody2D = current_scene.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector2(70, 485)
	player.reset_physics_interpolation()
	player._play_visual("idle")
	player.visual.pause()
	var directory := "res://.godot/red_idle_grounding/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for index in range(8):
		player.visual.frame = index
		var sole: float = player.ANIMATIONS.IDLE_FOOT_LINES[index]
		var foot_y: float = player.visual.position.y + (sole - 256) * player.visual.scale.y
		if not is_equal_approx(foot_y, 15.0) or not player.visual.scale.is_equal_approx(Vector2(.105, .105)):
			failures += 1
			push_error("Idle grounding or scale changed at frame %d" % index)
		print("IDLE FRAME %d: local feet=%f, position=%s" % [index, foot_y, player.visual.position])
		if DisplayServer.get_name() != "headless":
			await create_timer(.05).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory + "idle_%02d.png" % index)
	# Returning from a corrected later pose must restore the next clip's pivot.
	player.visual.frame = 4
	player._play_visual("attack_slash")
	if not player.visual.position.is_equal_approx(Vector2(0, -7)) or player.visual.scale != Vector2.ONE:
		failures += 1
	player._play_visual("idle")
	if not player.visual.position.is_equal_approx(Vector2(0, -7.47)):
		failures += 1
	print("RED IDLE GROUNDING: ", failures, " failures")
	quit(1 if failures else 0)
