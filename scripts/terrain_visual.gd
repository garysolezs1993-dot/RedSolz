extends Node2D

@export var dimensions := Vector2(220.0, 32.0)
@export var variant := 0
@export var surface_y := -9.0

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 841 + variant * 7919
	var half_width := dimensions.x * 0.5
	var depth := dimensions.y
	var top := PackedVector2Array()
	for index in range(9):
		var x := lerpf(-half_width, half_width, float(index) / 8.0)
		top.append(Vector2(x, surface_y + rng.randf_range(-2.0, 1.0)))

	# Jagged rock body; the StaticBody collision above it stays a simple box.
	var rock := top.duplicate()
	for index in range(1, 9):
		var x := lerpf(half_width, -half_width, float(index) / 8.0)
		rock.append(Vector2(x, depth * 0.5 + rng.randf_range(-3.0, 3.0)))
	draw_colored_polygon(rock, Color("292630"))

	# Broken stone faces and hanging roots add shape without changing collisions.
	for index in range(maxi(3, int(dimensions.x / 38.0))):
		var x := rng.randf_range(-half_width + 7.0, half_width - 7.0)
		var y := rng.randf_range(-2.0, depth * 0.24)
		var facet := PackedVector2Array([
			Vector2(x - 7.0, y),
			Vector2(x + rng.randf_range(-2.0, 4.0), y + rng.randf_range(4.0, 9.0)),
			Vector2(x + 8.0, y + 2.0),
		])
		var stone_color := Color("3b3640") if index % 2 == 0 else Color("342f3b")
		draw_colored_polygon(facet, stone_color)
		if index % 3 == variant % 3:
			draw_line(Vector2(x, depth * 0.28), Vector2(x + rng.randf_range(-4.0, 4.0), depth * 0.5 + 9.0), Color("493b36"), 2.0, true)

	# Mossy top lip follows the uneven silhouette, while staying near the flat collider top.
	var moss := top.duplicate()
	for index in range(8, -1, -1):
		moss.append(Vector2(top[index].x, top[index].y + rng.randf_range(4.0, 6.0)))
	draw_colored_polygon(moss, Color("4d604c"))
	draw_polyline(top, Color("8d8960"), 2.0, true)

	# Sparse grass and crimson leaves keep the walkable surface readable.
	var tuft_count := maxi(2, int(dimensions.x / 105.0))
	for index in range(tuft_count):
		var x := rng.randf_range(-half_width + 7.0, half_width - 7.0)
		var base_y := surface_y + 1.0
		draw_line(Vector2(x, base_y), Vector2(x - 2.0, base_y - rng.randf_range(3.0, 7.0)), Color("89906a"), 1.4, true)
		if index % 3 == variant % 3:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x + 3.0, base_y - 2.0),
				Vector2(x + 7.0, base_y - 4.0),
				Vector2(x + 5.0, base_y),
			]), Color("9b3744"))
