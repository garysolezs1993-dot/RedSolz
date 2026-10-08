extends CharacterBody2D

const FRAME_ROOT := "res://assets/game_assets/enemies/cursed_wolf_boss/"
const GRAVITY := 980.0
const DETECT_RANGE := 720.0
const WALK_SPEED := 92.0
const CHASE_SPEED := 168.0
const SLASH_RANGE := 118.0
const SLASH_DAMAGE := 18
const POUNCE_DAMAGE := 22
const HOWL_DAMAGE := 20
const POUNCE_SPEED := 430.0
const MAX_HEALTH := 320

# Source-pixel center of the ground ellipse, not its brightest flame or front rim.
# The second row of the source sheet places the ellipse higher in its canvas.
const HOWL_AOE_GROUND_ROWS := [460.0, 460.0, 462.0, 464.0, 398.0, 399.0, 407.0, 413.0]
const HOWL_AOE_REFERENCE_ROW := 417.0

@export var maximum_health := MAX_HEALTH

@export_group("Howl AOE Position")
@export var howl_aoe_base_position := Vector2(0.0, -145.0)
# Optional world-pixel adjustments AFTER the source frames have been aligned.
@export var howl_aoe_frame_offsets: Array[Vector2] = [
	Vector2.ZERO, # howl_aoe_00: faint ground tension
	Vector2.ZERO, # howl_aoe_01: ember buildup
	Vector2.ZERO, # howl_aoe_02: first pulse
	Vector2.ZERO, # howl_aoe_03: expanding wave
	Vector2.ZERO, # howl_aoe_04: full burst
	Vector2.ZERO, # howl_aoe_05: sustained pulse
	Vector2.ZERO, # howl_aoe_06: fading energy
	Vector2.ZERO  # howl_aoe_07: lingering embers
]

@export_group("Animation Test")
@export var howl_only_test_mode := false

@onready var visual: AnimatedSprite2D = $Visual
@onready var aoe_visual: AnimatedSprite2D = $HowlAOEEffect
@onready var body_collision: CollisionShape2D = $CollisionShape2D

var health := MAX_HEALTH
var target: Node2D
var state := "approach"
var state_timer := 0.0
var slash_cooldown := 0.0
var pounce_cooldown := 1.0
var howl_cooldown := 3.0
var pounce_direction := 1.0
var pounce_elapsed := 0.0
var damage_applied := false
var hurt_timer := 0.0
var death_timer := 0.0
var dead := false
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemies")
	health = maximum_health
	rng.randomize()
	visual.sprite_frames = _make_sprite_frames()
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.35, 0.35)
	visual.position = Vector2(0.0, -64.0)
	visual.flip_h = true
	aoe_visual.sprite_frames = visual.sprite_frames
	aoe_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Align the ground ellipse in each 512x512 frame independently of the flames.
	aoe_visual.scale = Vector2(0.9, 0.9)
	aoe_visual.position = howl_aoe_base_position
	aoe_visual.frame_changed.connect(_update_howl_aoe_position)
	aoe_visual.visible = false
	_update_howl_aoe_position()
	_play_animation("idle")
	call_deferred("_find_player")

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "idle", "walk", 8, 3.0, true)
	_add_animation(frames, "walk", "walk", 8, 8.0, true)
	_add_animation(frames, "jump", "jump", 8, 11.0, false)
	_add_animation(frames, "attack", "attack", 8, 12.0, false)
	_add_animation(frames, "pounce", "pounce", 8, 12.0, false)
	_add_animation(frames, "howl", "howl_v2", 8, 7.0, false, "howl")
	_add_animation(frames, "howl_aoe", "howl_aoe_v2", 8, 7.0, false, "howl_aoe")
	return frames

func _add_animation(frames: SpriteFrames, animation_name: String, folder_name: String, frame_count: int, fps: float, looping: bool, file_prefix: String = "") -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looping)
	var prefix := folder_name if file_prefix.is_empty() else file_prefix
	for index in range(frame_count):
		var frame_path := FRAME_ROOT + folder_name + "/" + prefix + "_%02d.png" % index
		var frame := load(frame_path) as Texture2D
		if frame != null:
			frames.add_frame(animation_name, frame)
		else:
			push_error("Missing Cursed Wolf frame: %s" % frame_path)

