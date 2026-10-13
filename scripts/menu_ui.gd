extends RefCounted

const FONT: Font = preload("res://assets/menu_font.tres")

static func build_canvas(owner_node: Node) -> Control:
	var layer := CanvasLayer.new()
	layer.name = "Presentation"
	layer.layer = 10
	owner_node.add_child(layer)
	var ui := Control.new()
	ui.name = "UI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.015, 0.02, 0.052, 0.28)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	return ui

static func build_panel(ui: Control, heading: String, subtitle: String, size: int = 30) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = "MenuPanel"
	panel.anchor_left = 0.04
	panel.anchor_right = 0.50
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.92
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.02, 0.042, 0.87)
	style.border_color = Color("51303e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	ui.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	column.add_child(label(heading, size, Color("d0b6b4")))
	column.add_child(label(subtitle, 17, Color("bab5c9")))
	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 2
	divider.color = Color("8c3248")
	column.add_child(divider)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	column.add_child(spacer)
	return column

static func label(caption: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = caption
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func button(caption: String, node_name: String) -> Button:
	var result := Button.new()
	result.name = node_name
	result.text = caption
	result.custom_minimum_size.y = 44
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", 18)
	result.add_theme_color_override("font_color", Color("eaded4"))
	result.add_theme_color_override("font_hover_color", Color("fff0d8"))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("3b2033") if state != "normal" else Color("171321")
		style.border_color = Color("b96670") if state != "normal" else Color("613746")
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		result.add_theme_stylebox_override(state, style)
	result.mouse_entered.connect(_highlight.bind(result, true))
	result.mouse_exited.connect(_highlight.bind(result, false))
	result.focus_entered.connect(_highlight.bind(result, true))
	result.focus_exited.connect(_highlight.bind(result, false))
	result.pressed.connect(func(): AudioDirector.play_sfx("menu_confirm"))
	return result

static func _highlight(target: Button, enabled: bool) -> void:
	if enabled:
		AudioDirector.play_sfx("menu_hover")
	var tween := target.create_tween()
	tween.tween_property(target, "modulate", Color(1.08, 1.02, 1.01) if enabled else Color.WHITE, 0.14)

static func link_focus(buttons: Array[Button]) -> void:
	for index in range(buttons.size()):
		var previous := buttons[posmod(index - 1, buttons.size())]
		var next := buttons[(index + 1) % buttons.size()]
		buttons[index].focus_neighbor_top = buttons[index].get_path_to(previous)
		buttons[index].focus_neighbor_bottom = buttons[index].get_path_to(next)
		buttons[index].focus_previous = buttons[index].get_path_to(previous)
		buttons[index].focus_next = buttons[index].get_path_to(next)
