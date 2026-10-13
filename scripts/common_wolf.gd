extends CharacterBody2D

const FRAME_ROOT := "res://assets/game_assets/enemies/common_wolf/"
const GRAVITY := 980.0
const DETECT_RANGE := 360.0
const ATTACK_RANGE := 34.0
const ATTACK_DAMAGE := 10
const HIT_STUN_DURATION := 0.4
const PATROL_RADIUS := 64.0
const PATROL_SPEED_MIN := 22.0
const PATROL_SPEED_MAX := 36.0
const CHASE_START_SPEED := 62.0
const CHASE_MAX_SPEED := 150.0
const CHASE_ACCELERATION := 105.0
const SEPARATION_DISTANCE := 48.0
const SEPARATION_STRENGTH := 58.0
const RANDOM_LEAP_MIN := 1.4
const RANDOM_LEAP_MAX := 2.8
const HOWL_WINDUP_MIN := 0.0
const HOWL_WINDUP_MAX := 0.22
const HOWL_DURATION := 1.1
const ATTACK_LUNGE_TRIGGER_RANGE := 100.0
const ATTACK_LUNGE_DURATION := 0.18
const MAX_SAFE_DROP := 48.0
const EDGE_CLEARANCE := 12.0

@export var maximum_health := 42
# Stage 1 configures these per encounter; defaults preserve other scenes.
@export var attack_warning_duration := 0.0
@export var attack_recovery_duration := 0.0
@export var random_leaps_enabled := true
@export var leap_interval := Vector2(RANDOM_LEAP_MIN, RANDOM_LEAP_MAX)
@export var jump_retry_interval := Vector2(.75, 1.15)
@export var leash_radius := 0.0
@export var encounter_pack := ""
@export var pack_attack_delay := 0.0
@export_range(0.0, 1.0, .05) var melee_knockback_scale := 1.0
var attack_warning_remaining := 0.0
var attack_recovery_remaining := 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D

var target: Node2D
var health := 42
var attack_cooldown := 0.0
var attack_elapsed := 0.0
var attack_landed := false
var attack_lunge_direction := 0.0
var attack_lunge_speed := 0.0
var hurt_timer := 0.0
var death_timer := 0.0
var dead := false
var pursuing := false
var patrol_origin_x := 0.0
var patrol_direction := 0.0
var patrol_speed := 0.0
var patrol_timer := 0.0
var chase_speed := CHASE_START_SPEED
var approach_offset := 0.0
var jump_cooldown := 0.0
var random_leap_timer := 0.0
var is_howling := false
var howl_windup_timer := 0.0
var howl_timer := 0.0
var chase_huff_timer := 0.0
var rng := RandomNumberGenerator.new()
var safe_floor: Node2D
var safe_floor_position := Vector2.ZERO
var has_safe_floor := false

func _ready() -> void:
	add_to_group("enemies")
	health = maximum_health
	patrol_origin_x = global_position.x
	rng.randomize()
	_choose_patrol_action()
	random_leap_timer = rng.randf_range(leap_interval.x, leap_interval.y)
	chase_huff_timer = rng.randf_range(0.65, 1.15)
	if patrol_direction != 0.0:
		visual.flip_h = patrol_direction < 0.0
	visual.sprite_frames = _make_frames()
	visual.play("idle")
	call_deferred("_find_player")

func _find_player() -> void:
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null:
		var scene := get_tree().current_scene
		if scene != null:
			player_node = scene.get_node_or_null("Player") as Node2D
	target = player_node
	if target is PhysicsBody2D:
		# Bites use distance checks. Red's body must never act as terrain that
		# shoves a lunging wolf below a one-way platform or carries it sideways.
		add_collision_exception_with(target as PhysicsBody2D)

func _ground_below(feet: Vector2, depth: float = MAX_SAFE_DROP) -> Dictionary:
	var excluded: Array[RID] = [get_rid()]
	if is_instance_valid(target) and target is PhysicsBody2D:
		excluded.append((target as PhysicsBody2D).get_rid())
	var query := PhysicsRayQueryParameters2D.create(feet - Vector2(0, 6), feet + Vector2(0, depth), 1, excluded)
	var contact := get_world_2d().direct_space_state.intersect_ray(query)
	if not contact.is_empty() and not contact["collider"] is StaticBody2D and not contact["collider"] is AnimatableBody2D:
		return {}
	return contact

