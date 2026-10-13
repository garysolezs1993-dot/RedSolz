extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://gothic_title_quit_verification.cfg"
	session.music_volume = 0
	session.sfx_volume = 0
	root.get_node("AudioDirector").apply_volumes()
	change_scene_to_file(session.TITLE)
	for index in range(135):
		await process_frame
	var menu := current_scene
	menu.buttons[3].grab_focus()
	menu.buttons[3].pressed.emit()
	if not menu.leaving:
		push_error("Quit did not lock menu input")
		quit(1)
		return
	print("PASS: Quit selected, menu locked; waiting for normal quit callback")
	# Only a broken quit path would reach this timeout.
	await create_timer(3).timeout
	push_error("Quit did not exit the process")
	quit(1)
