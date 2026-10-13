extends SceneTree

const VISUAL := preload("res://scenes/moon_wisp_visual.tscn")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _run() -> void:
	root.get_node("GameSession").save_path = "user://lily_trail_test.cfg"
	var visual := VISUAL.instantiate()
	visual.lily_trail_enabled = true
	root.add_child(visual)
	await frames(3)
	var pool: Node2D = visual.lily_trail_pool
	check(pool.get_parent() != visual and pool.capacity == 12, "Bounded pool lives outside the Wisp hierarchy")
	var sprite: AnimatedSprite2D = pool.slots[0].sprite
	check(not sprite.sprite_frames.get_animation_loop("trail") and sprite.sprite_frames.get_animation_speed("trail") == 16, "Lily clip is a 16 FPS one-shot")
	for index in range(8):
		var texture := sprite.sprite_frames.get_frame_texture("trail", index)
		check(texture.resource_path.ends_with("/lily_trail/lily_trail_%02d.png" % index) and texture.get_size() == Vector2(512,512) and not texture is AtlasTexture, "Whole untouched canvas " + str(index))
		var image := texture.get_image()
		check(image.get_pixel(0,0).a == 0 and image.get_used_rect().grow(-1).size.x > 0, "Real alpha transparency " + str(index))
		var bounds := image.get_used_rect()
		check(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 512 and bounds.end.y < 512, "Artwork has transparent margin " + str(index))
	visual.set_lily_trail_active(true)
	visual.play_state("idle")
	for index in range(30):
		visual.position.x += 3
		await physics_frame
	check(pool.spawned_count == 0, "Idle hover emits no lily trail")
	visual.play_state("move")
	await frames(20)
	check(pool.spawned_count == 0, "Stationary move animation emits no trail")
	visual.face_travel(Vector2.RIGHT)
	for index in range(8):
		visual.position.x += 5
		await physics_frame
	check(pool.spawned_count == 1 and visual.trail_pool.spawned_count == 0, "Distance spacing selects lily only, without stacking old trails")
	var fixed := sprite.global_position
	visual.position.x += 10
	await frames(2)
	check(sprite.global_position == fixed and sprite.modulate.a < 1, "Trail stays in world space and is softer than the core")
	visual.play_state("idle")
	var count: int = pool.spawned_count
	await frames(30)
	check(pool.spawned_count == count and pool.active_count == 0, "Stopping emission lets old trails finish naturally")
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		pool.emit_trail(Vector2(100,100), direction, .085, .28, .5, .2)
		var front: Vector2 = pool.front_pivot
		var rear: Vector2 = front - pool.authored_direction * 270
		if sprite.flip_h:
			front.x = 512 - front.x
			rear.x = 512 - rear.x
		check(sprite.to_global(front + sprite.offset).is_equal_approx(Vector2(100,100)), "Fixed pivot matches spawn " + str(direction))
		check((sprite.to_global(rear + sprite.offset) - sprite.global_position).dot(direction) < 0, "Petals point behind " + str(direction))
		var seen: Dictionary = {}
		var fades := false
		for index in range(29):
			await physics_frame
			seen[sprite.frame] = true
			fades = fades or (sprite.modulate.a > 0 and sprite.modulate.a < .28)
		check(seen.size() == 8 and pool.active_count == 1 and fades, "Eight frames play and fade during half-second life")
		await frames(5)
		check(pool.active_count == 0, "Trail expires after half a second")
	for index in range(20):
		pool.emit_trail(Vector2(index*32,0), Vector2.LEFT, .085, .28, .5, .2)
	check(pool.active_count == 12, "Pool enforces twelve-instance cap")
	visual.hide()
	check(sprite.is_visible_in_tree(), "Hiding Wisp leaves independent trails visible")
	await frames(35)
	check(pool.active_count == 0 and not pool.is_processing(), "Trails settle to an inactive pool")
	visual.queue_free()
	await frames(3)
	check(not is_instance_valid(pool), "Scene cleanup removes external pool")
	print("LILY TRAIL: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
