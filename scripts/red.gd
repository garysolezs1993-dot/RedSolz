extends CharacterBody2D

signal health_updated(current, maximum)
signal player_died
signal mechanic_demonstrated(mechanic: StringName)

const SPEED := 155.0
const RUN_SPEED := 220.0
const GRAVITY := 1050.0
const JUMP_VELOCITY := -360.0
const MAX_AIR_JUMPS := 2
const DROP_THROUGH_DURATION := 0.22
const DASH_SPEED := 430.0
const DASH_IFRAME_DURATION := 0.7
const ATTACK_RECOVERY := 0.16
const FINISHER_RECOVERY := 0.24
const GROUND_ATTACKS := ["attack_slash", "attack_spin", "attack_thrust"]
const AIR_ATTACKS := ["air_attack_1", "air_attack_2", "air_attack_3"]
const AIR_COMBO_GRAVITY_SCALE := .45
const AIR_FINISHER_PUSH := 120.0
const LAUNCHER_FOLLOWUP_FRAME := 4
const AIR_FINISHER_FOLLOWUP_FRAME := 6
const COMBO_WINDOW := Vector2i(4, 6)
const GROUND_COMBO_WINDOW := Vector2i(4, 7)
const HITSTOP_TIME := 0.055
const DAMAGE_HITSTOP_TIME := 0.075
const GAME_OVER_SCENE := "res://scenes/game_over.tscn"
const ANIMATIONS := preload("res://scripts/red_animation_library.gd")
const CRESCENT_PROJECTILE := preload("res://scripts/crescent_projectile.gd")

enum Action { NONE, DASH, ATTACK, SKILL, HURT, INTERACT, VICTORY, DEAD, ATTACK_RECOVERY }
var action_state := Action.NONE
const GROUND_ACTIVE_FRAMES := Vector2i(2, 5)

var facing := 1
var attacking: bool:
	get:
		return action_state == Action.ATTACK
var attack_timer := 0.0
var combo_step := 0
var combo_buffered := false
var combo_buffer_timer := 0.0
@export_range(.1, .5, .01) var combo_input_buffer := .25
@export_range(.08, .3, .01) var ground_attack_recovery := .14
@export_range(.12, .4, .01) var ground_finisher_recovery := .20
@export_range(300, 600, 10) var rising_slash_launch_speed := 440.0
@export_range(.1, 5.0, .1) var dash_cooldown_duration := 1.5
@export_range(.1, 10.0, .1) var crescent_cooldown_duration := 3.0
var dash_cooldown_remaining := 0.0
var crescent_cooldown_remaining := 0.0
var air_dash_used := false
var dash_available: bool:
	get:
		return not dead and dash_cooldown_remaining <= 0.0 and (is_on_floor() or not air_dash_used)
@export var air_combo_hang_enabled := true
@export_range(0, 150, 5) var air_followup_stall_speed := 90.0
@export_range(400, 1100, 25) var downward_dive_speed := 700.0
@export_range(.15, .6, .01) var downward_landing_recovery := .32
@export_range(.5, 4.0, .1) var downward_max_dive_time := 2.0
var downward_diving := false
var downward_used_in_air := false
var downward_dive_timer := 0.0
var downward_impact_active := false
var attack_recovery_timer := 0.0
var air_combo_step := 0
var air_combo_buffered := false
var air_combo_buffered_dive := false
var air_combo_buffer_timer := 0.0
var air_combo_used := false
var rising_slash_used_in_air := false
var rising_launch_applied := false
var air_finisher_push_applied := false
var can_chain_air_combo: bool:
	get:
		if not attacking or is_on_floor() or air_combo_used and air_combo_step == 0:
			return false
		if attack_animation == "rising_slash":
			return rising_launch_applied and visual.frame >= LAUNCHER_FOLLOWUP_FRAME
		if air_combo_step == 3:
			# Complete the third hit's damage frames before chaining its dive.
			return air_combo_buffered_dive and not downward_used_in_air and visual.frame >= AIR_FINISHER_FOLLOWUP_FRAME
		return air_combo_step > 0 and air_combo_step < 3 and visual.frame >= COMBO_WINDOW.x and visual.frame <= COMBO_WINDOW.y
var can_chain_combo: bool:
	get:
		return attacking and combo_step > 0 and combo_step < 3 and is_on_floor() and visual.frame >= GROUND_COMBO_WINDOW.x and visual.frame <= GROUND_COMBO_WINDOW.y
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
var crouch_state := "standing"
var standing_visual_scale := Vector2.ONE
var dead := false
var hitstop_serial := 0
@export var maximum_health := 100
## Temporary ending preview: overrides outgoing damage; normal damage stays 20.
@export var ending_test_one_hit_ko := false
@export var wolf_summon_enabled := false
var current_health := 100

@onready var hitbox = $AttackHitbox
@onready var visual: AnimatedSprite2D = $Visual
var attack_effect: AnimatedSprite2D
var vfx_anchor: Node2D
var combo_effect: AnimatedSprite2D
var air_combo_effect: AnimatedSprite2D
var downward_effect: AnimatedSprite2D
var dash_effects: Array[AnimatedSprite2D] = []
var active_attack_frames := GROUND_ACTIVE_FRAMES
var skill_animation := ""
var projectile_released := false
var presentation_timer := 0.0
var pending_interaction := ""
var seal_interaction: Node2D
var pending_victory := ""
var lantern_sequence: Node

