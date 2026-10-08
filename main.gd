extends Node2D

const LEVEL_WIDTH := 3400.0
const FLOOR_Y := 760.0
const PLAYER_SCRIPT := preload("res://player.gd")

var player: CharacterBody2D
var platforms: Array[Rect2] = []
var wraiths: Array[Vector2] = [Vector2(760, 680), Vector2(1430, 510), Vector2(2120, 570), Vector2(2700, 670)]
var bell_rung := false
var message_label: Label
var objective_label: Label
var time := 0.0

func _ready() -> void:
	_build_level()
	player = CharacterBody2D.new()
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector2(120, FLOOR_Y - 20)
	player.attack_requested.connect(_on_player_attack)
	add_child(player)
	_build_hud()
	_refresh_objective()
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	queue_redraw()
	if not bell_rung and player.global_position.distance_to(Vector2(3160, FLOOR_Y - 105)) < 100 and Input.is_action_just_pressed("interact"):
		bell_rung = true
		message_label.text = "The chapel bell rings. The silence breaks."
		_refresh_objective()
		get_tree().create_timer(3.0).timeout.connect(func(): message_label.text = "" if is_instance_valid(message_label) else "")

func _build_level() -> void:
	# Long stone floor and raised platforms form a small first playable route.
	_add_platform(Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180))
	platforms.append(Rect2(400, 620, 270, 28))
	platforms.append(Rect2(820, 520, 230, 28))
	platforms.append(Rect2(1190, 625, 250, 28))
	platforms.append(Rect2(1580, 500, 250, 28))
	platforms.append(Rect2(1980, 600, 250, 28))
	platforms.append(Rect2(2350, 475, 250, 28))
	platforms.append(Rect2(2740, 600, 240, 28))
	for rect in platforms:
		_add_platform(rect)
	# Invisible level boundaries.
	_add_platform(Rect2(-60, 0, 60, 1000))
	_add_platform(Rect2(LEVEL_WIDTH, 0, 60, 1000))

func _add_platform(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = rect.position + rect.size * 0.5
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 18)
	panel.custom_minimum_size = Vector2(380, 82)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.055, 0.88)
	style.border_color = Color("80634f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "THE SILENT KEEP"
	title.add_theme_color_override("font_color", Color("e9c88f"))
	title.add_theme_font_size_override("font_size", 20)
	stack.add_child(title)
	objective_label = Label.new()
	objective_label.add_theme_color_override("font_color", Color("ddd5d1"))
	objective_label.add_theme_font_size_override("font_size", 14)
	stack.add_child(objective_label)
	var controls := Label.new()
	controls.text = "A/D or arrows move   •   Space jump   •   Shift dash   •   J attack   •   E ring bell"
	controls.position = Vector2(22, 111)
	controls.add_theme_color_override("font_color", Color(0.87, 0.83, 0.79, 0.9))
	controls.add_theme_font_size_override("font_size", 13)
	layer.add_child(controls)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.anchor_left = 0.5
	message_label.anchor_right = 0.5
	message_label.position = Vector2(-280, 42)
	message_label.custom_minimum_size = Vector2(560, 34)
	message_label.add_theme_color_override("font_color", Color("ffe1a5"))
	message_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(message_label)

func _refresh_objective() -> void:
	if is_instance_valid(objective_label):
		objective_label.text = "Goal: Follow the ruined halls to the chapel bell." if not bell_rung else "The bell has rung. Explore the keep."

func _on_player_attack() -> void:
	for i in range(wraiths.size() - 1, -1, -1):
		var enemy := wraiths[i]
		if abs(enemy.x - player.global_position.x) < 115 and abs(enemy.y - player.global_position.y) < 90 and (enemy.x - player.global_position.x) * player.facing.x > -20:
			wraiths.remove_at(i)
			message_label.text = "The wraith dissolves into pale ash."
			get_tree().create_timer(1.8).timeout.connect(func(): message_label.text = "" if is_instance_valid(message_label) else "")
			return

func _draw() -> void:
	_draw_backdrop()
	_draw_architecture()
	_draw_platforms()
	_draw_wraiths()
	_draw_bell()

func _draw_backdrop() -> void:
	draw_rect(Rect2(0, 0, LEVEL_WIDTH, 950), Color("11131d"), true)
	# Moon and layered distant hills.
	draw_circle(Vector2(2860, 170), 82, Color(0.76, 0.72, 0.70, 0.12))
	draw_circle(Vector2(2860, 170), 59, Color("c4b9a9"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 510), Vector2(400, 300), Vector2(780, 520), Vector2(1200, 340), Vector2(1640, 520), Vector2(2140, 330), Vector2(2580, 520), Vector2(3000, 290), Vector2(3400, 480), Vector2(3400, 820), Vector2(0, 820)]), Color("1a1d29"))
	# Remote castle towers.
	for x in [160, 650, 1110, 1770, 2260, 3050, 3290]:
		var height := 230 + int(fposmod(float(x * 7), 180.0))
		_draw_tower_silhouette(float(x), 630.0 - height, float(height), Color("171923"))
	# Sparse stars.
	for i in range(55):
		var sx := fposmod(float(i * 197 + 34), LEVEL_WIDTH)
		var sy := 30.0 + fposmod(float(i * 83), 290.0)
		draw_circle(Vector2(sx, sy), 1.2 + float(i % 3) * 0.4, Color(0.85, 0.82, 0.76, 0.55))

