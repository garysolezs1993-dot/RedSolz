extends Node2D

const RETRY_FALLBACK := "res://scenes/main.tscn"

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.015, 0.02, 0.052, 0.32)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	var title := _make_label("RED RIDING HOOD", Vector2(58.0, 176.0), Vector2(500.0, 56.0), 36, Color(0.79, 0.16, 0.22, 1.0))
	ui.add_child(title)
	var subtitle := _make_label("THE SILENT KEEP", Vector2(62.0, 234.0), Vector2(340.0, 32.0), 18, Color(0.88, 0.83, 0.82, 1.0))
	ui.add_child(subtitle)
	var divider := ColorRect.new()
	divider.position = Vector2(62.0, 273.0)
	divider.size = Vector2(300.0, 2.0)
	divider.color = Color(0.63, 0.15, 0.22, 0.85)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(divider)
	var start := _make_button("ENTER THE FOREST", Vector2(62.0, 318.0))
	start.pressed.connect(_on_start)
	ui.add_child(start)
	var quit := _make_button("LEAVE THE FOREST", Vector2(62.0, 378.0))
	quit.pressed.connect(_on_quit)
	ui.add_child(quit)
	start.grab_focus()

func _make_label(text_value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = position_value
	label.size = size_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.025, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	return label

func _make_button(text_value: String, position_value: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = position_value
	button.custom_minimum_size = Vector2(292.0, 46.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.91, 0.85, 0.82, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.028, 0.047, 0.9)
	normal.border_color = Color(0.36, 0.17, 0.21, 0.88)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.08, 0.035, 0.055, 0.96)
	hover.border_color = Color(0.70, 0.22, 0.28, 0.92)
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	return button

func _on_start() -> void:
	var retry_path := str(get_tree().root.get_meta("retry_scene_path", RETRY_FALLBACK))
	if not ResourceLoader.exists(retry_path):
		retry_path = RETRY_FALLBACK
	get_tree().change_scene_to_file(retry_path)

func _on_quit() -> void:
	get_tree().quit()