func _ready() -> void:
	add_to_group("player")
	var root := get_tree().root
	if root.has_meta("stage_transition_health"):
		current_health = clampi(int(root.get_meta("stage_transition_health")), 0, maximum_health)
		root.remove_meta("stage_transition_health")
	else:
		current_health = maximum_health
	GameSession.prepare_player(self)
	default_collision_layer = collision_layer
	visual.scale = Vector2.ONE
	standing_visual_scale = Vector2.ONE
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hitbox.owner_node = self
	hitbox.hit_confirmed.connect(_on_attack_hit)
	hitbox.deactivate()
	visual.sprite_frames = _make_sprite_frames()
	visual.frame_changed.connect(_on_visual_frame_changed)
	# Keep per-player attack geometry independent of the scene resource.
	var attack_shape: CollisionShape2D = hitbox.get_node("CollisionShape2D")
	attack_shape.shape = attack_shape.shape.duplicate()
	var motion_frames := ANIMATIONS.motion_effects()
	for kind in ["dust", "petals", "speed_streak"]:
		var effect := AnimatedSprite2D.new()
		effect.name = "Dash" + kind.to_pascal_case()
		effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		effect.z_index = -1
		effect.sprite_frames = motion_frames
		effect.animation = kind
		effect.visible = false
		effect.animation_finished.connect(func() -> void: effect.visible = false)
		add_child(effect)
		dash_effects.append(effect)
	attack_effect = AnimatedSprite2D.new()
	attack_effect.name = "AttackEffect"
	attack_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	attack_effect.z_index = 1
	attack_effect.sprite_frames = ANIMATIONS.attack_effects()
	attack_effect.visible = false
	add_child(attack_effect)
	vfx_anchor = Node2D.new()
	vfx_anchor.name = "VFXAnchor"
	var initial_combo_profile: Vector3 = ANIMATIONS.COMBO_VFX_PROFILES[0]
	vfx_anchor.position = Vector2(initial_combo_profile.x, initial_combo_profile.y)
	add_child(vfx_anchor)
	combo_effect = AnimatedSprite2D.new()
	combo_effect.name = "AttackVFX"
	combo_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	combo_effect.z_index = 1
	combo_effect.sprite_frames = ANIMATIONS.combo_effects()
	# Seed interpolation at the actual display size before entering the tree.
	# Otherwise its first visible render can blend from the default 1x scale.
	combo_effect.scale = Vector2.ONE * initial_combo_profile.z
	combo_effect.visible = false
	vfx_anchor.add_child(combo_effect)
	air_combo_effect = AnimatedSprite2D.new()
	air_combo_effect.name = "AirAttackVFX"
	air_combo_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	air_combo_effect.z_index = 1
	air_combo_effect.sprite_frames = ANIMATIONS.air_combo_effects()
	air_combo_effect.scale = Vector2.ONE * ANIMATIONS.AIR_VFX_PROFILES[0].z
	air_combo_effect.visible = false
	vfx_anchor.add_child(air_combo_effect)
	downward_effect = AnimatedSprite2D.new()
	downward_effect.name = "DownwardSlashVFX"
	downward_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The broad opaque arc should frame the pose instead of covering Red.
	downward_effect.z_index = -1
	downward_effect.sprite_frames = ANIMATIONS.downward_effects()
	downward_effect.scale = Vector2.ONE * ANIMATIONS.DOWNWARD_VFX_PROFILE.z
	downward_effect.visible = false
	vfx_anchor.add_child(downward_effect)
	_play_visual("idle")
	lantern_sequence = Node.new()
	lantern_sequence.name = "MoonLanternSequence"
	lantern_sequence.set_script(preload("res://scripts/moon_lantern_sequence.gd"))
	add_child(lantern_sequence)
	var router := Node.new()
	router.name = "InteractionRouter"
	router.set_script(preload("res://scripts/interaction_router.gd"))
	add_child(router)

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	ANIMATIONS.add_movement(frames)
	ANIMATIONS.add_ground_combat(frames)
	ANIMATIONS.add_directional_combat(frames)
	ANIMATIONS.add_skills(frames)
	ANIMATIONS.add_crouch(frames)
	ANIMATIONS.add_presentation(frames)
	return frames

func _play_if_changed(animation: String) -> void:
	if visual.animation != animation:
		visual.speed_scale = 1.0
		visual.play(animation)
	_set_visual_offset(animation)

func _play_visual(animation: String) -> void:
	visual.stop()
	visual.speed_scale = 1.0
	visual.play(animation)
	_set_visual_offset(animation)

