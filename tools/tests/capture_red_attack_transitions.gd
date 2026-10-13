extends SceneTree

# Render live attacks, including the transition back from 48px to 512px frames.
# --script res://tools/tests/capture_red_attack_transitions.gd -- --presentation-test
var output := "res://.godot/red_attack_transitions/"
var physics_rate := 60

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-folder="):
			output = "res://.godot/" + argument.trim_prefix("--capture-folder=") + "/"
		elif argument.begins_with("--physics-rate="):
			physics_rate = argument.trim_prefix("--physics-rate=").to_int()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	# More render frames between physics ticks expose scale interpolation errors.
	Engine.physics_ticks_per_second = physics_rate
	Engine.max_fps = 120
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))
	var source: Node = load("res://scenes/main.tscn").instantiate()
	var player: CharacterBody2D = source.get_node("Player")
	source.remove_child(player)
	source.free()
	var arena := Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2000, 50)
	shape.shape = rectangle
	floor_body.position = Vector2(480, 375)
	floor_body.add_child(shape)
	arena.add_child(floor_body)
	arena.add_child(player)
	player.get_node("Camera2D").enabled = false
	player.global_position = Vector2(480, 335)
	player.reset_physics_interpolation()
	await create_timer(.4).timeout
	var event := InputEventAction.new()
	event.action = "attack"
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	await process_frame
	event = InputEventAction.new()
	event.action = "attack"
	event.pressed = false
	Input.parse_input_event(event)
	var log := FileAccess.open(output + "frames.csv", FileAccess.WRITE)
	log.store_line("frame,animation,scale")
	var started := Time.get_ticks_msec()
	var index := 0
	while Time.get_ticks_msec() - started < 1100:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "frame_%03d.png" % index)
		log.store_line("%d,%s,%f" % [index, player.visual.animation, player.visual.scale.x])
		index += 1
	log.close()
	print("RED ATTACK TRANSITIONS: ", index, " live render frames in ", output)
	quit()
