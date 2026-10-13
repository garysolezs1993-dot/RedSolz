extends SceneTree

var motion_frame := 0
const MOTION_DIR := "res://.godot/wisp_motion_preview/"

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/moon_wisp_" + label + ".png")

func capture_motion() -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(MOTION_DIR + "frame_%03d.png" % motion_frame)
	motion_frame += 1

func flight(visual: Node2D, start: Vector2, finish: Vector2, count: int) -> void:
	visual.global_position = start
	visual.face_travel(finish - start)
	visual.play_state("move")
	for index in range(count):
		visual.global_position = start.lerp(finish, float(index + 1) / count)
		await physics_frame
		if index % 5 == 4:
			await capture_motion()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOTION_DIR))
	var session := root.get_node("GameSession")
	session.save_path = "user://stage1_wisp_capture.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(20)
	var player := current_scene.get_node("Player") as CharacterBody2D
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.position = Vector2(3870, 149)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(20)
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await frames(4)
	var visual := preload("res://scenes/moon_wisp_visual.tscn").instantiate()
	current_scene.add_child(visual)
	visual.z_index = 7
	visual.global_position = player.global_position + Vector2(40, -28)
	visual.play_state("idle")
	for index in range(12):
		await frames(5)
		await capture_motion()
	await capture("01_idle_beside_red")
	var left := player.global_position + Vector2(-110, -65)
	var right := player.global_position + Vector2(110, -65)
	await flight(visual, left, right, 120)
	await capture("02_move_right")
	await capture("07_trail_history")
	await flight(visual, right, left, 120)
	await capture("03_move_left")
	await flight(visual, right, right + Vector2(0, -100), 60)
	await capture("04_move_up")
	visual.play_state("arrive", .7)
	for index in range(9):
		await frames(5)
		await capture_motion()
		if index == 4:
			await capture("05_arrival")
	await capture("08_after_disappear")
	visual.queue_free()
	current_scene.get_node("Stage1Layout/camp_moon_seal").interact(player)
	await frames(230)
	await capture("06_cinematic")
	await frames(280)
	print("MOON WISP PREVIEWS: 8; motion frames: ", motion_frame)
	current_scene.queue_free()
	await frames(3)
	quit()