func _set_visual_offset(animation: String) -> void:
	var profile := ANIMATIONS.character_transform(animation, visual.frame)
	var next_scale := standing_visual_scale * profile.x.length()
	var profile_changed := not visual.scale.is_equal_approx(next_scale) or not visual.position.is_equal_approx(profile.origin)
	visual.scale = next_scale
	visual.position = profile.origin
	visual.offset = Vector2.ZERO
	if profile_changed:
		# Texture canvases switch immediately (48px drafts / 512px replacements).
		# Blending their scales renders a giant or tiny character for one tick.
		# Snap the presentation transform, keeping normal movement interpolated.
		visual.reset_physics_interpolation()

func _animation_duration(animation: String) -> float:
	return float(visual.sprite_frames.get_frame_count(animation)) / visual.sprite_frames.get_animation_speed(animation)

func _play_sound(sound_name: String) -> void:
	var audio = get_tree().get_first_node_in_group("audio_manager")
	if audio:
		audio.play_sfx(sound_name)

func _physics_process(delta: float) -> void:
	if dead:
		return
	# Ability timers are independent of attack recovery/cancellation.
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	crescent_cooldown_remaining = maxf(0.0, crescent_cooldown_remaining - delta)
	cooldown = maxf(0.0, cooldown - delta)
	attack_recovery_timer = maxf(0.0, attack_recovery_timer - delta)
	if action_state == Action.ATTACK_RECOVERY and attack_recovery_timer <= 0.0:
		_cancel_action()
	combo_buffer_timer = maxf(0.0, combo_buffer_timer - delta)
	if combo_buffer_timer <= 0.0 or not is_on_floor():
		combo_buffered = false
	air_combo_buffer_timer = maxf(0.0, air_combo_buffer_timer - delta)
	if air_combo_buffer_timer <= 0.0:
		air_combo_buffered = false
		air_combo_buffered_dive = false
	knockback_lock_timer = maxf(0.0, knockback_lock_timer - delta)
	double_jump_animation_timer = maxf(0.0, double_jump_animation_timer - delta)
	if drop_through_timer > 0.0:
		drop_through_timer -= delta
		if drop_through_timer <= 0.0 and is_instance_valid(dropped_platform):
			remove_collision_exception_with(dropped_platform)
			dropped_platform = null
	if is_on_floor() and velocity.y >= 0.0 and drop_through_timer <= 0.0:
		jumps_used = 0
		air_dash_used = false
		air_combo_used = false
		rising_slash_used_in_air = false
		downward_used_in_air = false
	landing_timer = maxf(0.0, landing_timer - delta)
	if landing_timer <= 0.0 and visual.animation == "land":
		landing_timer = _animation_duration("recover")
		_play_visual("recover")
	skill_timer = maxf(0.0, skill_timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	if is_instance_valid(seal_interaction) and seal_interaction.advance_player(self, delta):
		return
	if lantern_sequence.active():
		if lantern_sequence.advance(delta):
			return
	if action_state == Action.HURT and hurt_timer <= 0.0:
		action_state = Action.NONE
		landing_timer = _animation_duration("recover") if is_on_floor() else 0.0
		if landing_timer > 0.0:
			_play_visual("recover")
	if action_state == Action.SKILL and skill_timer <= 0.0:
		action_state = Action.NONE
		attack_effect.visible = false
	if skill_timer <= 0.0 and skill_uses_hitbox:
		hitbox.deactivate()
		skill_uses_hitbox = false
	var direction := Input.get_axis("move_left", "move_right")
	var crouching := Input.is_action_pressed("move_down") and is_on_floor()
	var sprinting := Input.is_action_pressed("sprint")
	if action_state in [Action.INTERACT, Action.VICTORY]:
		presentation_timer = maxf(0.0, presentation_timer - delta)
		if presentation_timer <= 0.0 or direction != 0.0 or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("dash"):
			action_state = Action.NONE
	if action_state == Action.NONE and is_on_floor():
		if not pending_victory.is_empty():
			_begin_presentation("victory_" + pending_victory, Action.VICTORY)
			pending_victory = ""
		elif not pending_interaction.is_empty() and direction == 0.0:
			_begin_presentation("interact_" + pending_interaction, Action.INTERACT)
			pending_interaction = ""
	if direction != 0.0 and action_state == Action.NONE:
		facing = 1 if direction > 0.0 else -1
		visual.flip_h = facing < 0
	if Input.is_action_just_pressed("dash") and action_state in [Action.NONE, Action.ATTACK, Action.ATTACK_RECOVERY]:
		_begin_dash(direction)
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = facing * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		_play_if_changed("dash")
		_update_dash_effect_positions()
		if dash_timer <= 0.0:
			collision_layer = default_collision_layer
			action_state = Action.NONE
		return
	if not is_on_floor():
		if attacking and attack_animation == "downward_slash":
			# Startup holds the pose; the strike commits to the dive. Normal
			# gravity/air hang/input cannot overwrite this attack's motion.
			velocity.y = downward_dive_speed if downward_diving else 0.0
			if downward_diving:
				downward_dive_timer = maxf(0.0, downward_dive_timer - delta)
				if downward_dive_timer <= 0.0:
					_enter_attack_recovery(ATTACK_RECOVERY)
		elif air_combo_hang_enabled and attacking and air_combo_step > 0:
			# Suspend only the finite air string. Ending or cancelling the attack
			# immediately restores gravity. Horizontal input is locked below.
			velocity.y = 0.0
		else:
			var gravity_scale := AIR_COMBO_GRAVITY_SCALE if attacking and air_combo_step in [1, 2] else 1.0
			velocity.y += GRAVITY * gravity_scale * delta
	var move_speed := RUN_SPEED if sprinting else SPEED
	if crouching:
		move_speed *= 0.5
	if action_state in [Action.ATTACK, Action.ATTACK_RECOVERY]:
		# All basic attacks lock steering/momentum through recovery. Dive and
		# launcher keep their intended vertical motion; damage can interrupt.
		velocity.x = 0.0
	elif knockback_lock_timer > 0.0 or action_state == Action.HURT:
		velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, direction * move_speed, (1000.0 if direction != 0.0 else 1200.0) * delta)
	if action_state == Action.NONE and Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_down") and is_on_floor():
		_drop_through_platform()
	elif action_state == Action.NONE and Input.is_action_just_pressed("jump") and not crouching:
		landing_timer = 0.0
		if is_on_floor():
			jumps_used = 1
			velocity.y = JUMP_VELOCITY
			_play_sound("jump")
			mechanic_demonstrated.emit(&"jump")
		elif jumps_used < MAX_AIR_JUMPS:
			jumps_used += 1
			velocity.y = JUMP_VELOCITY
			double_jump_animation_timer = _animation_duration("double_jump")
			_play_visual("double_jump")
			_play_sound("jump")
	if Input.is_action_just_pressed("attack"):
		if attacking:
			_buffer_combo_attack()
		elif action_state == Action.ATTACK_RECOVERY and not is_on_floor() and attack_animation == AIR_ATTACKS[2] and Input.is_action_pressed("move_down") and not downward_used_in_air:
			# A late finisher input can still dive during Air 3's recovery.
			_begin_downward_slash()
		elif cooldown <= 0.0 and action_state == Action.NONE:
			_start_attack()
	if combo_buffered and can_chain_combo:
		_begin_ground_combo(combo_step + 1)
	if air_combo_buffered and can_chain_air_combo:
		if air_combo_buffered_dive:
			_begin_downward_slash()
		else:
			_begin_air_combo(air_combo_step + 1)
	if wolf_summon_enabled and Input.is_action_just_pressed("special") and action_state == Action.NONE:
		_guardian_howl()
	if Input.is_action_just_pressed("skill_blood_blossom") and action_state == Action.NONE:
		_start_skill("skill_blood_blossom", true)
	if Input.is_action_just_pressed("skill_execution") and action_state == Action.NONE:
		_start_skill("skill_execution", true)
	if Input.is_action_just_pressed("crescent_slash") and action_state == Action.NONE and cooldown <= 0.0 and crescent_cooldown_remaining <= 0.0:
		_start_skill("crescent_cast", false)
	attack_timer = maxf(0.0, attack_timer - delta)
	if attacking and attack_timer <= 0.0 and attack_animation != "downward_slash":
		if combo_step > 0:
			# The swing's closing poses already supplied the ground recovery.
			# Release movement immediately instead of adding a landing pose.
			_cancel_action()
			cooldown = 0.0
		else:
			_enter_attack_recovery(cooldown)
	var was_airborne := not is_on_floor()
	move_and_slide()
	if was_airborne and is_on_floor():
		_on_air_landing()
	_update_animation(direction, crouching, sprinting, delta)

