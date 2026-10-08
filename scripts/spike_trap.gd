extends Node2D

@onready var danger_area: Area2D = $DangerArea

func _ready() -> void:
	danger_area.body_entered.connect(_on_body_entered)

func _draw() -> void:
	for index in range(4):
		var left := -16.0 + float(index) * 8.0
		var triangle := PackedVector2Array([
			Vector2(left, 0.0), Vector2(left + 4.0, -15.0), Vector2(left + 8.0, 0.0),
		])
		draw_colored_polygon(triangle, Color("aaa0a6"))
		draw_line(Vector2(left + 4.0, -15.0), Vector2(left + 4.0, -4.0), Color("e2d8d8"), 1.0, true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(12, sign(body.global_position.x - global_position.x) * 180.0)