func _remember_safe_floor() -> void:
	if not is_on_floor():
		return
	var contact := _ground_below(global_position, 8.0)
	if contact.is_empty():
		return
	safe_floor = contact["collider"] as Node2D
	var ground: Vector2 = contact["position"]
	safe_floor_position = safe_floor.to_local(Vector2(global_position.x, ground.y))
	has_safe_floor = true

func _has_leap_landing(launch_speed: float, horizontal_speed: float) -> bool:
	var flight_time := 2.0 * launch_speed / GRAVITY
	var apex_height := launch_speed * launch_speed / (2.0 * GRAVITY)
	var landing_x := global_position.x + horizontal_speed * flight_time
	var probe := Vector2(landing_x, global_position.y - apex_height + 2.0)
	# Only leap toward terrain within jump height and the allowed small drop.
	return not _ground_below(probe, apex_height + MAX_SAFE_DROP).is_empty()

func _move_safely(delta: float) -> void:
	if leash_radius > 0.0 and delta > 0.0:
		velocity.x = clampf(velocity.x, (patrol_origin_x - leash_radius - global_position.x) / delta, (patrol_origin_x + leash_radius - global_position.x) / delta)
	# Every horizontal movement source uses this check, including separation,
	# attack burst and hit knockback. Normal small steps down remain available.
	if is_on_floor() and velocity.y >= 0.0 and absf(velocity.x) > 0.01:
		var ahead := global_position + Vector2(velocity.x * delta + signf(velocity.x) * EDGE_CLEARANCE, 0)
		if _ground_below(ahead).is_empty():
			velocity.x = 0.0
			if not pursuing:
				patrol_direction = -patrol_direction
				patrol_timer = rng.randf_range(.6, 1.2)
	move_and_slide()
	if is_on_floor():
		_remember_safe_floor()
	elif has_safe_floor and is_instance_valid(safe_floor) and velocity.y > 0.0:
		var safe_position := safe_floor.to_global(safe_floor_position)
		if global_position.y > safe_position.y + MAX_SAFE_DROP:
			# A miss must not strand a wolf on the catch floor below Red. Validate
			# the support first so a collapsed platform cannot create a hover.
			var support := _ground_below(safe_position, 8.0)
			if not support.is_empty() and support["collider"] == safe_floor:
				global_position = safe_position - Vector2(0, 1)
				velocity = Vector2.ZERO
				attack_elapsed = 0.0
				attack_cooldown = maxf(attack_cooldown, .3)
				jump_cooldown = maxf(jump_cooldown, .75)
				reset_physics_interpolation()

func _choose_patrol_action() -> void:
	patrol_timer = rng.randf_range(0.65, 1.7)
	if rng.randf() < 0.28:
		patrol_direction = 0.0
		patrol_speed = 0.0
	else:
		patrol_direction = -1.0 if rng.randf() < 0.5 else 1.0
		patrol_speed = rng.randf_range(PATROL_SPEED_MIN, PATROL_SPEED_MAX)

func _patrol(delta: float) -> void:
	patrol_timer -= delta
	var distance_from_origin := global_position.x - patrol_origin_x
	if absf(distance_from_origin) >= PATROL_RADIUS:
		patrol_direction = -signf(distance_from_origin)
		patrol_speed = rng.randf_range(PATROL_SPEED_MIN, PATROL_SPEED_MAX)
		patrol_timer = rng.randf_range(0.6, 1.2)
	elif patrol_timer <= 0.0:
		_choose_patrol_action()
	velocity.x = patrol_direction * patrol_speed
	if patrol_direction != 0.0:
		visual.flip_h = patrol_direction < 0.0
	_set_animation("walk" if patrol_direction != 0.0 else "idle")

func _separation_force() -> float:
	var force := 0.0
	for other_node in get_tree().get_nodes_in_group("enemies"):
		if other_node == self or not (other_node is CharacterBody2D) or other_node.get("dead") == true:
			continue
		var other_body := other_node as CharacterBody2D
		var offset_x: float = global_position.x - other_body.global_position.x
		if absf(offset_x) >= SEPARATION_DISTANCE or absf(global_position.y - other_body.global_position.y) >= 38.0:
			continue
		var away_direction := signf(offset_x)
		if away_direction == 0.0:
			away_direction = -1.0 if get_instance_id() < other_body.get_instance_id() else 1.0
		force += away_direction * (SEPARATION_DISTANCE - absf(offset_x)) / SEPARATION_DISTANCE
	return clampf(force, -1.0, 1.0)

