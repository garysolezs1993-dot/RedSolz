extends Node2D

const WOLF_BOSS_SCENE: PackedScene = preload("res://scenes/cursed_wolf_boss.tscn")
const TERRAIN_SCRIPT: Script = preload("res://scripts/terrain_visual.gd")
const PLATFORM_ART := preload("res://scripts/forest_platform_art.gd")
const MAP_WIDTH := 2800.0
const ARENA_FLOOR_Y := 500.0
# Layer 5 also identifies the solid arena floor for the boss's terrain mask.
const BOSS_FLOOR_LAYER := 1 << 4
@export var platform_art_enabled := true
@export var environment_art_enabled := true
@export var attack_cues_enabled := true
@export var region_labels_visible := false
var player: CharacterBody2D

# A connected forest clearing: the main floor stays readable while these
# broad ledges give Red a few safe routes above the boss's ground attacks.
const PLATFORMS := [
	[390.0, 438.0, 210.0, 36.0, 51],
	[690.0, 382.0, 190.0, 34.0, 52],
	[1010.0, 434.0, 220.0, 36.0, 53],
	[1350.0, 378.0, 210.0, 34.0, 54],
	[1660.0, 430.0, 200.0, 36.0, 55],
	[2050.0, 382.0, 210.0, 34.0, 56],
	[2410.0, 438.0, 220.0, 36.0, 57],
]

func _ready() -> void:
	_add_world_safety()
	_add_platform(1400.0, ARENA_FLOOR_Y, MAP_WIDTH, 44.0, 50, false)
	for platform in PLATFORMS:
		_add_platform(float(platform[0]), float(platform[1]), float(platform[2]), float(platform[3]), int(platform[4]))
	_add_cursed_wolf(Vector2(1860.0, 500.0))
	if environment_art_enabled:
		var art := Node2D.new()
		art.set_script(preload("res://scripts/stage2_environment_art.gd"))
		add_child(art)
	# Run the fallback after Red's movement, including dash and dive branches.
	process_physics_priority = 100
	queue_redraw()

func _add_world_safety() -> void:
	_add_platform(MAP_WIDTH * 0.5, 590.0, MAP_WIDTH + 400.0, 40.0, 58, false)
	_add_collision_box("LeftMapBoundary", Vector2(-36.0, 180.0), Vector2(40.0, 1000.0))
	_add_collision_box("RightMapBoundary", Vector2(MAP_WIDTH + 36.0, 180.0), Vector2(40.0, 1000.0))