func _draw_tower_silhouette(x: float, top: float, height: float, color: Color) -> void:
	var width := height * 0.24
	draw_rect(Rect2(x - width * 0.5, top + width * 0.55, width, height - width * 0.55), color, true)
	draw_colored_polygon(PackedVector2Array([Vector2(x - width * 0.72, top + width * 0.58), Vector2(x, top), Vector2(x + width * 0.72, top + width * 0.58)]), color)
	draw_rect(Rect2(x - width * 0.08, top + height * 0.55, width * 0.16, height * 0.2), Color("333044"), true)

func _draw_architecture() -> void:
	# Foreground keeps and arches frame the route without blocking it.
	for x in [300.0, 1080.0, 1880.0, 2580.0, 3260.0]:
		var color := Color("272631")
		draw_rect(Rect2(x, 275, 42, 485), color, true)
		draw_rect(Rect2(x + 340, 275, 42, 485), color, true)
		draw_rect(Rect2(x - 20, 255, 382, 28), Color("49434a"), true)
		for bx in [x + 22, x + 96, x + 170, x + 244, x + 318]:
			draw_rect(Rect2(bx, 242, 24, 20), Color("49434a"), true)
		# Narrow stained-glass slit windows.
		draw_rect(Rect2(x + 58, 385, 27, 118), Color("171720"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 58, 407), Vector2(x + 71.5, 380), Vector2(x + 85, 407), Vector2(x + 85, 503), Vector2(x + 58, 503)]), Color("673f62"))
		draw_line(Vector2(x + 71, 390), Vector2(x + 71, 501), Color("bb8b9d"), 2)
	# Torch glows and iron brackets.
	for x in [355.0, 720.0, 1130.0, 1490.0, 1900.0, 2290.0, 2670.0, 3100.0]:
		var flicker := 0.9 + sin(time * 7.0 + x) * 0.1
		draw_circle(Vector2(x, 562), 66 * flicker, Color(0.97, 0.42, 0.18, 0.045))
		draw_line(Vector2(x, 575), Vector2(x, 542), Color("78685d"), 5)
		draw_circle(Vector2(x, 539), 7 * flicker, Color("ffbd65"))
		draw_circle(Vector2(x, 536), 3 * flicker, Color("fff0bd"))

func _draw_platforms() -> void:
	# Continuous floor plus floating ledges.
	_draw_stone_platform(Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180))
	for rect in platforms:
		_draw_stone_platform(rect)
	# Cracks and scattered pale flowers along the floor.
	for x in range(70, int(LEVEL_WIDTH), 180):
		draw_line(Vector2(x, FLOOR_Y + 12), Vector2(x + 15, FLOOR_Y + 30), Color("111219"), 2)
		for j in range(3):
			draw_line(Vector2(x + 38 + j * 5, FLOOR_Y), Vector2(x + 34 + j * 8, FLOOR_Y - 10 - j * 2), Color("667169"), 2)

func _draw_stone_platform(rect: Rect2) -> void:
	draw_rect(rect, Color("28262d"), true)
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 9), Color("71635e"), true)
	for x in range(int(rect.position.x + 20), int(rect.end.x), 55):
		draw_line(Vector2(x, rect.position.y + 12), Vector2(x - 9, rect.end.y - 3), Color("17171d"), 2)
		draw_line(Vector2(x + 3, rect.position.y + 13), Vector2(x + 32, rect.position.y + 13), Color("3a363d"), 1)

func _draw_wraiths() -> void:
	for i in range(wraiths.size()):
		var p := wraiths[i] + Vector2(0, sin(time * 2.4 + float(i)) * 7.0)
		draw_circle(p, 37, Color(0.53, 0.72, 0.88, 0.09))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-19, 15), p + Vector2(-18, -11), p + Vector2(-10, -25), p + Vector2(0, -30), p + Vector2(12, -23), p + Vector2(19, -8), p + Vector2(16, 13), p + Vector2(8, 23), p + Vector2(0, 13), p + Vector2(-8, 23)]), Color("75899a"))
		draw_circle(p + Vector2(-7, -7), 3, Color("dce7e3"))
		draw_circle(p + Vector2(7, -7), 3, Color("dce7e3"))

func _draw_bell() -> void:
	var p := Vector2(3160, FLOOR_Y - 105)
	draw_rect(Rect2(3070, FLOOR_Y - 30, 180, 30), Color("393039"), true)
	draw_rect(Rect2(3110, FLOOR_Y - 155, 100, 125), Color("322a34"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(3092, FLOOR_Y - 155), Vector2(3160, FLOOR_Y - 225), Vector2(3228, FLOOR_Y - 155)]), Color("51404a"))
	var glow := 0.8 + sin(time * 3.0) * 0.2
	draw_circle(p, 55 * glow, Color(0.95, 0.74, 0.43, 0.11))
	draw_circle(p + Vector2(0, -6), 13, Color("edcd92"))
	draw_arc(p + Vector2(0, -12), 13, PI, TAU, 22, Color("fff0bb"), 4)
	draw_line(p + Vector2(-11, -5), p + Vector2(11, -5), Color("fff0bb"), 3)
