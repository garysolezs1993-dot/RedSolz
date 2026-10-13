extends SceneTree

const VISUAL := preload("res://scenes/moon_gate_visual.tscn")
const MAP := preload("res://scripts/stage1_definition.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok:
		failures += 1

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func tap(key: String) -> void:
	var event := InputEventAction.new()
	event.action = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames(3)
	event = InputEventAction.new()
	event.action = key
	Input.parse_input_event(event)
	await frames(2)

func _run() -> void:
	var visual := VISUAL.instantiate()
	root.add_child(visual)
	visual.position = Vector2(300, 500)
	var sprite := visual.get_node("Sprite") as AnimatedSprite2D
	check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Gate uses nearest filtering")
	check(sprite.material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED, "Gate energy remains readable under selective forest lighting")
	check(visual.awakening_1_brightness < visual.awakening_2_brightness and visual.awakening_2_brightness < 1.0, "Early awakening brightness is deliberately restrained")
	for completed in range(4):
		visual.set_seal_count(completed)
		var clip: StringName = visual.STATES[completed]
		check(sprite.animation == clip, "Correct visual at %d/3" % completed)
		check(sprite.sprite_frames.get_frame_count(clip) == (1 if completed == 0 else 5), "Correct frame count: " + str(clip))
		check(sprite.sprite_frames.get_animation_loop(clip) == (completed > 0), "Only awakened states loop: " + str(clip))
		if completed > 0:
			check(is_equal_approx(sprite.sprite_frames.get_animation_speed(clip), float(5 + completed)), "Escalating 6/7/8 FPS: " + str(clip))
		var scale_before := sprite.scale
		var offset_before := sprite.offset
		var seen: Dictionary = {}
		var wraps := 0
		var previous_frame := sprite.frame
		var changes: int = visual.state_changes
		for index in range(135):
			# Repeated progress notifications must not reset the animation.
			visual.set_seal_count(completed)
			await physics_frame
			seen[sprite.frame] = true
			if sprite.frame < previous_frame:
				wraps += 1
			previous_frame = sprite.frame
		check(visual.state_changes == changes, "Unchanged seal count never restarts: " + str(clip))
		check(seen.size() == (1 if completed == 0 else 5) and (wraps >= 2 if completed > 0 else not sprite.is_playing()), "Actual playback and loop behavior: " + str(clip))
		for index in range(sprite.sprite_frames.get_frame_count(clip)):
			sprite.frame = index
			var texture := sprite.sprite_frames.get_frame_texture(clip, index)
			check(texture != null and not texture is AtlasTexture, "Full uncropped source texture: " + str(clip) + str(index))
			check(texture.get_size() == (Vector2(1254, 1254) if completed == 0 else Vector2(512, 800)), "Source canvas preserved: " + str(clip) + str(index))
			check(sprite.scale == scale_before and sprite.offset == offset_before and visual.position == Vector2(300, 500), "No per-frame transform changes: " + str(clip) + str(index))
			check(visual.floor_anchor().is_equal_approx(Vector2(300, 500)), "Stone sill stays on the shared ground line: " + str(clip) + str(index))
	visual.queue_free()
	await frames(2)
	var session := root.get_node("GameSession")
	session.save_path = "user://presentation_test_moon_gate_visual.cfg"
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
		enemy.queue_free()
	player.position = Vector2(MAP.GATE_POSITION.x, 485)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	var layout := current_scene.get_node("Stage1Layout")
	var gate := layout.get_node("StageTwoGate")
	var objectives := layout.get_node("StageObjectives")
	await frames(15)
	for completed in range(4):
		if completed > 0:
			session.complete_objective(session.STAGE_ONE, objectives.required_seal_ids[completed - 1])
			objectives.progress_changed.emit(completed, 3)
		await frames(3)
		check(gate.seal_count == completed and gate.progress_art.seal_count == completed, "Live gate responds to objective progress: %d/3" % completed)
		check(gate.is_unlocked() == (completed == 3), "Gate unlock matches objective state: %d/3" % completed)
		check(gate.progress_art.floor_anchor().is_equal_approx(Vector2(MAP.GATE_POSITION.x, 500)), "Live visual is anchored on platform: %d/3" % completed)
		check(layout.get_node("Stage1Journey/DistantMoonGate").visual.seal_count == completed, "Distant glimpse uses the same progress state: %d/3" % completed)
		if completed < 3:
			for key: String in ["interact", "ui_up", "ui_accept"]:
				await tap(key)
				await frames(28)
				check(current_scene.scene_file_path == session.STAGE_ONE and not gate.transitioning, "Entry blocked at %d/3 using %s" % [completed, key])
	# Restore from persisted progress without repeating the awakening pulse.
	reload_current_scene()
	await frames(20)
	gate = current_scene.get_node("Stage1Layout/StageTwoGate")
	check(gate.progress_art.seal_count == 3 and gate.is_unlocked(), "Saved 3/3 restores the fully awakened loop")
	player = current_scene.get_node("Player")
	player.position = Vector2(MAP.GATE_POSITION.x, 485)
	player.velocity = Vector2.ZERO
	player.current_health = 73
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(15)
	await tap("interact")
	await frames(40)
	check(current_scene.scene_file_path == session.STAGE_TWO, "E enters Stage 2 only at 3/3")
	check(current_scene.get_node("Player").current_health == 73, "Stage 2 transition preserves Red's health")
	print("MOON GATE VISUAL: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