func _make_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "idle", 8, 8.0, true)
	_add_animation(frames, "walk", 8, 10.0, true)
	_add_animation(frames, "run", 8, 12.0, true)
	_add_animation(frames, "jump", 6, 12.0, false)
	_add_animation(frames, "howl", 8, 8.0, false)
	_add_animation(frames, "attack", 8, 12.0, false)
	_add_animation(frames, "hurt", 4, 10.0, false)
	_add_animation(frames, "die", 8, 10.0, false)
	return frames

func _add_animation(frames: SpriteFrames, animation: String, count: int, fps: float, looping: bool, skipped_frames: Array = []) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, looping)
	for index in range(count):
		if skipped_frames.has(index):
			continue
		var path := FRAME_ROOT + animation + "/" + animation + "_%02d.png" % index
		var frame: Texture2D = load(path)
		frames.add_frame(animation, frame)

func _physics_process(delta: float) -> void:
	if dead:
		death_timer -= delta
		if death_timer <= 0.0:
			queue_free()
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_remember_safe_floor()
	if target == null or not is_instance_valid(target):
		_find_player()
		if target == null:
			_patrol(delta)
			_move_safely(delta)
			return
		chase_speed = CHASE_START_SPEED
		_move_safely(delta)
		return
	var distance_x := target.global_position.x - global_position.x
	var distance_y := absf(target.global_position.y - global_position.y)
	var horizontal_distance := absf(distance_x)
	var facing_player := (distance_x > 0.0 and not visual.flip_h) or (distance_x < 0.0 and visual.flip_h)
	var inside_encounter := leash_radius <= 0.0 or absf(target.global_position.x - patrol_origin_x) <= leash_radius
	if pursuing:
		if horizontal_distance > DETECT_RANGE + 60.0 or distance_y > 240.0 or not inside_encounter:
			pursuing = false
			is_howling = false
			attack_warning_remaining = 0.0
	elif inside_encounter and horizontal_distance < DETECT_RANGE and distance_y < 180.0 and facing_player:
		pursuing = true
		approach_offset = signf(global_position.x - target.global_position.x) * rng.randf_range(8.0, 28.0)
		random_leap_timer = rng.randf_range(leap_interval.x, leap_interval.y)
		is_howling = true
		howl_windup_timer = rng.randf_range(HOWL_WINDUP_MIN, HOWL_WINDUP_MAX)
		howl_timer = HOWL_DURATION
		visual.sprite_frames.set_animation_speed("howl", 8.0 / howl_timer)
		chase_huff_timer = rng.randf_range(0.65, 1.15)
	if pursuing and horizontal_distance > 4.0:
		visual.flip_h = distance_x < 0.0
	if pursuing and horizontal_distance > ATTACK_LUNGE_TRIGGER_RANGE and is_on_floor() and hurt_timer <= 0.0 and attack_elapsed <= 0.0 and attack_warning_remaining <= 0.0 and attack_recovery_remaining <= 0.0 and not is_howling:
		random_leap_timer -= delta
		var target_is_above := target.global_position.y < global_position.y - 46.0
		if jump_cooldown <= 0.0 and (target_is_above or is_on_wall() or random_leaps_enabled and random_leap_timer <= 0.0):
			var launch_speed := rng.randf_range(305.0, 355.0)
			var leap_speed := signf(distance_x) * CHASE_MAX_SPEED
			if _has_leap_landing(launch_speed, leap_speed):
				velocity.y = -launch_speed
				jump_cooldown = rng.randf_range(jump_retry_interval.x, jump_retry_interval.y)
			random_leap_timer = rng.randf_range(leap_interval.x, leap_interval.y)
	if hurt_timer > 0.0:
		is_howling = false
		velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
		_set_animation("hurt")
	elif is_howling:
		velocity.x = move_toward(velocity.x, 0.0, 360.0 * delta)
		if howl_windup_timer > 0.0:
			howl_windup_timer = maxf(0.0, howl_windup_timer - delta)
			_set_animation("idle")
		elif howl_timer > 0.0:
			howl_timer = maxf(0.0, howl_timer - delta)
			if visual.animation != "howl":
				_play_wolf_sfx("wolf_howl")
			_set_animation("howl")
		else:
			is_howling = false
	elif attack_recovery_remaining > 0.0:
		attack_recovery_remaining = maxf(0.0, attack_recovery_remaining - delta)
		velocity.x = 0.0
		_set_animation("idle")
	elif attack_warning_remaining > 0.0:
		attack_warning_remaining = maxf(0.0, attack_warning_remaining - delta)
		velocity.x = 0.0
		if attack_warning_remaining <= 0.0:
			_release_lunge()
	elif attack_elapsed > 0.0:
		attack_elapsed += delta
		if attack_elapsed <= ATTACK_LUNGE_DURATION:
			velocity.x = attack_lunge_direction * attack_lunge_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if not attack_landed and attack_elapsed >= 0.22:
			attack_landed = true
			if is_instance_valid(target) and target.has_method("take_damage") and absf(distance_x) <= ATTACK_RANGE + 10.0 and distance_y < 42.0:
				var push_direction: float = signf(distance_x)
				if push_direction == 0:
					push_direction = -1 if visual.flip_h else 1
				target.take_damage(ATTACK_DAMAGE, push_direction * 190.0)
		if attack_elapsed >= 8.0 / 12.0:
			attack_elapsed = 0.0
			attack_cooldown = 0.8
			attack_recovery_remaining = attack_recovery_duration
	elif pursuing and is_on_floor() and horizontal_distance <= ATTACK_LUNGE_TRIGGER_RANGE and distance_y < 42.0 and attack_cooldown <= 0.0 and _pack_can_attack():
		attack_landed = false
		attack_lunge_direction = signf(distance_x)
		if attack_lunge_direction == 0.0:
			attack_lunge_direction = -1.0 if visual.flip_h else 1.0
		attack_lunge_speed = rng.randf_range(320.0, 360.0)
		if attack_warning_duration > 0.0:
			attack_warning_remaining = attack_warning_duration + pack_attack_delay
			velocity.x = 0.0
			visual.play("attack")
			visual.set_frame_and_progress(0, 0.0)
			visual.pause()
			_play_wolf_sfx("wolf_huff")
		else:
			_release_lunge()
	elif pursuing:
		chase_speed = move_toward(chase_speed, CHASE_MAX_SPEED, CHASE_ACCELERATION * delta)
		var approach_x := target.global_position.x + approach_offset
		velocity.x = signf(approach_x - global_position.x) * chase_speed
		if not is_on_floor():
			_set_animation("jump")
		else:
			_set_animation("run" if chase_speed >= 105.0 else "walk")
		chase_huff_timer -= delta
		if chase_huff_timer <= 0.0:
			_play_wolf_sfx("wolf_huff")
			chase_huff_timer = rng.randf_range(0.85, 1.4)
	else:
		chase_speed = CHASE_START_SPEED
		_patrol(delta)
	if pursuing and hurt_timer <= 0.0 and attack_elapsed <= 0.0 and attack_warning_remaining <= 0.0 and attack_recovery_remaining <= 0.0 and not is_howling:
		velocity.x = clampf(velocity.x + _separation_force() * SEPARATION_STRENGTH, -CHASE_MAX_SPEED, CHASE_MAX_SPEED)
	_move_safely(delta)
	queue_redraw()

