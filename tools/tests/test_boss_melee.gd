extends SceneTree

# Actual Stage 2 boss/player. --presentation-test [--before-fix] [--capture]
var player: CharacterBody2D
var boss: CharacterBody2D
var checks := 0
var failures := 0
var captures: Array[Dictionary] = []
const OUTPUT := "res://.godot/boss_melee_review/"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func input_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func tap() -> void:
	input_action("attack", true)
	await wait(.04)
	input_action("attack", false)
	await wait(.025)

func until_frame(frame: int) -> void:
	var started := Time.get_ticks_msec()
	while player.attacking and player.visual.frame < frame and Time.get_ticks_msec() - started < 1500:
		await process_frame

func pose(name: String) -> void:
	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		captures.append({"name": name, "image": root.get_texture().get_image()})

func reset(face: int, distance: float) -> void:
	input_action("attack", false)
	player._cancel_action()
	player.cooldown = 0.0
	player.position = Vector2(1860.0 - distance * face, 485.0)
	player.velocity = Vector2.ZERO
	player.facing = face
	player.visual.flip_h = face < 0
	player.invulnerable = 100
	player.reset_physics_interpolation()
	boss.health = boss.maximum_health
	boss.velocity = Vector2.ZERO
	boss.position = Vector2(1860, 500)
	boss.visual.flip_h = face > 0
	boss._play_animation("walk")
	await wait(.12)

func _run() -> void:
	change_scene_to_file("res://scenes/stage2_boss.tscn")
	await wait(.4)
	player = current_scene.get_node("Player")
	boss = get_first_node_in_group("boss")
	boss.set_physics_process(false)
	AudioServer.set_bus_mute(0, true)
	# Keep animation and actual damage handling, without hitstop affecting timing.
	player.hitbox.hit_confirmed.disconnect(player._on_attack_hit)
	var before := OS.get_cmdline_user_args().has("--before-fix")
	for face in [1, -1]:
		for distance in [65.0, 85.0, 105.0, 145.0]:
			await reset(face, distance)
			await tap()
			await until_frame(3)
			await pose("%s_face_%d_distance_%d" % ["before" if before else "after", face, distance])
			await wait(.75)
			var damage: int = boss.maximum_health - boss.health
			print("REACH face=%d distance=%.0f damage=%d" % [face, distance, damage])
			check(damage == (20 if distance <= (75.0 if before else 105.0) else 0), "Measured ground swing damage at distance %.0f facing %d" % [distance, face])
	if not before:
		for face in [1, -1]:
			await reset(face, 85)
			await tap()
			for step in range(1, 4):
				await until_frame(4)
				check(boss.health == boss.maximum_health - step * 20, "Ground combo step %d hits boss once facing %d" % [step, face])
				if step < 3:
					await tap()
					var started := Time.get_ticks_msec()
					while player.combo_step == step and Time.get_ticks_msec() - started < 1500:
						await process_frame
			await wait(.75)
			check(boss.health == boss.maximum_health - 60, "Full combo gives 60 total, without body/area double damage")
		# Overlap both the compact body and hurtbox with one swing.
		await reset(1, 45)
		await tap()
		await wait(.85)
		check(boss.health == boss.maximum_health - 20, "Overlapping body and hurtbox count as one target")
		# Aim away from the boss, though its visual is nearby.
		await reset(1, 105)
		player.facing = -1
		player.visual.flip_h = true
		await tap()
		await wait(.85)
		check(boss.health == boss.maximum_health, "A backward melee swing does not hit nearby boss")
		# Crescent still resolves the same receiver once through the new area.
		await reset(1, 140)
		player.crescent_cooldown_remaining = 0.0
		input_action("crescent_slash", true)
		await wait(.04)
		input_action("crescent_slash", false)
		await wait(1.0)
		check(boss.health == boss.maximum_health - 20, "Crescent hits boss once through its hurtbox")
		var shape: RectangleShape2D = boss.get_node("CollisionShape2D").shape
		check(shape.size == Vector2(52, 32), "Boss terrain/body collision remains compact")
		# Also check a normal close-range swing against the live boss AI.
		for face in [1, -1]:
			await reset(face, 95)
			player.current_health = player.maximum_health
			player.invulnerable = 0.0
			boss.target = player
			boss.state = "approach"
			boss.hurt_timer = 0.0
			boss.slash_cooldown = 0.0
			boss.pounce_cooldown = 2.0
			boss.howl_cooldown = 3.0
			boss.set_physics_process(true)
			await tap()
			await wait(.85)
			check(boss.health == boss.maximum_health - 20, "Normal melee hits live boss once facing %d" % face)
			boss.set_physics_process(false)
		boss.take_damage(1000)
		await physics_frame
		await process_frame
		check(boss.dead and boss.get_node("Hurtbox").collision_layer == 0, "Death removes the boss hurtbox from damage queries")
	for capture in captures:
		capture.image.save_png(OUTPUT + capture.name + ".png")
	print("BOSS MELEE CHECKS: %d passed, %d failed" % [checks - failures, failures])
	current_scene.queue_free()
	captures.clear()
	await process_frame
	quit(1 if failures else 0)
