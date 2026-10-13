extends Node2D

# Cinematic travel shape only. The supplied animation belongs to the impact.
func _ready() -> void:
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit

func _draw() -> void:
	draw_line(Vector2(-42,0),Vector2(7,0),Color(1,.03,.15,.15),18)
	draw_line(Vector2(-35,0),Vector2(9,0),Color(.9,.02,.13,.7),7)
	draw_colored_polygon(PackedVector2Array([Vector2(14,0),Vector2(-10,-6),Vector2(-22,0),Vector2(-10,6)]),Color("cd1a40"))
	draw_line(Vector2(-18,0),Vector2(10,0),Color("ffccd5"),2)
