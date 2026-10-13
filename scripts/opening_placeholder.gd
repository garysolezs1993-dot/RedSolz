extends Control

# Deliberately simple storyboard silhouettes. Replace with panel artwork later.
var panel_kind := 0:
	set(value):
		panel_kind = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var unit := size / Vector2(960, 540)
	draw_set_transform(Vector2.ZERO, 0, unit)
	draw_rect(Rect2(0, 0, 960, 540), Color("16141e"))
	for band in range(12):
		draw_rect(Rect2(0, band * 45, 960, 45), Color(.08 + band * .002, .055 + band * .003, .09 + band * .006))
	draw_circle(Vector2(740, 145), 76 if panel_kind == 0 else 50, Color("77343e"))
	draw_circle(Vector2(740, 145), 69 if panel_kind == 0 else 44, Color("a74c52"))
	for index in range(9):
		var x := float(index * 135 - 40)
		var y := 275.0 + sin(index * 1.8) * 28
		draw_colored_polygon(PackedVector2Array([Vector2(x - 120, 420), Vector2(x + 35, y), Vector2(x + 170, 420)]), Color("242330"))
	if panel_kind == 0:
		for tower in [Vector2(585, 280), Vector2(650, 210), Vector2(730, 260), Vector2(790, 295)]:
			draw_rect(Rect2(tower, Vector2(42, 390 - tower.y)), Color("090a10"))
			draw_colored_polygon(PackedVector2Array([tower + Vector2(-7, 0), tower + Vector2(21, -65), tower + Vector2(49, 0)]), Color("090a10"))
			draw_rect(Rect2(tower + Vector2(18, 22), Vector2(6, 12)), Color("a94350"))
		draw_rect(Rect2(600, 325, 200, 80), Color("090a10"))
	for index in range(10):
		var x := float(index * 113 - 30)
		var height := 230.0 + sin(index * 2.3) * 65
		if panel_kind == 0 and x > 480 and x < 825:
			continue
		draw_line(Vector2(x, 410), Vector2(x + 9, 410 - height), Color("0a0c13"), 14)
		draw_line(Vector2(x + 5, 280), Vector2(x - 42, 215), Color("0a0c13"), 8)
		draw_line(Vector2(x + 7, 240), Vector2(x + 48, 188), Color("0a0c13"), 7)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 410), Vector2(220, 393), Vector2(490, 420), Vector2(750, 394), Vector2(960, 410), Vector2(960, 540), Vector2(0, 540)]), Color("0b0c12"))
	if panel_kind in [1, 2, 3]:
		var red := Vector2(315, 383)
		draw_circle(red + Vector2(0, -24), 12, Color("aa4150"))
		draw_colored_polygon(PackedVector2Array([red + Vector2(-8, -20), red + Vector2(-23, 27), red + Vector2(24, 27), red + Vector2(8, -20)]), Color("6a2536"))
		draw_line(red + Vector2(-7, 24), red + Vector2(-8, 37), Color("24202b"), 6)
		draw_line(red + Vector2(7, 24), red + Vector2(10, 37), Color("24202b"), 6)
	if panel_kind == 2:
		# A dropped cloth and oversized paw marks, rather than final story art.
		draw_colored_polygon(PackedVector2Array([Vector2(415, 397), Vector2(430, 392), Vector2(449, 406), Vector2(416, 410)]), Color("aaa1ab"))
		for center in [Vector2(495, 409), Vector2(558, 388), Vector2(623, 412)]:
			draw_circle(center, 8, Color("534857"))
			for toe in range(3):
				draw_circle(center + Vector2((toe - 1) * 7, -11), 3, Color("534857"))
	if panel_kind == 3:
		var wolf := Vector2(748, 344)
		draw_colored_polygon(PackedVector2Array([wolf + Vector2(-58, 2), wolf + Vector2(-25, -17), wolf + Vector2(19, -13), wolf + Vector2(29, -39), wolf + Vector2(39, -25), wolf + Vector2(54, -21), wolf + Vector2(40, -8), wolf + Vector2(21, 10), wolf + Vector2(-41, 14)]), Color("07080c"))
		draw_line(wolf + Vector2(-25, 9), wolf + Vector2(-31, 38), Color("07080c"), 10)
		draw_line(wolf + Vector2(20, 7), wolf + Vector2(25, 38), Color("07080c"), 10)
		draw_circle(wolf + Vector2(40, -19), 1.5, Color("ab4853"))
	if panel_kind in [4, 5, 6, 7]:
		var brother := Vector2(625, 305) if panel_kind == 7 else Vector2(590, 305)
		_draw_brother(brother)
		if panel_kind != 4:
			_draw_red(Vector2(375, 315), panel_kind == 5)
		if panel_kind == 6:
			# Close framing of the existing keepsake, not a new gift being handed over.
			draw_circle(Vector2(750, 260), 62, Color("241b25"))
			draw_line(Vector2(703, 260), Vector2(794, 260), Color("873844"), 26)
			_draw_lily(Vector2(750, 260), 3.5)
	if panel_kind == 8:
		_draw_red(Vector2(380, 315), false)
		draw_rect(Rect2(510, 330, 90, 12), Color("3c2930"))
		draw_line(Vector2(523, 341), Vector2(519, 395), Color("31232a"), 7)
		draw_line(Vector2(585, 341), Vector2(591, 395), Color("31232a"), 7)
		draw_circle(Vector2(552, 310), 24, Color(.9, .62, .32, .08))
		draw_rect(Rect2(548, 310, 8, 20), Color("b28c68"))
		draw_circle(Vector2(552, 306), 3, Color("e4b371"))
	if panel_kind == 9:
		_draw_red(Vector2(470, 305), false)
		draw_line(Vector2(501, 346), Vector2(572, 299), Color("b9b3c1"), 5)
		draw_line(Vector2(505, 326), Vector2(523, 350), Color("a58a69"), 4)
	draw_set_transform(Vector2.ZERO)

