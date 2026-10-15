extends Control

const RETRY_FALLBACK := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const UI := preload("res://scripts/menu_ui.gd")

@export var background_artwork: Texture2D
# Interactive areas in source-image pixels; preserve the fitted image alignment.
@export var try_again_rect := Rect2(220,456,514,66)
@export var return_title_rect := Rect2(220,548,514,66)

var menu_ui: Control
var menu_buttons: Array[Button] = []
var retry_dimmer: ColorRect
var departing := false
var menu_revealed := false

func _ready() -> void:
	_build_ui()
	GameSession.reveal()
	if not GameSession.death_in_progress:
		call_deferred("reveal_death_menu")

func _build_ui() -> void:
	var base := ColorRect.new()
	base.color = Color("0d0913")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_ui = Control.new()
	menu_ui.name = "IllustratedDeathMenu"
	menu_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_ui)
	menu_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var artwork := TextureRect.new()
	artwork.name = "Artwork"
	artwork.texture = background_artwork
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_ui.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	retry_dimmer = ColorRect.new()
	retry_dimmer.name = "UnselectedRetryDimmer"
	retry_dimmer.color = Color(.01,.005,.01,.42)
	retry_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retry_dimmer.hide()
	menu_ui.add_child(retry_dimmer)
	var retry_button := _art_button("TryAgain","Try Again",0)
	var title_button := _art_button("ReturnToTitle","Return to Title",1)
	menu_buttons = [retry_button,title_button]
	retry_button.pressed.connect(_on_try_again)
	title_button.pressed.connect(_on_return_to_title)
	UI.link_focus(menu_buttons)
	resized.connect(_layout_buttons)
	_layout_buttons()
	# During death, the persistent fog reveals the complete illustration first.
	# Its controller calls reveal_death_menu after the fog has cleared.
	menu_ui.modulate.a = 1.0 if GameSession.death_in_progress else 0.0

func _art_button(node_name: String, caption: String, index: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.tooltip_text = caption
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name in ["normal","disabled"]:
		button.add_theme_stylebox_override(style_name,StyleBoxEmpty.new())
	var highlight := StyleBoxFlat.new()
	highlight.bg_color = Color(1,.25,.3,.10)
	highlight.border_color = Color(1,.7,.7,.95)
	highlight.set_border_width_all(2)
	highlight.set_corner_radius_all(3)
	button.add_theme_stylebox_override("hover",highlight)
	button.add_theme_stylebox_override("focus",highlight)
	var pressed := highlight.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(.04,.005,.015,.25)
	button.add_theme_stylebox_override("pressed",pressed)
	button.disabled = true
	button.modulate.a = 0.0
	menu_ui.add_child(button)
	button.focus_entered.connect(_select_choice.bind(index))
	button.mouse_entered.connect(func():
		if not button.disabled:
			button.grab_focus()
	)
	return button

func _select_choice(index: int) -> void:
	retry_dimmer.visible = index == 1
	if not menu_buttons[index].disabled:
		AudioDirector.play_sfx("menu_hover")

func _layout_buttons() -> void:
	if background_artwork == null or menu_buttons.size() != 2:
		return
	var source_size := background_artwork.get_size()
	var fit_scale := minf(size.x/source_size.x,size.y/source_size.y)
	var fitted_origin := (size-source_size*fit_scale)*.5
	var rectangles: Array[Rect2] = [try_again_rect,return_title_rect]
	for index in range(menu_buttons.size()):
		menu_buttons[index].position = fitted_origin+rectangles[index].position*fit_scale
		menu_buttons[index].size = rectangles[index].size*fit_scale
	retry_dimmer.position = menu_buttons[0].position
	retry_dimmer.size = menu_buttons[0].size

func reveal_death_menu() -> void:
	if menu_revealed:
		return
	menu_revealed = true
	var intro := create_tween().set_ignore_time_scale(true)
	intro.tween_property(menu_ui,"modulate:a",1.0,.55)
	intro.set_parallel(true)
	for button in menu_buttons:
		intro.tween_property(button,"modulate:a",1.0,.25).set_delay(.55)
	await intro.finished
	for button in menu_buttons:
		button.disabled = false
	menu_buttons[0].grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_echo() or menu_buttons.is_empty() or menu_buttons[0].disabled:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_return_to_title()

func _begin_departure() -> bool:
	if departing or GameSession.transitioning:
		return false
	departing = true
	for button in menu_buttons:
		button.disabled = true
	AudioDirector.play_sfx("menu_confirm")
	return true

func _on_try_again() -> void:
	if not _begin_departure():
		return
	var retry_path := str(get_tree().root.get_meta("retry_scene_path",RETRY_FALLBACK))
	GameSession.retry_stage(retry_path)

func _on_return_to_title() -> void:
	if _begin_departure():
		GameSession.transition_to(TITLE_SCENE)