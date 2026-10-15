extends Node2D

@export var world_width := 4800.0
@export var ambient_color := Color(.80, .82, .94, 1)
@export var background_tint := Color(.90, .86, .92, 1)
@export_group("Stage 1 Selective Lighting")
@export var selective_lighting_enabled := false
@export_range(0, 1, .01) var far_background_brightness := .85
@export_range(0, 1, .01) var mid_background_brightness := .90
@export_range(0, 1, .01) var moon_castle_brightness := .80
@export_range(0, 1, .01) var foreground_brightness := .85
# Retain the previous background's night tone when removing CanvasModulate.
# Brightness sliders then provide the conservative 10-15% first-pass reduction.
@export var selective_shadow_tint := Color(.72, .71, .86, 1)
@export var regional_background_shading := true
@export_range(0, 1, .01) var platform_brightness := .94
@export_range(0, 1, .01) var platform_underside_brightness := .72
@export_range(0, 1, .01) var scenery_brightness := .82
@export_range(0, .15, .005) var vignette_strength := .045
const BACKGROUND_SHADER := preload("res://shaders/forest_background_grade.gdshader")
const VIGNETTE_SHADER := preload("res://shaders/forest_vignette.gdshader")
const GROUND_TOP := 500.0
# Small pools at the entrance, abandoned camp and chapel. Moon Lanterns
# provide the main lights along the journey instead of a lamp every few steps.
const LANTERN_X := [175.0, 2490.0, 3810.0]

var elapsed := 0.0
var motes: Array[Dictionary] = []
var checkpoint_posts: Array[float] = []
var ambient: CanvasModulate
var player: Node2D
var vignette: ColorRect
var lighting_settings: Array = []
var current_background_tint := Color(.72, .71, .86, 1)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42317
	var sky := Polygon2D.new()
	sky.name = "NightSkyBacking"
	sky.z_index = -100
	sky.polygon = PackedVector2Array([Vector2(-600, -800), Vector2(world_width + 600, -800), Vector2(world_width + 600, 1300), Vector2(-600, 1300)])
	sky.color = Color("10101f")
	add_child(sky)
	for index in range(roundi(38 * world_width / 4800.0)):
		motes.append({
			"position": Vector2(rng.randf_range(0.0, world_width), rng.randf_range(70.0, GROUND_TOP - 12.0)),
			"speed": rng.randf_range(5.0, 13.0),
			"phase": rng.randf_range(0.0, TAU),
		})
	if selective_lighting_enabled:
		# No CanvasModulate darkness in Stage 1: characters, effects and lanterns
		# retain their artwork colors and still receive the existing local lights.
		_add_vignette()
		call_deferred("_apply_selective_lighting")
	else:
		_add_ambient_tint()
		for path in ["FarParallax/MoonlitRidge", "MidParallax/RedwoodMist", "ForegroundParallax/ThornedCanopy"]:
			var layer := get_node_or_null(path) as Sprite2D
			if layer != null:
				layer.self_modulate = background_tint
	var glow_texture := _make_glow_texture()
	for x in LANTERN_X:
		if x < world_width:
			_add_lantern_light(Vector2(x, GROUND_TOP - 39.0), glow_texture)
	# The player is a later sibling in Main, so defer group lookup until the
	# complete scene tree has entered and all sibling groups are available.
	call_deferred("_add_player_rim_light", glow_texture)
	call_deferred("_refresh_checkpoint_posts")

func _refresh_checkpoint_posts() -> void:
	if not is_inside_tree():
		return
	for checkpoint in get_tree().get_nodes_in_group("forest_checkpoints"):
		var local: Vector2 = to_local(checkpoint.global_position)
		if absf(local.y - GROUND_TOP) < 4.0:
			checkpoint_posts.append(local.x)
	for x in LANTERN_X:
		if _overlaps_checkpoint(x):
			var light := get_node_or_null("LanternLight_%d" % int(x)) as PointLight2D
			if light != null:
				light.hide()

