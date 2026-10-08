extends Node2D

const RETRY_FALLBACK := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

@onready var red_sprite: Sprite2D = $RedFallen
@onready var wolf_sprite: Sprite2D = $WolfSilhouette

var elapsed := 0.0
var eye_glows: Array[Polygon2D] = []

func _ready() -> void:
	_build_eye_glows()
	_build_sword()
	_build_ui()

func _process(delta: float) -> void:
	elapsed += delta
	red_sprite.position.y = get_viewport_rect().size.y - 102.0 + sin(elapsed * 0.42) * 0.8
	red_sprite.rotation = sin(elapsed * 0.31) * 0.006
	var reveal_time := fposmod(elapsed, 9.0)
	var reveal := 0.0
	if reveal_time < 0.45:
		reveal = reveal_time / 0.45
	elif reveal_time < 1.35:
		reveal = 1.0
	elif reveal_time < 1.8:
		reveal = 1.0 - (reveal_time - 1.35) / 0.45
	wolf_sprite.modulate.a = reveal * 0.28
	for eye in eye_glows:
		eye.color.a = reveal * 0.52

func _build_eye_glows() -> void:
	for local_position: Vector2 in [Vector2(6.0, -5.0), Vector2(10.0, -5.0)]:
		var eye := Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(-1.0, -1.0), Vector2(1.0, -1.0),
			Vector2(1.0, 1.0), Vector2(-1.0, 1.0),
		])
		eye.position = wolf_sprite.position + local_position * wolf_sprite.scale
		eye.color = Color(0.94, 0.18, 0.24, 0.0)
		eye.z_index = 2
		add_child(eye)
		eye_glows.append(eye)

func _build_sword() -> void:
	var screen_size := get_viewport_rect().size
	var sword_origin := Vector2(screen_size.x * 0.715, screen_size.y - 51.0)
	var hilt := Polygon2D.new()
	hilt.position = sword_origin
	hilt.polygon = PackedVector2Array([
		Vector2(-31.0, 9.0), Vector2(-25.0, 5.0),
		Vector2(-17.0, 9.0), Vector2(-23.0, 13.0),
	])
	hilt.color = Color(0.20, 0.09, 0.11, 1.0)
	add_child(hilt)
	var guard := Polygon2D.new()
	guard.position = sword_origin
	guard.polygon = PackedVector2Array([
		Vector2(-23.0, 2.0), Vector2(-20.0, 5.0),
		Vector2(-14.0, 14.0), Vector2(-17.0, 16.0),
	])
	guard.color = Color(0.55, 0.36, 0.34, 1.0)
	add_child(guard)
	var blade := Polygon2D.new()
	blade.position = sword_origin
	blade.polygon = PackedVector2Array([
		Vector2(-22.0, 7.0), Vector2(18.0, -6.0),
		Vector2(27.0, -11.0), Vector2(21.0, -2.0),
		Vector2(-18.0, 10.0),
	])
	blade.color = Color(0.58, 0.63, 0.70, 0.86)
	add_child(blade)
	var blade_edge := Line2D.new()
	blade_edge.points = PackedVector2Array([Vector2(-17.0, 9.0), Vector2(21.0, -2.0)])
	blade_edge.position = sword_origin
	blade_edge.width = 1.0
	blade_edge.default_color = Color(0.84, 0.81, 0.78, 0.9)
	add_child(blade_edge)

func _build_ui() -> void:
	var screen_size := get_viewport_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.015, 0.02, 0.052, 0.38)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	var panel := Panel.new()
	panel.position = Vector2(28.0, screen_size.y * 0.355)
	panel.size = Vector2(minf(530.0, screen_size.x * 0.58), 280.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	ui.add_child(panel)
	var title := _make_label(
		"THE FOREST CLAIMS YOU", Vector2(52.0, screen_size.y * 0.385),
		Vector2(minf(500.0, screen_size.x * 0.55), 48.0), 29,
		Color(0.92, 0.82, 0.78, 1.0), HORIZONTAL_ALIGNMENT_LEFT
	)
	ui.add_child(title)
	var divider := ColorRect.new()
	divider.position = Vector2(54.0, screen_size.y * 0.385 + 49.0)
	divider.size = Vector2(340.0, 2.0)
	divider.color = Color(0.66, 0.16, 0.22, 0.9)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(divider)
	var subtitle := _make_label(
		"But the story is not yet over...", Vector2(55.0, screen_size.y * 0.385 + 66.0),
		Vector2(440.0, 34.0), 17, Color(0.76, 0.75, 0.80, 1.0), HORIZONTAL_ALIGNMENT_LEFT
	)
	ui.add_child(subtitle)
	var try_again := _make_button("TRY AGAIN", Vector2(54.0, screen_size.y * 0.385 + 130.0))
	try_again.pressed.connect(_on_try_again)
	ui.add_child(try_again)
	var return_button := _make_button("RETURN TO TITLE", Vector2(54.0, screen_size.y * 0.385 + 190.0))
	return_button.pressed.connect(_on_return_to_title)
	ui.add_child(return_button)
	try_again.grab_focus()

func _make_label(text_value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color, alignment: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.012, 0.027, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _make_button(text_value: String, position_value: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = position_value
	button.custom_minimum_size = Vector2(292.0, 46.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.91, 0.85, 0.82, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.88, 1.0))
	button.add_theme_stylebox_override("normal", _make_button_style(false))
	button.add_theme_stylebox_override("hover", _make_button_style(true))
	button.add_theme_stylebox_override("pressed", _make_button_style(true))
	button.add_theme_stylebox_override("focus", _make_button_style(true))
	return button

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.02, 0.045, 0.76)
	style.border_color = Color(0.31, 0.12, 0.17, 0.74)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func _make_button_style(highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.035, 0.055, 0.94) if highlighted else Color(0.035, 0.028, 0.047, 0.88)
	style.border_color = Color(0.70, 0.22, 0.28, 0.92) if highlighted else Color(0.36, 0.17, 0.21, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

func _on_try_again() -> void:
	var retry_path := str(get_tree().root.get_meta("retry_scene_path", RETRY_FALLBACK))
	if not ResourceLoader.exists(retry_path):
		retry_path = RETRY_FALLBACK
	get_tree().change_scene_to_file(retry_path)

func _on_return_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)
