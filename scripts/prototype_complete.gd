extends Control

const TRANSITIONS := preload("res://scripts/story_transitions.gd")
@export var completion_artwork: Texture2D
# Clickable rectangle in source-image pixels; scales with the fitted artwork.
@export var return_button_rect := Rect2(1130, 780, 410, 70)
var artwork: TextureRect
var return_button: Button
var departing := false

func _ready() -> void:
	get_tree().paused = false
	GameSession.ending_in_progress = false
	AudioDirector.set_context("prototype_complete")
	var background := ColorRect.new()
	background.color = Color("0d0913")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var presentation := Control.new()
	presentation.name = "CompletionArtwork"
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(presentation)
	presentation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	presentation.modulate.a = 0
	artwork = TextureRect.new()
	artwork.name = "Artwork"
	artwork.texture = completion_artwork
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return_button = Button.new()
	return_button.name = "ReturnToTitle"
	# New completion art contains the title/message; the button remains editable.
	return_button.text = "Return to Title"
	return_button.add_theme_font_override("font", preload("res://assets/menu_font.tres"))
	return_button.add_theme_color_override("font_color", Color("f0e4dc"))
	return_button.add_theme_color_override("font_hover_color", Color("fff1df"))
	return_button.add_theme_color_override("font_focus_color", Color("fff1df"))
	return_button.tooltip_text = "Return to Title — Enter / Space / controller A"
	return_button.focus_mode = Control.FOCUS_ALL
	return_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name in ["normal", "disabled"]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(.035, .012, .026, .88)
		normal.border_color = Color("a68169")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(3)
		normal.content_margin_left = 18
		normal.content_margin_right = 18
		return_button.add_theme_stylebox_override(style_name, normal)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0,0,0,0)
	focus.border_color = Color("efd2b1")
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(3)
	return_button.add_theme_stylebox_override("focus",focus)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(.15, .025, .04, .94)
	hover.border_color = Color("e0b58f")
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(3)
	return_button.add_theme_stylebox_override("hover",hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(.08, .01, .03, .18)
	return_button.add_theme_stylebox_override("pressed",pressed)
	return_button.disabled = true
	presentation.add_child(return_button)
	return_button.pressed.connect(return_to_title)
	return_button.mouse_entered.connect(func():
		if not return_button.disabled:
			AudioDirector.play_sfx("menu_hover")
	)
	resized.connect(_layout_art_button)
	_layout_art_button()
	GameSession.reveal()
	await TRANSITIONS.fade(self,presentation,^"modulate:a",1.0,.8).finished
	return_button.disabled = false
	return_button.grab_focus()

func _layout_art_button() -> void:
	if return_button == null or completion_artwork == null:
		return
	var source_size := completion_artwork.get_size()
	var fit_scale := minf(size.x / source_size.x, size.y / source_size.y)
	var fitted_origin := (size - source_size * fit_scale) * .5
	return_button.add_theme_font_size_override("font_size", maxi(12, roundi(28 * fit_scale)))
	return_button.position = fitted_origin + return_button_rect.position * fit_scale
	return_button.size = return_button_rect.size * fit_scale

func _input(event: InputEvent) -> void:
	if event.is_echo():
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and not return_button.disabled:
		get_viewport().set_input_as_handled()
		return_to_title()

func return_to_title() -> void:
	if departing:
		return
	departing = true
	return_button.disabled = true
	AudioDirector.play_sfx("menu_confirm")
	GameSession.transition_to(GameSession.TITLE)
