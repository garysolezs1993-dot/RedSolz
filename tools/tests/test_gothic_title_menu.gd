extends SceneTree

var checks := 0
var failures := 0
var session: Node
var title: Control

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", caption)

func frames(count: int) -> void:
	for index in range(count):
		await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(3)
	event = InputEventKey.new()
	event.keycode = code
	Input.parse_input_event(event)
	await frames(3)

func capture(caption: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://docs/previews/title_menu_" + caption + ".png")
	check(error == OK, "Capture " + caption)

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://gothic_title_verification.cfg"
	session.checkpoint_scene = ""
	session.pending_spawn = false
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	root.size = Vector2i(960, 540)
	change_scene_to_file(session.TITLE)
	await frames(4)
	title = current_scene
	check(not title.intro_finished, "Intro begins with input locked")
	check(title.background_root.modulate.a < .1, "Background starts black")
	await key(KEY_ENTER)
	check(current_scene == title, "Early confirmation does not start gameplay")
	await frames(125)
	check(title.intro_finished, "Intro finishes")
	check(is_equal_approx(title.menu_animation.get_animation("intro").length, 1.75), "Intro length 1.75 seconds")
	check(root.gui_get_focus_owner() == title.buttons[0], "Start receives initial focus")
	check(title.buttons.size() == 4, "All four buttons exist")
	check(title.continue_button.is_visible_in_tree() and title.continue_button.disabled, "No-save Continue stays visible and disabled")
	check(title.continue_button.focus_mode == Control.FOCUS_NONE, "No-save Continue cannot receive focus")
	check(title.background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Background preserves aspect ratio")
	check(title.background.texture != null, "Clean background loads")
	check(title.background_animation.is_playing(), "Ambient background animation loops")
	await capture("960_start_focused")
	await capture("960_continue_disabled")
	await key(KEY_DOWN)
	check(root.gui_get_focus_owner() == title.buttons[2], "Keyboard skips disabled Continue")
	await key(KEY_ENTER)
	check(title.settings_panel.visible, "Settings opens")
	await capture("960_settings")
	await key(KEY_ESCAPE)
	check(not title.settings_panel.visible, "Escape closes Settings")
	check(root.gui_get_focus_owner() == title.buttons[2], "Settings restores prior menu focus")
	await key(KEY_DOWN)
	check(root.gui_get_focus_owner() == title.buttons[3], "Keyboard reaches Quit")
	await key(KEY_DOWN)
	check(root.gui_get_focus_owner() == title.buttons[0], "Keyboard focus wraps")
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await frames(15)
		for button in title.buttons:
			var rect: Rect2 = button.get_global_rect()
			check(Rect2(Vector2.ZERO, title.size).encloses(rect), "Button in viewport: %s at %s" % [button.name, resolution])
		check(title.size.is_equal_approx(Vector2(960, 540)), "16:9 logical viewport stays 960x540 at " + str(resolution))
		await capture("%dx%d" % [resolution.x, resolution.y])
	root.size = Vector2i(960, 540)
	await frames(10)
	var original_scale: Vector2 = title.background.scale
	title.background_animation.seek(16.0, true)
	check(title.background.scale.is_equal_approx(Vector2.ONE * 1.02), "Background breathing maximum is 2 percent")
	title.background_animation.seek(0.0, true)
	check(title.background.scale.is_equal_approx(Vector2.ONE), "Background returns to 1x")
	check(original_scale.x >= 1.0, "Ambient zoom keeps screen covered")
	# Save only to the dedicated verification path, never the player's journey.
	session.set_checkpoint(session.STAGE_TWO, Vector2(70, 485))
	change_scene_to_file(session.TITLE)
	await frames(135)
	title = current_scene
	check(not title.continue_button.disabled, "Valid save enables Continue")
	await key(KEY_DOWN)
	check(root.gui_get_focus_owner() == title.continue_button, "Continue participates in keyboard navigation")
	await capture("960_continue_enabled")
	await key(KEY_ENTER)
	check(title.leaving, "Continue begins transition")
	await frames(90)
	check(current_scene.scene_file_path == session.STAGE_TWO, "Continue loads saved Stage 2")
	check(current_scene.get_node("Player").current_health > 0, "Continue preserves player initialization")
	change_scene_to_file(session.TITLE)
	await frames(135)
	title = current_scene
	# Gamepad D-pad and A use the existing menu bindings.
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_DPAD_DOWN
	pad.pressed = true
	Input.parse_input_event(pad)
	await frames(4)
	check(root.gui_get_focus_owner() == title.continue_button, "Gamepad D-pad navigates")
	pad = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_DPAD_DOWN
	Input.parse_input_event(pad)
	title.buttons[0].grab_focus()
	pad = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	Input.parse_input_event(pad)
	await frames(3)
	pad = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	Input.parse_input_event(pad)
	await frames(3)
	check(title.leaving, "Gamepad A selects Start")
	check(current_scene == title, "Start does not instantly change scenes")
	await frames(42)
	check(title.fade.color.a > .7, "Start fades toward black")
	await frames(65)
	check(current_scene.scene_file_path == session.OPENING, "Start fade leads to OpeningCutscene")
	current_scene.skip()
	await frames(65)
	check(current_scene.scene_file_path == session.STAGE_ONE, "Skip opening leads to Stage 1")
	check(session.stage_objectives.is_empty(), "Start uses existing new-game reset")
	check(session.pending_spawn == false, "New-game spawn is consumed normally")
	print("GOTHIC TITLE MENU: ", checks, " checks; ", failures, " failures")
	quit(0 if failures == 0 else 1)
