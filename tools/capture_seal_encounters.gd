extends SceneTree

var player: CharacterBody2D
var layout: Node2D

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func place(where: Vector2) -> void:
	player._cancel_action()
	player.position = where
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(16)
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await frames(4)

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/seal_encounters_" + label + ".png")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://stage1_seal_encounters_capture.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(20)
	player = current_scene.get_node("Player")
	layout = current_scene.get_node("Stage1Layout")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	await place(Vector2(3870, 149))
	await capture("01_safe_chapel")
	layout.get_node("camp_moon_seal").interact(player)
	await frames(260)
	await capture("02_wisp_tour")
	await frames(230)
	await place(Vector2(4160, 725))
	await capture("03_cellar_guardians")
	await place(Vector2(6100, 435))
	await capture("04_upward_fork")
	await place(Vector2(7040, 273))
	await capture("05_hazard_crossing")
	await place(Vector2(7230, 3))
	await capture("06_canopy_lookout")
	await place(Vector2(8140, 111))
	await capture("07_sanctuary")
	await place(Vector2(8920, 273))
	await capture("08_quiet_descent")
	print("SEAL ENCOUNTER PREVIEWS: 8")
	current_scene.queue_free()
	await frames(3)
	quit()
