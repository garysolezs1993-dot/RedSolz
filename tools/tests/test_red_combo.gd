extends SceneTree

# --script res://tools/tests/test_red_combo.gd -- --presentation-test [--capture]
const DUMMY := preload("res://tools/tests/red_damage_dummy.gd")
var player: CharacterBody2D
var arena: Node2D
var checks := 0
var failures := 0
var capture_enabled := false
const OUTPUT := "res://.godot/red_combo_checks/"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", description)
	if not ok:
		failures += 1

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func input_action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(name: String = "attack") -> void:
	input_action(name, true)
	await wait(.035)
	input_action(name, false)
	await wait(.02)

func until_frame(index: int) -> bool:
	var started := Time.get_ticks_msec()
	while player.attacking and player.visual.frame < index and Time.get_ticks_msec() - started < 1200:
		await process_frame
	return player.attacking and player.visual.frame == index

func until_step(step: int) -> bool:
	var started := Time.get_ticks_msec()
	while player.combo_step != step and Time.get_ticks_msec() - started < 1200:
		await process_frame
	return player.combo_step == step

func pose_capture(name: String) -> void:
	if capture_enabled:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT + name + ".png")

func reset_player(face: int = 1) -> void:
	input_action("attack", false)
	input_action("move_up", false)
	input_action("move_down", false)
	player._cancel_action()
	player.cooldown = 0
	player.position = Vector2(1500, 485)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10
	player.facing = face
	player.visual.flip_h = face < 0
	player.reset_physics_interpolation()
	await wait(.12)

