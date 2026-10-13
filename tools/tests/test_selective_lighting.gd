extends SceneTree

var checks := 0
var failures := 0
var art_count := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", description)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func inspect_art(node: Node) -> void:
	if node.has_method("set_lighting"):
		art_count += 1
		var shelves := 0
		for child in node.get_children():
			if child is Sprite2D and str(child.name).begins_with("MossShelf_"):
				shelves += 1
				check(child.material is ShaderMaterial, "Shelf has a visual depth shader")
				if child.material is ShaderMaterial:
					check(is_equal_approx(child.material.get_shader_parameter("top_brightness"), .94), "Platform top retains 94% brightness")
					check(is_equal_approx(child.material.get_shader_parameter("underside_brightness"), .72), "Platform underside is darker")
		check(shelves > 0, "Platform artwork retains whole shelf sprites")
		check(node.get_node("WalkableMossLip").material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED, "Walkable edge stays readable")
	for child in node.get_children():
		inspect_art(child)

func _run() -> void:
	root.get_node("GameSession").save_path = "user://presentation_test_test_selective_lighting.cfg"
	var session := root.get_node("GameSession")
	session.pending_spawn = false
	session.checkpoint_scene = ""
	session.activated_checkpoints.clear()
	change_scene_to_file("res://scenes/main.tscn")
	await frames(20)
	var environment := current_scene.get_node("ForestEnvironment")
	var red := current_scene.get_node("Player")
	check(environment.selective_lighting_enabled, "Selective treatment is enabled for Stage 1")
	check(environment.ambient == null and environment.get_node_or_null("NightAmbient") == null, "Stage 1 has no global darkness CanvasModulate")
	check(red.visual.material == null and red.visual.modulate == Color.WHITE and red.visual.self_modulate == Color.WHITE, "Red receives no darkening material or modulation")
	for effect in [red.attack_effect, red.combo_effect, red.air_combo_effect, red.downward_effect] + red.dash_effects:
		check(effect.material == null and effect.self_modulate == Color.WHITE, "Player VFX receive no darkening material")
	for enemy in get_nodes_in_group("enemies"):
		check(enemy.visual.material == null and enemy.visual.self_modulate == Color.WHITE, "Enemy silhouette is excluded from background grading")
	var far := environment.get_node("FarParallax/MoonlitRidge")
	var mid := environment.get_node("MidParallax/RedwoodMist")
	check(far.material is ShaderMaterial and mid.material is ShaderMaterial, "Parallax layers have independent grading materials")
	check(far.material != mid.material, "Background materials are independent")
	check(is_equal_approx(far.material.get_shader_parameter("brightness"), .85), "Far background begins at 85%")
	check(is_equal_approx(mid.material.get_shader_parameter("brightness"), .90), "Mid background begins at 90%")
	check(far.material.get_shader_parameter("soften_moon_castle") and not mid.material.get_shader_parameter("soften_moon_castle"), "Moon/castle mask applies only to the far PNG")
	check(is_equal_approx(mid.modulate.a, .55) and is_equal_approx(environment.get_node("ForegroundParallax/ThornedCanopy").modulate.a, .34), "Existing parallax transparency is preserved")
	check(is_equal_approx(environment.vignette.material.get_shader_parameter("strength"), .045), "Vignette is a mild 4.5% edge treatment")
	check(environment.vignette.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Vignette does not intercept controls")
	check(environment.vignette.get_parent().layer < current_scene.get_node("UI").layer, "HUD renders above vignette")
	inspect_art(current_scene.get_node("Stage1Layout"))
	check(art_count >= 142, "Expanded upper-ruins platform helpers are covered")
	var lantern := get_nodes_in_group("forest_checkpoints")[0]
	check(lantern.visual.material == null and lantern.visual.self_modulate == Color.WHITE, "Lantern artwork remains ungraded")
	var dormant: float = lantern.crimson_light.energy
	lantern.activated = true
	lantern._update_lighting()
	check(lantern.crimson_light.energy > dormant * 10 and lantern.core_light.energy > 0, "Active lantern retains its light pool and warm center")
	environment.far_background_brightness = .77
	environment.platform_brightness = .88
	environment.vignette_strength = 0
	await frames(2)
	check(is_equal_approx(far.material.get_shader_parameter("brightness"), .77), "Inspector background changes update at runtime")
	var art := current_scene.get_node("Stage1Layout").find_child("GothicPlatformArt", true, false)
	check(is_equal_approx(art.get_child(0).material.get_shader_parameter("top_brightness"), .88), "Inspector platform changes update at runtime")
	check(is_zero_approx(environment.vignette.material.get_shader_parameter("strength")), "Vignette can be disabled using the Inspector")
	environment.far_background_brightness = .85
	environment.platform_brightness = .94
	environment.vignette_strength = .045
	await frames(2)
	red.set_physics_process(false)
	red.position = Vector2(4300, 725)
	environment._update_background_mood(10)
	var background_color: Color = far.material.get_shader_parameter("shadow_tint")
	check(background_color.r < environment.selective_shadow_tint.r, "Cellar mood darkens only the background")
	check(red.visual.self_modulate == Color.WHITE and environment.ambient == null, "Cellar mood leaves Red undarkened")
	var projectile := CharacterBody2D.new()
	projectile.set_script(preload("res://scripts/crescent_projectile.gd"))
	projectile.position = Vector2(200, 100)
	current_scene.add_child(projectile)
	check(projectile.visual.material == null and projectile.visual.self_modulate == Color.WHITE, "Crescent projectile is excluded from background darkening")
	change_scene_to_file("res://scenes/stage2_boss.tscn")
	await frames(20)
	var boss_environment := current_scene.get_node("ForestEnvironment")
	check(not boss_environment.selective_lighting_enabled and boss_environment.ambient != null, "Stage 2 retains its previous lighting mode")
	check(boss_environment.get_node_or_null("ForestVignette") == null, "Stage 1 vignette does not leak into Stage 2")
	print("SELECTIVE LIGHTING: ", checks, " checks, ", failures, " failures")
	current_scene.queue_free()
	await frames(3)
	quit(0 if failures == 0 else 1)
