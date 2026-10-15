extends SceneTree

const OUT := "res://docs/previews/stage2_polish/"
var checks := 0
var failures := 0
var session: Node
var stage: Node2D
var player: CharacterBody2D
var boss: CharacterBody2D
var terrain_signature: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func signature(layout: Node) -> Array[String]:
	var result: Array[String] = []
	for node in layout.get_children():
		if not node is StaticBody2D:
			continue
		var collider := node.get_child(0) as CollisionShape2D
		result.append("%s:%s:%s:%s:%s:%s:%s:%s" % [node.name, node.transform, node.collision_layer, node.collision_mask, collider.transform, collider.shape.size, collider.one_way_collision, collider.one_way_collision_margin])
	return result

func decorative(node: Node) -> void:
	check(not node is CollisionObject2D and not node is CollisionShape2D, str(node.name) + " is decorative")
	if node is Sprite2D:
		check(is_equal_approx(node.scale.x, node.scale.y), str(node.name) + " preserves art proportions")
	for child in node.get_children():
		decorative(child)

func setup(use_art: bool) -> void:
	session.pending_spawn = false
	session.opening_arrival_pending = false
	session.stage_objectives = {session.STAGE_ONE: ["camp_moon_seal"]}
	session.checkpoint_scene = session.STAGE_TWO
	session.checkpoint_position = Vector2(70,485)
	stage = (load(session.STAGE_TWO) as PackedScene).instantiate()
	stage.get_node("Stage2BossLayout").environment_art_enabled = use_art
	root.add_child(stage)
	current_scene = stage
	await frames(10)
	player = stage.get_node("Player")
	boss = stage.get_node("Stage2BossLayout/CursedWolfBoss")
	player.invulnerable = 10000.0

