extends SceneTree

# Render the actual Stage 1 scene. All save writes use a dedicated test path.
const OUT := "res://docs/previews/petal_natural_review/"
var session: Node
var red: CharacterBody2D
var petals: Node2D
var camera: Camera2D
var checks := 0
var failures := 0
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", description)

func delay(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout

func view_rect() -> Rect2:
	var active_camera := root.get_camera_2d()
	var size := root.get_visible_rect().size / active_camera.zoom
	return Rect2(active_camera.get_screen_center_position() - size * .5, size)

func visible_petals() -> Dictionary:
	var counts := [0, 0, 0]
	var positions: Array[Vector2] = []
	var view := view_rect()
	for petal in petals.petals:
		if petals.is_visible_in_tree() and petal.active and petal.sprite.is_visible_in_tree() and petal.sprite.modulate.a >= .05 and view.has_point(petal.world_position):
			counts[petal.depth] += 1
			positions.append(petal.world_position)
	return {"background": counts[0], "midground": counts[1], "foreground": counts[2], "small": counts[0] + counts[1], "positions": positions, "combat": petals.combat_blend}

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUT + label + ".png")
	check(error == OK, "Captured " + label)

func sample(label: String, seconds: float) -> Dictionary:
	var samples: Array[Dictionary] = []
	var sum := 0.0
	var minimum := 999
	var maximum := 0
	var combat_sum := 0.0
	for index in range(roundi(seconds * 10.0)):
		await delay(.1)
		var state := visible_petals()
		samples.append(state)
		var count := int(state.small)
		sum += count
		combat_sum += float(state.combat)
		minimum = mini(minimum, count)
		maximum = maxi(maximum, count)
	var result := {"region": label, "mean_visible_small": sum / samples.size(), "min": minimum, "max": maximum, "mean_combat_blend": combat_sum / samples.size(), "samples": samples}
	results.append(result)
	print("PETAL_SAMPLE ", label, " mean=", result.mean_visible_small, " range=", minimum, "-", maximum, " combat=", result.mean_combat_blend)
	return result

func place(where: Vector2) -> void:
	red.global_position = where
	red.velocity = Vector2.ZERO
	red.reset_physics_interpolation()
	camera.make_current()
	camera.reset_smoothing()
	camera.force_update_scroll()
	await delay(.2)

