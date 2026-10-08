extends CharacterBody2D

signal health_updated(current, maximum)
signal player_died

const SPEED := 155.0
const RUN_SPEED := 220.0
const GRAVITY := 1050.0
const JUMP_VELOCITY := -360.0
const MAX_AIR_JUMPS := 2
const DROP_THROUGH_DURATION := 0.22
const DASH_SPEED := 430.0
const DASH_IFRAME_DURATION := 0.7
const ATTACK_RECOVERY := 0.16
const ATTACK_WINDUP := 0.12
const HITSTOP_TIME := 0.055
const DAMAGE_HITSTOP_TIME := 0.075
const FRAME_ROOT := "res://assets/character_frames_clean_final/"
const CROUCH_FRAME_OFFSET := Vector2(0.0, 10.0)
const GAME_OVER_SCENE := "res://scenes/game_over.tscn"

var facing := 1
var attacking := false
var attack_timer := 0.0
var attack_windup_timer := 0.0
var attack_style_index := 0
var attack_animation := "attack_slash"
var cooldown := 0.0
var dash_timer := 0.0
var jumps_used := 0
var double_jump_animation_timer := 0.0
var drop_through_timer := 0.0
var dropped_platform: CollisionObject2D
var knockback_lock_timer := 0.0
var landing_timer := 0.0
var skill_timer := 0.0
var skill_uses_hitbox := false
var hurt_timer := 0.0
var invulnerable := 0.0
var default_collision_layer := 1
var idle_blink_timer := 3.0
var crouch_state := "standing"
var standing_visual_scale := Vector2.ONE
var dead := false
var hitstop_serial := 0
@export var maximum_health := 100
var current_health := 100

@onready var hitbox = $AttackHitbox
@onready var visual: AnimatedSprite2D = $Visual
var spin_effect: AnimatedSprite2D

func _ready() -> void:
	var root := get_tree().root
	if root.has_meta("stage_transition_health"):
		current_health = clampi(int(root.get_meta("stage_transition_health")), 0, maximum_health)
		root.remove_meta("stage_transition_health")
	else:
		current_health = maximum_health
	default_collision_layer = collision_layer
	standing_visual_scale = visual.scale
	hitbox.owner_node = self
	hitbox.hit_confirmed.connect(_on_attack_hit)
	hitbox.deactivate()
	visual.sprite_frames = _make_sprite_frames()
	spin_effect = AnimatedSprite2D.new()
	spin_effect.name = "SpinEffect"
	spin_effect.position = visual.position
	spin_effect.scale = visual.scale * 0.62
	spin_effect.z_index = -1
	spin_effect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	spin_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spin_effect.sprite_frames = _make_spin_effect_frames()
	spin_effect.visible = false
	add_child(spin_effect)
	_play_visual("idle")

func _make_spin_effect_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 12.0)
	frames.set_animation_loop("spin", false)
	for index in range(8):
		var frame_path := FRAME_ROOT + "spin_fx/spin_fx_%02d.png" % index
		frames.add_frame("spin", load(frame_path))
	return frames

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_sequence(frames, "idle", 5, 5.0, true, [2])
	_add_sequence(frames, "blink", 3, 12.0, false)
	_add_sequence(frames, "breath", 4, 8.0, true)
	_add_sequence(frames, "walk", 8, 12.0, true)
	_add_sequence(frames, "run", 6, 15.0, true)
	_add_sequence(frames, "jump", 5, 14.0, false)
	# The supplied ZIP is a labeled reference sheet, not a frame atlas. Reuse
	# Red's existing transparent jump poses for a distinct second-takeoff clip.
	_add_sequence(frames, "double_jump", 5, 11.0, false, [], "jump")
	_add_sequence(frames, "fall", 3, 12.0, true)
	_add_sequence(frames, "land", 3, 14.0, false)
	_add_sequence(frames, "crouch_enter", 3, 12.0, false, [], "crouch")
	_add_sequence(frames, "crouch_hold", 10, 10.0, true, [0, 1, 2, 7, 8, 9], "crouch")
	_add_sequence(frames, "crouch_move", 6, 12.0, true, [], "crouch_walk")
	_add_sequence(frames, "crouch_exit", 10, 12.0, false, [0, 1, 2, 3, 4, 5, 6], "crouch")
	_add_sequence(frames, "dash", 3, 20.0, false)
	_add_sequence(frames, "attack_slash", 5, 12.0, false)
	_add_sequence(frames, "attack_spin", 8, 12.0, false)
	_add_sequence(frames, "attack_thrust", 4, 10.0, false)
	_add_sequence(frames, "attack_air", 6, 12.0, false)
	_add_sequence(frames, "skill_blood_blossom", 8, 16.0, false)
	_add_sequence(frames, "skill_wolf_summon", 6, 16.0, false)
	_add_sequence(frames, "skill_execution", 8, 16.0, false)
	_add_sequence(frames, "hurt", 5, 16.0, false)
	_add_sequence(frames, "heavy_hurt", 4, 14.0, false)
	_add_sequence(frames, "down", 4, 10.0, false)
	_add_sequence(frames, "death", 4, 10.0, false)
	_add_sequence(frames, "revive", 5, 12.0, false)
	return frames