func capture(label: String, where: Vector2) -> void:
	player.position = where
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	var camera := player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	await frames(5)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "Capture " + label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	session = root.get_node("GameSession")
	session.save_path = "user://presentation_test_stage2_polish.cfg"
	await setup(false)
	terrain_signature = signature(stage.get_node("Stage2BossLayout"))
	stage.queue_free()
	await frames(4)
	await setup(true)
	var layout := stage.get_node("Stage2BossLayout")
	check(signature(layout) == terrain_signature, "Every floor, boundary and ledge retains collision and position")
	check(not stage.get_node("UI/HUD/BossHP").visible, "First entry keeps boss HUD hidden")
	check(stage.get_node("BossIntroCutscene").phase == "waiting", "First entry retains the introduction")
	var art := layout.get_node("Stage2EnvironmentArt")
	decorative(art)
	check(art.z_index < 0, "Arena dressing stays behind Red and the boss")
	check(art.has_node("AltarStoneBase") and art.has_node("AltarBrokenArch"), "Rooted altar landmark assembled")
	check(not stage.get_node("UI/HUD/Controls").visible and not stage.get_node("UI/HUD/State").visible, "Combat HUD clears control list and generic story label")
	check(not stage.get_node("ForestEnvironment").has_node("NightAmbient"), "Selective lighting excludes actors from global darkening")
	stage.get_node("BossIntroCutscene").skip()
	var saw_skip_howl := false
	for index in range(240):
		var intro := stage.get_node_or_null("BossIntroCutscene")
		if intro == null:
			break
		saw_skip_howl = saw_skip_howl or intro.phase == "cinematic_howl"
		await physics_frame
	check(saw_skip_howl, "Skipping story retains the boss's opening howl")
	await frames(2)
	check(session.objective_completed(session.STAGE_TWO,"boss_intro_seen"), "Intro acknowledgement persisted")
	check(session.checkpoint_scene == session.STAGE_TWO and session.checkpoint_position == Vector2(1500,485), "Rematch anchor is beside clearing")
	check(session.objective_completed(session.STAGE_ONE,"camp_moon_seal"), "Stage 1 progress preserved")
	var config := ConfigFile.new()
	check(config.load(session.save_path) == OK and config.get_value("journey","position") == Vector2(1500,485), "Retry anchor written to isolated journey save")
	check(stage.get_node("UI/HUD/BossName").visible, "Boss name appears with battle HUD")
	# Freeze actors for art review while retaining real rendering and particle updates.
	player.set_physics_process(false)
	boss.set_physics_process(false)
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	boss.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	await frames(70)
	player.call("_play_visual","idle")
	await capture("entrance_after",Vector2(220,485))
	await capture("arena_after",Vector2(1720,485))
	var cues := boss.get_node("AttackCues")
	for entry in [["slash",.56,"attack",0],["pounce_windup",.22,"pounce",1],["howl_aoe",.7,"howl",2],["recovery",.4,"walk",0]]:
		boss.state = entry[0]
		boss.state_timer = entry[1]
		boss.damage_applied = false
		boss.visual.play(entry[2])
		boss.visual.set_frame_and_progress(entry[3],0)
		boss.visual.pause()
		boss.pounce_direction = -1
		await frames(3)
		check(cues.visible and not cues.cue.is_empty(), "Readable cue during " + str(entry[0]))
		await capture("cue_" + str(entry[0]),Vector2(1720,485))
		if entry[0] == "pounce_windup":
			check(cues.facing == -1, "Pounce arrow matches travel direction")
	boss.state = "slash"
	boss.state_timer = .4
	boss.damage_applied = true
	await frames(2)
	check(not cues.visible, "Windup cue ends when damage has resolved")
	boss.state = "approach"
	var petals := stage.get_node("CrimsonPetals")
	await frames(500)
	var active_petals := 0
	for petal in petals.petals:
		if petal.active:
			active_petals += 1
	check(petals.foreground_count == 0 and petals.petals.size() == 10, "Small reused petal pool has no foreground layer")
	check(active_petals > 0 and active_petals <= 5, "Battle maintains sparse petals (active=" + str(active_petals) + ")")
	await capture("arena_petals",Vector2(1720,485))
	paused = true
	await frames(3)
	check(not petals.visible and not cues.visible, "Petals and cues hide during cinematic pause")
	paused = false
	await frames(3)
	var health_before: int = player.current_health
	player.global_position = Vector2(1720,820)
	await frames(3)
	check(player.global_position.y < 500 and player.current_health == health_before, "Player floor rescue remains intact")
	boss.global_position = Vector2(2900,820)
	boss.call("_keep_in_arena")
	check(boss.global_position.y < 500 and boss.global_position.x <= 2772 and boss.health == boss.maximum_health, "Boss floor/boundary rescue retains health")
	boss.position = Vector2(1860,500)
	boss.state = "approach"
	# Existing melee damage must still resolve against the actual boss receiver.
	player.set_physics_process(true)
	player.global_position = Vector2(1775,485)
	player.velocity = Vector2.ZERO
	player.facing = 1
	player.invulnerable = 10000
	player.reset_physics_interpolation()
	await frames(5)
	player.call("_start_attack")
	await frames(65)
	check(boss.health == boss.maximum_health - 20, "Normal attack still hits boss once for 20 damage")
	player.current_health = 17
	var old_stage := stage
	session.retry_stage(session.STAGE_TWO)
	var saw_retry_howl := false
	for index in range(180):
		await physics_frame
		if current_scene != old_stage and current_scene != null:
			var intro := current_scene.get_node_or_null("BossIntroCutscene")
			saw_retry_howl = saw_retry_howl or (intro != null and intro.phase == "cinematic_howl")
		if current_scene != old_stage and current_scene != null and not session.transitioning and current_scene.get_node_or_null("BossIntroCutscene") == null:
			break
	stage = current_scene
	player = stage.get_node("Player")
	boss = stage.get_node("Stage2BossLayout/CursedWolfBoss")
	check(stage != old_stage and stage.get_node_or_null("BossIntroCutscene") == null, "Retry bypasses the acknowledged intro")
	check(saw_retry_howl, "Rematch also plays its opening howl")
	check(absf(player.position.x - 1500) < 2 and absf(player.position.y - 485) < 2, "Retry starts at clearing")
	check(player.current_health == player.maximum_health and boss.health == boss.maximum_health, "Rematch resets both fighters to full health")
	check(not paused and not stage.get_meta("boss_intro_pending",true), "Rematch restores gameplay and clears cinematic gate")
	check(stage.get_node("UI/HUD/BossHP").visible, "Rematch boss HUD initialized")
	check(stage.get_node_or_null("BossOpeningGrace") != null, "Rematch retains opening breathing room")
	print("STAGE 2 POLISH: ",checks," checks; ",failures," failures")
	var result := FileAccess.open(OUT + "test_result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"checks":checks,"failures":failures,"terrain_entries":terrain_signature.size(),"active_battle_petals":active_petals},"\t"))
	quit(0 if failures == 0 else 1)
