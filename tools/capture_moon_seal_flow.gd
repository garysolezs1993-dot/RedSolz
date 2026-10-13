extends SceneTree

var motion_index := 0
const MOTION_DIR := "res://.godot/moon_seal_motion/"
var player: CharacterBody2D
var guide: Node2D

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/moon_seal_" + label + ".png")

func motion(count: int) -> void:
	for index in range(count):
		await frames(5)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(MOTION_DIR + "frame_%03d.png" % motion_index)
		motion_index += 1

func place(seal: Node2D, distance: float) -> void:
	player._cancel_action()
	player.position = seal.position + Vector2(distance, -15)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(15)
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await frames(3)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOTION_DIR))
	var session := root.get_node("GameSession")
	session.save_path = "user://presentation_test_seal_flow_capture.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(25)
	player = current_scene.get_node("Player")
	var layout := current_scene.get_node("Stage1Layout")
	guide = layout.get_node("MoonWispGuide")
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	var number := 0
	for id: String in ["camp_moon_seal", "oak_moon_seal", "heartwood_moon_seal"]:
		number += 1
		var seal := layout.get_node(id)
		await place(seal, -95)
		await capture("%d_dormant" % number)
		if number == 1:
			await motion(6)
		await place(seal, -55)
		await capture("%d_ready" % number)
		if number == 1:
			await motion(12)
		seal.interact(player)
		var activation_frame := 0
		while seal.state == "activating":
			await frames(5)
			activation_frame += 5
			if activation_frame == 40:
				await capture("%d_activation" % number)
			if number == 1:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(MOTION_DIR + "frame_%03d.png" % motion_index)
				motion_index += 1
		await capture("%d_activated" % number)
		if number == 1:
			for index in range(84):
				await motion(1)
				if index == 7:
					await capture("1_release")
				if index == 21:
					await capture("1_guide")
		else:
			await frames(40)
			await capture("%d_release" % number)
			await frames(70)
			await capture("%d_guide" % number)
			await frames(430)
		print("CAPTURE: Moon Seal ", number, " complete")
	print("MOON SEAL CAPTURES: 18; motion frames: ", motion_index)
	current_scene.queue_free()
	await frames(3)
	quit()
