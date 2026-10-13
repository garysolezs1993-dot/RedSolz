extends Node2D

@export var title_mode := false
@export var quiet_mode := false
var elapsed := 0.0
@onready var background: Sprite2D = $Background

func _ready() -> void:
	if title_mode:
		background.texture = load("res://assets/game_assets/backgrounds/forest_approach.png")
	$FogAndLeaves.set("calm", quiet_mode)
	_fit_background()
	get_viewport().size_changed.connect(_fit_background)

func _fit_background() -> void:
	var view_size := get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0 or background.texture == null:
		return
	var texture_size := Vector2(background.texture.get_width(), background.texture.get_height())
	var cover_scale := maxf(view_size.x / texture_size.x, view_size.y / texture_size.y)
	background.position = view_size * 0.5
	background.scale = Vector2.ONE * cover_scale
	background.modulate = Color(0.58, 0.65, 0.80, 1.0) if quiet_mode else Color(0.72, 0.75, 0.88, 1.0)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	# Sparse foreground trunks sway only a few pixels; existing art supplies the forest.
	var size := get_viewport_rect().size
	for index in range(3):
		var x := size.x * (0.03 if index == 0 else 0.95 + float(index - 1) * 0.08)
		var sway := sin(elapsed * 0.16 + index) * (0.8 if quiet_mode else 2.2)
		var color := Color(0.018, 0.015, 0.034, 0.62)
		draw_line(Vector2(x, size.y), Vector2(x + sway, size.y * 0.15), color, 15, false)
		draw_line(Vector2(x + sway, size.y * 0.35), Vector2(x - 38 + sway, size.y * 0.18), color, 7, false)
		draw_line(Vector2(x + sway, size.y * 0.5), Vector2(x + 44 + sway, size.y * 0.31), color, 6, false)
