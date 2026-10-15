extends SceneTree

var previous_phase := ""
var phase_frames := 0
var captured: Dictionary = {}
var movie_frame := 0
const MOVIE_DIR := "res://.godot/boss_intro_final_preview/"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://boss_intro_storyboard_capture.cfg"
	session.stage_objectives.erase(session.STAGE_TWO)
	session.checkpoint_scene = session.STAGE_TWO
	session.checkpoint_position = Vector2(70, 485)
	session.pending_spawn = false
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	root.size = Vector2i(960, 540)
	if OS.get_cmdline_user_args().has("--record-preview"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOVIE_DIR))
	change_scene_to_file(session.STAGE_TWO)
	for index in range(25):
		await process_frame
	var player := current_scene.get_node("Player") as CharacterBody2D
	var intro := current_scene.get_node("BossIntroCutscene")
	player.global_position = Vector2(intro.trigger_x + 10, 485)
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	player.get_node("Camera2D").reset_smoothing()
	for index in range(1800):
		await process_frame
		intro = current_scene.get_node_or_null("BossIntroCutscene")
		var phase := str(intro.phase) if intro != null else "battle"
		if phase != previous_phase:
			print("BOSS STORY PHASE: ", phase, " at frame ", index)
			previous_phase = phase
			phase_frames = 0
		phase_frames += 1
		if OS.get_cmdline_user_args().has("--record-preview") and index % 12 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(MOVIE_DIR + "frame_%03d.png" % movie_frame)
			movie_frame += 1
		var capture_at := 70 if phase in ["run", "curse_takeover"] else 40
		if phase == "cinematic_howl":
			capture_at = 37
		if phase_frames == capture_at and not captured.has(phase) and phase in ["silent_wolf", "lily", "recognition", "memory", "brother", "run", "curse_takeover", "cinematic_howl", "boss_title"]:
			await _capture(phase)
		if phase == "battle" and phase_frames == 8:
			await _capture(phase)
		if phase == "battle" and phase_frames == 72:
			print("BOSS STORY CAPTURE COMPLETE: ", captured.keys(), "; paused=", paused, "; HUD=", current_scene.get_node("UI/HUD").visible, "; preview frames=", movie_frame)
			quit()
			return
	print("BOSS STORY CAPTURE STOPPED AT: ", previous_phase)
	quit()

func _capture(phase: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/boss_intro_" + phase + ".png")
	captured[phase] = true
