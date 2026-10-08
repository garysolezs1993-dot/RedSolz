extends Node2D

@onready var background: Sprite2D = $Background

func _ready() -> void:
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
	background.modulate = Color(0.72, 0.75, 0.88, 1.0)

