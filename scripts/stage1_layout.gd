extends Node2D

const WOLF_SCENE: PackedScene = preload("res://scenes/common_wolf.tscn")
const TERRAIN_SCRIPT: Script = preload("res://scripts/terrain_visual.gd")
const SPIKE_SCENE: PackedScene = preload("res://scenes/spike_trap.tscn")
const MAP_WIDTH := 4800.0

# Each marker is [center_x, walk_surface_y, width, visual_depth, variation].
const PLATFORMS := [
	[315.0, 462.0, 190.0, 34.0, 1], [475.0, 424.0, 190.0, 36.0, 2], [640.0, 462.0, 190.0, 34.0, 3],
	[850.0, 445.0, 200.0, 34.0, 4], [1010.0, 407.0, 190.0, 36.0, 5], [1175.0, 445.0, 190.0, 34.0, 6],
	[1375.0, 462.0, 190.0, 36.0, 7], [1535.0, 424.0, 190.0, 34.0, 8], [1695.0, 386.0, 190.0, 36.0, 9],
	[1855.0, 348.0, 190.0, 36.0, 10], [2015.0, 386.0, 190.0, 34.0, 11], [2175.0, 424.0, 190.0, 36.0, 12],
	[2335.0, 462.0, 210.0, 36.0, 13], [2585.0, 455.0, 220.0, 38.0, 14],
	[2825.0, 462.0, 190.0, 34.0, 15], [2985.0, 424.0, 190.0, 36.0, 16], [3145.0, 386.0, 190.0, 36.0, 17],
	[3305.0, 348.0, 190.0, 34.0, 18], [3465.0, 310.0, 190.0, 36.0, 19], [3625.0, 348.0, 190.0, 34.0, 20],
	[3785.0, 386.0, 190.0, 36.0, 21], [3945.0, 424.0, 190.0, 34.0, 22], [4105.0, 462.0, 190.0, 38.0, 23],
	[4285.0, 435.0, 210.0, 38.0, 24], [4465.0, 462.0, 200.0, 36.0, 25], [4635.0, 425.0, 190.0, 38.0, 26],
	# Optional raised detours and secret shelves branch above the main routes.
	[720.0, 386.0, 150.0, 28.0, 27], [1245.0, 369.0, 155.0, 30.0, 28], [2240.0, 374.0, 155.0, 30.0, 29],
	[2700.0, 396.0, 155.0, 30.0, 30], [3210.0, 300.0, 155.0, 30.0, 31], [3860.0, 333.0, 155.0, 30.0, 32],
	[4385.0, 377.0, 155.0, 30.0, 33],
]

const WOLF_POSITIONS := [
	Vector2(560, 500), Vector2(820, 500), Vector2(940, 500),
	Vector2(1430, 500), Vector2(1600, 424), Vector2(1920, 500),
	Vector2(2310, 500),
	Vector2(2860, 500), Vector2(3075, 424), Vector2(3350, 500),
	Vector2(3560, 500), Vector2(3740, 500),
	Vector2(4120, 500), Vector2(4260, 500), Vector2(4350, 500),
]

func _ready() -> void:
	_add_ground(1375.0, 500.0, 2750.0, 40.0, 40)
	_add_ground(2990.0, 590.0, 470.0, 40.0, 41)
	_add_ground(4135.0, 500.0, 1330.0, 40.0, 42)
	_add_platform(3235.0, 555.0, 110.0, 32.0, 43)
	_add_platform(3300.0, 530.0, 110.0, 32.0, 44)
	_add_platform(3360.0, 500.0, 110.0, 32.0, 45)
	for platform in PLATFORMS:
		_add_platform(float(platform[0]), float(platform[1]), float(platform[2]), float(platform[3]), int(platform[4]))
	for spawn in WOLF_POSITIONS:
		_add_wolf(spawn)
	_add_alpha_wolf(Vector2(2510.0, 500.0))
	_add_spike(Vector2(2945.0, 590.0))
	_add_spike(Vector2(3065.0, 590.0))
	queue_redraw()

