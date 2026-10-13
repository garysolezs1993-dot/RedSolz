extends SceneTree

var saved_phases: Dictionary = {}
var last_phase := ""
var phase_frames := 0
var movie_frame := 0
var skip_sent := false
const MOVIE_DIR := "res://.godot/opening_final_preview/"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://opening_storyboard_capture.cfg"
	if OS.get_cmdline_user_args().has("--skip-opening"):
		session.save_path = "user://opening_storyboard_capture_skip.cfg"
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	root.size = Vector2i(960, 540)
	if OS.get_cmdline_user_args().has("--record-preview"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOVIE_DIR))
	session.start_new_game()
	for frame in range(3300):
		await process_frame
		if current_scene == null:
			continue
		var scene := current_scene
		var phase := "loading"
		if current_scene.scene_file_path == session.OPENING:
			phase = str(current_scene.phase)
			if phase.begins_with("panel_"):
				phase += "_line_%d" % (int(current_scene.current_line) + 1)
		elif current_scene.scene_file_path == session.STAGE_ONE:
			var arrival := current_scene.get_node_or_null("OpeningArrival")
			phase = "arrival_" + str(arrival.phase) if arrival != null else "gameplay"
		if phase != last_phase:
			print("STORYBOARD PHASE: ", phase, " at frame ", frame)
			phase_frames = 0
			last_phase = phase
		phase_frames += 1
		if OS.get_cmdline_user_args().has("--record-preview") and frame % 12 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(MOVIE_DIR + "frame_%03d.png" % movie_frame)
			movie_frame += 1
			if current_scene != scene:
				continue # Rendering may coincide with the scene handoff.
		var capture_at := 26 if phase.begins_with("panel_") and current_scene.current_line > 0 else 44
		if phase_frames == capture_at and not saved_phases.has(phase) and (phase.begins_with("panel_") or phase == "title"):
			await _capture(phase)
			if current_scene != scene:
				continue
		if OS.get_cmdline_user_args().has("--skip-opening") and not skip_sent and phase == "panel_4_line_3" and phase_frames == 30:
			var skip_event := InputEventKey.new()
			skip_event.keycode = KEY_ESCAPE
			skip_event.pressed = true
			Input.parse_input_event(skip_event)
			skip_sent = true
			print("OPENING CAPTURE: Escape Skip sent")
		if current_scene.scene_file_path == session.OPENING and not current_scene.auto_advance and current_scene.awaiting_continue and phase_frames >= 120:
			# Simulate a reader using the actual UI. Keyboard confirm now advances
			# dialogue instead of skipping the intro; alternate with the button.
			if int(current_scene.current_line) % 2 == 0:
				var event := InputEventKey.new()
				event.keycode = KEY_ENTER
				event.pressed = true
				Input.parse_input_event(event)
			else:
				current_scene.next_button.pressed.emit()
		if phase == "arrival_dialogue" and phase_frames == 40:
			await _capture(phase)
		if phase == "gameplay" and phase_frames == 15:
			await _capture(phase)
			print("STORYBOARD CAPTURE COMPLETE: ", saved_phases.keys())
			var player := current_scene.get_node("Player") as CharacterBody2D
			print("OPENING HANDOFF: paused=", paused, "; HUD=", current_scene.get_node("UI/HUD").visible, "; zoom=", player.get_node("Camera2D").zoom, "; music=", root.get_node("AudioDirector").current_context, "; preview frames=", movie_frame)
			if skip_sent:
				root.get_texture().get_image().save_png("res://docs/previews/opening_skipped_gameplay.png")
			quit()
			return
	print("STORYBOARD CAPTURE STOPPED AT: ", last_phase)
	quit()

func _capture(phase: String) -> void:
	var first_line: bool = phase.begins_with("panel_") and current_scene.current_line == 0
	var panel_number: int = int(current_scene.current_panel) + 1 if first_line else 0
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/opening_" + phase + ".png")
	saved_phases[phase] = true
	if first_line:
		root.get_texture().get_image().save_png("res://docs/previews/opening_panel_%d.png" % panel_number)