func _add_sequence(frames: SpriteFrames, animation: String, frame_count: int, fps: float, loop: bool, skipped_frames: Array = [], source_folder: String = "") -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	var frame_folder := animation if source_folder.is_empty() else source_folder
	for index in range(frame_count):
		if skipped_frames.has(index):
			continue
		var frame_path := FRAME_ROOT + frame_folder + "/" + frame_folder + "_%02d.png" % index
		var frame: Texture2D = load(frame_path)
		frames.add_frame(animation, frame)

func _play_if_changed(animation: String) -> void:
	_set_visual_offset(animation)
	if visual.animation != animation:
		visual.play(animation)

func _play_visual(animation: String) -> void:
	_set_visual_offset(animation)
	visual.play(animation)

func _set_visual_offset(animation: String) -> void:
	visual.scale = standing_visual_scale
	# The 32x32 crouch art needs an origin adjustment to match Red's 64x64
	# standing-frame footline. Keep the source frames at their native size.
	visual.offset = CROUCH_FRAME_OFFSET if animation.begins_with("crouch_") else Vector2.ZERO

func _animation_duration(animation: String) -> float:
	return float(visual.sprite_frames.get_frame_count(animation)) / visual.sprite_frames.get_animation_speed(animation)

func _play_sound(sound_name: String) -> void:
	var audio = get_tree().get_first_node_in_group("audio_manager")
	if audio:
		audio.play_sfx(sound_name)

