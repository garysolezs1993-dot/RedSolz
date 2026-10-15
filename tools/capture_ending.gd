extends SceneTree

const MOVIE_DIR := "res://.godot/ending_final_art_preview/"
var movie_frame := 0
var seen: Dictionary = {}
var last_phase := ""
var phase_frames := 0
var skip_sent := false
var return_sent := false
var phase_order: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://ending_final_skip_capture.cfg" if OS.get_cmdline_user_args().has("--skip-ending") else "user://ending_final_full_capture.cfg"
	session.stage_objectives.clear()
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_TWO
	session.checkpoint_position = Vector2(1500,485)
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	root.size = Vector2i(960,540)
	if OS.get_cmdline_user_args().has("--record-preview"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOVIE_DIR))
	change_scene_to_file(session.STAGE_TWO)
	for index in range(25):
		await process_frame
	current_scene.get_node("BossIntroCutscene").skip()
	# Story Skip now keeps the short opening howl before releasing gameplay.
	for index in range(240):
		if current_scene.get_node_or_null("BossIntroCutscene") == null:
			break
		await process_frame
	# Timing previews keep automatic playback; normal gameplay waits for Continue.
	current_scene.get_node("EndingCutscene").auto_advance = true
	var player := current_scene.get_node("Player") as CharacterBody2D
	player.invulnerable = 10000
	for index in range(90):
		await process_frame
	var boss := current_scene.get_node("Stage2BossLayout/CursedWolfBoss") as CharacterBody2D
	if OS.get_cmdline_user_args().has("--real-hit"):
		# Capture-only setup: one normal-damage hit reaches the cinematic.
		boss.health = 20
		player.call("_cancel_action")
		player.global_position = boss.global_position + Vector2(-55,-15)
		player.velocity = Vector2.ZERO
		player.facing = 1
		for index in range(3):
			await physics_frame
		player.call("_start_attack")
		for index in range(180):
			await process_frame
			if boss.dead:
				break
		if not boss.dead:
			push_error("Capture attack did not defeat the reduced-health boss")
			quit(1)
			return
		print("ENDING: normal-damage Red attack defeated reduced-health capture boss")
	else:
		boss.take_damage(int(boss.maximum_health))
	print("ENDING TRIGGER: boss HP=",boss.health,"; retained=",is_instance_valid(boss),"; old victory=",current_scene.get_node("UI").stage_clear_presented)
	for frame in range(6000):
		await process_frame
		if current_scene == null:
			continue
		var scene := current_scene
		var phase := "loading"
		if scene.scene_file_path == session.STAGE_TWO:
			phase = scene.get_node("EndingCutscene").phase
		elif scene.scene_file_path == session.PROTOTYPE_COMPLETE:
			phase = "prototype_complete"
		elif scene.scene_file_path == session.TITLE:
			phase = "title"
		if phase != last_phase:
			last_phase = phase
			phase_frames = 0
			print("ENDING PHASE: ",phase," at frame ",frame)
			phase_order.append(phase)
		phase_frames += 1
		if OS.get_cmdline_user_args().has("--record-preview") and frame % 15 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(MOVIE_DIR+"frame_%03d.png" % movie_frame)
			movie_frame += 1
			if current_scene != scene:
				continue
		var capture_at := 65 if phase == "prototype_complete" else 45
		if phase_frames == capture_at and not seen.has(phase):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/previews/ending_final_"+phase+".png")
			seen[phase] = true
			if current_scene != scene:
				continue
		if OS.get_cmdline_user_args().has("--skip-ending") and not skip_sent and phase == "sacrifice" and phase_frames == 120:
			var event := InputEventKey.new()
			event.keycode = KEY_ESCAPE
			event.pressed = true
			Input.parse_input_event(event)
			skip_sent = true
			print("ENDING: Escape Skip sent")
		if phase == "prototype_complete" and phase_frames == 90 and not return_sent:
			print("ENDING RESOLVED: paused=",paused,"; story complete=",session.objective_completed(session.STAGE_TWO,"prototype_complete"),"; ending flag=",session.ending_in_progress,"; boss nodes=",get_nodes_in_group("boss").size())
			scene.return_button.pressed.emit()
			return_sent = true
		if phase == "title" and phase_frames == 120:
			if not OS.get_cmdline_user_args().has("--skip-ending"):
				var expected: Array[String] = ["collapse","red_approaches","lucidity","keep_reacts","curse_launch","curse_intercept","curse_impact","sacrifice","final_words","white_lily","guardian_transformation","guardian_birth","guardian_touch","together","complete","prototype_complete","title"]
				if phase_order.has("guardian_approach"):
					expected.insert(expected.find("guardian_touch"),"guardian_approach")
				if phase_order != expected:
					push_error("Ending story order mismatch: " + str(phase_order))
					quit(1)
					return
			if paused or session.ending_in_progress or not session.objective_completed(session.STAGE_TWO,"prototype_complete"):
				push_error("Ending completion did not restore/save state")
				quit(1)
				return
			print("ENDING CAPTURE COMPLETE: phases=",seen.keys(),"; movie frames=",movie_frame,"; paused=",paused,"; music=",root.get_node("AudioDirector").current_context)
			quit()
			return
	push_error("Ending capture did not reach Title")
	quit(1)