func _add_ground(center_x: float, surface_y: float, width: float, depth: float, variant: int) -> void:
	var body := StaticBody2D.new()
	body.name = "ForestFloor_%02d" % variant
	body.position = Vector2(center_x, surface_y + depth * 0.5)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, depth)
	collision.shape = shape
	body.add_child(collision)
	var visual := Node2D.new()
	visual.name = "MossAndStoneVisual"
	visual.set_script(TERRAIN_SCRIPT)
	visual.set("dimensions", Vector2(width, depth))
	visual.set("variant", variant)
	visual.set("surface_y", -depth * 0.5)
	body.add_child(visual)
	add_child(body)

func _add_platform(center_x: float, surface_y: float, width: float, depth: float, variant: int) -> void:
	var body := StaticBody2D.new()
	body.name = "RootedLedge_%02d" % variant
	body.position = Vector2(center_x, surface_y + 9.0)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 18.0)
	collision.shape = shape
	# Ledges are top-only: Red can jump up through them instead of hitting a wall.
	collision.one_way_collision = true
	collision.one_way_collision_margin = 8.0
	body.add_child(collision)
	var visual := Node2D.new()
	visual.name = "UnevenRockVisual"
	visual.set_script(TERRAIN_SCRIPT)
	visual.set("dimensions", Vector2(width, depth))
	visual.set("variant", variant)
	visual.set("surface_y", -9.0)
	body.add_child(visual)
	add_child(body)

func _add_wolf(spawn: Vector2) -> void:
	var wolf := WOLF_SCENE.instantiate() as CharacterBody2D
	wolf.position = spawn
	add_child(wolf)

func _add_alpha_wolf(spawn: Vector2) -> void:
	var wolf := WOLF_SCENE.instantiate() as CharacterBody2D
	wolf.name = "AlphaWolf"
	wolf.position = spawn
	wolf.set("maximum_health", 126)
	wolf.add_to_group("boss")
	var visual := wolf.get_node("Visual") as AnimatedSprite2D
	visual.scale = Vector2(1.65, 1.65)
	visual.modulate = Color(0.88, 0.68, 0.76, 1.0)
	add_child(wolf)

func _add_spike(spawn: Vector2) -> void:
	var spikes := SPIKE_SCENE.instantiate()
	spikes.position = spawn
	add_child(spikes)

func _draw() -> void:
	_draw_region_labels()
	_draw_entrance_sign()
	_draw_ruins()
	_draw_root_cave()
	_draw_corrupted_tree()
	_draw_witch_gate()
	_draw_secret_marker()

