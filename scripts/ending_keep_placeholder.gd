extends Node2D

var pulse_strength := 0.0:
	set(value):
		pulse_strength = value
		queue_redraw()

func _draw() -> void:
	# Temporary, fixed world-space landmark; never follows the player.
	draw_circle(Vector2(45,-92), 73, Color(.48 + pulse_strength * .3, .09, .14, .8))
	draw_colored_polygon(PackedVector2Array([Vector2(-125,40),Vector2(0,-20),Vector2(150,40)]), Color("111320"))
	draw_rect(Rect2(-72,-42,148,47), Color("11101a"))
	for tower in [Vector2(-60,-63), Vector2(-20,-130), Vector2(30,-88), Vector2(72,-50)]:
		draw_rect(Rect2(tower,Vector2(26,-tower.y)), Color("10101a"))
		draw_colored_polygon(PackedVector2Array([tower + Vector2(-6,0),tower + Vector2(13,-40),tower + Vector2(32,0)]), Color("10101a"))
		draw_rect(Rect2(tower + Vector2(10,13),Vector2(5,11)), Color(.45 + pulse_strength * .5,.05,.11))
