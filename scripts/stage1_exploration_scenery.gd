extends Node2D

# Existing terrain colors, roots and ruined-stone shapes decorate the new rooms.
# Scenery has no collision; shelves and marked hazards own all gameplay geometry.
func _ready() -> void:
	z_index = -2
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(510, 0))
	_draw_creek()
	draw_set_transform(Vector2(-2100, 0))
	_draw_oak()
	draw_set_transform(Vector2(-2090, 0))
	_draw_cellar()
	draw_set_transform(Vector2(-800, 180))
	_draw_burial_ground()
	draw_set_transform(Vector2(-300, 0))
	_draw_heartwood()
	draw_set_transform(Vector2.ZERO)
	_draw_upper_ruins()
	for sign in [
		[Vector2(2720, 382), "FOREST CROSSROADS", "The chapel above. The hollow below."],
		[Vector2(3700, 112), "BROKEN CHAPEL", "A sleeping seal beneath the fallen bell."],
		[Vector2(4000, 410), "HOLLOW OAK", "The roots remember another path."],
		[Vector2(3450, 570), "ROOT CELLAR", "A seal waits beneath the old roots."],
		[Vector2(4860, 657), "ROOTBOUND SHORTCUT", "Wake the cellar seal to raise the lift."],
		[Vector2(5480, 350), "RUINED BRIDGE", "The creek threads through the stones."],
		[Vector2(6720, 586), "BURIAL RUINS", "Old names sleep beneath the bridge."],
		[Vector2(6240, 306), "UPPER FOREST RUINS", "Above the bridge, the canopy opens."],
		[Vector2(6920, 60), "CANOPY LOOKOUT", "A glimpse of the journey's end."],
		[Vector2(7960, 42), "UPPER SANCTUARY", "The final seal waits beyond the broken tower."],
		[Vector2(8200, 268), "HEARTWOOD CLEARING", "Beyond the roots, the moon waits."],
		[Vector2(9420, 298), "MOON GATE", "The forest opens beneath the crimson moon."],
	]:
		var sign_position: Vector2 = sign[0]
		draw_string(ThemeDB.fallback_font, sign_position, str(sign[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b7a9bb"))
		draw_string(ThemeDB.fallback_font, sign_position + Vector2(0, 19), str(sign[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ae989c"))

func _draw_upper_ruins() -> void:
	# Reuse the chapel's stone palette and oak's roots; all dressing is visual only.
	for x in [7750.0, 8060.0, 8460.0]:
		draw_rect(Rect2(x, -44, 22, 170), Color("302d39"))
		draw_rect(Rect2(x - 5, -50, 32, 10), Color("49414b"))
	draw_line(Vector2(7761, -44), Vector2(7900, -140), Color("393542"), 14)
	draw_line(Vector2(7900, -140), Vector2(8071, -44), Color("393542"), 14)
	for x in [6620.0, 6840.0, 7440.0]:
		draw_line(Vector2(x, 298), Vector2(x + 50, 350), Color("392d3b"), 8)
		draw_line(Vector2(x + 50, 350), Vector2(x + 12, 387), Color("513949"), 4)

func _draw_creek() -> void:
	# Moonlit water remains below the readable main path; there is no lethal pit.
	draw_rect(Rect2(4900, 544, 760, 80), Color("1d263b"))
	for index in range(9):
		var start := Vector2(4930 + index * 80, 558 + index % 3 * 12)
		draw_line(start, start + Vector2(45, 0), Color("475166"), 2)
	for x in [4845.0, 5100.0, 5740.0]:
		draw_line(Vector2(x, 490), Vector2(x + 90, 455), Color("403336"), 19)
		draw_line(Vector2(x + 5, 485), Vector2(x + 85, 455), Color("6a5650"), 2)

func _draw_oak() -> void:
	var bark := Color("27212f")
	draw_colored_polygon(PackedVector2Array([Vector2(6150, 500), Vector2(6270, 200), Vector2(6340, -95), Vector2(6400, -150), Vector2(6460, 20), Vector2(6490, 270), Vector2(6670, 500)]), bark)
	for branch in [
		[Vector2(6380, -50), Vector2(6540, -28)],
		[Vector2(6380, 50), Vector2(6100, 90)],
		[Vector2(6420, 100), Vector2(6840, 125)],
		[Vector2(6340, 210), Vector2(5680, 232)],
		[Vector2(6450, 270), Vector2(7040, 288)],
	]:
		draw_line(branch[0], branch[1], bark, 28)
		draw_line(branch[0] + Vector2(0, -7), branch[1] + Vector2(0, -7), Color("473849"), 3)
	draw_colored_polygon(PackedVector2Array([Vector2(6310, 500), Vector2(6330, 402), Vector2(6360, 370), Vector2(6410, 412), Vector2(6430, 500)]), Color("15121e"))
	for x in [5870.0, 6370.0, 6890.0]:
		draw_line(Vector2(x, 170), Vector2(x + 24, 232), Color("53404a"), 3)

func _draw_cellar() -> void:
	draw_rect(Rect2(5420, 540, 1900, 245), Color("161320"))
	for index in range(15):
		var x := 5460.0 + index * 126.0
		draw_line(Vector2(x, 544), Vector2(x + 17, 604 + index % 3 * 16), Color("3a2b36"), 11)
		draw_line(Vector2(x + 17, 604 + index % 3 * 16), Vector2(x - 11, 627 + index % 3 * 16), Color("513949"), 5)
		draw_line(Vector2(x, 770), Vector2(x + 30, 720), Color("392d3b"), 8)
	for lantern in [Vector2(5625, 686), Vector2(6250, 635), Vector2(7040, 634)]:
		draw_circle(lantern, 24, Color(1, .59, .28, .08))
		draw_rect(Rect2(lantern - Vector2(5, 12), Vector2(10, 16)), Color("57404b"))
		draw_rect(Rect2(lantern - Vector2(2, 9), Vector2(4, 9)), Color("e4b681"))
	# Two separate vertical exits reconnect with the main forest.
	draw_line(Vector2(5480, 505), Vector2(5590, 665), Color("7e665e"), 3)
	draw_line(Vector2(7150, 690), Vector2(7280, 505), Color("7e665e"), 3)

func _draw_burial_ground() -> void:
	for index in range(5):
		var x := 7420.0 + index * 124
		draw_rect(Rect2(x, 464, 23, 36), Color("49424f"))
		draw_circle(Vector2(x + 11.5, 464), 11.5, Color("49424f"))
		draw_line(Vector2(x + 11, 460), Vector2(x + 11, 483), Color("8e7f85"), 2)
		draw_line(Vector2(x + 4, 470), Vector2(x + 18, 470), Color("8e7f85"), 2)
	for x in [7700.0, 7930.0]:
		draw_rect(Rect2(x, 350, 22, 150), Color("302d39"))
		draw_rect(Rect2(x - 4, 344, 30, 11), Color("524854"))
	draw_line(Vector2(7710, 350), Vector2(7800, 282), Color("393542"), 13)
	draw_line(Vector2(7800, 282), Vector2(7914, 350), Color("393542"), 13)
	draw_circle(Vector2(7800, 303), 5, Color("b59a81"))

func _draw_heartwood() -> void:
	var trunk := Color("241b2b")
	draw_line(Vector2(8580, 500), Vector2(8730, 244), trunk, 55)
	draw_line(Vector2(8730, 244), Vector2(8630, 90), trunk, 32)
	draw_line(Vector2(8730, 244), Vector2(9010, 82), trunk, 25)
	draw_line(Vector2(8650, 361), Vector2(8410, 302), trunk, 25)
	draw_line(Vector2(8690, 307), Vector2(8950, 280), Color("642c43"), 5)
	for ember_position in [Vector2(8730, 244), Vector2(8950, 280), Vector2(8610, 439)]:
		draw_circle(ember_position, 12, Color(.75, .15, .24, .10))
		draw_circle(ember_position, 3, Color("c34a61"))
