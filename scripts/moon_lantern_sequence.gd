extends Node

# One player-side sequence used by every reusable checkpoint instance.
var phase := "idle"
var lantern: Node2D
var suppressed: WeakRef
var camera: Camera2D
var normal_zoom := Vector2.ONE
var normal_offset := Vector2.ZERO
var camera_tween: Tween
var alignment_x := 0.0
var red_finished := false
@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	player.visual.frame_changed.connect(_on_frame)
	player.visual.animation_finished.connect(_on_animation_finished)

func active() -> bool:
	return phase != "idle"

func _process(_delta: float) -> void:
	if suppressed != null:
		var blocked := suppressed.get_ref() as Node2D
		if blocked == null or not blocked.in_interaction_range(player):
			suppressed = null
	if active() and (not is_instance_valid(lantern) or GameSession.transitioning or player.dead):
		cancel()

func preview(target: Node2D) -> void:
	if active() or player.dead or GameSession.transitioning or not player.is_on_floor() or player.action_state != player.Action.NONE:
		return
	if suppressed != null and suppressed.get_ref() == target:
		return
	player._cancel_action()
	lantern = target
	phase = "waiting"
	player.action_state = player.Action.INTERACT
	player.velocity = Vector2.ZERO
	player.facing = 1 if player.global_position.x <= target.global_position.x + 10.0 else -1
	player.visual.flip_h = player.facing < 0
	player._play_visual("lantern_interact")
	player.visual.set_frame_and_progress(1, 0.0)
	player.visual.pause()
	camera = player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		# Rapid reentry during restoration retains the original baseline.
		if camera_tween == null or not camera_tween.is_valid():
			normal_zoom = camera.zoom
			normal_offset = camera.offset
		_zoom(target.lantern_camera_zoom, normal_offset + (target.global_position - player.global_position) * .5, target.lantern_zoom_in_duration)

func confirm(target: Node2D) -> void:
	if phase != "waiting" or lantern != target:
		return
	phase = "lighting"
	red_finished = false
	var marker: Marker2D = target.get_node("InteractionAnchor" if player.facing > 0 else "RightInteractionAnchor")
	alignment_x = player.global_position.x + clampf(marker.global_position.x - player.global_position.x, -target.maximum_alignment, target.maximum_alignment)
	player.visual.play("lantern_interact", 1.0)
	player.visual.set_frame_and_progress(2, 0.0)

func advance(delta: float) -> bool:
	if not active():
		return false
	if not is_instance_valid(lantern) or player.action_state != player.Action.INTERACT or not lantern.in_interaction_range(player) or not player.is_on_floor() or GameSession.transitioning:
		cancel()
		return false
	player.velocity.x = 0.0
	if phase == "lighting":
		player.velocity.x = clampf((alignment_x - player.global_position.x) / delta, -lantern.alignment_speed, lantern.alignment_speed)
	player.velocity.y = player.GRAVITY * delta
	player.move_and_slide()
	if phase == "lighting" and red_finished and not lantern.activation_playing:
		cancel(false)
	return true

func _input(event: InputEvent) -> void:
	if active() and event.is_action_pressed("ui_cancel") and not event.is_echo():
		if phase == "waiting":
			cancel()
		get_viewport().set_input_as_handled()

func _on_frame() -> void:
	if phase == "lighting" and player.visual.animation == "lantern_interact" and player.visual.frame == 4 and is_instance_valid(lantern):
		lantern.ignite(player)

func _on_animation_finished() -> void:
	if phase == "lighting" and player.visual.animation == "lantern_interact":
		red_finished = true

func _zoom(zoom: Vector2, offset: Vector2, duration: float) -> void:
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "zoom", zoom, duration)
	camera_tween.tween_property(camera, "offset", offset, duration)

func cancel(block_reentry: bool = true) -> void:
	if not active():
		return
	var old_lantern := lantern
	phase = "idle"
	lantern = null
	if is_instance_valid(old_lantern):
		if block_reentry:
			suppressed = weakref(old_lantern)
		old_lantern.end_interaction()
		if is_instance_valid(camera):
			_zoom(normal_zoom, normal_offset, old_lantern.lantern_zoom_out_duration)
	elif is_instance_valid(camera):
		_zoom(normal_zoom, normal_offset, .25)
	if player.action_state == player.Action.INTERACT and not player.dead:
		player.action_state = player.Action.NONE
		player.velocity.x = 0.0
		player._play_visual("idle")

func _exit_tree() -> void:
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	if is_instance_valid(camera):
		camera.zoom = normal_zoom
		camera.offset = normal_offset