func _add_collision_box(node_name: String, box_position: Vector2, box_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = box_position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_platform(center_x: float, surface_y: float, width: float, depth: float, variant: int, drop_through: bool = true) -> void:
	var body := StaticBody2D.new()
	# Red recognizes RootedLedge_* as droppable. Ground must not use that name.
	body.name = ("RootedLedge_%02d" if drop_through else "ArenaGround_%02d") % variant
	body.collision_layer = (1 | BOSS_FLOOR_LAYER) if variant == 50 else 1
	body.collision_mask = 0
	body.position = Vector2(center_x, surface_y + 9.0)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var collision_depth := 18.0 if drop_through else 80.0
	shape.size = Vector2(width, collision_depth)
	collision.position.y = collision_depth * .5 - 9.0
	collision.one_way_collision = drop_through
	collision.one_way_collision_margin = 8.0
	collision.shape = shape
	body.add_child(collision)
	var visual := Node2D.new()
	visual.name = "UnevenRockVisual"
	visual.set_script(TERRAIN_SCRIPT)
	visual.set("dimensions", Vector2(width, depth))
	visual.set("variant", variant)
	visual.set("surface_y", -9.0)
	body.add_child(visual)
	if platform_art_enabled:
		visual.hide()
		var art := Node2D.new()
		art.name = "GothicPlatformArt"
		art.set_script(PLATFORM_ART)
		art.set("dimensions", Vector2(width, depth))
		art.set("surface_y", -9.0)
		art.set("variant", variant)
		art.set("area_style", "cellar" if variant == 58 else ("gate" if center_x < 750 and variant != 50 else "heartwood"))
		# Thin pieces keep the low combat ledges clear of the main floor below.
		art.set("compact_surface", variant != 50)
		body.add_child(art)
	add_child(body)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(player) or player.get("dead") == true:
		return
	var foot_offset := 15.0
	var body_shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null and body_shape.shape is RectangleShape2D:
		foot_offset = body_shape.position.y + (body_shape.shape as RectangleShape2D).size.y * .5
	var bounded_x := clampf(player.global_position.x, 16.0, MAP_WIDTH - 16.0)
	var below_floor := player.global_position.y + foot_offset > ARENA_FLOOR_Y + 40.0
	if below_floor:
		# Last-resort rescue, without changing health or resetting boss progress.
		player.call("_cancel_action")
		var dropped := player.get("dropped_platform") as CollisionObject2D
		if is_instance_valid(dropped):
			player.remove_collision_exception_with(dropped)
		player.set("dropped_platform", null)
		player.set("drop_through_timer", 0.0)
		player.global_position = Vector2(bounded_x, ARENA_FLOOR_Y - foot_offset - 1.0)
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.reset_smoothing()
	elif not is_equal_approx(bounded_x, player.global_position.x):
		player.global_position.x = bounded_x
		player.velocity.x = 0.0
		player.reset_physics_interpolation()

func _add_cursed_wolf(spawn: Vector2) -> void:
	var wolf := WOLF_BOSS_SCENE.instantiate() as CharacterBody2D
	wolf.name = "CursedWolfBoss"
	wolf.position = spawn
	wolf.collision_mask |= BOSS_FLOOR_LAYER
	wolf.set("arena_safety_enabled", true)
	wolf.set("arena_floor_y", ARENA_FLOOR_Y)
	wolf.set("arena_limits_x", Vector2(28, MAP_WIDTH - 28))
	add_child(wolf)
	if attack_cues_enabled:
		var cues := Node2D.new()
		cues.name = "AttackCues"
		cues.set_script(preload("res://scripts/boss_attack_cues.gd"))
		wolf.add_child(cues)

func _draw() -> void:
	var label_color := Color(0.78, 0.68, 0.73, 0.9)
	if region_labels_visible:
		draw_string(ThemeDB.fallback_font, Vector2(70.0, 300.0), "THE BLOOD MOON CLEARING", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, label_color)
		draw_string(ThemeDB.fallback_font, Vector2(1510.0, 300.0), "CURSED WOLF DEN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, label_color)
	if environment_art_enabled:
		return
	_draw_entrance_arch()
	_draw_crimson_roots()
	_draw_lanterns()

func _draw_entrance_arch() -> void:
	for x in [120.0, 210.0]:
		draw_rect(Rect2(x, 388.0, 18.0, 112.0), Color("302a35"), true)
		draw_rect(Rect2(x - 5.0, 382.0, 28.0, 10.0), Color("514450"), true)
	draw_line(Vector2(125.0, 390.0), Vector2(174.0, 344.0), Color("403744"), 12.0, true)
	draw_line(Vector2(174.0, 344.0), Vector2(222.0, 390.0), Color("403744"), 12.0, true)

func _draw_crimson_roots() -> void:
	var root_color := Color("302630")
	draw_line(Vector2(1750.0, 500.0), Vector2(1712.0, 340.0), root_color, 18.0, true)
	draw_line(Vector2(1712.0, 340.0), Vector2(1615.0, 282.0), root_color, 10.0, true)
	draw_line(Vector2(1732.0, 420.0), Vector2(1830.0, 335.0), Color("582a3b"), 8.0, true)
	draw_line(Vector2(1830.0, 335.0), Vector2(1940.0, 280.0), Color("713143"), 5.0, true)
	draw_line(Vector2(2115.0, 500.0), Vector2(2150.0, 360.0), root_color, 16.0, true)
	draw_line(Vector2(2150.0, 360.0), Vector2(2260.0, 315.0), Color("542938"), 7.0, true)
	for point in [Vector2(1830.0, 335.0), Vector2(1940.0, 280.0), Vector2(2260.0, 315.0)]:
		draw_circle(point, 5.0, Color("b54650", 0.55))

func _draw_lanterns() -> void:
	for x in [310.0, 1120.0, 1590.0, 2500.0]:
		draw_line(Vector2(x, 500.0), Vector2(x, 458.0), Color("382b2b"), 3.0, true)
		draw_rect(Rect2(x - 4.0, 453.0, 8.0, 10.0), Color("ffba66"), true)
		draw_circle(Vector2(x, 458.0), 14.0, Color(1.0, 0.4, 0.16, 0.11))
