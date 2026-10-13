extends SceneTree

# Real renderer, fixed poses and isolated saves. Pass --lighting-before for
# the pre-change capture. Never overwrites the earlier lighting previews.
func _initialize() -> void:
	call_deferred("_capture")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _capture() -> void:
	var session := root.get_node("GameSession")
	session.pending_spawn = false
	session.checkpoint_scene = ""
	session.activated_checkpoints.clear()
	session.learned_mechanics.clear()
	session.collected_petals.clear()
	change_scene_to_file("res://scenes/main.tscn")
	await frames(20)
	var red := current_scene.get_node("Player") as CharacterBody2D
	red.set_physics_process(false)
	red.set("action_state", red.Action.DEAD)
	red.visual.pause()
	red.visual.set_frame_and_progress(0, 0)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.position.x = enemy.patrol_origin_x
		enemy.visual.play("idle")
		enemy.visual.set_frame_and_progress(0, 0)
		enemy.visual.pause()
	var environment := current_scene.get_node("ForestEnvironment")
	environment.set_process(false)
	environment.elapsed = 0
	environment.motes.clear()
	var lantern := current_scene.get_node("Stage1Layout/Promise_1100")
	lantern.set_process(false)
	var phase := "before" if OS.get_cmdline_user_args().has("--lighting-before") else "after"
	for entry in [
		["entrance", Vector2(400, 485)],
		["lantern_dormant", Vector2(1070, 485)],
		["lantern_active", Vector2(1070, 485)],
		["cellar", Vector2(8000, 725)],
		["heartwood", Vector2(10020, 485)],
		["moon_gate", Vector2(11020, 485)],
	]:
		if entry[0] == "lantern_active":
			lantern.activated = true
			lantern.visual.play("active")
			lantern.visual.set_frame_and_progress(0, 0)
			lantern.visual.pause()
			lantern._update_lighting()
		red.position = entry[1]
		red.reset_physics_interpolation()
		if environment.ambient != null:
			environment.ambient.color = environment._ambient_at(red.position)
		elif environment.has_method("_update_background_mood"):
			environment._update_background_mood(10)
		var camera := red.get_node("Camera2D") as Camera2D
		camera.reset_smoothing()
		camera.force_update_scroll()
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/previews/selective_%s_%s.png" % [entry[0], phase])
	print("SELECTIVE LIGHTING CAPTURES: ", phase)
	current_scene.queue_free()
	await frames(3)
	quit()
