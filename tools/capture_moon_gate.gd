extends SceneTree

const MAP := preload("res://scripts/stage1_definition.gd")
const LABELS := ["00_dormant", "01_awakening_1", "02_awakening_2", "03_fully_awakened"]
var motion_frame := 0
const MOTION_DIR := "res://.godot/moon_gate_motion_preview/"

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOTION_DIR))
	var session := root.get_node("GameSession")
	session.save_path = "user://stage1_moon_gate_capture.cfg"
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
	player.position = Vector2(MAP.GATE_POSITION.x - 200, 485)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(20)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	await frames(4)
	var layout := current_scene.get_node("Stage1Layout")
	var gate := layout.get_node("StageTwoGate")
	var objectives := layout.get_node("StageObjectives")
	# These are objective progress updates, rather than bypassing the visual setter.
	# Capture avoids triggering seal cinematics from across the map.
	for completed in range(4):
		if completed > 0:
			session.complete_objective(session.STAGE_ONE, objectives.required_seal_ids[completed - 1])
			objectives.progress_changed.emit(completed, 3)
		await frames(130)
		session.toast.modulate.a = 0.0
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/previews/moon_gate_" + LABELS[completed] + ".png")
		for index in range(18):
			await frames(5)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(MOTION_DIR + "frame_%03d.png" % motion_frame)
			motion_frame += 1
		print("CAPTURE: ", LABELS[completed], "; zoom ", camera.zoom, "; floor ", gate.progress_art.floor_anchor())
	print("MOON GATE PREVIEWS: 4; motion frames: ", motion_frame)
	current_scene.queue_free()
	await frames(3)
	quit()