func snapshot_pair(label: String) -> void:
	petals.set_process(false)
	await capture(label + "_with_petals")
	petals.hide()
	await capture(label + "_without_petals")
	petals.show()
	petals.set_process(true)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	session = root.get_node("GameSession")
	session.save_path = "user://crimson_petals_runtime_test.cfg"
	session.pending_spawn = false
	session.checkpoint_scene = session.STAGE_ONE
	session.checkpoint_position = Vector2(70, 485)
	session.activated_checkpoints.clear()
	session.stage_objectives.clear()
	session.learned_mechanics.clear()
	session.collected_petals.clear()
	session.opening_arrival_pending = true
	change_scene_to_file(session.STAGE_ONE)
	await process_frame
	await process_frame
	red = current_scene.get_node("Player") as CharacterBody2D
	petals = current_scene.get_node("CrimsonPetals") as Node2D
	camera = red.get_node("Camera2D") as Camera2D
	petals.rng.seed = 14062026
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	current_scene.get_node("Stage1Layout/MoonWispGuide").set_process(false)
	check(session.opening_arrival_active and paused, "Real opening arrival has locked gameplay")
	# Short actual-renderer recording of entry, dialogue and handoff.
	for index in range(64):
		await delay(.125)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "arrival_%03d.png" % index)
		if index == 23:
			check(petals.visible and int(visible_petals().small) > 0, "Petals are visible during the paused arrival")
			await capture("opening_arrival")
	check(not paused and not session.opening_arrival_active, "Arrival restores normal gameplay")
	red.set_physics_process(false)
	red.invulnerable = 10000.0
	await place(Vector2(420, 485))
	await delay(8.0)
	var entrance := await sample("entrance_quiet", 3.0)
	await snapshot_pair("entrance")
	check(float(entrance.mean_visible_small) >= 6.0, "Quiet entrance maintains fuller petal coverage")
	await place(Vector2(3880, 149))
	await delay(8.0)
	var chapel := await sample("chapel_quiet", 3.0)
	await snapshot_pair("chapel")
	check(float(chapel.mean_visible_small) >= 7.0, "Chapel has richer petal coverage")
	check(float(chapel.mean_visible_small) <= 15.0, "Chapel clusters remain moderate")
	# Force one scheduled gust to verify it and record the motion clearly.
	petals.current_gust_duration = 0.0
	petals.gust_timer = 0.0
	await delay(.2)
	check(petals.current_gust_duration > 0.0 and petals.gust_source != null, "Quiet Chapel starts an occasional wind cluster")
	var gust_origin: Vector2 = petals.gust_source.position
	for index in range(32):
		await delay(.125)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "chapel_motion_%03d.png" % index)
	check(petals.gust_source.position == gust_origin, "Wind cluster origin remains fixed in world space")
	check(petals.current_gust_duration == 0.0 and petals.gust_remaining == 0, "Gust finishes and returns to quiet drift")
	await place(Vector2(6320, 485))
	await delay(8.0)
	var open_stretch := await sample("open_stretch", 3.0)
	await snapshot_pair("open_stretch")
	check(float(open_stretch.mean_visible_small) >= 5.0, "Open outdoor stretch receives natural drift between scenery sources")
	# Camera follows traversal rather than sampling only a stationary view.
	await place(Vector2(9100, 485))
	for index in range(70):
		red.global_position.x = 9100.0 + index * 9.0
		red.reset_physics_interpolation()
		await delay(.1)
		if index % 10 == 0:
			var state := visible_petals()
			results.append({"region": "gate_approach_traversal", "x": red.global_position.x, "state": state})
	await sample("gate_approach_settled", 3.0)
	await snapshot_pair("gate_approach")
	await place(Vector2(5680, 409))
	await delay(3.0)
	check(petals.combat_blend > .9, "Nearby Creek Wolf activates combat suppression")
	check(petals.current_gust_duration == 0.0 and petals.gust_remaining == 0, "Combat stops wind clusters")
	await sample("creek_combat", 3.0)
	await snapshot_pair("creek_combat")
	await place(Vector2(4800, 725))
	await delay(8.0)
	await sample("root_cellar", 3.0)
	await snapshot_pair("root_cellar")
	check(is_equal_approx(petals._region_density(), .15), "Cellar uses reduced density")
	var pool_count: int = petals.petals.size()
	var active_before := 0
	for petal in petals.petals:
		if petal.active:
			active_before += 1
	petals.ambient_timer = -1.0
	petals._update_ambient_drift(.1, view_rect(), .15)
	var active_after := 0
	for petal in petals.petals:
		if petal.active:
			active_after += 1
	check(active_before == active_after, "Cellar does not add ambient petals")
	petals.gust_timer = -1.0
	check(is_zero_approx(petals._update_gusts(.1, view_rect(), .15)) and petals.gust_remaining == 0, "Cellar does not start wind clusters")
	await place(Vector2(9400, 485))
	await delay(5.0)
	var observed = null
	for petal in petals.petals:
		if petal.active and petal.depth < 2:
			observed = petal
			break
	check(observed != null, "An active world petal is available for motion checks")
	if observed != null:
		var before: Vector2 = observed.world_position
		await delay(.3)
		check(observed.world_position.y > before.y, "Petals fall over time")
		before = observed.world_position
		red.global_position.x += 40.0
		camera.reset_smoothing()
		camera.force_update_scroll()
		await delay(.05)
		check(absf(observed.world_position.x - before.x) < 12.0, "Small petals remain in world space when camera moves")
	paused = true
	await delay(.2)
	check(not petals.visible, "Ordinary pause hides petals")
	var positions: Array[Vector2] = []
	for petal in petals.petals:
		positions.append(petal.world_position)
	await delay(.3)
	var frozen := true
	for index in range(pool_count):
		frozen = frozen and positions[index] == petals.petals[index].world_position
	check(frozen, "Ordinary pause stops petal motion")
	paused = false
	await delay(.2)
	check(petals.visible, "Petals resume after ordinary pause")
	check(petals.petals.size() == pool_count and pool_count == 34, "Runtime retains its bounded 34-sprite pool")
	var report := FileAccess.open(OUT + "runtime_results.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "failures": failures, "results": results}, "\t"))
	print("PETAL_RUNTIME_RESULT checks=", checks, " failures=", failures)
	current_scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
