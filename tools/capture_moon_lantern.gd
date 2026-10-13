extends SceneTree

# Normal renderer timing for final visual review; saves isolated by the flag.
var captures: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func capture(name: String, player: CharacterBody2D) -> void:
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await RenderingServer.frame_post_draw
	captures[name] = root.get_texture().get_image()

func _run() -> void:
	var session := root.get_node("GameSession")
	session.pending_spawn = false
	session.checkpoint_scene = ""
	session.activated_checkpoints.clear()
	change_scene_to_file("res://scenes/main.tscn")
	await frames(15)
	var player: CharacterBody2D = current_scene.get_node("Player")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)
	var lanterns := get_nodes_in_group("forest_checkpoints")
	for index in range(lanterns.size()):
		var lantern: Node2D = lanterns[index]
		player.global_position = lantern.global_position + Vector2(-18 if index != 1 else 36, -15)
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
		await frames(40)
		await capture("final_%d_waiting" % index, player)
		lantern.interact(player)
		await frames(19)
		await capture("final_%d_contact" % index, player)
		await frames(22)
		await capture("final_%d_burst" % index, player)
		await frames(65)
		await capture("final_%d_active" % index, player)
	for name in captures:
		captures[name].save_png("res://.godot/moon_lantern_review/" + name + ".png")
	print("LANTERN PREVIEWS: ", captures.size())
	current_scene.queue_free()
	await frames(3)
	quit()
