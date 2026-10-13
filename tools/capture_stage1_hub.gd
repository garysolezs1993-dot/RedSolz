extends SceneTree

var player: CharacterBody2D
var session: Node
var layout: Node2D

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func action(key: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = key
	event.pressed = pressed
	Input.parse_input_event(event)

func place(where: Vector2) -> void:
	player._cancel_action()
	player.position = where
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(16)
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	await frames(3)

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/stage1_hub_" + label + ".png")

func activate() -> void:
	action("interact", true)
	await frames(3)
	action("interact", false)
	await frames(28)

func _run() -> void:
	session = root.get_node("GameSession")
	# Separate from both real saves and regression saves.
	session.save_path = "user://stage1_hub_capture.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.activated_checkpoints.clear()
	session.stage_objectives.clear()
	session.collected_petals.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(20)
	player = current_scene.get_node("Player")
	layout = current_scene.get_node("Stage1Layout")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	await place(Vector2(2800,485))
	await capture("01_crossroads")
	await activate()
	await frames(75)
	await place(Vector2(3340,485))
	await capture("02_upper_and_lower_fork")
	await place(Vector2(3870,149))
	await capture("03_chapel_seal")
	await activate()
	await capture("04_chapel_awakened")
	await place(Vector2(4348,725))
	await capture("05_root_cellar")
	await activate()
	await place(Vector2(5010,725))
	await capture("06_cellar_shortcut")
	await place(Vector2(5700,409))
	await capture("07_bridge")
	await place(Vector2(7128,665))
	await capture("08_side_ruins")
	await activate()
	await place(Vector2(8440,485))
	await capture("09_heartwood")
	await place(Vector2(9650,485))
	await frames(170)
	session.toast.modulate.a=0
	await capture("10_moon_gate")
	print("STAGE 1 HUB PREVIEWS: 10")
	current_scene.queue_free()
	await frames(3)
	quit()
