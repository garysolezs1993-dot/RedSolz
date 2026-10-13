extends SceneTree

var largest_height := 0
var failures := 0
var captures := 0
var visual: AnimatedSprite2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	root.get_node("GameSession").toast.hide()
	root.get_node("GameSession").fade_rect.hide()
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	visual = preload("res://scripts/moon_seal_visual.gd").new()
	stage.add_child(visual)
	visual.position = Vector2(480, 380)
	visual.set_state("interact_ready")
	for index in range(8):
		await physics_frame
	# Include the reported exit/reentry pair as well as the other state changes.
	var states := ["interact_ready", "dormant", "interact_ready", "activating", "activated_idle", "dormant"]
	for index in range(72):
		if index % 6 == 0:
			visual.set_state(states[int(index / 6) % states.size()])
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		var bounds := rendered.get_used_rect()
		largest_height = maxi(largest_height, bounds.size.y)
		captures += 1
		if bounds.size.y > 130:
			failures += 1
			print("FAIL: frame ", index, " ", visual.state, " rendered height ", bounds.size.y, " declared scale ", visual.scale)
			if failures == 1:
				rendered.save_png("res://docs/previews/moon_seal_transition_flash.png")
		await process_frame
	print("MOON SEAL RENDER TRANSITIONS: ", captures, " frames; ", failures, " failures; max height ", largest_height)
	stage.queue_free()
	await process_frame
	quit(1 if failures else 0)