func _begin_dash(direction: float) -> void:
	if not dash_available or action_state not in [Action.NONE, Action.ATTACK, Action.ATTACK_RECOVERY]:
		return
	dash_cooldown_remaining = dash_cooldown_duration
	if not is_on_floor():
		air_dash_used = true
	# Dash cancels attack/recovery without refilling jumps or air combo uses.
	_cancel_action()
	cooldown = 0.0
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		visual.flip_h = facing < 0
	action_state = Action.DASH
	mechanic_demonstrated.emit(&"dash")
	dash_timer = _animation_duration("dash")
	invulnerable = maxf(invulnerable, DASH_IFRAME_DURATION)
	# Preserve terrain collisions while passing through wolves.
	collision_layer = 1 << 2
	_play_sound("dash")
	for effect in dash_effects:
		effect.stop()
		# The approved dash character frames already include their trail.
		effect.visible = false
	_update_dash_effect_positions()

func _start_attack() -> void:
	_reset_combo()
	_reset_air_combo()
	if Input.is_action_pressed("move_up"):
		attack_animation = "rising_slash"
	elif not is_on_floor() and Input.is_action_pressed("move_down"):
		_begin_downward_slash()
		return
	elif not is_on_floor():
		if not air_combo_used:
			_begin_air_combo(1)
		return
	else:
		_begin_ground_combo(1)
		return
	_begin_attack_playback()

