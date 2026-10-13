extends CharacterBody2D

signal defeated
var ending_managed := false

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

# Both replacement layers have their paw/ground-center anchor at source row 567.
const HOWL_FRAME_COUNT := 8
const HOWL_FPS := 7.0
const HOWL_DURATION := float(HOWL_FRAME_COUNT) / HOWL_FPS
const HOWL_RELEASE_FRAME := 4
const HOWL_AOE_STRENGTH := [0.08, 0.18, 0.40, 0.70, 1.0, 0.75, 0.38, 0.08]

@export var maximum_health := MAX_HEALTH

@export_group("Howl Attack Sound")
@export_file("*.wav") var boss_howl_sound := "res://audio/sfx/boss_howl.wav"
@export_range(-30, 0, .5) var boss_howl_volume_db := -9.0
var boss_howl_player: AudioStreamPlayer

@export_group("Arena Safety")
@export var arena_safety_enabled := false
@export var arena_floor_y := 500.0
@export var arena_limits_x := Vector2(28, 2772)

@export_group("Death Animation")
@export_range(1.0, 24.0, 0.5) var death_animation_fps := 6.0
@export_range(0.0, 5.0, 0.05) var death_final_pose_hold := 0.75
@export_range(0.05, 3.0, 0.05) var death_fade_duration := 0.65

@export_group("Howl AOE Position")
@export var howl_aoe_base_position := Vector2(0.0, -64.0)
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
var dead := false
var death_animation_started := false
var hurt_flash: Tween
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemies")
	health = maximum_health
	rng.randomize()
	boss_howl_player = AudioStreamPlayer.new()
	boss_howl_player.name = "BossHowlSound"
	boss_howl_player.bus = "SFX"
	boss_howl_player.stream = load(boss_howl_sound) as AudioStreamWAV
	boss_howl_player.volume_db = boss_howl_volume_db
	add_child(boss_howl_player)
	visual.sprite_frames = _make_sprite_frames()
	visual.animation_finished.connect(_on_visual_animation_finished)
	visual.frame_changed.connect(_sync_howl_layers)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.35, 0.35)
	visual.position = Vector2(0.0, -64.0)
	visual.flip_h = true
	aoe_visual.sprite_frames = visual.sprite_frames
	aoe_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Ground anchors are packed into the textures; only the wolf owns a clock.
	aoe_visual.scale = Vector2(0.35, 0.35)
	aoe_visual.position = howl_aoe_base_position
	aoe_visual.animation = "howl_aoe"
	aoe_visual.pause()
	aoe_visual.visible = false
	_update_howl_aoe_position()
	_play_animation("idle")
	call_deferred("_find_player")

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "idle", "walk_v3", 8, 3.0, true, "walk")
	_add_animation(frames, "walk", "walk_v3", 8, 8.0, true, "walk")
	_add_animation(frames, "jump", "jump_v3", 8, 11.0, false, "jump")
	_add_animation(frames, "attack", "attack_v3", 8, 12.0, false, "attack")
	_add_animation(frames, "pounce", "pounce_v3", 8, 12.0, false, "pounce")
	_add_animation(frames, "howl", "howl_v3", HOWL_FRAME_COUNT, HOWL_FPS, false, "howl")
	_add_animation(frames, "howl_aoe", "howl_aoe_v3", HOWL_FRAME_COUNT, HOWL_FPS, false, "howl_aoe")
	_add_animation(frames, "death", "death", 8, death_animation_fps, false)
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
	if target != player_node and is_instance_valid(target) and target is PhysicsBody2D:
		remove_collision_exception_with(target as PhysicsBody2D)
	target = player_node
	if target is PhysicsBody2D:
		# Damage is handled by attack ranges/hurtboxes, not body collisions. Red
		# shares terrain layer 1 and otherwise can shove the boss through a ledge.
		add_collision_exception_with(target as PhysicsBody2D)

func _keep_in_arena() -> void:
	if not arena_safety_enabled:
		return
	var bounded_x := clampf(global_position.x, arena_limits_x.x, arena_limits_x.y)
	if not is_equal_approx(bounded_x, global_position.x):
		global_position.x = bounded_x
		velocity.x = 0
		reset_physics_interpolation()
	# Last-resort recovery also handles a boss already below the arena after a
	# live reload or unusually large collision displacement. Normal jumps remain.
	if global_position.y > arena_floor_y + 12:
		global_position.y = arena_floor_y - 1
		velocity = Vector2.ZERO
		reset_physics_interpolation()
		if not dead:
			aoe_visual.visible = false
			damage_applied = true
			_enter_recovery(.58)

