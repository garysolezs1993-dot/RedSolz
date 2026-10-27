extends Control

const UI := preload("res://scripts/menu_ui.gd")
const SETTINGS := preload("res://scripts/audio_settings_panel.gd")
const MENU_BUTTON := preload("res://scripts/gothic_menu_button.gd")
const DIVIDER := preload("res://scripts/menu_divider.gd")
const MOTES := preload("res://scripts/story_motes.gd")

@export_file("*.png") var background_image := "res://assets/menu/silent_keep_background.png"
@export_range(0.5, 3.0, .05) var intro_duration := 1.75
@export_range(0.0, 1.0, .01) var left_scrim_opacity := .80
@export_range(0.0, 0.2, .005) var background_zoom_amount := .02
@export_range(8.0, 30.0, .5) var background_zoom_duration := 16.0
@export var version_caption := "Prototype v0.1"

var background_root: Control
var background: TextureRect
var menu_root: Control
var title_label: Label
var subtitle_label: Label
var divider: Control
var button_container: VBoxContainer
var buttons: Array[Button] = []
var continue_button: Button
var controls_hint: Label
var version_label: Label
var settings_panel: Control
var fade: ColorRect
var menu_animation: AnimationPlayer
var background_animation: AnimationPlayer
var intro_finished := false
var leaving := false
var exit_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black := ColorRect.new()
	black.name = "BlackBase"
	black.color = Color(.006, .003, .012)
	_full_rect(black, self)
	_build_background()
	_build_menu()
	_build_animations()
	settings_panel = Control.new()
	settings_panel.set_script(SETTINGS)
	add_child(settings_panel)
	fade = ColorRect.new()
	fade.name = "TransitionBlack"
	fade.color = Color(.006, .003, .012, 0)
	_full_rect(fade, self)
	fade.z_index = 100
	menu_animation.animation_finished.connect(_intro_complete)
	GameSession.reveal()
	menu_animation.play("intro")
	menu_animation.advance(0)
	background_animation.play("breathe")
	resized.connect(_resize_background)
	_resize_background()