func _draw_red(at: Vector2, reaching: bool) -> void:
	draw_circle(at, 19, Color("b68d96"))
	draw_arc(at + Vector2(0, 1), 22, PI, TAU, 12, Color("a63c4d"), 12)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-13, 18), at + Vector2(-40, 86), at + Vector2(38, 86), at + Vector2(13, 18)]), Color("722738"))
	draw_line(at + Vector2(-12, 79), at + Vector2(-12, 99), Color("24202b"), 10)
	draw_line(at + Vector2(12, 79), at + Vector2(15, 99), Color("24202b"), 10)
	if reaching:
		draw_line(at + Vector2(17, 36), at + Vector2(65, 23), Color("b68d96"), 8)

func _draw_brother(at: Vector2) -> void:
	draw_circle(at, 22, Color("ac8b84"))
	draw_arc(at + Vector2(0, -5), 22, PI, TAU, 12, Color("34232b"), 13)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-18, 24), at + Vector2(-30, 74), at + Vector2(30, 74), at + Vector2(18, 24)]), Color("373340"))
	draw_line(at + Vector2(-14, 70), at + Vector2(-18, 108), Color("24202b"), 12)
	draw_line(at + Vector2(14, 70), at + Vector2(18, 108), Color("24202b"), 12)
	draw_line(at + Vector2(-23, 27), at + Vector2(23, 27), Color("a23b4b"), 10)
	draw_line(at + Vector2(18, 28), at + Vector2(36, 66), Color("a23b4b"), 9)
	_draw_lily(at + Vector2(14, 29), 1.0)

func _draw_lily(at: Vector2, size_factor: float) -> void:
	for petal in range(5):
		var angle := TAU * petal / 5
		draw_circle(at + Vector2(cos(angle), sin(angle)) * 4 * size_factor, 3 * size_factor, Color("e6ded4"))
	draw_circle(at, 1.5 * size_factor, Color("bd9670"))