func _buffer_combo_attack() -> void:
	# A short early press waits for the window; holding C never auto-chains.
	# Directional attacks remain separate and cannot queue a ground follow-up.
	if attack_animation == "rising_slash" and not air_combo_used:
		air_combo_buffered = true
		air_combo_buffered_dive = Input.is_action_pressed("move_down")
		air_combo_buffer_timer = combo_input_buffer
	elif air_combo_step > 0 and not is_on_floor() and visual.frame <= (7 if air_combo_step == 3 else COMBO_WINDOW.y) and (air_combo_step < 3 or Input.is_action_pressed("move_down") and not downward_used_in_air):
		air_combo_buffered = true
		air_combo_buffered_dive = Input.is_action_pressed("move_down")
		air_combo_buffer_timer = combo_input_buffer
	elif combo_step > 0 and combo_step < 3 and is_on_floor() and visual.frame <= GROUND_COMBO_WINDOW.y and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"):
		combo_buffered = true
		combo_buffer_timer = combo_input_buffer

func _reset_combo() -> void:
	combo_step = 0
	combo_buffered = false
	combo_buffer_timer = 0.0
	if is_instance_valid(combo_effect):
		combo_effect.visible = false

func _begin_ground_combo(step: int) -> void:
	_reset_combo()
	_reset_air_combo()
	combo_step = clampi(step, 1, 3)
	attack_animation = GROUND_ATTACKS[combo_step - 1]
	var profile: Vector3 = ANIMATIONS.COMBO_VFX_PROFILES[combo_step - 1]
	vfx_anchor.position = Vector2(profile.x * facing, profile.y)
	combo_effect.scale = Vector2.ONE * profile.z
	combo_effect.flip_h = facing < 0
	vfx_anchor.reset_physics_interpolation()
	combo_effect.reset_physics_interpolation()
	_begin_attack_playback()
	_update_ground_combo_effect()

func _reset_air_combo() -> void:
	air_combo_step = 0
	air_combo_buffered = false
	air_combo_buffered_dive = false
	air_combo_buffer_timer = 0.0
	if is_instance_valid(air_combo_effect):
		air_combo_effect.visible = false

func _begin_air_combo(step: int) -> void:
	if is_on_floor() or step == 1 and air_combo_used:
		return
	_reset_combo()
	_reset_air_combo()
	air_combo_step = clampi(step, 1, 3)
	air_combo_used = true
	attack_animation = AIR_ATTACKS[air_combo_step - 1]
	velocity.x = 0.0
	if air_combo_hang_enabled:
		velocity.y = 0.0
	elif air_combo_step == 2:
		# One small stall per string, not a jump refill or continuous levitation.
		velocity.y = minf(velocity.y, -air_followup_stall_speed)
	var profile: Vector3 = ANIMATIONS.AIR_VFX_PROFILES[air_combo_step - 1]
	vfx_anchor.position = Vector2(profile.x * facing, profile.y)
	air_combo_effect.scale = Vector2.ONE * profile.z
	air_combo_effect.flip_h = facing < 0
	vfx_anchor.reset_physics_interpolation()
	air_combo_effect.reset_physics_interpolation()
	_begin_attack_playback()
	_update_air_combo_effect()

func _on_air_landing() -> void:
	air_dash_used = false
	if attacking and attack_animation == "downward_slash":
		_land_downward_slash()
		return
	var landed_step := air_combo_step
	_reset_air_combo()
	air_combo_used = false
	rising_slash_used_in_air = false
	downward_used_in_air = false
	if landed_step > 0:
		_enter_attack_recovery(FINISHER_RECOVERY if landed_step == 3 else ATTACK_RECOVERY, true)
	elif action_state in [Action.NONE, Action.ATTACK_RECOVERY]:
		landing_timer = _animation_duration("land")
		_play_visual("land")

func _begin_downward_slash() -> void:
	if is_on_floor() or downward_used_in_air:
		return
	_reset_combo()
	_reset_air_combo()
	air_combo_used = true
	downward_used_in_air = true
	downward_diving = false
	downward_dive_timer = downward_max_dive_time
	downward_impact_active = false
	attack_animation = "downward_slash"
	velocity = Vector2.ZERO
	var profile: Vector3 = ANIMATIONS.DOWNWARD_VFX_PROFILE
	vfx_anchor.position = Vector2(profile.x * facing, profile.y)
	downward_effect.scale = Vector2.ONE * profile.z
	downward_effect.flip_h = facing < 0
	vfx_anchor.reset_physics_interpolation()
	downward_effect.reset_physics_interpolation()
	_begin_attack_playback()
	_update_downward_effect()

func _enter_attack_recovery(duration: float, landed: bool = false) -> void:
	_cancel_action()
	action_state = Action.ATTACK_RECOVERY
	attack_recovery_timer = maxf(0.0, duration)
	cooldown = attack_recovery_timer
	velocity.x = 0.0
	if landed:
		velocity.y = 0.0
		landing_timer = _animation_duration("land")
		_play_visual("land")
	else:
		_play_visual("recover" if is_on_floor() else "fall")

