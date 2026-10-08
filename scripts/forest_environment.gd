extends Node2D

const WORLD_WIDTH := 4800.0
const GROUND_TOP := 500.0
const LANTERN_X := [175.0, 610.0, 1090.0, 1580.0, 2190.0, 2710.0, 3210.0, 3730.0, 4210.0, 4660.0]

var elapsed := 0.0
var motes: Array[Dictionary] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42317
	for index in range(38):
		motes.append({
			"position": Vector2(rng.randf_range(0.0, WORLD_WIDTH), rng.randf_range(70.0, GROUND_TOP - 12.0)),
			"speed": rng.randf_range(5.0, 13.0),
			"phase": rng.randf_range(0.0, TAU),
		})
	_add_ambient_tint()
	var glow_texture := _make_glow_texture()
	for x in LANTERN_X:
		_add_lantern_light(Vector2(x, GROUND_TOP - 39.0), glow_texture)
	# The player is a later sibling in Main, so defer group lookup until the
	# complete scene tree has entered and all sibling groups are available.
	call_deferred("_add_player_rim_light", glow_texture)

func _process(delta: float) -> void:
	elapsed += delta
	for mote in motes:
		var mote_position: Vector2 = mote["position"]
		mote_position.y += float(mote["speed"]) * delta
		mote_position.x += sin(elapsed * 0.7 + float(mote["phase"])) * 4.0 * delta
		if mote_position.y > GROUND_TOP - 8.0:
			mote_position.y = 55.0
			mote_position.x = fposmod(mote_position.x + 271.0, WORLD_WIDTH)
		mote["position"] = mote_position
	queue_redraw()

func _draw() -> void:
	_draw_lantern_posts()
	_draw_gravestones()
	_draw_ground_growth()
	for index in range(motes.size()):
		var mote_position: Vector2 = motes[index]["position"]
		var pulse := 0.45 + sin(elapsed * 2.1 + float(motes[index]["phase"])) * 0.2
		var color := Color(1.0, 0.35, 0.19, pulse) if index % 3 == 0 else Color(0.93, 0.72, 0.48, pulse * 0.72)
		draw_circle(mote_position, 1.1 if index % 3 == 0 else 0.8, color)

func _draw_lantern_posts() -> void:
	for x in LANTERN_X:
		var base := Vector2(x, GROUND_TOP)
		var lamp := base + Vector2(4.0, -39.0)
		var flicker := 0.86 + sin(elapsed * 8.0 + x) * 0.08
		# Muted layered glows give a soft falloff around each lantern.
		draw_circle(lamp, 31.0 * flicker, Color(1.0, 0.30, 0.12, 0.025))
		draw_circle(lamp, 18.0 * flicker, Color(1.0, 0.42, 0.17, 0.055))
		draw_circle(lamp, 7.0, Color(1.0, 0.67, 0.31, 0.18))
		draw_line(base + Vector2(0, -2), base + Vector2(0, -38), Color("382b2b"), 3.0, true)
		draw_line(base + Vector2(-5, -33), base + Vector2(6, -38), Color("564044"), 2.0, true)
		draw_rect(Rect2(lamp.x - 4.0, lamp.y - 5.0, 8.0, 10.0), Color("755143"), true)
		draw_rect(Rect2(lamp.x - 2.0, lamp.y - 3.0, 4.0, 6.0), Color("ffba66"), true)

func _draw_gravestones() -> void:
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

func _draw_ground_growth() -> void:
	for x in range(45, int(WORLD_WIDTH), 115):
		if x >= 2750 and x <= 3220:
			continue
		var y := GROUND_TOP - 1.0
		var side := 1.0 if x % 2 == 0 else -1.0
		draw_line(Vector2(x, y), Vector2(x + 4.0 * side, y - 8.0), Color("52654e"), 2.0, true)
		draw_line(Vector2(x + 2.0, y), Vector2(x + 8.0, y - 5.0), Color("657154"), 1.5, true)
		if x % 4 == 1:
			draw_circle(Vector2(x + 11.0, y - 2.0), 1.5, Color("a23846"))

func _add_ambient_tint() -> void:
	var tint := CanvasModulate.new()
	tint.name = "NightAmbient"
	tint.color = Color(0.88, 0.89, 1.0, 1.0)
	add_child(tint)

func _add_lantern_light(lantern_position: Vector2, glow_texture: Texture2D) -> void:
	var light := PointLight2D.new()
	light.name = "LanternLight_%d" % int(lantern_position.x)
	light.position = lantern_position
	light.texture = glow_texture
	light.texture_scale = 0.9
	light.color = Color(1.0, 0.46, 0.22, 1.0)
	light.energy = 0.45
	add_child(light)

func _add_player_rim_light(glow_texture: Texture2D) -> void:
	# A deferred callback can run after a scene transition has orphaned this node.
	if not is_inside_tree():
		return
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	var player := scene_tree.get_first_node_in_group("player")
	if player == null:
		return
	var light := PointLight2D.new()
	light.name = "RedRimLight"
	light.position = Vector2(0.0, -12.0)
	light.texture = glow_texture
	light.texture_scale = 0.45
	light.color = Color(1.0, 0.30, 0.34, 1.0)
	light.energy = 0.28
	player.add_child(light)

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
