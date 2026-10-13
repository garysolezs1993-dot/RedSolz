extends Control

# Temporary storyboard shapes only; final illustrated shots plug into textures.
enum Shot { LILY, RECOGNITION, MEMORY }
var shot := Shot.LILY:
	set(value):
		shot = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _flower(center: Vector2, scale_factor: float) -> void:
	for index in range(6):
		var angle := float(index) * TAU / 6
		var petal := PackedVector2Array()
		for point in [Vector2(0, 2), Vector2(-9, -17), Vector2(0, -35), Vector2(9, -17)]:
			petal.append(center + point.rotated(angle) * scale_factor)
		draw_colored_polygon(petal, Color("ddd5c7"))
	draw_circle(center, 5 * scale_factor, Color("9f7960"))

func _person(center: Vector2, hooded: bool, warm: bool) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-40, 35), center + Vector2(-66, 145), center + Vector2(68, 145), center + Vector2(35, 30)]), Color("713644"))
	if hooded:
		draw_circle(center, 63, Color("8c3a47"))
	else:
		draw_circle(center + Vector2(0, -12), 52, Color("382c31"))
	draw_circle(center + Vector2(0, 6), 45, Color("c4a195") if warm else Color("afa3ad"))
	if hooded:
		draw_colored_polygon(PackedVector2Array([center + Vector2(-48, -15), center + Vector2(15, -38), center + Vector2(46, -12), center + Vector2(22, 5), center + Vector2(-25, -1)]), Color("d3c7ce"))
	draw_circle(center + Vector2(-15, 10), 4, Color("6d3344"))
	draw_circle(center + Vector2(15, 10), 4, Color("6d3344"))

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(960, 540))
	var warm := shot == Shot.MEMORY
	draw_rect(Rect2(0, 0, 960, 540), Color("57423c") if warm else Color("181620"))
	for index in range(7):
		var x := float(index * 170 - 30)
		draw_line(Vector2(x, 540), Vector2(x + 40, 0), Color("493936") if warm else Color("0d1018"), 34)
	match shot:
		Shot.LILY:
			draw_colored_polygon(PackedVector2Array([Vector2(190, 420), Vector2(250, 105), Vector2(700, 90), Vector2(815, 430)]), Color("272530"))
			for index in range(9):
				draw_line(Vector2(240 + index * 55, 250), Vector2(215 + index * 60, 415), Color("333039"), 11)
			draw_colored_polygon(PackedVector2Array([Vector2(255, 195), Vector2(710, 170), Vector2(755, 252), Vector2(460, 281), Vector2(393, 409), Vector2(312, 381), Vector2(375, 266), Vector2(270, 264)]), Color("8a3544"))
			_flower(Vector2(575, 224), 1.45)
		Shot.RECOGNITION:
			_person(Vector2(476, 255), true, false)
			_flower(Vector2(425, 202), .5)
		Shot.MEMORY:
			_person(Vector2(360, 250), true, true)
			_person(Vector2(605, 250), false, true)
			draw_line(Vector2(390, 330), Vector2(582, 310), Color("b79790"), 12)
			_flower(Vector2(595, 326), .62)
	draw_set_transform(Vector2.ZERO)