func _overlaps_checkpoint(x: float) -> bool:
	for checkpoint_x in checkpoint_posts:
		if absf(checkpoint_x - x) < 60.0:
			return true
	return false

func _process(delta: float) -> void:
	elapsed += delta
	if selective_lighting_enabled and lighting_settings != _lighting_settings():
		_apply_selective_lighting()
	if selective_lighting_enabled:
		_update_background_mood(delta)
	if is_instance_valid(player) and ambient != null:
		ambient.color = ambient.color.lerp(_ambient_at(player.global_position), 1.0 - exp(-delta * 1.8))
	for mote in motes:
		var mote_position: Vector2 = mote["position"]
		mote_position.y += float(mote["speed"]) * delta
		mote_position.x += sin(elapsed * 0.7 + float(mote["phase"])) * 4.0 * delta
		if mote_position.y > GROUND_TOP - 8.0:
			mote_position.y = 55.0
			mote_position.x = fposmod(mote_position.x + 271.0, world_width)
		mote["position"] = mote_position
	queue_redraw()

func _lighting_settings() -> Array:
	return [far_background_brightness, mid_background_brightness, moon_castle_brightness, foreground_brightness, selective_shadow_tint, regional_background_shading, platform_brightness, platform_underside_brightness, scenery_brightness, vignette_strength]

func _apply_selective_lighting() -> void:
	if not is_inside_tree():
		return
	lighting_settings = _lighting_settings()
	var entries := [
		["FarParallax/MoonlitRidge", far_background_brightness, true],
		["MidParallax/RedwoodMist", mid_background_brightness, false],
		["ForegroundParallax/ThornedCanopy", foreground_brightness, false],
	]
	for entry in entries:
		var layer := get_node_or_null(entry[0]) as Sprite2D
		if layer == null:
			continue
		var grade := layer.material as ShaderMaterial
		if grade == null:
			grade = ShaderMaterial.new()
			grade.shader = BACKGROUND_SHADER
			layer.material = grade
		grade.set_shader_parameter("brightness", entry[1])
		grade.set_shader_parameter("shadow_tint", selective_shadow_tint)
		grade.set_shader_parameter("moon_castle_brightness", moon_castle_brightness)
		grade.set_shader_parameter("soften_moon_castle", entry[2])
	var layout := get_parent().get_node_or_null("Stage1Layout")
	if layout == null:
		layout = get_parent().get_node_or_null("Stage2BossLayout")
	if layout != null:
		_shade_platforms(layout)
		var scenery := layout.get_node_or_null("HollowOakAndCellar") as CanvasItem
		if scenery != null:
			scenery.self_modulate = Color(scenery_brightness, scenery_brightness, scenery_brightness, 1)
		var environment_art := layout.get_node_or_null("Stage1EnvironmentArt")
		if environment_art == null:
			environment_art = layout.get_node_or_null("Stage2EnvironmentArt")
		if environment_art != null:
			environment_art.set_brightness(scenery_brightness)
	if vignette != null:
		(vignette.material as ShaderMaterial).set_shader_parameter("strength", vignette_strength)

func _update_background_mood(delta: float) -> void:
	var target := selective_shadow_tint
	if regional_background_shading and is_instance_valid(player):
		var mood := _ambient_at(player.global_position)
		target *= Color(mood.r / maxf(.01, ambient_color.r), mood.g / maxf(.01, ambient_color.g), mood.b / maxf(.01, ambient_color.b), 1)
	current_background_tint = current_background_tint.lerp(target, 1.0 - exp(-delta * 1.8))
	for path in ["FarParallax/MoonlitRidge", "MidParallax/RedwoodMist", "ForegroundParallax/ThornedCanopy"]:
		var layer := get_node_or_null(path) as Sprite2D
		if layer != null and layer.material is ShaderMaterial:
			(layer.material as ShaderMaterial).set_shader_parameter("shadow_tint", current_background_tint)

func _shade_platforms(node: Node) -> void:
	if node.has_method("set_lighting"):
		node.set_lighting(platform_brightness, platform_underside_brightness)
	for child in node.get_children():
		_shade_platforms(child)