func _find_player() -> void:
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null and get_tree().current_scene != null:
		player_node = get_tree().current_scene.get_node_or_null("Player") as Node2D
	target = player_node

func _physics_process(delta: float) -> void:
	if dead:
		death_timer -= delta
		if death_timer <= 0.0:
			queue_free()
		return
	slash_cooldown = maxf(0.0, slash_cooldown - delta)
	pounce_cooldown = maxf(0.0, pounce_cooldown - delta)
	howl_cooldown = maxf(0.0, howl_cooldown - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if target == null or not is_instance_valid(target):
		_find_player()
	if target == null:
		velocity.x = move_toward(velocity.x, 0.0, 360.0 * delta)
		_play_animation("idle")
		move_and_slide()
		return

	var offset := target.global_position - global_position
	var distance_x := absf(offset.x)
	var distance_y := absf(offset.y)
	var direction := signf(offset.x)
	if direction == 0.0:
		direction = -1.0 if visual.flip_h else 1.0
	if distance_x > 5.0:
		visual.flip_h = direction < 0.0

	if hurt_timer > 0.0:
		state = "hurt"
		velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
		_play_animation("walk")
	elif distance_x > DETECT_RANGE and state == "approach":
		velocity.x = move_toward(velocity.x, 0.0, 360.0 * delta)
		_play_animation("idle")
	else:
		_run_boss_state(delta, distance_x, distance_y, direction)

	move_and_slide()
	queue_redraw()
	if state == "pounce" and pounce_elapsed > 0.28 and is_on_floor():
		_enter_recovery(0.58)

func _run_boss_state(delta: float, distance_x: float, distance_y: float, direction: float) -> void:
	match state:
		"approach":
			if howl_only_test_mode:
				if distance_x < 310.0 and distance_y < 90.0:
					_begin_howl()
				else:
					velocity.x = move_toward(velocity.x, direction * (WALK_SPEED if distance_x > 190.0 else CHASE_SPEED), 480.0 * delta)
					_play_animation("walk")
			elif distance_x <= SLASH_RANGE and distance_y < 66.0 and slash_cooldown <= 0.0:
				_begin_slash()
			elif distance_x < 390.0 and distance_y < 160.0 and pounce_cooldown <= 0.0:
				_begin_pounce(direction)
			elif distance_x < 310.0 and distance_y < 90.0 and howl_cooldown <= 0.0 and rng.randf() < 0.4:
				_begin_howl()
			else:
				velocity.x = move_toward(velocity.x, direction * (WALK_SPEED if distance_x > 190.0 else CHASE_SPEED), 480.0 * delta)
				_play_animation("walk")
		"slash":
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			_play_animation("attack")
			if not damage_applied and state_timer <= 0.36:
				damage_applied = true
				_damage_target_if_close(SLASH_RANGE, 70.0, SLASH_DAMAGE, 270.0)
			if state_timer <= 0.0:
				slash_cooldown = 0.72
				_enter_recovery(0.28)
		"pounce_windup":
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 680.0 * delta)
			_play_animation("pounce")
			if state_timer <= 0.0:
				state = "pounce"
				pounce_elapsed = 0.0
				state_timer = 0.95
				damage_applied = false
				velocity = Vector2(pounce_direction * POUNCE_SPEED, -350.0)
				_play_animation("jump")
		"pounce":
			pounce_elapsed += delta
			state_timer -= delta
			velocity.x = move_toward(velocity.x, pounce_direction * POUNCE_SPEED, 1300.0 * delta)
			_play_animation("jump" if pounce_elapsed < 0.18 else "pounce")
			if not damage_applied and pounce_elapsed >= 0.20 and distance_x <= 120.0 and distance_y <= 120.0:
				damage_applied = true
				_damage_target_if_close(120.0, 120.0, POUNCE_DAMAGE, 360.0)
			if state_timer <= 0.0:
				pounce_cooldown = 2.0
				_enter_recovery(0.58)
		"howl_aoe":
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			_play_animation("howl")
			_update_howl_aoe_position()
			if not damage_applied and state_timer <= 0.57:
				damage_applied = true
				_damage_target_if_close(235.0, 92.0, HOWL_DAMAGE, 330.0, true)
			if state_timer <= 0.0:
				aoe_visual.visible = false
				aoe_visual.stop()
				howl_cooldown = 0.0 if howl_only_test_mode else 5.5
				_enter_recovery(0.55)
		"recovery":
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 820.0 * delta)
			_play_animation("walk")
			if state_timer <= 0.0:
				state = "approach"
		"hurt":
			_play_animation("walk")
			if hurt_timer <= 0.0:
				state = "approach"
		"dead":
			velocity.x = 0.0

