extends SceneTree

# --script res://tools/tests/test_red_animations.gd -- --presentation-test --red-group=movement
var checks := 0
var failures := 0
var player: CharacterBody2D
var arena: Node2D
const DUMMY := preload("res://tools/tests/red_damage_dummy.gd")

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", description)
	if not ok:
		failures += 1

func wait(seconds: float = .1) -> void:
	await create_timer(seconds).timeout

func action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(name: String) -> void:
	action(name, true)
	await wait(.025)
	action(name, false)
	await wait(.025)

func reset_player() -> void:
	# Each independent scenario starts with fresh ability availability.
	player.dash_cooldown_remaining = 0.0
	player.crescent_cooldown_remaining = 0.0
	player.global_position = Vector2(400, 485)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10
	player.reset_physics_interpolation()
	await wait(.4)

func _setup() -> void:
	# Reuse the real player scene nodes in an isolated terrain fixture.
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
	rectangle.size = Vector2(2400, 50)
	shape.shape = rectangle
	floor_body.position = Vector2(600, 525)
	floor_body.add_child(shape)
	arena.add_child(floor_body)
	arena.add_child(player)
	await reset_player()

func movement() -> void:
	check(player.visual.animation == "idle", "Native idle loops")
	check(player.visual.sprite_frames.get_frame_count("idle") == 8, "All eight idle poses imported")
	check(player.visual.scale.is_equal_approx(Vector2(.105, .105)), "Full 512px idle canvas uses one uniform display scale")
	check(player.visual.position.is_equal_approx(Vector2(0, -7.47)), "Replacement idle pivot anchored at body bottom")
	check(player.get_node("CollisionShape2D").shape.size == Vector2(18, 30), "Body collider unchanged")
	for clip in ["idle", "walk", "run", "jump", "double_jump", "fall", "land", "recover", "dash", "hurt", "knockback", "crouch_enter", "crouch_hold", "crouch_exit", "crouch_move", "air_attack_1", "air_attack_2", "air_attack_3", "rising_slash"]:
		var frames: SpriteFrames = player.visual.sprite_frames
		var all_full := true
		var all_replacements := true
		for index in range(frames.get_frame_count(clip)):
			var texture: Texture2D = frames.get_frame_texture(clip, index)
			all_full = all_full and not texture is AtlasTexture
			all_replacements = all_replacements and texture.resource_path.begins_with("res://assets/game_assets/red_gothic_replacements/")
		check(all_full and all_replacements, "Uncropped replacement source for " + clip)
	check(is_equal_approx(player._animation_duration("dash"), .15), "Dash remains 0.15 seconds")
	check(is_equal_approx(player._animation_duration("land") + player._animation_duration("recover"), 1.0 / 3.0), "Four landing frames preserve the original combined recovery duration")
	check(player.visual.sprite_frames.get_frame_texture("rising_slash", 0).resource_path.ends_with("red_rising_slash_vfx_01.png"), "Swapped rising folders routed by actual character content")
	action("move_right", true)
	await wait(.25)
	check(player.visual.animation == "walk" and player.velocity.x > 100, "Idle to walk")
	action("sprint", true)
	await wait(.12)
	check(player.visual.animation == "run", "Walk to sprint run")
	await tap("jump")
	check(player.visual.animation == "jump" and player.velocity.y < 0, "Running jump uses new jump")
	action("move_right", false)
	action("sprint", false)
	var fell := false
	var landed := false
	var recovered := false
	for frame in range(100):
		await physics_frame
		fell = fell or player.visual.animation == "fall"
		landed = landed or player.visual.animation == "land"
		recovered = recovered or player.visual.animation == "recover"
		if recovered and player.visual.animation == "idle":
			break
	check(fell, "Jump transitions into fall")
	check(landed, "Landing starts once")
	check(recovered, "Landing transitions into recovery")
	check(player.visual.animation == "idle", "Recovery returns to idle")
	await tap("jump")
	await wait(.13)
	await tap("jump")
	check(player.jumps_used == 2 and player.visual.animation == "double_jump", "Double jump preserved")
	await reset_player()
	var before := player.position.x
	player.invulnerable = 0
	await tap("dash")
	check(player.visual.animation == "dash" and player.invulnerable > .5 and player.invulnerable <= .7, "Idle dash uses new poses and keeps 0.7s iframe")
	await wait(.2)
	# Includes the original deceleration after the 64.5px burst.
	check(player.position.x - before > 50 and player.position.x - before < 160, "Dash burst and existing deceleration preserved")
	check(player.collision_layer == 1, "Dash restores collision layer")
	action("move_left", true)
	await wait(.18)
	check(player.visual.flip_h and player.facing == -1, "Left facing flips the supplied frames")
	await wait(player.dash_cooldown_remaining + .05)
	before = player.position.x
	await tap("dash")
	await wait(.17)
	action("move_left", false)
	check(player.position.x < before - 50, "Running left dash works")
	await wait(.25)
	check(player.visual.animation == "idle", "Run to idle")

