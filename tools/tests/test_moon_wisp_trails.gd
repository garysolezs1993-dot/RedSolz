extends SceneTree

const VISUAL := preload("res://scenes/moon_wisp_visual.tscn")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok:
		failures += 1

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://presentation_test_moon_wisp_trails.cfg"
	var container := Node2D.new()
	root.add_child(container)
	var visual := VISUAL.instantiate()
	container.add_child(visual)
	await frames(3)
	var pool: Node2D = visual.trail_pool
	check(pool.get_parent() != visual and pool.get_parent() != container, "Afterimages live outside the Wisp's moving/hidden hierarchy")
	check(pool.slots.size() == 12 and pool.get_child_count() == 12, "Pool preallocates twelve sprites, with no per-spawn node allocation")
	for slot in pool.slots:
		var sprite := slot.sprite as AnimatedSprite2D
		check(not slot.active and not sprite.visible, "Unused pooled trail starts hidden")
		check(not sprite.sprite_frames.get_animation_loop("trail") and sprite.sprite_frames.get_animation_speed("trail") == 16, "Eight-frame trail is a 16 FPS one-shot")
		for index in range(8):
			var texture := sprite.sprite_frames.get_frame_texture("trail", index)
			check(texture.resource_path.ends_with("/trail/wisp_trail_%02d.png" % index) and texture.get_size() == Vector2(444,444) and not texture is AtlasTexture, "Trail uses supplied whole-canvas frame " + str(index))
	visual.play_state("idle")
	for index in range(30):
		visual.position.x += 3
		await physics_frame
	check(pool.spawned_count == 0, "Idle/circling emits no afterimages")
	visual.face_travel(Vector2.RIGHT)
	visual.play_state("move")
	await frames(20)
	check(pool.spawned_count == 0, "Animated move pose does not emit trails when stationary")
	for index in range(6):
		visual.position.x += 5
		await physics_frame
	check(pool.spawned_count == 1 and pool.active_count == 1, "Actual movement emits only after distance and minimum time thresholds")
	var first := pool.slots[0].sprite as AnimatedSprite2D
	var fixed_position := first.global_position
	var fixed_rotation := first.rotation
	visual.face_travel(Vector2.LEFT)
	for index in range(8):
		visual.position.x += 5
		await physics_frame
	check(first.global_position == fixed_position and first.rotation == fixed_rotation and not first.flip_h, "An old trail retains its world position and facing when Wisp moves and turns")
	check(pool.spawned_count >= 2, "New movement emits separate trails at new locations; total=" + str(pool.spawned_count))
	check((pool.slots[1].sprite as AnimatedSprite2D).global_position != fixed_position, "New trail has a distinct historical world position")
	visual.play_state("idle")
	var count: int = pool.spawned_count
	var seen: Dictionary = {}
	var faded := false
	for index in range(24):
		await physics_frame
		if pool.slots[0].active:
			seen[first.frame] = true
			faded = faded or first.modulate.a < visual.trail_opacity and first.modulate.a > 0
	check(pool.spawned_count == count and faded, "Stopping emission lets old trails fade independently")
	check(not pool.slots[0].active and not first.visible, "Trail returns to its pool after roughly half a second")
	check(seen.has(7), "Final trail frame is displayed before removal")
	await frames(35)
	check(pool.active_count == 0 and not pool.is_processing(), "Idle pool becomes inactive after all effects finish")
	# Validate fixed front anchor and rear-facing art for every travel direction.
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		pool.emit_trail(Vector2(100,100), direction, .05, .35, .5, .2)
		var sprite := pool.slots[0].sprite as AnimatedSprite2D
		var rear := Vector2(100,300)
		var front: Vector2 = pool.FRONT_PIVOT
		if sprite.flip_h:
			rear.x = 444 - rear.x
			front.x = 444 - front.x
		check(sprite.to_global(front + sprite.offset).is_equal_approx(Vector2(100,100)), "Emitted trail front matches its spawn position")
		check((sprite.to_global(rear + sprite.offset) - sprite.global_position).dot(direction) < 0, "Trail art points behind travel direction: " + str(direction))
		check(sprite.flip_h == (direction.x < 0), "Trail correctly mirrors for reverse travel")
		var seen_frames: Dictionary = {}
		for index in range(29):
			await physics_frame
			seen_frames[sprite.frame] = true
		check(seen_frames.size() == 8 and pool.slots[0].active, "All eight frames play once during the 0.5-second lifetime")
		await frames(5)
		check(pool.active_count == 0, "Directional trail expires automatically")
	pool.emit_trail(Vector2(70,80), Vector2.RIGHT, .05, .35, .5, .2)
	container.hide()
	check(first.is_visible_in_tree(), "Hiding the Wisp/guide does not instantly hide existing world trails")
	await frames(35)
	check(pool.active_count == 0, "Trails naturally finish even when the guide is hidden")
	container.show()
	for index in range(20):
		pool.emit_trail(Vector2(index*20,100), Vector2.RIGHT, .05, .35, .5, .2)
	check(pool.active_count == 12 and pool.get_child_count() == 12, "Pool skips extra emissions at its hard cap")
	await frames(35)
	check(pool.active_count == 0, "A full pool completely returns to idle")
	visual.play_appearance(.28)
	check(visual.appearing and visual.sprite.animation == "arrive", "Appear reuses arrival art in reverse")
	await frames(20)
	check(not visual.appearing and visual.visible and visual.sprite.animation == "idle", "Appearance settles into idle without hiding or emitting trails")
	# Real guide movement and world pause: afterimages must still animate.
	container.queue_free()
	await frames(3)
	check(not is_instance_valid(pool), "Deleting the visual cleans up its external pool")
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70,485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	change_scene_to_file(session.STAGE_ONE)
	await frames(20)
	var player := current_scene.get_node("Player") as CharacterBody2D
	var guide := current_scene.get_node("Stage1Layout/MoonWispGuide")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)
	player.position = Vector2(3870,149)
	player.velocity = Vector2.ZERO
	player.invulnerable = 10000
	await frames(12)
	current_scene.get_node("Stage1Layout/camp_moon_seal").interact(player)
	# Shrine activation and the half-second release now precede the camera tour.
	await frames(180)
	check(paused and guide.phase == "travel" and guide.art.sprite.animation == "move", "Actual cinematic guidance uses moving assets while the world is paused")
	var guide_pool: Node2D = guide.art.lily_trail_pool if guide.art.use_lily_trail else guide.art.trail_pool
	check(guide_pool.spawned_count > 0 and guide_pool.active_count > 0, "World-space trails spawn and age during the paused camera tour")
	await frames(350)
	check(not paused and guide.phase == "hidden" and guide_pool.active_count == 0, "Guidance and lingering trails both finish cleanly")
	var old_pool: Node2D = guide_pool
	change_scene_to_file(session.STAGE_TWO)
	await frames(20)
	check(not is_instance_valid(old_pool), "Changing stages leaves no orphan trail pool")
	print("MOON WISP TRAILS: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