func _begin_slash() -> void:
	state = "slash"
	state_timer = 0.68
	damage_applied = false
	_play_animation("attack")
	_play_sfx("wolf_attack")

func _begin_pounce(direction: float) -> void:
	state = "pounce_windup"
	state_timer = 0.38
	pounce_direction = direction
	pounce_cooldown = 2.6
	damage_applied = false
	_play_animation("pounce")
	_play_sfx("wolf_howl")

func _begin_howl() -> void:
	# Start both 8-frame tracks together so the shockwave grows and fades with the howl pose.
	state = "howl_aoe"
	state_timer = 1.14
	howl_cooldown = 0.0 if howl_only_test_mode else 7.0
	damage_applied = false
	_play_animation("howl")
	aoe_visual.visible = true
	aoe_visual.play("howl_aoe")
	_update_howl_aoe_position()
	_play_sfx("wolf_howl")

func _update_howl_aoe_position() -> void:
	if aoe_visual == null:
		return
	aoe_visual.position = howl_aoe_base_position
	var frame_index := clampi(aoe_visual.frame, 0, HOWL_AOE_GROUND_ROWS.size() - 1)
	# Centered sprites put source row 256 at the node origin. Row 417 at scale
	# 0.9 and base Y -145 lands on the boss's foot line (approximately Y 0).
	aoe_visual.position.y += (HOWL_AOE_REFERENCE_ROW - float(HOWL_AOE_GROUND_ROWS[frame_index])) * aoe_visual.scale.y
	if frame_index < howl_aoe_frame_offsets.size():
		aoe_visual.position += howl_aoe_frame_offsets[frame_index]

func _enter_recovery(duration: float) -> void:
	state = "recovery"
	state_timer = duration
	_play_animation("walk")

func _damage_target_if_close(range_x: float, range_y: float, amount: int, knockback: float, grounded_only: bool = false) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	var offset := target.global_position - global_position
	if absf(offset.x) > range_x or absf(offset.y) > range_y:
		return
	if grounded_only and target is CharacterBody2D and not (target as CharacterBody2D).is_on_floor():
		return
	var push_direction := signf(offset.x)
	if push_direction == 0.0:
		push_direction = -1.0 if visual.flip_h else 1.0
	target.take_damage(amount, push_direction * knockback)

func _play_animation(animation_name: String) -> void:
	# All wolf animations use the same canvas and sprite scale so the howl does not shrink.
	visual.scale = Vector2(0.35, 0.35)
	if visual.animation != animation_name:
		visual.play(animation_name)
	# Frames 0-3 have paws 42 source pixels lower than frames 4-7.
	# Lift those frames by the scaled difference so the feet stay on the floor line.
	var howl_ground_adjustment := -15.0 if animation_name == "howl" and visual.frame < 4 else 0.0
	visual.position = Vector2(0.0, -64.0 + howl_ground_adjustment)

func _play_sfx(sound_name: String) -> void:
	var audio_manager := get_tree().get_first_node_in_group("audio_manager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sound_name)

func take_damage(amount: int, knockback: float = 0.0) -> void:
	if dead:
		return
	aoe_visual.visible = false
	health = maxi(0, health - amount)
	if health == 0:
		dead = true
		state = "dead"
		velocity = Vector2.ZERO
		body_collision.set_deferred("disabled", true)
		collision_layer = 0
		collision_mask = 0
		visual.modulate = Color(1.0, 0.3, 0.36, 0.7)
		_play_animation("howl")
		death_timer = 0.95
		return
	state = "hurt"
	hurt_timer = 0.24
	velocity.x = knockback * 0.55
	velocity.y = -100.0
	visual.modulate = Color(1.0, 0.48, 0.52, 1.0)
	var flash := create_tween()
	flash.tween_property(visual, "modulate", Color.WHITE, 0.18)