func _run() -> void:
	await _setup()
	var group := "movement"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--red-group="):
			group = argument.get_slice("=", 1)
	if group == "movement":
		await movement()
	elif group == "combat":
		await combat()
	elif group == "directional":
		await directional()
	elif group == "crescent":
		await crescent()
	elif group == "crouch":
		await crouch()
	elif group == "presentation":
		await presentation()
	elif group == "legacy":
		await legacy()
	print("RED CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)

func dummy(where: Vector2) -> CharacterBody2D:
	var target := CharacterBody2D.new()
	target.set_script(DUMMY)
	target.position = where
	arena.add_child(target)
	return target

func combat() -> void:
	for face in [1, -1]:
		await reset_player()
		player.facing = face
		player.visual.flip_h = face < 0
		player.cooldown = 0
		var target := dummy(player.position + Vector2(30 * face, 0))
		await wait(.05)
		player._start_attack()
		check(not player.hitbox.active and target.hits == 0, "Attack anticipation has no hit, facing %d" % face)
		await wait(.23)
		check(target.hits == 1 and player.hitbox.active, "Active attack frames hit once, facing %d" % face)
		await wait(.42)
		check(target.hits == 1 and not player.hitbox.active, "Recovery has no extra hits, facing %d" % face)
		check(signf(target.last_knockback) == face, "Hit knockback follows facing %d" % face)
		target.queue_free()
	await reset_player()
	player.cooldown = 0
	player._start_attack()
	player.invulnerable = 0
	player.take_damage(8, -180)
	check(player.action_state == player.Action.HURT and not player.hitbox.active and not player.attacking, "Hurt interrupts attack and its hitbox")
	action("move_right", true)
	await tap("jump")
	await tap("attack")
	await tap("dash")
	check(player.action_state == player.Action.HURT and player.dash_timer == 0 and player.velocity.x <= 0, "Hurt locks movement, jump, attack and dash")
	action("move_right", false)
	var hp: int = player.current_health
	player.take_damage(8)
	check(player.current_health == hp and player.invulnerable > 0, "Damage iframe remains 0.5 seconds")
	await wait(.55)
	check(player.action_state == player.Action.NONE, "Hurt returns control")
	player.invulnerable = 0
	player.take_damage(30, 180)
	check(player.visual.animation == "knockback", "Heavy damage uses the full knocked-down hurt sequence")
	await wait(.6)
	player.invulnerable = 0
	player.take_damage(1000)
	check(player.dead and player.visual.animation == "death" and not player.hitbox.active, "Death locks control and starts replacement animation")
	check(player.visual.sprite_frames.get_frame_count("death") == 8 and not player.visual.sprite_frames.get_animation_loop("death"), "Death uses all eight frames and never loops")
	check(is_equal_approx(player._animation_duration("death"), 1.0), "New collapse lasts one second, including the final held pose")
	for index in range(8):
		var texture: Texture2D = player.visual.sprite_frames.get_frame_texture("death", index)
		check(texture.resource_path.ends_with("red_gothic_replacements/death/death_%02d.png" % index) and not texture is AtlasTexture, "Death uses unchanged replacement PNG %02d" % index)
	await wait(5.2)
	check(current_scene.scene_file_path == "res://scenes/game_over.tscn", "New death reaches existing Game Over flow")

func directional() -> void:
	await reset_player()
	action("move_up", true)
	var above := dummy(player.position + Vector2(12, -35))
	await wait(.05)
	await tap("attack")
	action("move_up", false)
	check(player.visual.animation == "rising_slash" and not player.hitbox.active, "Up+attack starts rising anticipation")
	await wait(.2)
	check(above.hits == 1 and above.velocity.y < 0, "Rising slash hits above and launches light enemies")
	check(player.attack_effect.visible and player.attack_effect.animation == "rising", "Rising arc is a separate synchronized node")
	await wait(.45)
	check(not player.hitbox.active and not player.attack_effect.visible, "Rising recovery ends damage and effect")
	above.queue_free()
	await reset_player()
	await tap("jump")
	player.cooldown = 0
	await tap("attack")
	check(player.visual.animation == "air_attack_1", "Airborne attack selects master opener")
	await wait(.35)
	check(player.attacking and player.air_combo_effect.visible and not player.attack_effect.visible, "Master air trail uses its independent layer")
	await wait(.4)
	check(not player.attacking and player.visual.animation in ["fall", "land", "recover", "idle"], "Air attack returns to fall or landing")
	await reset_player()
	player.position = Vector2(400, 300)
	player.velocity = Vector2.ZERO
	await wait(.025)
	var below := dummy(player.position + Vector2(6, 43))
	action("move_down", true)
	player.cooldown = 0
	await tap("attack")
	action("move_down", false)
	check(player.visual.animation == "downward_slash", "Down+air attack selects falling strike")
	var dove := false
	for frame in range(22):
		await physics_frame
		dove = dove or player.downward_diving and player.velocity.y > 0
	check(below.hits == 1 and dove, "Downward slash hits below once and keeps diving without a bounce")
	await wait(.3)
	check(not player.attacking and not player.hitbox.active, "Downward strike returns control")
	below.queue_free()

func crescent() -> void:
	check(InputMap.action_get_events("crescent_slash")[0].physical_keycode == KEY_R, "R key binds Crescent Slash")
	for face in [1, -1]:
		await reset_player()
		player.facing = face
		player.cooldown = 0
		var target := dummy(player.position + Vector2(140 * face, -10))
		await wait(.05)
		await tap("crescent_slash")
		check(player.visual.animation == "crescent_cast" and get_nodes_in_group("red_projectiles").is_empty(), "Cast anticipation has no projectile, facing %d" % face)
		await wait(.19)
		var shots := get_nodes_in_group("red_projectiles")
		check(shots.size() == 1 and shots[0].direction == face and shots[0].visual.flip_h == (face < 0), "One projectile releases at frame 3, facing %d" % face)
		await wait(.25)
		shots = get_nodes_in_group("red_projectiles")
		check(target.hits == 1 and shots.size() == 1 and shots[0].impacting and shots[0].visual.animation == "impact", "Projectile hits once and shows separate impact, facing %d" % face)
		await wait(.45)
		check(get_nodes_in_group("red_projectiles").is_empty(), "Impact completion frees projectile, facing %d" % face)
		target.queue_free()
	await reset_player()
	player.facing = 1
	var wall := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20, 100)
	collision.shape = rectangle
	wall.position = player.position + Vector2(100, -20)
	wall.add_child(collision)
	arena.add_child(wall)
	var behind_wall := dummy(player.position + Vector2(150, -10))
	await wait(.05)
	player.cooldown = 0
	await tap("crescent_slash")
	await wait(.5)
	check(behind_wall.hits == 0, "Crescent stops at terrain instead of hitting enemies behind it")
	wall.queue_free()
	behind_wall.queue_free()
	await wait(.6)
	await wait(player.crescent_cooldown_remaining + .05)
	player.cooldown = 0
	await tap("crescent_slash")
	await wait(1.8)
	check(get_nodes_in_group("red_projectiles").is_empty(), "Missed Crescent expires at its maximum range")
	await wait(player.crescent_cooldown_remaining + .05)
	player.cooldown = 0
	await tap("crescent_slash")
	player.invulnerable = 0
	player.take_damage(8)
	await wait(.5)
	check(get_nodes_in_group("red_projectiles").is_empty(), "Hurt before release cancels the cast")

