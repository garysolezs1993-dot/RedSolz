extends Node2D

@export var calm := false
var elapsed := 0.0
var motes: Array[Dictionary] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 92814
	var view_size := get_viewport_rect().size
	for index in range(18):
		motes.append({
			"position": Vector2(rng.randf_range(0.0, view_size.x), rng.randf_range(40.0, view_size.y * 0.78)),
			"speed": rng.randf_range(7.0, 18.0),
			"drift": rng.randf_range(-5.0, 5.0),
			"phase": rng.randf_range(0.0, TAU),
			"size": rng.randf_range(1.0, 2.4),
		})
	get_viewport().size_changed.connect(_on_viewport_resized)

func _process(delta: float) -> void:
	delta *= 0.45 if calm else 1.0
	elapsed += delta
	var view_size := get_viewport_rect().size
	for index in range(motes.size()):
		var mote: Dictionary = motes[index]
		var mote_position: Vector2 = mote["position"]
		mote_position.y += float(mote["speed"]) * delta
		mote_position.x += (float(mote["drift"]) + sin(elapsed * 0.48 + float(mote["phase"])) * 9.0) * delta
		if mote_position.y > view_size.y * 0.86:
			mote_position.y = 30.0
			mote_position.x = fposmod(mote_position.x + view_size.x * 0.37, view_size.x)
		mote["position"] = mote_position
		motes[index] = mote
	queue_redraw()

func _on_viewport_resized() -> void:
	var view_size := get_viewport_rect().size
	for index in range(motes.size()):
		var mote: Dictionary = motes[index]
		var mote_position: Vector2 = mote["position"]
		mote_position.x = fposmod(mote_position.x, view_size.x)
		mote["position"] = mote_position
		motes[index] = mote
	queue_redraw()

func _draw() -> void:
	var view_size := get_viewport_rect().size
	for band in range(3):
		var base_y := view_size.y * 0.72 + float(band) * 30.0
		var upper := PackedVector2Array()
		var lower := PackedVector2Array()
		for x in range(-80, int(view_size.x) + 120, 80):
			var wave := sin(float(x) * 0.009 + elapsed * (0.18 + float(band) * 0.035) + float(band) * 1.7)
			var y := base_y + wave * (7.0 + float(band) * 2.0)
			upper.append(Vector2(float(x), y))
			lower.append(Vector2(float(x), y + 28.0 + sin(float(x) * 0.013 + elapsed * 0.25) * 5.0))
		var fog_shape := upper.duplicate()
		for index in range(lower.size() - 1, -1, -1):
			fog_shape.append(lower[index])
		var fog_alpha := 0.045 + float(band) * 0.018
		draw_colored_polygon(fog_shape, Color(0.57, 0.61, 0.76, fog_alpha))

	var index := 0
	for mote in motes:
		var center: Vector2 = mote["position"]
		var size := float(mote["size"])
		var phase := float(mote["phase"])
		var angle := sin(elapsed * 0.55 + phase) * 0.75
		var leaf := PackedVector2Array([
			Vector2(-size, 0.0), Vector2(0.0, -size * 1.7),
			Vector2(size * 1.5, 0.0), Vector2(0.0, size * 1.1),
		])
		for point_index in range(leaf.size()):
			leaf[point_index] = center + leaf[point_index].rotated(angle)
		var leaf_alpha := 0.34 + (sin(elapsed + phase) + 1.0) * 0.12
		var color := Color(0.82, 0.75, 0.71, leaf_alpha * 0.75) if calm and index % 4 == 0 else Color(0.62, 0.11, 0.18, leaf_alpha * (0.65 if calm else 1.0))
		draw_colored_polygon(leaf, color)
		index += 1