func _add_vignette() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ForestVignette"
	canvas.layer = 0 # World fringe only; HUD/tutorial/interaction layers draw above.
	add_child(canvas)
	vignette = ColorRect.new()
	vignette.name = "SoftEdges"
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = VIGNETTE_SHADER
	material.set_shader_parameter("strength", vignette_strength)
	vignette.material = material
	canvas.add_child(vignette)

func _draw() -> void:
	# A few dim stars fill the high canopy view above the existing forest layers.
	if world_width > 4800.0:
		for index in range(64):
			var star_x := 4850.0 + fposmod(float(index) * 271.0, 2500.0)
			if world_width > 9600.0:
				star_x += 1600.0
			var star_y := -340.0 + fposmod(float(index) * 83.0, 230.0)
			draw_circle(Vector2(star_x, star_y), 0.8, Color(.68, .66, .82, .21))
	_draw_lantern_posts()
	_draw_gravestones()
	_draw_ground_growth()
	for index in range(motes.size()):
		var mote_position: Vector2 = motes[index]["position"]
		var pulse := 0.20 + sin(elapsed * 2.1 + float(motes[index]["phase"])) * 0.08
		var color := Color(1.0, 0.35, 0.19, pulse) if index % 3 == 0 else Color(0.93, 0.72, 0.48, pulse * 0.72)
		draw_circle(mote_position, 1.1 if index % 3 == 0 else 0.8, color)

func _draw_lantern_posts() -> void:
	var visual_kit := _has_stage1_environment_art()
	for x in LANTERN_X:
		if x >= world_width or _overlaps_checkpoint(x):
			continue
		var base := Vector2(x, GROUND_TOP)
		var lamp := base + Vector2(4.0, -39.0)
		var flicker := 0.86 + sin(elapsed * 8.0 + x) * 0.08
		# Muted layered glows give a soft falloff around each lantern.
		draw_circle(lamp, 31.0 * flicker, Color(1.0, 0.30, 0.12, 0.025))
		draw_circle(lamp, 18.0 * flicker, Color(1.0, 0.42, 0.17, 0.055))
		draw_circle(lamp, 7.0, Color(1.0, 0.67, 0.31, 0.18))
		if visual_kit:
			continue # v2 supplies the lamp/post artwork; these glows still apply.
		draw_line(base + Vector2(0, -2), base + Vector2(0, -38), Color("382b2b"), 3.0, true)
		draw_line(base + Vector2(-5, -33), base + Vector2(6, -38), Color("564044"), 2.0, true)
		draw_rect(Rect2(lamp.x - 4.0, lamp.y - 5.0, 8.0, 10.0), Color("755143"), true)
		draw_rect(Rect2(lamp.x - 2.0, lamp.y - 3.0, 4.0, 6.0), Color("ffba66"), true)

func _draw_gravestones() -> void:
	if _has_stage1_environment_art():
		return # Authored v2 burial clusters replace the scattered grey markers.
	for x in [1240.0, 1292.0, 2320.0, 2380.0, 2670.0, 2718.0, 4130.0, 4182.0, 4510.0, 4570.0]:
		var y := GROUND_TOP - (18.0 if int(x) % 2 == 0 else 14.0)
		var stone := PackedVector2Array([
			Vector2(x - 10.0, GROUND_TOP), Vector2(x - 9.0, y + 5.0),
			Vector2(x - 6.0, y), Vector2(x + 5.0, y),
			Vector2(x + 10.0, y + 6.0), Vector2(x + 10.0, GROUND_TOP),
		])
		draw_colored_polygon(stone, Color("393542"))
		draw_line(Vector2(x, y + 5.0), Vector2(x, y + 14.0), Color("766775"), 1.2, true)
		draw_line(Vector2(x - 3.0, y + 9.0), Vector2(x + 3.0, y + 9.0), Color("766775"), 1.2, true)