func _land_downward_slash() -> void:
	# move_and_slide has already resolved floor contact; never teleport into it.
	_enter_attack_recovery(downward_landing_recovery)
	velocity = Vector2.ZERO
	air_combo_used = false
	rising_slash_used_in_air = false
	downward_used_in_air = false
	downward_impact_active = true
	mechanic_demonstrated.emit(&"downward_slash")
	visual.sprite_frames.set_animation_speed("downward_impact", 4.0 / downward_landing_recovery)
	_play_visual("downward_impact")
	_update_downward_effect()

func _begin_attack_playback() -> void:
	action_state = Action.ATTACK
	attack_recovery_timer = 0.0
	velocity.x = 0.0
	rising_launch_applied = false
	air_finisher_push_applied = false
	_configure_attack()
	attack_timer = _animation_duration(attack_animation)
	if combo_step > 0:
		# Startup and damage frames keep their authored speed. Frames after the
		# last damage frame form one short recovery, with every pose retained.
		var fps := visual.sprite_frames.get_animation_speed(attack_animation)
		var recovery := ground_finisher_recovery if combo_step == 3 else ground_attack_recovery
		attack_timer = float(active_attack_frames.y + 1) / fps + recovery
		cooldown = attack_timer
	else:
		cooldown = attack_timer + (FINISHER_RECOVERY if air_combo_step == 3 else ATTACK_RECOVERY)
	hitbox.deactivate()
	_play_visual(attack_animation)
	var attack_sounds := {
		"attack_slash": "slash",
		"attack_spin": "spin",
		"attack_thrust": "thrust",
		"air_attack_1": "slash",
		"air_attack_2": "spin",
		"air_attack_3": "thrust",
		"rising_slash": "slash",
		"downward_slash": "thrust",
	}
	_play_sound(attack_sounds[attack_animation])

func _process(_delta: float) -> void:
	if attacking and attack_animation in GROUND_ATTACKS:
		_update_ground_combo_effect()
	elif attacking and attack_animation in AIR_ATTACKS:
		_update_air_combo_effect()
	elif (attacking and attack_animation == "downward_slash") or downward_impact_active:
		_update_downward_effect()

func _update_downward_effect() -> void:
	attack_effect.visible = false
	combo_effect.visible = false
	air_combo_effect.visible = false
	var was_hidden := not downward_effect.visible
	downward_effect.animation = "downward_slash"
	downward_effect.set_frame_and_progress(visual.frame + (4 if downward_impact_active else 0), visual.frame_progress)
	downward_effect.pause()
	downward_effect.visible = true
	if was_hidden:
		vfx_anchor.reset_physics_interpolation()
		downward_effect.reset_physics_interpolation()

func _update_air_combo_effect() -> void:
	attack_effect.visible = false
	combo_effect.visible = false
	var was_hidden := not air_combo_effect.visible
	air_combo_effect.animation = "air_attack_%d_vfx" % air_combo_step
	air_combo_effect.set_frame_and_progress(visual.frame, visual.frame_progress)
	air_combo_effect.pause()
	air_combo_effect.visible = true
	if was_hidden:
		vfx_anchor.reset_physics_interpolation()
		air_combo_effect.reset_physics_interpolation()

func _update_ground_combo_effect() -> void:
	var step := GROUND_ATTACKS.find(attack_animation) + 1
	var clip := "attack_%d_vfx" % step
	# One clock: Red frame N drives effect frame N, including hitstop. The
	# anchor remains fixed for the swing and never inherits boot-pivot changes.
	attack_effect.visible = false
	var was_hidden := not combo_effect.visible
	combo_effect.animation = clip
	combo_effect.set_frame_and_progress(visual.frame, visual.frame_progress)
	combo_effect.pause()
	combo_effect.visible = true
	if was_hidden:
		# Hidden CanvasItems may retain their last rendered interpolation state.
		# Reset after visibility changes as well as at attack configuration time.
		vfx_anchor.reset_physics_interpolation()
		combo_effect.reset_physics_interpolation()

func _on_visual_frame_changed() -> void:
	_set_visual_offset(visual.animation)
	if attacking:
		if combo_step > 0 and visual.frame > active_attack_frames.y:
			var recovery := ground_finisher_recovery if combo_step == 3 else ground_attack_recovery
			var tail_frames := visual.sprite_frames.get_frame_count(attack_animation) - active_attack_frames.y - 1
			var fps := visual.sprite_frames.get_animation_speed(attack_animation)
			visual.speed_scale = float(tail_frames) / (fps * recovery)
		if attack_animation == "downward_slash" and visual.frame >= 3 and not downward_diving:
			downward_diving = true
			velocity.y = downward_dive_speed
			# Hold the committed strike while travelling, then use poses 4-7 on
			# contact. One damage activation stays active throughout the dive.
			visual.pause()
		elif attack_animation == "rising_slash" and visual.frame >= 2 and not rising_launch_applied and not rising_slash_used_in_air:
			rising_launch_applied = true
			rising_slash_used_in_air = true
			velocity.y = -rising_slash_launch_speed
			jumps_used = maxi(jumps_used, 1)
			mechanic_demonstrated.emit(&"rising_slash")
		elif not air_combo_hang_enabled and air_combo_step == 3 and visual.frame >= 3 and not air_finisher_push_applied:
			air_finisher_push_applied = true
			velocity.y = maxf(0.0, velocity.y) + AIR_FINISHER_PUSH
		var active := visual.frame >= active_attack_frames.x and visual.frame <= active_attack_frames.y
		if active and not hitbox.active:
			hitbox.activate()
			if attack_animation in GROUND_ATTACKS:
				mechanic_demonstrated.emit(&"attack")
			elif attack_animation in AIR_ATTACKS:
				mechanic_demonstrated.emit(&"air_attack")
		elif not active and hitbox.active:
			hitbox.deactivate()
		_update_attack_effect()
	elif downward_impact_active:
		_update_downward_effect()
	elif action_state == Action.SKILL:
		if skill_animation == "crescent_cast":
			_update_crescent_effect()
		if skill_animation == "crescent_cast" and visual.frame >= 3 and not projectile_released:
			projectile_released = true
			_release_crescent()
		elif skill_uses_hitbox:
			var active := visual.frame >= 2 and visual.frame <= 5
			if active and not hitbox.active:
				hitbox.activate()
			elif not active and hitbox.active:
				hitbox.deactivate()