func _release_lunge() -> void:
	attack_elapsed = .001
	visual.play("attack")
	visual.set_frame_and_progress(0, 0.0)
	_play_wolf_sfx("wolf_attack")

func _pack_can_attack() -> bool:
	if encounter_pack.is_empty():
		return true
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or other.get("dead") == true or other.get("encounter_pack") != encounter_pack:
			continue
		if float(other.get("attack_warning_remaining")) > 0.0 or float(other.get("attack_elapsed")) > 0.0 or float(other.get("attack_recovery_remaining")) > .35:
			return false
	return true

func _draw() -> void:
	if attack_warning_remaining > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -36), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e4ba73"))

func _set_animation(animation: String) -> void:
	if visual.animation != animation:
		visual.play(animation)

func _play_wolf_sfx(sound_name: String) -> void:
	var audio_manager := get_tree().get_first_node_in_group("audio_manager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sound_name)

func take_damage(amount: int, knockback: float = 0.0) -> void:
	if dead:
		return
	health -= amount
	attack_warning_remaining = 0.0
	attack_recovery_remaining = 0.0
	attack_elapsed = 0.0
	queue_redraw()
	attack_cooldown = 0.3
	if health <= 0:
		dead = true
		velocity = Vector2.ZERO
		collision.set_deferred("disabled", true)
		collision_layer = 0
		collision_mask = 0
		_set_animation("die")
		death_timer = 0.8
		return
	velocity.x = knockback * melee_knockback_scale
	velocity.y = -105.0
	hurt_timer = HIT_STUN_DURATION
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio:
		audio.play_sfx("hit")
	_set_animation("hurt")