func _physics_process(delta: float) -> void:
	if dead:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return
	cooldown = maxf(0.0, cooldown - delta)
	knockback_lock_timer = maxf(0.0, knockback_lock_timer - delta)
	double_jump_animation_timer = maxf(0.0, double_jump_animation_timer - delta)
	if drop_through_timer > 0.0:
		drop_through_timer -= delta
		if drop_through_timer <= 0.0 and is_instance_valid(dropped_platform):
			remove_collision_exception_with(dropped_platform)
			dropped_platform = null
	if is_on_floor() and drop_through_timer <= 0.0:
		jumps_used = 0
	landing_timer = maxf(0.0, landing_timer - delta)
	skill_timer = maxf(0.0, skill_timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	if skill_timer <= 0.0 and skill_uses_hitbox:
		hitbox.deactivate()
		skill_uses_hitbox = false
	var direction := Input.get_axis("move_left", "move_right")
	var crouching := Input.is_action_pressed("move_down") and is_on_floor()
	var sprinting := Input.is_action_pressed("sprint")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		visual.flip_h = facing < 0
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = facing * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		_play_if_changed("dash")
		if dash_timer <= 0.0:
			collision_layer = default_collision_layer
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var move_speed := RUN_SPEED if sprinting else SPEED
	if crouching:
		move_speed *= 0.5
	if knockback_lock_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, direction * move_speed, (1000.0 if direction != 0.0 else 1200.0) * delta)
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_down") and is_on_floor():
		_drop_through_platform()
	elif Input.is_action_just_pressed("jump") and not crouching:
		if is_on_floor():
			jumps_used = 1
			velocity.y = JUMP_VELOCITY
			_play_sound("jump")
		elif jumps_used < MAX_AIR_JUMPS:
			jumps_used += 1
			velocity.y = JUMP_VELOCITY
			double_jump_animation_timer = _animation_duration("double_jump")
			_play_visual("double_jump")
			_play_sound("jump")
	if Input.is_action_just_pressed("dash") and not attacking and skill_timer <= 0.0:
		dash_timer = _animation_duration("dash")
		invulnerable = maxf(invulnerable, DASH_IFRAME_DURATION)
		# Wolves use layer 1 in their collision mask. Temporarily move Red to
		# layer 3 so they cannot block or carry her during the dash; mask 1 stays
		# enabled, preserving collision with terrain and walls.
		collision_layer = 1 << 2
		_play_sound("dash")
	if Input.is_action_just_pressed("attack") and cooldown <= 0.0 and not attacking and skill_timer <= 0.0:
		_start_attack()
	if Input.is_action_just_pressed("special") and not attacking and skill_timer <= 0.0:
		_guardian_howl()
	if Input.is_action_just_pressed("skill_blood_blossom") and not attacking and skill_timer <= 0.0:
		_start_skill("skill_blood_blossom", true)
	if Input.is_action_just_pressed("skill_execution") and not attacking and skill_timer <= 0.0:
		_start_skill("skill_execution", true)
	attack_timer = maxf(0.0, attack_timer - delta)
	if attacking and attack_windup_timer > 0.0:
		attack_windup_timer = maxf(0.0, attack_windup_timer - delta)
		if attack_windup_timer <= 0.0:
			hitbox.activate()
	if attacking and attack_timer <= 0.0:
		attacking = false
		hitbox.deactivate()
		spin_effect.visible = false
	var was_airborne := not is_on_floor()
	move_and_slide()
	if was_airborne and is_on_floor() and not attacking:
		landing_timer = _animation_duration("land")
		_play_visual("land")
	_update_animation(direction, crouching, sprinting, delta)

func _start_attack() -> void:
	attacking = true
	if not is_on_floor():
		attack_animation = "attack_air"
	else:
		var ground_attacks := ["attack_slash", "attack_spin", "attack_thrust"]
		attack_animation = ground_attacks[attack_style_index % ground_attacks.size()]
		attack_style_index += 1
	attack_timer = _animation_duration(attack_animation)
	attack_windup_timer = ATTACK_WINDUP
	cooldown = attack_timer + ATTACK_RECOVERY
	hitbox.position.x = 27.0 * facing
	hitbox.deactivate()
	_play_visual(attack_animation)
	spin_effect.visible = attack_animation == "attack_spin"
	if spin_effect.visible:
		spin_effect.flip_h = visual.flip_h
		spin_effect.position.x = visual.position.x + 18.0 * facing
		spin_effect.play("spin")
	var attack_sounds := {
		"attack_slash": "slash",
		"attack_spin": "spin",
		"attack_thrust": "thrust",
		"attack_air": "slash",
	}
	_play_sound(attack_sounds[attack_animation])

func _on_attack_hit(_target: Node2D) -> void:
	_start_hitstop(0.08, HITSTOP_TIME)

func _start_hitstop(time_scale: float, duration: float) -> void:
	hitstop_serial += 1
	var this_hitstop := hitstop_serial
	Engine.time_scale = time_scale
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(_finish_hitstop.bind(this_hitstop))

func _finish_hitstop(hitstop_id: int) -> void:
	if hitstop_id == hitstop_serial:
		Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _start_skill(animation: String, use_hitbox: bool) -> void:
	skill_timer = _animation_duration(animation)
	skill_uses_hitbox = use_hitbox
	if use_hitbox:
		hitbox.position.x = 34.0 * facing
		hitbox.activate()
	_play_visual(animation)
	var skill_sounds := {
		"skill_blood_blossom": "blood_blossom",
		"skill_wolf_summon": "wolf_summon",
		"skill_execution": "execution",
	}
	_play_sound(skill_sounds[animation])

