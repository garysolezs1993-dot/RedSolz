extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size * .5
	var color := Color("973d50")
	draw_line(Vector2(0, center.y), center - Vector2(12, 0), color, 1, true)
	draw_line(center + Vector2(12, 0), Vector2(size.x, center.y), color, 1, true)
	draw_polyline(PackedVector2Array([center + Vector2(-6, 0), center + Vector2(0, -6), center + Vector2(6, 0), center + Vector2(0, 6), center + Vector2(-6, 0)]), color, 1, true)
	draw_circle(center, 1.5, Color("d76a76"))