func _has_stage1_environment_art() -> bool:
	var layout := get_parent().get_node_or_null("Stage1Layout")
	if layout == null:
		layout = get_parent().get_node_or_null("Stage2BossLayout")
	return layout != null and bool(layout.get("environment_art_enabled"))

func _draw_ground_growth() -> void:
	for x in range(45, int(world_width), 115):
		if x >= 2750 and x <= 3220:
			continue
		var y := GROUND_TOP - 1.0
		var side := 1.0 if x % 2 == 0 else -1.0
		draw_line(Vector2(x, y), Vector2(x + 4.0 * side, y - 8.0), Color("52654e"), 2.0, true)
		draw_line(Vector2(x + 2.0, y), Vector2(x + 8.0, y - 5.0), Color("657154"), 1.5, true)
		if x % 4 == 1:
			draw_circle(Vector2(x + 11.0, y - 2.0), 1.5, Color("a23846"))

func _add_ambient_tint() -> void:
	ambient = CanvasModulate.new()
	ambient.name = "NightAmbient"
	ambient.color = ambient_color
	add_child(ambient)

func _ambient_at(where: Vector2) -> Color:
	if world_width < 10000.0:
		return ambient_color # Boss arena retains consistent combat visibility.
	var woodland := Color(.70, .72, .86, 1)
	var result := ambient_color.lerp(woodland, smoothstep(3000.0, 4100.0, where.x))
	# The optional cellar is darkest, with a gradual transition at its entrances.
	var cellar := smoothstep(3300.0, 3500.0, where.x) * (1.0 - smoothstep(5200.0, 5400.0, where.x)) * smoothstep(550.0, 680.0, where.y)
	result = result.lerp(Color(.56, .59, .74, 1), cellar)
	result = result.lerp(Color(.75, .77, .89, 1), smoothstep(8000.0, 8600.0, where.x))
	return result.lerp(Color(.83, .78, .88, 1), smoothstep(8900.0, 9700.0, where.x))

func _add_lantern_light(lantern_position: Vector2, glow_texture: Texture2D) -> void:
	var light := PointLight2D.new()
	light.name = "LanternLight_%d" % int(lantern_position.x)
	light.position = lantern_position
	light.texture = glow_texture
	light.texture_scale = 0.9
	light.color = Color(1.0, 0.46, 0.22, 1.0)
	light.energy = 0.45
	light.range_z_min = -2
	light.range_z_max = 3
	add_child(light)

func _add_player_rim_light(glow_texture: Texture2D) -> void:
	# A deferred callback can run after a scene transition has orphaned this node.
	if not is_inside_tree():
		return
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	player = scene_tree.get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var light := PointLight2D.new()
	light.name = "RedRimLight"
	light.position = Vector2(0.0, -12.0)
	light.texture = glow_texture
	light.texture_scale = 0.45
	light.color = Color(1.0, 0.30, 0.34, 1.0)
	light.energy = 0.28
	light.range_item_cull_mask = 2
	var visual := player.get_node_or_null("Visual") as CanvasItem
	if visual != null:
		visual.light_mask |= 2
	player.add_child(light)
	# Actor-only lights maintain silhouettes without lighting the entire floor.
	for enemy in scene_tree.get_nodes_in_group("enemies"):
		var enemy_visual := enemy.get_node_or_null("Visual") as CanvasItem
		if enemy_visual == null:
			continue	
		enemy_visual.light_mask |= 4
		var rim := PointLight2D.new()
		rim.name = "MoonlitRim"
		rim.texture = glow_texture
		rim.position = Vector2(0, -40 if enemy.is_in_group("boss") else -12)
		rim.texture_scale = 1.8 if enemy.is_in_group("boss") else .55
		rim.color = Color(.66, .68, 1, 1)
		rim.energy = .35
		rim.range_item_cull_mask = 4
		enemy.add_child(rim)

func _make_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.38, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.73, 0.42, 0.34),
		Color(1.0, 0.42, 0.20, 0.12),
		Color(1.0, 0.25, 0.10, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.gradient = gradient
	return texture
