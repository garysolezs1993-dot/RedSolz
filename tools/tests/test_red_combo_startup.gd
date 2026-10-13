extends SceneTree

# Cold first-attack rendering check. Run without --headless, with
# --presentation-test [--review-name=before|after]. No combo prewarming.
var player: CharacterBody2D
var captures: Array[Image] = []
var trace: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Use --physics-ticks=10 to exaggerate interpolation between physics ticks.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--physics-ticks="):
			Engine.physics_ticks_per_second = int(arg.trim_prefix("--physics-ticks="))
	Engine.max_fps = 120
	var arena := Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = Vector2(960, 540)
	arena.add_child(background)
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2000, 50)
	collision.shape = shape
	floor_body.position = Vector2(480, 325)
	floor_body.add_child(collision)
	arena.add_child(floor_body)
	var source: Node = load("res://scenes/main.tscn").instantiate()
	player = source.get_node("Player")
	source.remove_child(player)
	source.free()
	player.position = Vector2(480, 285)
	player.get_node("Camera2D").enabled = false
	arena.add_child(player)
	player.visual.visible = false # Isolate only the attack VFX in the capture.
	await create_timer(.5).timeout
	assert(player.is_on_floor())
	var air_attack := OS.get_cmdline_user_args().has("--air-attack")
	var downward_attack := OS.get_cmdline_user_args().has("--downward-attack")
	if air_attack or downward_attack:
		var jump := InputEventAction.new()
		jump.action = "jump"
		jump.pressed = true
		Input.parse_input_event(jump)
		await create_timer(.15).timeout
		jump.pressed = false
		Input.parse_input_event(jump)
		assert(not player.is_on_floor())
	if downward_attack:
		var down := InputEventAction.new()
		down.action = "move_down"
		down.pressed = true
		Input.parse_input_event(down)
	var event := InputEventAction.new()
	event.action = "attack"
	event.pressed = true
	Input.parse_input_event(event)
	var effect: AnimatedSprite2D = player.air_combo_effect if air_attack else player.combo_effect
	if downward_attack:
		effect = player.downward_effect
	while not effect.visible:
		await process_frame
	for index in range(20):
		await RenderingServer.frame_post_draw
		captures.append(root.get_texture().get_image())
		trace.append({"frame": player.visual.frame,
			"fraction": Engine.get_physics_interpolation_fraction(),
			"scale": effect.scale.x})
	event.pressed = false
	Input.parse_input_event(event)
	var review_name := "after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-name="):
			review_name = arg.trim_prefix("--review-name=")
	var folder := "res://.godot/red_combo_startup/" + review_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for index in range(captures.size()):
		captures[index].save_png(folder + "/render_%02d.png" % index)
		# Only the VFX is visible over black. Sample its actual rendered extent,
		# since the node's scale property alone missed the original renderer bug.
		var left := 960
		var right := -1
		for y in range(0, 540, 4):
			for x in range(0, 960, 4):
				var color := captures[index].get_pixel(x, y)
				if maxf(color.r, maxf(color.g, color.b)) > .1:
					left = mini(left, x)
					right = maxi(right, x)
		assert(right >= left and right - left + 4 <= (64 if downward_attack else 60), "Oversized startup VFX in render %d" % index)
	var file := FileAccess.open(folder + "/trace.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(trace, "\t"))
	file.close()
	print("Cold attack: 20 rendered size checks passed without prewarming.")
	arena.queue_free()
	await process_frame
	quit()
