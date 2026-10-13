extends SceneTree

# Final rendered review, without simulated-time acceleration/interpolation artifacts.
var player: CharacterBody2D
var images: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _run() -> void:
	var session := root.get_node("GameSession")
	session.pending_spawn = false
	session.collected_petals.clear()
	session.learned_mechanics.clear()
	session.checkpoint_position = Vector2(70, 485)
	change_scene_to_file("res://scenes/main.tscn")
	await frames(15)
	player = current_scene.get_node("Player")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)
		wolf.visual.flip_h = true
	for entry in [
		["platform_camp", Vector2(2490, 485)],
		["platform_chapel", Vector2(3810, 485)],
		["platform_creek", Vector2(5630, 485)],
		["platform_oak_trail", Vector2(7330, 485)],
		["platform_oak_canopy", Vector2(8140, -43)],
		["platform_cellar", Vector2(8000, 725)],
		["platform_burial", Vector2(9440, 341)],
		["platform_heartwood", Vector2(10020, 485)],
		["platform_quiet_approach", Vector2(10520, 485)],
		["platform_moon_gate", Vector2(11020, 485)],
		["platform_return_steps", Vector2(9000, 790)],

	]:
		player._cancel_action()
		player.position = entry[1]
		player.velocity = Vector2.ZERO
		player.invulnerable = 100
		player.reset_physics_interpolation()
		await frames(35)
		session.toast.modulate.a = 0
		player.get_node("Camera2D").reset_smoothing()
		player.get_node("Camera2D").force_update_scroll()
		await frames(3)
		await RenderingServer.frame_post_draw
		images[entry[0]] = root.get_texture().get_image()
	for label in images:
		images[label].save_png("res://docs/previews/" + label + ".png")
	print("PLATFORM ROLLOUT PREVIEWS: ", images.size())
	current_scene.queue_free()
	await frames(3)
	quit()