func setup() -> void:
	capture_enabled = OS.get_cmdline_user_args().has("--capture")
	if capture_enabled:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
		change_scene_to_file("res://scenes/main.tscn")
		await wait(.4)
		arena = current_scene
		player = arena.get_node("Player")
		for wolf in get_nodes_in_group("enemies"):
			wolf.set_physics_process(false)
	else:
		var source: Node = load("res://scenes/main.tscn").instantiate()
		player = source.get_node("Player")
		source.remove_child(player)
		source.free()
		arena = Node2D.new()
		root.add_child(arena)
		current_scene = arena
		var floor_body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(4000, 50)
		shape.shape = rectangle
		floor_body.position = Vector2(1500, 525)
		floor_body.add_child(shape)
		arena.add_child(floor_body)
		arena.add_child(player)
	# Use deterministic animation time here; separate combat regressions retain
	# actual hitstop and directional hit behavior.
	player.hitbox.hit_confirmed.disconnect(player._on_attack_hit)
	AudioServer.set_bus_mute(0, true)
	await reset_player()
	if capture_enabled:
		player.get_node("Camera2D").reset_smoothing()
		await wait(.3)

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_red_combo.cfg"
	await setup()
	check(InputMap.action_get_events("attack")[0].physical_keycode == KEY_C, "C binds attack")
	check(InputMap.action_get_events("crescent_slash")[0].physical_keycode == KEY_R, "R binds Crescent")
	check(not player.wolf_summon_enabled and InputMap.action_get_events("special").is_empty(), "Wolf summon remains disabled")
	for step in range(1, 4):
		var clip: String = player.GROUND_ATTACKS[step - 1]
		check(player.visual.sprite_frames.get_frame_count(clip) == 8 and not player.visual.sprite_frames.get_animation_loop(clip), "Eight non-looping poses for step %d" % step)
		check(player.visual.sprite_frames.get_animation_speed(clip) == (10.0 if step == 3 else 12.0), "Requested cadence for step %d" % step)
		var usable := true
		for index in range(8):
			var texture: Texture2D = player.visual.sprite_frames.get_frame_texture(clip, index)
			usable = usable and not texture is AtlasTexture and texture.resource_path.ends_with("combo_master/attack_%d/character/attack%d_%02d.png" % [step, step, index]) and texture.get_size() == Vector2(512, 512)
			var effect_texture: Texture2D = player.combo_effect.sprite_frames.get_frame_texture("attack_%d_vfx" % step, index)
			usable = usable and not effect_texture is AtlasTexture and effect_texture.resource_path.ends_with("combo_master/attack_%d/vfx/attack%d_vfx_%02d.png" % [step, step, index]) and effect_texture.get_size() == Vector2(512, 512)
		check(usable, "Uses unchanged master character/VFX PNGs for step %d" % step)
	check(player.combo_effect.get_parent() == player.vfx_anchor and player.vfx_anchor.get_parent() == player, "Separate AttackVFX follows Red through VFXAnchor")
	# Inspect every authored pose/paired effect without advancing either clock.
	player.set_physics_process(false)
	for step in range(1, 4):
		player._begin_ground_combo(step)
		player.visual.pause()
		var anchor: Vector2 = player.vfx_anchor.position
		var effect_scale: Vector2 = player.combo_effect.scale
		for index in range(8):
			player.visual.set_frame_and_progress(index, .5)
			player._update_ground_combo_effect()
			var sole: float = player.ANIMATIONS.COMBO_FOOT_LINES[player.attack_animation][index]
			var grounded := is_equal_approx(player.visual.position.y + (sole - 256) * player.visual.scale.y, 15.0)
			check(grounded and player.visual.scale.is_equal_approx(Vector2(.105, .105)), "Grounded boot anchor and fixed character scale: %d/%02d" % [step, index])
			check(player.combo_effect.frame == index and is_equal_approx(player.combo_effect.frame_progress, .5) and player.vfx_anchor.position == anchor and player.combo_effect.scale == effect_scale and not player.combo_effect.is_playing(), "Frame-matched VFX with fixed transform: %d/%02d" % [step, index])
	var effect_position: Vector2 = player.combo_effect.global_position
	player.position += Vector2(8, 0)
	check(player.combo_effect.global_position.is_equal_approx(effect_position + Vector2(8, 0)), "VFX anchor follows Red's movement")
	player._cancel_action()
	check(not player.combo_effect.visible, "Cancellation hides the independent effect")
	player.set_physics_process(true)
	await reset_player()
	await tap()
	check(player.combo_step == 1, "First press starts starter")
	await wait(.8)
	check(not player.attacking and player.combo_step == 0 and player.visual.animation == "idle", "No follow-up returns to idle and resets combo")
	check(not player.combo_effect.visible, "Unchained attack hides its effect")
	await tap()
	check(player.combo_step == 1, "Separate later attack restarts at step 1")
	await wait(.85)
	for face in [1, -1]:
		await reset_player(face)
		var target := CharacterBody2D.new()
		target.set_script(DUMMY)
		target.position = player.position + Vector2(30 * face, 0)
		arena.add_child(target)
		await wait(.04)
		await tap()
		check(not player.hitbox.active and target.hits == 0, "Starter anticipation, facing %d" % face)
		await until_frame(2)
		await physics_frame
		check(target.hits == 1 and player.active_attack_frames == Vector2i(2, 4), "Starter hits once in 2–4, facing %d" % face)
		await pose_capture("face_%d_step_1" % face)
		await tap()
		check(player.combo_buffered or player.combo_step == 2, "Early/window press is queued or consumed, facing %d" % face)
		check(await until_step(2), "Buffer chains starter to follow-up at window, facing %d" % face)
		check(not player.combo_buffered and player.visual.frame <= 1, "Buffer consumed and follow-up starts at frame zero")
		await until_frame(2)
		await physics_frame
		check(target.hits == 2 and player.active_attack_frames == Vector2i(2, 4), "Follow-up hits once in 2–4, facing %d" % face)
		await pose_capture("face_%d_step_2" % face)
		await until_frame(4)
		check(player.can_chain_combo, "Frames 4–7 open the next ground combo window")
		await tap()
		check(player.combo_step == 3 and not player.hitbox.active, "Window press starts finisher anticipation, facing %d" % face)
		await until_frame(1)
		check(not player.hitbox.active and target.hits == 2, "Finisher anticipation precedes frame 2")
		await until_frame(3)
		await physics_frame
		check(target.hits == 3 and target.health == 940 and player.active_attack_frames == Vector2i(2, 4), "Finisher deals one 20-damage hit in 2–4, facing %d" % face)
		check(signf(target.last_knockback) == face, "Each combo faces/knocks back correctly")
		check(player.visual.scale.is_equal_approx(Vector2(.105, .105)), "Uniform display scale across combo")
		check(player.combo_effect.visible and player.combo_effect.frame == player.visual.frame and not player.attack_effect.visible, "Master VFX follows the current pose with no extra legacy layer")
		await pose_capture("face_%d_step_3" % face)
		await tap()
		check(player.combo_step == 3 and not player.combo_buffered, "Finisher cannot queue a fourth attack")
		await until_step(0)
		check(not player.attacking and player.cooldown <= 0.0 and target.hits == 3, "Finisher completes its closing-pose recovery with no extra hit")
		await wait(.3)
		check(player.combo_step == 0 and player.visual.animation == "idle", "Full combo returns to idle")
		check(not player.combo_effect.visible, "Finisher VFX disappears on return to idle")
		target.queue_free()
	await reset_player()
	input_action("attack", true)
	await wait(.9)
	check(player.combo_step == 0 and not player.attacking, "Holding attack does not auto-chain")
	input_action("attack", false)
	await reset_player()
	# Deliberately shorten this configurable buffer to make expiry distinct
	# from render/physics scheduling at the normal window boundary.
	player.combo_input_buffer = .1
	await tap()
	await tap()
	await wait(.8)
	check(player.combo_step == 0 and player.visual.animation == "idle", "Expired early buffer cannot cause an unexpected later hit")
	player.combo_input_buffer = .25
	await reset_player()
	await tap()
	await until_frame(2)
	await tap()
	player.invulnerable = 0
	player.take_damage(8, -180)
	check(player.action_state == player.Action.HURT and player.combo_step == 0 and not player.combo_buffered and not player.hitbox.active, "Damage cancels combo, queued press and hitbox")
	check(not player.combo_effect.visible, "Damage cancels master VFX")
	await wait(.6)
	await reset_player()
	input_action("move_up", true)
	await tap()
	input_action("move_up", false)
	check(player.attack_animation == "rising_slash" and player.combo_step == 0, "Up+C keeps rising slash separate")
	await wait(.7)
	await reset_player()
	await tap()
	await until_frame(2)
	player.position.y = 300
	player.velocity = Vector2.ZERO
	await wait(.05)
	await tap()
	check(not player.combo_buffered and player.combo_step == 1, "Leaving the floor prevents a ground follow-up")
	await wait(.9)
	await reset_player()
	player.position.y = 300
	await wait(.04)
	input_action("move_down", true)
	await tap()
	input_action("move_down", false)
	check(player.attack_animation == "downward_slash" and player.combo_step == 0, "Down+C while airborne keeps downward slash")
	check(player.get_node("CollisionShape2D").shape.size == Vector2(18, 30), "Body collider unchanged")
	print("COMBO CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