func crouch() -> void:
	action("move_down", true)
	await wait(.08)
	check(player.visual.animation == "crouch_enter", "Down enters crouch")
	await wait(.25)
	check(player.visual.animation == "crouch_hold", "Crouch holds the low poses")
	action("move_right", true)
	await wait(.2)
	check(player.visual.animation == "crouch_move" and player.velocity.x < 90, "Crouch walk uses eight poses at half speed")
	action("move_right", false)
	action("move_left", true)
	await wait(.2)
	check(player.visual.flip_h and player.visual.animation == "crouch_move", "Crouch walk flips left")
	action("move_left", false)
	check(player.visual.position.is_equal_approx(Vector2(0, -1.38)) and player.visual.offset == Vector2.ZERO, "Crouch walk keeps its whole-canvas authored pivot")
	check(player.get_node("CollisionShape2D").shape.size == Vector2(18, 30), "Crouch keeps the stable collider")
	action("move_down", false)
	await wait(.04)
	check(player.visual.animation == "crouch_exit", "Releasing Down plays standing recovery")
	await wait(.3)
	check(player.visual.animation == "idle", "Crouch exit returns to idle")
	# Real one-way platform collision, not a mocked flag.
	var platform := StaticBody2D.new()
	platform.add_to_group("drop_through_platform")
	platform.position = Vector2(400, 410)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(180, 12)
	shape.shape = rect
	shape.one_way_collision = true
	platform.add_child(shape)
	arena.add_child(platform)
	player.position = Vector2(400, 380)
	player.velocity = Vector2.ZERO
	await wait(.2)
	check(player.is_on_floor() and player.position.y < 400, "Red can stand on a one-way platform")
	action("move_down", true)
	await tap("jump")
	action("move_down", false)
	await wait(.3)
	check(player.position.y > 425, "Down+Space still drops through")
	platform.queue_free()

