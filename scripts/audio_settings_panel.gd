extends Control

const UI := preload("res://scripts/menu_ui.gd")
var previous_focus: Control
var music_slider: HSlider
var sfx_slider: HSlider

func _ready() -> void:
	name = "AudioSettings"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 50
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.01, 0.026, 0.88)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 310)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	column.add_child(UI.label("SOUND SETTINGS", 26, Color("eaded4")))
	music_slider = _add_slider(column, "Music", GameSession.music_volume)
	sfx_slider = _add_slider(column, "SFX", GameSession.sfx_volume)
	var close_button := UI.button("BACK", "CloseSettings")
	close_button.pressed.connect(close)
	column.add_child(close_button)
	music_slider.focus_neighbor_bottom = music_slider.get_path_to(sfx_slider)
	sfx_slider.focus_neighbor_top = sfx_slider.get_path_to(music_slider)
	sfx_slider.focus_neighbor_bottom = sfx_slider.get_path_to(close_button)
	close_button.focus_neighbor_top = close_button.get_path_to(sfx_slider)
	close_button.focus_neighbor_bottom = close_button.get_path_to(music_slider)
	music_slider.focus_neighbor_top = music_slider.get_path_to(close_button)
	hide()

func _add_slider(column: VBoxContainer, channel: String, value: float) -> HSlider:
	var caption := UI.label("%s  %d%%" % [channel, roundi(value * 100)], 18, Color("d2c6d8"))
	column.add_child(caption)
	var slider := HSlider.new()
	slider.name = channel + "Volume"
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(value * 100)
	slider.custom_minimum_size.y = 28
	slider.focus_mode = Control.FOCUS_ALL
	column.add_child(slider)
	slider.value_changed.connect(func(new_value: float):
		GameSession.set_audio_volume(channel, new_value / 100.0)
		caption.text = "%s  %d%%" % [channel, roundi(new_value)]
	)
	return slider

func open() -> void:
	previous_focus = get_viewport().gui_get_focus_owner()
	show()
	music_slider.grab_focus()

func close() -> void:
	hide()
	if is_instance_valid(previous_focus):
		previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