func _release_crescent() -> void:
	mechanic_demonstrated.emit(&"crescent")
	var projectile := CharacterBody2D.new()
	projectile.set_script(CRESCENT_PROJECTILE)
	projectile.source = self
	if ending_test_one_hit_ko:
		projectile.damage = 100000
	projectile.direction = facing
	projectile.position = get_parent().to_local(global_position + Vector2(26 * facing, -10))
	get_parent().add_child(projectile)
	_play_sound("slash")

func _update_crescent_effect() -> void:
	# The character controls both layers; no independent effect clock can drift.
	attack_effect.visible = true
	attack_effect.animation = "crescent"
	attack_effect.flip_h = facing < 0
	attack_effect.scale = Vector2(.105, .105)
	attack_effect.position = visual.position + Vector2(22 * facing, 0)
	attack_effect.set_frame_and_progress(visual.frame, visual.frame_progress)
	attack_effect.pause()
	attack_effect.reset_physics_interpolation()

func _configure_attack() -> void:
	var shape: RectangleShape2D = hitbox.get_node("CollisionShape2D").shape
	active_attack_frames = GROUND_ACTIVE_FRAMES
	hitbox.damage = 100000 if ending_test_one_hit_ko else 20
	hitbox.position = Vector2(27 * facing, 0)
	shape.size = Vector2(44, 28)
	attack_effect.visible = false
	match attack_animation:
		"attack_slash", "attack_spin", "attack_thrust":
			active_attack_frames = Vector2i(2, 4)
		"rising_slash":
			hitbox.position = Vector2(12 * facing, -24)
			shape.size = Vector2(36, 56)
			active_attack_frames = Vector2i(2, 4)
		"downward_slash":
			hitbox.position = Vector2(6 * facing, 30)
			shape.size = Vector2(32, 48)
			active_attack_frames = Vector2i(3, 3)
		"air_attack_1", "air_attack_2":
			hitbox.position = Vector2(24 * facing, 5)
			shape.size = Vector2(42, 36)
			active_attack_frames = Vector2i(2, 4)
		"air_attack_3":
			hitbox.position = Vector2(14 * facing, 18)
			shape.size = Vector2(42, 44)
			active_attack_frames = Vector2i(2, 5)

func _update_attack_effect() -> void:
	var frame := visual.frame
	if attack_animation in GROUND_ATTACKS:
		_update_ground_combo_effect()
		return
	if attack_animation in AIR_ATTACKS:
		_update_air_combo_effect()
		return
	if attack_animation == "downward_slash":
		_update_downward_effect()
		return
	attack_effect.visible = frame >= 2 and attack_animation == "rising_slash"
	if not attack_effect.visible:
		return
	attack_effect.flip_h = facing < 0
	attack_effect.scale = Vector2.ONE
	attack_effect.animation = "rising_fade" if frame >= 5 else "rising"
	var base := Vector2(12 * facing, -8)
	attack_effect.set_frame_and_progress(clampi(frame - (5 if frame >= 5 else 2), 0, 2), visual.frame_progress)
	attack_effect.position = base + _texture_region_offset(attack_effect, 96)
	attack_effect.pause()

func _texture_region_offset(sprite: AnimatedSprite2D, canvas: int) -> Vector2:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame) as AtlasTexture
	if texture == null:
		return Vector2.ZERO
	var offset := texture.region.get_center() - Vector2.ONE * float(canvas) * .5
	offset.x *= facing
	return offset

func _update_dash_effect_positions() -> void:
	for effect in dash_effects:
		var base := Vector2(-12 * facing, -8 if effect.animation == "dust" else -7)
		effect.position = base + _texture_region_offset(effect, 64)