func presentation() -> void:
	await tap("interact")
	check(player.visual.animation == "interact_look_around", "E uses supplied interaction poses")
	await wait(.45)
	check(player.visual.animation == "idle", "Interaction returns to idle")
	var reward: Node2D = load("res://scenes/forest_reward.tscn").instantiate()
	reward.identifier = "red_animation_test_petal"
	root.get_node("GameSession").collected_petals.erase(reward.identifier)
	player.current_health = 70
	reward.position = player.position
	arena.add_child(reward)
	await wait(.08)
	check(player.visual.animation == "interact_pickup" and player.current_health == 82, "Actual petal collection plays pickup and retains healing")
	await wait(.4)
	for style in ["stage1_bittersweet", "normal_stage_clear", "cheerful"]:
		player.play_victory(style)
		await wait(.06)
		check(player.visual.animation == "victory_" + style, "Victory pose available: " + style)
		await wait(1.1)
		check(player.visual.animation == "idle", "Victory returns control: " + style)
	player.play_interaction("open_chest")
	action("move_right", true)
	await wait(.1)
	check(player.action_state == player.Action.NONE and player.visual.animation == "walk", "Movement can interrupt optional presentation")
	action("move_right", false)
	await wait(.2)
	await tap("dash")
	check(player.dash_effects.size() == 3 and not player.dash_effects[0].visible, "Replacement dash trail is not doubled with legacy VFX")
	await wait(.45)
	check(not player.dash_effects[0].visible and not player.dash_effects[1].visible and not player.dash_effects[2].visible, "Dash VFX finish and hide")
	# Exercise victory through the actual boss/UI relationship, without changing AI.
	change_scene_to_file("res://scenes/stage2_boss.tscn")
	await wait(.3)
	player = current_scene.get_node("Player")
	player.invulnerable = 10
	var boss: CharacterBody2D = get_first_node_in_group("boss")
	boss.take_damage(10000)
	await wait(.15)
	check(player.visual.animation == "victory_stage1_bittersweet", "Boss defeat triggers bittersweet victory through HUD integration")
	var session := root.get_node("GameSession")
	for path: String in [session.settings_path, session.save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func legacy() -> void:
	for attempt in range(3):
		await reset_player()
		player.cooldown = 0
		var target := dummy(player.position + Vector2(30, 0))
		await wait(.05)
		await tap("attack")
		check(player.visual.animation == "attack_slash", "Separate attack restarts combo at starter, attempt %d" % attempt)
		await wait(.85)
		check(target.hits == 1 and target.health == 980, "Unchained attack preserves one 20-damage hit, attempt %d" % attempt)
		target.queue_free()
	for skill in ["skill_blood_blossom", "skill_execution"]:
		await reset_player()
		var target := dummy(player.position + Vector2(35, 0))
		await wait(.05)
		await tap(skill)
		check(player.visual.animation == skill and not player.hitbox.active, "Existing skill uses new cast anticipation: " + skill)
		await wait(.23)
		check(target.hits == 1, "Existing skill still damages its target: " + skill)
		await wait(.45)
		check(not player.hitbox.active and target.hits == 1, "Existing skill finishes without extra damage: " + skill)
		target.queue_free()
	await reset_player()
	var source: Node = load("res://scenes/main.tscn").instantiate()
	var guardian: Node2D = source.get_node("WolfGuardian")
	source.remove_child(guardian)
	source.free()
	arena.add_child(guardian)
	var target := dummy(player.position + Vector2(85, 0))
	await wait(.05)
	await tap("special")
	check(not guardian.visual.visible and player.visual.animation == "idle" and target.health == 1000, "Wolf summon remains disabled")
	await wait(1.1)
	check(not guardian.visual.visible and player.action_state == player.Action.NONE, "Disabled summon leaves control available")
	target.queue_free()
