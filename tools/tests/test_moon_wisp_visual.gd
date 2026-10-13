extends SceneTree

const VISUAL := preload("res://scenes/moon_wisp_visual.tscn")
const MAP := preload("res://scripts/stage1_definition.gd")
var checks := 0
var failures := 0
var completions := 0

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

func _completed() -> void:
	completions += 1

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://presentation_test_moon_wisp_visual.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.stage_objectives.clear()
	session.activated_checkpoints.clear()
	session.collected_petals.clear()
	var visual := VISUAL.instantiate()
	root.add_child(visual)
	visual.position = Vector2(300, 200)
	visual.arrival_finished.connect(_completed)
	var sprite := visual.get_node("Sprite") as AnimatedSprite2D
	check(not visual.visible and not sprite.is_playing(), "Reusable visual starts inactive")
	check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and sprite.material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED, "Nearest filtering and unshaded glow preserve readability")
	check(is_equal_approx(visual.gameplay_scale, .045), "Conservative scale is shared by every clip")
	for clip: String in ["idle", "move", "arrive"]:
		check(sprite.sprite_frames.get_frame_count(clip) == 8, clip + " has all eight supplied frames")
		check(sprite.sprite_frames.get_animation_loop(clip) == (clip != "arrive"), clip + " has the correct loop flag")
		visual.play_state(clip)
		for index in range(8):
			sprite.frame = index
			var texture := sprite.sprite_frames.get_frame_texture(clip, index)
			var prefix := "arrival" if clip == "arrive" else clip
			check(texture.resource_path.ends_with("/" + clip + "/wisp_" + prefix + "_%02d.png" % index), clip + str(index) + " loads the correct source set")
			check(texture.get_size() == Vector2(512, 512) and not texture is AtlasTexture, clip + str(index) + " uses the entire uncropped canvas")
			var pixels := texture.get_image()
			check(pixels.get_pixel(0, 0).a == 0 and pixels.get_pixel(511, 511).a == 0, clip + str(index) + " has real transparent corners")
			check(sprite.scale.is_equal_approx(Vector2.ONE * .045), clip + str(index) + " retains one uniform scale")
			for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				visual.face_travel(direction)
				var pivot: Vector2 = visual.core_anchor()
				if sprite.flip_h:
					pivot.x = 512 - pivot.x
				var world_core := sprite.to_global(pivot + sprite.offset)
				check(world_core.is_equal_approx(visual.global_position), clip + str(index) + " core stays anchored: " + str(direction))
				if clip == "move":
					var local_front := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
					check(local_front.rotated(sprite.rotation).is_equal_approx(direction), "Moving head faces travel and tail stays behind")
				check(sprite.flip_h == (direction.x < 0), "Opposite direction mirrors the same source frames")
	for clip: String in ["idle", "move"]:
		visual.play_state(clip)
		var seen: Dictionary = {}
		var wraps := 0
		var previous_frame := sprite.frame
		for index in range(130):
			await physics_frame
			seen[sprite.frame] = true
			if sprite.frame < previous_frame:
				wraps += 1
			previous_frame = sprite.frame
		check(seen.size() == 8 and wraps >= 2 and visual.visible, clip + " actually plays and loops repeatedly")
	visual.play_state("arrive", .85)
	var arrival_frames: Dictionary = {}
	for index in range(49):
		await physics_frame
		arrival_frames[sprite.frame] = true
	check(visual.visible and sprite.frame == 7 and not visual.arrival_complete, "Last arrival frame remains visible for its full interval")
	await frames(5)
	check(arrival_frames.size() == 8 and completions == 1 and visual.arrival_complete and not visual.visible, "All arrival frames play once before hiding")
	await frames(70)
	check(completions == 1 and not sprite.is_playing(), "Arrival never loops or emits repeated completion")
	visual.play_state("idle")
	check(visual.visible and not visual.arrival_complete and sprite.speed_scale == 1.0, "Visual can be reused at the normal idle speed")
	visual.deactivate()
	visual.queue_free()
	change_scene_to_file(session.STAGE_ONE)
	await frames(20)
	var player := current_scene.get_node("Player") as CharacterBody2D
	var guide := current_scene.get_node("Stage1Layout/MoonWispGuide")
	for wolf in get_nodes_in_group("enemies"):
		wolf.set_physics_process(false)
	player.invulnerable = 10000
	player.position = Vector2(3870, 149)
	player.velocity = Vector2.ZERO
	await frames(12)
	check(not guide.visible and not guide.art.visible, "Guidance stays inactive before discovery")
	current_scene.get_node("Stage1Layout/camp_moon_seal").interact(player)
	# The shrine now finishes its activation before releasing the cinematic Wisp.
	while not guide.cinematic_active:
		await frames(1)
	check(guide.cinematic_active and paused and guide.art.appearing, "First seal gathers the Wisp from appearance VFX while pausing the world")
	var visited: Dictionary = {}
	var arriving_seen := false
	var arrival_finished_before_return := false
	var start_y: float = guide.global_position.y
	var lowest_y := start_y
	for index in range(480):
		await physics_frame
		visited[guide.phase] = true
		lowest_y = maxf(lowest_y, guide.global_position.y)
		if guide.phase == "travel":
			check(guide.art.sprite.animation == "move" and guide.art.visible, "Cinematic travel uses the moving visual")
		elif guide.phase == "fade":
			arriving_seen = arriving_seen or guide.art.sprite.animation == "arrive"
		elif guide.phase == "camera_return":
			arrival_finished_before_return = not guide.art.visible
	check(visited.has("swirl") and visited.has("pause") and visited.has("travel") and visited.has("landmark") and visited.has("fade") and visited.has("camera_return"), "Existing guidance flow drives every visual state")
	check(arriving_seen and arrival_finished_before_return, "Cinematic shows the arrival before camera return")
	check(lowest_y - start_y > 280 and guide.destination == MAP.FIRST_WISP_ROUTE.back(), "Wisp follows the existing vertical route to the region, not the exact seal")
	check(not paused and not guide.cinematic_active and player.get_node("Camera2D").is_current() and guide.phase == "hidden", "Camera and world resume after all eight arrival frames")
	# Exercise an actual short guide flight back left and upward, independent
	# of the player's camera; target selection itself is covered by progression.
	guide.cooldown = 0
	guide.request_guidance(true)
	guide.brief_cue = true
	guide.destination = guide.origin + Vector2(-150, -100)
	await frames(40)
	check(guide.phase == "travel" and guide.art.sprite.flip_h and guide.art.heading.x < 0 and guide.art.heading.y < 0, "Guidance can travel left and upward with a trailing comet")
	check(not guide.cinematic_active and not paused and player.get_node("Camera2D").is_current(), "Short cue keeps the camera with Red")
	await frames(425)
	check(guide.phase == "hidden" and not guide.art.visible, "Short cue completes and deactivates the reusable visual")
	print("MOON WISP VISUAL: ", checks, " checks; ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(1 if failures else 0)
