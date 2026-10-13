extends SceneTree

# Uses the actual complete Stage 1 player/terrain, not an animation fixture.
# --script res://tools/tests/test_red_air_combo.gd -- --presentation-test [--capture]
const DUMMY := preload("res://tools/tests/red_damage_dummy.gd")
var player: CharacterBody2D
var checks := 0
var failures := 0
var capturing := false
var following_target: CharacterBody2D

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

func until_step(step: int) -> bool:
	var start := Time.get_ticks_msec()
	while player.air_combo_step != step and Time.get_ticks_msec() - start < 1600:
		await process_frame
	return player.air_combo_step == step

func until_frame(frame: int) -> bool:
	var start := Time.get_ticks_msec()
	while player.attacking and player.visual.frame < frame and Time.get_ticks_msec() - start < 1600:
		await process_frame
	return player.attacking and player.visual.frame == frame

func reset_player(face: int = 1) -> void:
	for action in ["attack", "jump", "move_up", "move_down", "move_left", "move_right"]:
		input_action(action, false)
	player._cancel_action()
	player.cooldown = 0
	player.position = Vector2(140, 485)
	player.velocity = Vector2.ZERO
	player.facing = face
	player.visual.flip_h = face < 0
	player.invulnerable = 10
	player.reset_physics_interpolation()
	await wait(.3)
	check(player.is_on_floor() and not player.air_combo_used and not player.rising_slash_used_in_air, "Ground contact resets aerial restrictions")

func pose(name: String) -> void:
	if capturing:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/red_air_review/" + name + ".png")

func check_effect() -> void:
	var step: int = player.air_combo_step
	var profile: Vector3 = player.ANIMATIONS.AIR_VFX_PROFILES[step - 1]
	check(player.air_combo_effect.visible and player.air_combo_effect.frame == player.visual.frame and not player.air_combo_effect.is_playing(), "Air VFX uses the character's current frame")
	check(player.vfx_anchor.position.is_equal_approx(Vector2(profile.x * player.facing, profile.y)) and player.air_combo_effect.scale.is_equal_approx(Vector2.ONE * profile.z), "Air VFX has a fixed authored anchor/scale")
	check(player.air_combo_effect.global_position.is_equal_approx(player.global_position + player.vfx_anchor.position) and not player.attack_effect.visible and not player.combo_effect.visible, "VFX follows vertical movement without legacy overlap")

func follow_target() -> void:
	if is_instance_valid(following_target):
		following_target.position = player.position + player.hitbox.position