func _update_animation(direction: float, crouching: bool, sprinting: bool, delta: float) -> void:
	if attacking:
		_play_if_changed(attack_animation)
	elif skill_timer > 0.0:
		return
	elif hurt_timer > 0.0:
		return
	elif landing_timer > 0.0:
		return
	elif not is_on_floor():
		idle_blink_timer = 3.0
		if double_jump_animation_timer > 0.0:
			_play_if_changed("double_jump")
		else:
			_play_if_changed("jump" if velocity.y < 0.0 else "fall")
	elif crouching:
		idle_blink_timer = 3.0
		if crouch_state != "entering" and crouch_state != "holding":
			crouch_state = "entering"
			_play_visual("crouch_enter")
		elif crouch_state == "entering":
			if not visual.is_playing():
				crouch_state = "holding"
				_play_visual("crouch_move" if absf(direction) > 0.05 else "crouch_hold")
		elif crouch_state == "holding":
			_play_if_changed("crouch_move" if absf(direction) > 0.05 else "crouch_hold")
		return
	elif crouch_state == "entering" or crouch_state == "holding":
		crouch_state = "exiting"
		_play_visual("crouch_exit")
		return
	elif crouch_state == "exiting":
		if visual.is_playing():
			return
		crouch_state = "standing"
	elif absf(direction) > 0.05:
		idle_blink_timer = 3.0
		_play_if_changed("run" if sprinting else "walk")
	else:
		idle_blink_timer -= delta
		if idle_blink_timer <= 0.0:
			_play_visual("blink")
			idle_blink_timer = 3.0
		elif visual.animation != "blink" or not visual.is_playing():
			_play_if_changed("idle")

func _guardian_howl() -> void:
	_start_skill("skill_wolf_summon", false)
	var wolf := get_tree().get_first_node_in_group("wolf_guardian")
	if wolf:
		wolf.perform_guardian_attack(global_position, facing)

func _drop_through_platform() -> void:
	for index in range(get_slide_collision_count()):
		var contact := get_slide_collision(index)
		var platform := contact.get_collider()
		if platform is StaticBody2D and String(platform.name).begins_with("RootedLedge_"):
			dropped_platform = platform
			add_collision_exception_with(dropped_platform)
			drop_through_timer = DROP_THROUGH_DURATION
			jumps_used = 1
			velocity.y = 90.0
			return

func take_damage(amount: int, knockback: float = 0.0) -> void:
	if dead:
		return
	if invulnerable > 0.0:
		return
	current_health = maxi(0, current_health - amount)
	health_updated.emit(current_health, maximum_health)
	if current_health == 0:
		_on_died()
		return
	_play_sound("hit")
	velocity.x = knockback
	velocity.y = -210.0
	knockback_lock_timer = 0.16
	invulnerable = 0.5
	_start_hitstop(0.2, DAMAGE_HITSTOP_TIME)
	var hurt_animation := "heavy_hurt" if amount >= 25 else "hurt"
	hurt_timer = _animation_duration(hurt_animation)
	_play_visual(hurt_animation)

func _on_died() -> void:
	dead = true
	velocity = Vector2.ZERO
	hitbox.deactivate()
	spin_effect.visible = false
	_play_visual("down")
	await visual.animation_finished
	if not is_inside_tree():
		return
	_play_visual("death")
	await visual.animation_finished
	if not is_inside_tree():
		return
	var retry_scene := "res://scenes/main.tscn"
	var current_scene := get_tree().current_scene
	if current_scene != null and not current_scene.scene_file_path.is_empty():
		retry_scene = current_scene.scene_file_path
	get_tree().root.set_meta("retry_scene_path", retry_scene)
	player_died.emit()
	get_tree().change_scene_to_file(GAME_OVER_SCENE)