func _full_rect(node: Control, parent: Node) -> void:
	parent.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_background() -> void:
	background_root = Control.new()
	background_root.name = "BackgroundRoot"
	_full_rect(background_root, self)
	background = TextureRect.new()
	background.name = "Background"
	background.texture = load(background_image) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_full_rect(background, background_root)
	var darkener := ColorRect.new()
	darkener.name = "BackgroundDarkener"
	darkener.color = Color(.015, .004, .025, .07)
	_full_rect(darkener, background_root)
	var petals := Node2D.new()
	petals.name = "AmbientPetals"
	petals.set_script(MOTES)
	petals.set("calm", true)
	petals.modulate.a = .45
	background_root.add_child(petals)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, .29, .48, .64, 1])
	gradient.colors = PackedColorArray([Color(.008, .003, .015, left_scrim_opacity), Color(.008, .003, .015, left_scrim_opacity * .87), Color(.008, .003, .015, .32), Color(.008, .003, .015, 0), Color(0, 0, 0, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 960
	texture.height = 2
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(1, 0)
	var scrim := TextureRect.new()
	scrim.name = "LeftGradient"
	scrim.texture = texture
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_full_rect(scrim, background_root)

func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "MenuRoot"
	_full_rect(menu_root, self)
	var title_group := Control.new()
	title_group.name = "TitleGroup"
	title_group.position = Vector2(60, 70)
	title_group.size = Vector2(340, 100)
	title_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(title_group)
	title_label = UI.label("THE SILENT KEEP", 30, Color("f0e4dc"))
	title_label.name = "TitleLabel"
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.add_theme_color_override("font_shadow_color", Color(.55, .08, .16, .7))
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_group.add_child(title_label)
	subtitle_label = UI.label("M O O N L I T  O A T H", 13, Color("bdb0b7"))
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	subtitle_label.position = Vector2(1, 48)
	title_group.add_child(subtitle_label)
	divider = Control.new()
	divider.name = "Divider"
	divider.set_script(DIVIDER)
	divider.position = Vector2(0, 78)
	divider.size = Vector2(330, 14)
	title_group.add_child(divider)
	button_container = VBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.position = Vector2(60, 209)
	button_container.size = Vector2(330, 220)
	button_container.add_theme_constant_override("separation", 12)
	menu_root.add_child(button_container)
	var names := ["StartGame", "ContinueGame", "Settings", "QuitGame"]
	var captions := ["START GAME", "CONTINUE", "SETTINGS", "QUIT GAME"]
	for index in range(4):
		var holder := Control.new()
		holder.name = names[index] + "Slot"
		holder.custom_minimum_size = Vector2(330, 46)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button_container.add_child(holder)
		var button := Button.new()
		button.set_script(MENU_BUTTON)
		button.name = names[index]
		button.text = captions[index]
		_full_rect(button, holder)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_selected.bind(index))
		buttons.append(button)
	continue_button = buttons[1]
	controls_hint = UI.label("↑↓ / D-pad   Navigate     Enter / A   Select", 12, Color("9c8d9e"))
	controls_hint.name = "ControlsHint"
	controls_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	menu_root.add_child(controls_hint)
	controls_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls_hint.offset_left = 60
	controls_hint.offset_right = 390
	controls_hint.offset_top = -44
	controls_hint.offset_bottom = -24
	version_label = UI.label(version_caption, 11, Color("93818a"))
	version_label.name = "VersionLabel"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	menu_root.add_child(version_label)
	version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version_label.offset_left = -150
	version_label.offset_right = -24
	version_label.offset_top = -35
	version_label.offset_bottom = -18

func _track(animation: Animation, node: Node, property: String, times: Array, values: Array) -> void:
	var index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index, str(get_path_to(node)) + ":" + property)
	for key in range(times.size()):
		animation.track_insert_key(index, float(times[key]), values[key])

func _build_animations() -> void:
	menu_animation = AnimationPlayer.new()
	menu_animation.name = "MenuAnimationPlayer"
	add_child(menu_animation)
	var intro := Animation.new()
	intro.length = intro_duration
	var timing := intro_duration / 1.75
	_track(intro, background_root, "modulate:a", [0, .20 * timing, .95 * timing], [0.0, 0.0, 1.0])
	_track(intro, title_label, "modulate:a", [0, .45 * timing, .85 * timing], [0.0, 0.0, 1.0])
	_track(intro, title_label, "position", [0, .45 * timing, .85 * timing], [Vector2(0, -10), Vector2(0, -10), Vector2.ZERO])
	for node in [subtitle_label, divider]:
		_track(intro, node, "modulate:a", [0, .70 * timing, 1.0 * timing], [0.0, 0.0, 1.0])
	for index in range(buttons.size()):
		var start := (.90 + index * .12) * timing
		_track(intro, buttons[index], "modulate:a", [0, start, start + .28 * timing], [0.0, 0.0, 1.0])
		_track(intro, buttons[index], "position", [0, start, start + .28 * timing], [Vector2(-10, 0), Vector2(-10, 0), Vector2.ZERO])
	for node in [controls_hint, version_label]:
		_track(intro, node, "modulate:a", [0, 1.45 * timing, 1.70 * timing], [0.0, 0.0, 1.0])
	var library := AnimationLibrary.new()
	library.add_animation("intro", intro)
	menu_animation.add_animation_library("", library)
	background_animation = AnimationPlayer.new()
	background_animation.name = "BackgroundAnimationPlayer"
	add_child(background_animation)
	var breathe := Animation.new()
	breathe.length = background_zoom_duration * 2
	breathe.loop_mode = Animation.LOOP_LINEAR
	var index := breathe.add_track(Animation.TYPE_VALUE)
	breathe.track_set_path(index, str(get_path_to(background)) + ":scale")
	breathe.track_set_interpolation_type(index, Animation.INTERPOLATION_CUBIC)
	breathe.track_insert_key(index, 0, Vector2.ONE)
	breathe.track_insert_key(index, background_zoom_duration, Vector2.ONE * (1 + background_zoom_amount))
	breathe.track_insert_key(index, breathe.length, Vector2.ONE)
	var ambient_library := AnimationLibrary.new()
	ambient_library.add_animation("breathe", breathe)
	background_animation.add_animation_library("", ambient_library)

func _resize_background() -> void:
	background.pivot_offset = background.size * .5

func _intro_complete(clip: StringName) -> void:
	if clip != &"intro" or leaving:
		return
	intro_finished = true
	var enabled: Array[Button] = []
	for index in range(buttons.size()):
		var button := buttons[index]
		button.disabled = index == 1 and not GameSession.has_valid_save()
		button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
		button.queue_redraw()
		if not button.disabled:
			enabled.append(button)
	UI.link_focus(enabled)
	buttons[0].grab_focus()

func _input(event: InputEvent) -> void:
	if (not intro_finished or leaving) and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()

func _selected(index: int) -> void:
	if not intro_finished or leaving or settings_panel.visible:
		return
	if index == 2:
		buttons[index].call("confirm_response", false)
		settings_panel.call("open")
		return
	if index == 1 and not GameSession.has_valid_save():
		return
	leaving = true
	buttons[index].call("confirm_response")
	for button in buttons:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().create_timer(.15).timeout
	# Save/load logic stays in GameSession; this fade can precede a later opening.
	if AudioDirector.music_tween != null and AudioDirector.music_tween.is_valid():
		AudioDirector.music_tween.kill()
	exit_tween = create_tween().set_parallel(true)
	exit_tween.tween_property(menu_root, "modulate:a", 0.0, .30)
	exit_tween.tween_property(fade, "color:a", 1.0, .55).set_delay(.10)
	exit_tween.tween_property(AudioDirector.music_player, "volume_db", -60.0, .60)
	await exit_tween.finished
	match index:
		0: GameSession.start_new_game()
		1: GameSession.continue_game()
		3: get_tree().quit()