func _draw_region_labels() -> void:
	var label_color := Color(0.74, 0.67, 0.70, 0.78)
	draw_string(ThemeDB.fallback_font, Vector2(55, 300), "FOREST ENTRANCE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
	draw_string(ThemeDB.fallback_font, Vector2(820, 300), "LOWER FOREST", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
	draw_string(ThemeDB.fallback_font, Vector2(1480, 300), "DEEP FOREST", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
	draw_string(ThemeDB.fallback_font, Vector2(2260, 300), "FOREST RUINS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
	draw_string(ThemeDB.fallback_font, Vector2(2910, 300), "ROOT PASSAGE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
	draw_string(ThemeDB.fallback_font, Vector2(3370, 300), "UPPER FOREST", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
	draw_string(ThemeDB.fallback_font, Vector2(4040, 300), "CORRUPTED GROVE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
	draw_string(ThemeDB.fallback_font, Vector2(4500, 300), "WITCH'S GATE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)

func _draw_entrance_sign() -> void:
	draw_line(Vector2(112, 498), Vector2(112, 444), Color("47342e"), 5.0, true)
	draw_rect(Rect2(89, 446, 47, 18), Color("594035"), true)
	draw_line(Vector2(94, 451), Vector2(128, 451), Color("a58668"), 1.0, true)
	draw_line(Vector2(94, 458), Vector2(119, 458), Color("a58668"), 1.0, true)

func _draw_ruins() -> void:
	for x in [2220.0, 2330.0, 2650.0, 2760.0]:
		draw_rect(Rect2(x, 365, 23, 135), Color("302d39"), true)
		draw_rect(Rect2(x - 5, 360, 33, 10), Color("49414b"), true)
	draw_line(Vector2(2227, 365), Vector2(2280, 316), Color("393542"), 15.0, true)
	draw_line(Vector2(2280, 316), Vector2(2338, 365), Color("393542"), 15.0, true)
	draw_circle(Vector2(2280, 324), 4.0, Color("ff9b55", 0.85))
	for x in [2380.0, 2710.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 12, 500), Vector2(x - 11, 475), Vector2(x - 5, 466), Vector2(x + 8, 466), Vector2(x + 12, 477), Vector2(x + 12, 500)]), Color("45404a"))

func _draw_root_cave() -> void:
	draw_rect(Rect2(2750, 500, 470, 90), Color("17141e"), true)
	draw_line(Vector2(2825, 500), Vector2(2836, 438), Color("302729"), 12.0, true)
	draw_line(Vector2(2836, 438), Vector2(2880, 407), Color("302729"), 10.0, true)
	draw_line(Vector2(2880, 407), Vector2(2910, 450), Color("302729"), 8.0, true)
	draw_line(Vector2(3120, 500), Vector2(3100, 442), Color("302729"), 10.0, true)
	draw_line(Vector2(3100, 442), Vector2(3062, 410), Color("302729"), 8.0, true)
	draw_line(Vector2(3222, 500), Vector2(3200, 430), Color("302729"), 12.0, true)
	draw_line(Vector2(3200, 430), Vector2(3160, 398), Color("302729"), 9.0, true)
	draw_circle(Vector2(2887, 550), 2.5, Color("a44668", 0.8))
	draw_circle(Vector2(3132, 570), 2.0, Color("a44668", 0.65))

func _draw_corrupted_tree() -> void:
	var trunk := Color("201d27")
	draw_line(Vector2(4185, 500), Vector2(4172, 280), trunk, 28.0, true)
	draw_line(Vector2(4172, 345), Vector2(4055, 265), trunk, 14.0, true)
	draw_line(Vector2(4178, 330), Vector2(4300, 224), trunk, 17.0, true)
	draw_line(Vector2(4176, 400), Vector2(4075, 430), Color("4f2638"), 5.0, true)
	draw_line(Vector2(4176, 382), Vector2(4280, 320), Color("7b2d43"), 4.0, true)
	for point in [Vector2(4170, 320), Vector2(4280, 320), Vector2(4075, 430)]:
		draw_circle(point, 5.0, Color("b54650", 0.66))

func _draw_witch_gate() -> void:
	draw_rect(Rect2(4544, 334, 38, 166), Color("33303a"), true)
	draw_rect(Rect2(4738, 334, 38, 166), Color("33303a"), true)
	draw_rect(Rect2(4535, 324, 250, 22), Color("49424c"), true)
	draw_line(Vector2(4563, 335), Vector2(4660, 260), Color("393541"), 16.0, true)
	draw_line(Vector2(4660, 260), Vector2(4760, 335), Color("393541"), 16.0, true)
	draw_rect(Rect2(4600, 360, 120, 140), Color("17131c", 0.94), true)
	draw_line(Vector2(4660, 374), Vector2(4660, 470), Color("8a313f", 0.62), 3.0, true)
	draw_circle(Vector2(4660, 372), 7.0, Color("b8484f", 0.52))

func _draw_secret_marker() -> void:
	draw_circle(Vector2(1245, 344), 3.0, Color("ffcf8a", 0.75))
	draw_circle(Vector2(1245, 344), 8.0, Color(1.0, 0.57, 0.25, 0.09))