func full_string(from_launcher: bool, face: int) -> void:
	await reset_player(face)
	if from_launcher:
		input_action("move_up", true)
		await tap()
		input_action("move_up", false)
		await until_frame(1)
		await tap()
		check(await until_step(1), "Buffered launcher press starts air opener")
		check(is_zero_approx(player.velocity.y) and not player.is_on_floor(), "Launcher follow-up starts an airborne hang")
	else:
		await tap("jump")
		await tap()
		check(player.air_combo_step == 1, "Jump then attack starts air opener")
	var jumps: int = player.jumps_used
	var hang_height := player.position.y
	var hang_x := player.position.x
	var steering := "move_right" if face > 0 else "move_left"
	input_action(steering, true)
	for step in range(1, 4):
		await until_frame(2)
		check(player.air_combo_step == step and player.hitbox.damage == 20, "Air step %d retains damage" % step)
		check(is_zero_approx(player.velocity.y) and absf(player.position.y - hang_height) < .1, "Air step %d holds Red at the combo's starting height" % step)
		check(is_zero_approx(player.velocity.x) and absf(player.position.x - hang_x) < .1 and player.facing == face, "Air step %d ignores held steering and preserves its position/facing" % step)
		var expected_scale: float = .10 if step == 1 else .09
		check(player.visual.scale.is_equal_approx(Vector2.ONE * expected_scale), "Air step %d uses its reviewed character size" % step)
		check_effect()
		await pose("%s_face_%d_step_%d" % ["launcher" if from_launcher else "jump", face, step])
		if step < 3:
			await tap()
			check(await until_step(step + 1), "Buffered press chains air step %d" % step)
		else:
			await until_frame(3)
			check(not player.air_finisher_push_applied and is_zero_approx(player.velocity.y), "Finisher stays suspended through its impact pose")
			await tap()
			check((player.air_combo_step == 3 or player.is_on_floor() and player.air_combo_step == 0) and not player.air_combo_buffered, "Finisher cannot queue a fourth attack")
			await until_frame(6)
			check(player.air_combo_step == 3 and is_zero_approx(player.velocity.y) and absf(player.position.y - hang_height) < .1, "Hang lasts through finisher recovery frames")
			await pose("%s_face_%d_finisher_fade" % ["launcher" if from_launcher else "jump", face])
		check(player.jumps_used == jumps or player.is_on_floor() and player.jumps_used == 0, "Air combo never refills jumps; landing resets normally")
	input_action(steering, false)
	await wait(.9)
	check(player.is_on_floor() and player.air_combo_step == 0 and not player.air_combo_buffered and not player.air_combo_effect.visible, "Full air string lands and resets safely")
	check(player.action_state == player.Action.NONE, "Landing returns movement control")

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_red_air_combo.cfg"
	capturing = OS.get_cmdline_user_args().has("--capture")
	change_scene_to_file("res://scenes/main.tscn")
	await wait(.4)
	player = current_scene.get_node("Player")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.hitbox.hit_confirmed.disconnect(player._on_attack_hit)
	AudioServer.set_bus_mute(0, true)
	await reset_player()
	check(current_scene.scene_file_path == "res://scenes/main.tscn", "Checks use the actual Stage 1 scene")
	check(not player.visual.sprite_frames.has_animation("attack_air"), "Old standalone air artwork is inactive")
	check(player.air_combo_hang_enabled, "Air combo hang is enabled by default")
	for step in range(1, 4):
		var clip := "air_attack_%d" % step
		check(player.visual.sprite_frames.get_frame_count(clip) == 8 and not player.visual.sprite_frames.get_animation_loop(clip), "Eight non-looping character frames for air step %d" % step)
		for frame in range(8):
			var character: Texture2D = player.visual.sprite_frames.get_frame_texture(clip, frame)
			var effect: Texture2D = player.air_combo_effect.sprite_frames.get_frame_texture(clip + "_vfx", frame)
			var effect_canvas: int = player.ANIMATIONS.AIR_VFX_CANVASES[step - 1]
			check(not character is AtlasTexture and not effect is AtlasTexture and character.get_size() == Vector2(512, 512) and effect.get_size() == Vector2.ONE * effect_canvas and character.resource_path.ends_with("air_attack%d_character_%02d.png" % [step, frame]) and effect.resource_path.ends_with("air_attack%d_vfx_%02d.png" % [step, frame]), "Uncropped character/replacement VFX canvas %d/%02d" % [step, frame])
			var transform: Transform2D = player.ANIMATIONS.character_transform(clip, frame)
			check(is_equal_approx(transform.x.length(), .10 if step == 1 else .09), "Character scale stays fixed throughout clip %d/%02d" % [step, frame])
	for face in [1, -1]:
		await full_string(false, face)
		await full_string(true, face)
	# Single opener and two attacks without continuing input both fall normally.
	for stop_step in [1, 2]:
		await reset_player()
		await tap("jump")
		await tap()
		if stop_step == 2:
			await until_frame(2)
			await tap()
			await until_step(2)
		await wait(.7)
		check(player.air_combo_step == 0 and not player.attacking and not player.air_combo_effect.visible, "Stopping at air step %d releases to normal airborne/landing state" % stop_step)
		await wait(.6)
		check(player.is_on_floor(), "Stopping input does not levitate Red")
	await reset_player()
	await tap("jump")
	await wait(.4)
	check(player.velocity.y > 0 and not player.is_on_floor(), "Descending jump is available for hang check")
	await tap()
	var falling_hang_height := player.position.y
	var falling_hang_x := player.position.x
	input_action("move_right", true)
	await wait(.15)
	input_action("move_right", false)
	check(is_zero_approx(player.velocity.y) and absf(player.position.y - falling_hang_height) < .1, "Starting an attack while falling also suspends Red")
	check(is_zero_approx(player.velocity.x) and absf(player.position.x - falling_hang_x) < .1, "Horizontal input cannot move Red during the hang")
	input_action("move_right", true)
	await wait(.75)
	input_action("move_right", false)
	check(not player.attacking and player.position.x > falling_hang_x + 1, "Held movement resumes after air attack recovery ends")
	# The inspector switch preserves the old falling finisher for comparison.
	await reset_player()
	player.air_combo_hang_enabled = false
	await tap("jump")
	await tap()
	player._begin_air_combo(3)
	await until_frame(3)
	check(player.air_finisher_push_applied and player.velocity.y > 0, "Disabling hang restores the old finisher's downward push")
	player.air_combo_hang_enabled = true
	await reset_player()
	await tap("jump")
	await tap("jump")
	player.velocity.x = 140
	await tap()
	await wait(.1)
	check(player.jumps_used == 2 and is_zero_approx(player.velocity.x), "Air opener stops incoming momentum without refilling double jump")
	player._cancel_action()
	await tap("jump")
	check(player.jumps_used == 2, "Air attack interruption does not grant a third jump")
	# Ground launcher alone leaves the floor at the existing strike frame.
	await reset_player()
	input_action("move_up", true)
	await tap()
	input_action("move_up", false)
	await until_frame(2)
	await physics_frame
	# physics_frame fires before Red's move_and_slide updates the floor flag.
	await process_frame
	check(player.rising_launch_applied and not player.is_on_floor() and player.velocity.y < -300 and player.jumps_used == 1, "Ground Rising Slash physically launches Red and consumes the ground jump (frame=%d, vy=%.2f, jumps=%d, launched=%s, floor=%s)" % [player.visual.frame, player.velocity.y, player.jumps_used, player.rising_launch_applied, player.is_on_floor()])
	await wait(.45)
	check(player.rising_slash_used_in_air and not player.is_on_floor(), "Launcher restriction persists through recovery")
	# Allow a second rising animation high above terrain, but no second boost.
	player.position.y = 100
	player.velocity.y = 50
	# Cooldown alone cannot bypass the new stationary recovery state.
	while player.action_state == player.Action.ATTACK or player.action_state == player.Action.ATTACK_RECOVERY:
		await process_frame
	player.cooldown = 0
	input_action("move_up", true)
	await tap()
	input_action("move_up", false)
	await until_frame(3)
	check(not player.rising_launch_applied and player.velocity.y > 0, "Repeated airborne Rising Slash gives no new vertical boost")
	# Landing in each attack cancels the queue/effect without starting a ground step.
	for step in range(1, 4):
		await reset_player()
		await tap("jump")
		await tap()
		if step > 1:
			player._begin_air_combo(step)
		await until_frame(1)
		await tap()
		# Simulate terrain contacting the suspended player, rather than falling
		# toward a floor (which the enabled hang intentionally prevents).
		player.position = Vector2(140, 486)
		player.velocity = Vector2.ZERO
		await wait(.1)
		check(player.is_on_floor() and player.air_combo_step == 0 and not player.air_combo_buffered and not player.hitbox.active and not player.air_combo_effect.visible and player.combo_step == 0, "Landing during air step %d clears attack and buffered input" % step)
		check(player.cooldown <= (player.FINISHER_RECOVERY if step == 3 else player.ATTACK_RECOVERY), "Air landing uses bounded recovery")
	# An exhausted string stays exhausted until a real landing, even after cancel.
	await reset_player()
	await tap("jump")
	await tap()
	player._cancel_action()
	player.position.y = 100
	player.velocity = Vector2.ZERO
	player.cooldown = 0
	await tap()
	check(player.air_combo_used and player.air_combo_step == 0 and not player.attacking, "Cannot restart an exhausted air string without landing")
	await wait(.1)
	check(player.velocity.y > 0, "Cancelling the attack immediately releases the hang to gravity")
	# Each separate attack still hits once, using the real player hitbox.
	await reset_player()
	following_target = CharacterBody2D.new()
	following_target.set_script(DUMMY)
	current_scene.add_child(following_target)
	physics_frame.connect(follow_target)
	await tap("jump")
	await tap()
	for step in range(1, 4):
		await until_frame(3)
		await physics_frame
		check(following_target.hits == step and following_target.health == 1000 - 20 * step, "Air step %d hits once for the original 20 damage" % step)
		if step < 3:
			await tap()
			await until_step(step + 1)
	physics_frame.disconnect(follow_target)
	following_target.queue_free()
	following_target = null
	await wait(.8)
	# Damage interruption must remove a queued follow-up and both VFX layers.
	await reset_player()
	await tap("jump")
	await tap()
	await until_frame(2)
	await tap()
	player.invulnerable = 0
	player.take_damage(8, -180)
	check(player.action_state == player.Action.HURT and player.air_combo_step == 0 and not player.air_combo_buffered and not player.air_combo_effect.visible and not player.hitbox.active, "Hurt cancels air state, queue, VFX and damage")
	var hurt_height := player.position.y
	await wait(.08)
	check(player.position.y < hurt_height and player.velocity.y < 0, "Hurt knockback overrides the cancelled air hang")
	await wait(.6)
	await reset_player()
	await tap()
	check(player.combo_step == 1 and player.air_combo_step == 0, "Ground C still starts the ground combo")
	await reset_player()
	await tap("jump")
	await tap()
	await until_frame(2)
	await tap()
	player.invulnerable = 0
	player.take_damage(1000)
	check(player.dead and player.air_combo_step == 0 and not player.air_combo_buffered and not player.air_combo_effect.visible and not player.hitbox.active, "Death clears air attack, follow-up buffer, VFX and hitbox")
	print("AIR COMBO CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