func _cancel_action() -> void:
	if is_instance_valid(seal_interaction):
		seal_interaction.cancel_activation()
	if is_instance_valid(lantern_sequence):
		lantern_sequence.cancel()
	action_state = Action.NONE
	visual.speed_scale = 1.0
	_reset_combo()
	_reset_air_combo()
	attack_timer = 0.0
	attack_recovery_timer = 0.0
	downward_diving = false
	downward_dive_timer = 0.0
	downward_impact_active = false
	if is_instance_valid(downward_effect):
		downward_effect.visible = false
	skill_timer = 0.0
	skill_uses_hitbox = false
	dash_timer = 0.0
	landing_timer = 0.0
	crouch_state = "standing"
	collision_layer = default_collision_layer
	hitbox.deactivate()
	attack_effect.visible = false
	for effect in dash_effects:
		effect.stop()
		effect.visible = false
	pending_interaction = ""

func _on_attack_hit(target: Node2D) -> void:
	if attacking and attack_animation == "rising_slash" and target is CharacterBody2D and not target.is_in_group("boss"):
		(target as CharacterBody2D).velocity.y = -260.0
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
	if animation == "crescent_cast":
		if dead or crescent_cooldown_remaining > 0.0:
			return
		# Spend on cast startup, even if damage interrupts before release.
		crescent_cooldown_remaining = crescent_cooldown_duration
	action_state = Action.SKILL
	skill_animation = animation
	projectile_released = false
	skill_timer = _animation_duration(animation)
	cooldown = skill_timer + ATTACK_RECOVERY
	skill_uses_hitbox = use_hitbox
	attack_effect.visible = false
	hitbox.deactivate()
	if use_hitbox:
		hitbox.position = Vector2(34.0 * facing, 0)
		hitbox.get_node("CollisionShape2D").shape.size = Vector2(44, 28)
		hitbox.damage = 100000 if ending_test_one_hit_ko else 20
	_play_visual(animation)
	if animation == "crescent_cast":
		_update_crescent_effect()
	var skill_sounds := {
		"skill_blood_blossom": "blood_blossom",
		"skill_wolf_summon": "wolf_summon",
		"skill_execution": "execution",
	}
	if skill_sounds.has(animation):
		_play_sound(skill_sounds[animation])

func _update_animation(direction: float, crouching: bool, sprinting: bool, _delta: float) -> void:
	if attacking:
		_play_if_changed(attack_animation)
	elif action_state in [Action.DASH, Action.INTERACT, Action.VICTORY, Action.ATTACK_RECOVERY]:
		return
	elif skill_timer > 0.0:
		return
	elif hurt_timer > 0.0:
		return
	elif landing_timer > 0.0:
		return
	elif not is_on_floor():
		crouch_state = "standing"
		if double_jump_animation_timer > 0.0:
			_play_if_changed("double_jump")
		else:
			_play_if_changed("jump" if velocity.y < 0.0 else "fall")
	elif crouching:
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
		_play_if_changed("run" if sprinting else "walk")
	else:
		# Breathing, hair movement and blink are already in the new idle cycle.
		_play_if_changed("idle")

func _begin_presentation(animation: String, kind: Action) -> void:
	action_state = kind
	landing_timer = 0.0
	presentation_timer = _animation_duration(animation)
	_play_visual(animation)

func play_interaction(kind: String = "look_around") -> void:
	if dead or not visual.sprite_frames.has_animation("interact_" + kind):
		return
	if action_state == Action.NONE and is_on_floor():
		_begin_presentation("interact_" + kind, Action.INTERACT)
	else:
		pending_interaction = kind

func play_victory(style: String = "stage1_bittersweet") -> void:
	if not dead and visual.sprite_frames.has_animation("victory_" + style):
		pending_victory = style

func _guardian_howl() -> void:
	# Reserved for future development; no cast, damage or sound while disabled.
	if not wolf_summon_enabled:
		return
	_start_skill("skill_wolf_summon", false)
	var wolf := get_tree().get_first_node_in_group("wolf_guardian")
	if wolf:
		wolf.perform_guardian_attack(global_position, facing)

func _drop_through_platform() -> void:
	for index in range(get_slide_collision_count()):
		var contact := get_slide_collision(index)
		var platform := contact.get_collider()
		if (platform is StaticBody2D or platform is AnimatableBody2D) and (String(platform.name).begins_with("RootedLedge_") or platform.is_in_group("drop_through_platform")):
			dropped_platform = platform
			add_collision_exception_with(dropped_platform)
			drop_through_timer = DROP_THROUGH_DURATION
			jumps_used = 1
			velocity.y = 90.0
			mechanic_demonstrated.emit(&"drop_through")
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
	_cancel_action()
	action_state = Action.HURT
	velocity.x = knockback
	velocity.y = -210.0
	knockback_lock_timer = 0.16
	invulnerable = 0.5
	_start_hitstop(0.2, DAMAGE_HITSTOP_TIME)
	var hurt_animation := "knockback" if amount >= 25 else "hurt"
	hurt_timer = _animation_duration(hurt_animation)
	_play_visual(hurt_animation)

func _on_died() -> void:
	_cancel_action()
	action_state = Action.DEAD
	dead = true
	pending_victory = ""
	# Invalidate outstanding hitstop callbacks before real-time presentation.
	hitstop_serial += 1
	Engine.time_scale = 1.0
	velocity = Vector2.ZERO
	hitbox.deactivate()
	_play_visual("death")
	GameSession.present_death(self)