func _physics_process(delta: float) -> void:
	if dead:
		# Keep terrain collision so a boss defeated in midair settles on a ledge.
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		_keep_in_arena()
		if is_on_floor() and not death_animation_started:
			death_animation_started = true
			visual.play("death")
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
		_keep_in_arena()
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
	_keep_in_arena()
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
			_sync_howl_layers()
			if not damage_applied and visual.frame >= HOWL_RELEASE_FRAME:
				damage_applied = true
				_damage_target_if_close(235.0, 92.0, HOWL_DAMAGE, 330.0, true)
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
	# Restart one master clock; the effect copies its exact frame and progress.
	state = "howl_aoe"
	state_timer = HOWL_DURATION
	howl_cooldown = 0.0 if howl_only_test_mode else 7.0
	damage_applied = false
	_play_animation("howl")
	visual.set_frame_and_progress(0, 0.0)
	aoe_visual.visible = true
	_sync_howl_layers()
	boss_howl_player.volume_db = boss_howl_volume_db
	boss_howl_player.play()

func _sync_howl_layers() -> void:
	if aoe_visual == null or visual.animation != "howl":
		return
	aoe_visual.set_frame_and_progress(visual.frame, visual.frame_progress)
	aoe_visual.flip_h = visual.flip_h
	var next_frame := mini(visual.frame + 1, HOWL_FRAME_COUNT - 1)
	aoe_visual.modulate.a = lerpf(float(HOWL_AOE_STRENGTH[visual.frame]), float(HOWL_AOE_STRENGTH[next_frame]), visual.frame_progress)
	_update_howl_aoe_position()

func _update_howl_aoe_position() -> void:
	if aoe_visual == null:
		return
	aoe_visual.position = howl_aoe_base_position
	var frame_index := clampi(aoe_visual.frame, 0, HOWL_FRAME_COUNT - 1)
	if frame_index < howl_aoe_frame_offsets.size():
		aoe_visual.position += howl_aoe_frame_offsets[frame_index]

func _enter_recovery(duration: float) -> void:
	boss_howl_player.stop()
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
	# Stop the dedicated voice immediately if damage or another state cancels the howl.
	if animation_name != "howl" and boss_howl_player != null and boss_howl_player.playing:
		boss_howl_player.stop()
	# Replacement frames already share a fixed display scale and foot anchor.
	visual.scale = Vector2(0.35, 0.35)
	if visual.animation != animation_name:
		visual.play(animation_name)
	visual.position = Vector2(0.0, -64.0)

func _play_sfx(sound_name: String) -> void:
	var audio_manager := get_tree().get_first_node_in_group("audio_manager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sound_name)

func _begin_death() -> void:
	boss_howl_player.stop()
	dead = true
	state = "dead"
	hurt_timer = 0.0
	damage_applied = true
	aoe_visual.stop()
	aoe_visual.visible = false
	velocity = Vector2(0.0, maxf(velocity.y, 0.0))
	# No attacks can target or collide with the corpse; retain its terrain mask.
	remove_from_group("enemies")
	collision_layer = 0
	$Hurtbox.set_deferred("collision_layer", 0)
	if is_instance_valid(target) and target is PhysicsBody2D:
		add_collision_exception_with(target as PhysicsBody2D)
	if hurt_flash != null and hurt_flash.is_valid():
		hurt_flash.kill()
	visual.modulate = Color.WHITE
	_play_animation("death")
	death_animation_started = is_on_floor()
	if not death_animation_started:
		# Hold the wounded first pose until landing, then play the full collapse.
		visual.pause()
	defeated.emit()

func _on_visual_animation_finished() -> void:
	if not dead and state == "howl_aoe" and visual.animation == "howl":
		aoe_visual.visible = false
		aoe_visual.pause()
		howl_cooldown = 0.0 if howl_only_test_mode else 5.5
		_enter_recovery(0.55)
		return
	if not dead or visual.animation != "death":
		return
	if ending_managed:
		return # The ending owns the collapsed body until the final story handoff.
	# Completion comes from the animation, so all eight frames play at any FPS.
	var disappearance := create_tween()
	disappearance.tween_interval(death_final_pose_hold)
	disappearance.tween_property(visual, "modulate:a", 0.0, death_fade_duration)
	disappearance.tween_callback(queue_free)

func take_damage(amount: int, knockback: float = 0.0) -> void:
	if dead:
		return
	boss_howl_player.stop()
	aoe_visual.visible = false
	health = maxi(0, health - amount)
	if health == 0:
		_begin_death()
		return
	state = "hurt"
	hurt_timer = 0.24
	velocity.x = knockback * 0.55
	velocity.y = -100.0
	visual.modulate = Color(1.0, 0.48, 0.52, 1.0)
	if hurt_flash != null and hurt_flash.is_valid():
		hurt_flash.kill()
	hurt_flash = create_tween()
	hurt_flash.tween_property(visual, "modulate", Color.WHITE, 0.18)
