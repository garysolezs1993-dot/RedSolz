extends Control

const TRANSITIONS := preload("res://scripts/story_transitions.gd")
const PLACEHOLDER := preload("res://scripts/opening_placeholder.gd")
const UI := preload("res://scripts/menu_ui.gd")
const STORY_LINE := preload("res://scripts/opening_story_line.gd")
const AMBIENCE := preload("res://scripts/opening_ambience.gd")
signal continue_requested
@export var panels: Array[Resource] = []
@export_dir var panel_art_directory := "res://assets/cutscenes/opening"
@export var auto_advance := false
@export var panel_fade_in := .4
@export var panel_fade_out := .35
@export var title_hold := 2.5
@export_range(-50, -12, 1) var ambience_volume_db := -24.0
@export_group("Story Petals")
@export var story_petals_enabled := true
@export_range(.01, .2, .01) var story_petal_opacity := .11
@export_range(.01, .08, .005) var story_petal_scale := .035

var placeholder: Control
var artwork: TextureRect
var previous_artwork: TextureRect
var petal_layer: Control
var caption: Label
var speaker: Label
var text_box: PanelContainer
var next_button: Button
var panel_counter: Label
var title_group: VBoxContainer
var black: ColorRect
var skip_button: Button
var storyboard_note: Label
var active_tween: Tween
var finishing := false
var phase := "starting"
var current_panel := -1
var current_line := -1
var awaiting_continue := false
var motion_elapsed := 0.0
var motion_duration := 1.0
var motion_zoom := .03
var motion_pan := Vector2.ZERO
var music_level_tween: Tween
var ambience_tween: Tween
var wind: AudioStreamPlayer

func _ready() -> void:
	_install_controls()
	_build()
	AudioDirector.set_context("opening")
	wind = AudioStreamPlayer.new()
	wind.name = "OpeningForestWind"
	wind.bus = "SFX"
	wind.volume_db = -60
	wind.stream = AMBIENCE.make_wind()
	add_child(wind)
	wind.play()
	ambience_tween = TRANSITIONS.fade(self, wind, ^"volume_db", ambience_volume_db, .8)
	GameSession.reveal()
	# Let AudioDirector start the opening stream before per-shot ducking owns
	# its volume. This also supports playing this scene directly from the editor.
	await get_tree().create_timer(.35).timeout
	if not finishing:
		call_deferred("_play_sequence")

func _install_controls() -> void:
	# Opening confirm advances dialogue; it must not also skip the whole intro.
	# Leave other cutscenes' default bindings unchanged.
	if not InputMap.has_action("skip_opening"):
		InputMap.add_action("skip_opening")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		InputMap.action_add_event("skip_opening", escape)
		for code in [JOY_BUTTON_START, JOY_BUTTON_B]:
			var button := InputEventJoypadButton.new()
			button.device = -1
			button.button_index = code
			InputMap.action_add_event("skip_opening", button)

func _full_rect(control: Control) -> void:
	add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "CinematicBackdrop"
	backdrop.color = Color(.006, .003, .010)
	_full_rect(backdrop)
	placeholder = Control.new()
	placeholder.name = "PlaceholderPanel"
	placeholder.set_script(PLACEHOLDER)
	_full_rect(placeholder)
	previous_artwork = TextureRect.new()
	previous_artwork.name = "PreviousPanelArtwork"
	previous_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	previous_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previous_artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_full_rect(previous_artwork)
	previous_artwork.hide()
	artwork = TextureRect.new()
	artwork.name = "PanelArtwork"
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_full_rect(artwork)
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	petal_layer = Control.new()
	petal_layer.name = "SymbolicLilyPetals"
	_full_rect(petal_layer)
	text_box = PanelContainer.new()
	text_box.name = "StoryTextBox"
	add_child(text_box)
	text_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text_box.offset_left = 40
	text_box.offset_right = -40
	text_box.offset_top = -155
	text_box.offset_bottom = -48
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.018, .012, .026, .92)
	style.border_color = Color("563342")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	text_box.add_theme_stylebox_override("panel", style)
	var text_column := VBoxContainer.new()
	text_box.add_child(text_column)
	speaker = UI.label("", 15, Color("d9949d"))
	speaker.name = "Speaker"
	speaker.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_column.add_child(speaker)
	caption = UI.label("", 22, Color("ece0d9"))
	caption.name = "StoryCaption"
	caption.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_column.add_child(caption)
	black = ColorRect.new()
	black.name = "PanelFade"
	black.color = Color(.006, .003, .012, 1)
	_full_rect(black)
	var center := CenterContainer.new()
	center.name = "TitleCard"
	_full_rect(center)
	title_group = VBoxContainer.new()
	title_group.name = "Titles"
	title_group.custom_minimum_size.x = 600
	title_group.modulate.a = 0
	title_group.add_theme_constant_override("separation", 15)
	center.add_child(title_group)
	for item in [["RED RIDING HOOD", 36], ["THE SILENT KEEP", 19]]:
		var label := UI.label(str(item[0]), int(item[1]), Color("eee0d8"))
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_group.add_child(label)
	storyboard_note = UI.label("TEMPORARY STORYBOARD", 11, Color("817580"))
	storyboard_note.autowrap_mode = TextServer.AUTOWRAP_OFF
	storyboard_note.position = Vector2(24, 20)
	add_child(storyboard_note)
	panel_counter = UI.label("", 11, Color("b5a3ad"))
	panel_counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel_counter.custom_minimum_size = Vector2(100, 18)
	panel_counter.position = Vector2(24, 43)
	add_child(panel_counter)
	next_button = Button.new()
	next_button.name = "ContinueStory"
	next_button.text = "Continue  ·  Enter / Space / E / A"
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.add_theme_font_size_override("font_size", 12)
	next_button.add_theme_color_override("font_color", Color("e4c5cd"))
	next_button.add_theme_color_override("font_outline_color", Color("100a13"))
	next_button.add_theme_constant_override("outline_size", 3)
	next_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	next_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_child(next_button)
	next_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	next_button.offset_left = 40
	next_button.offset_right = 340
	next_button.offset_top = -35
	next_button.offset_bottom = -12
	next_button.pressed.connect(advance)
	next_button.disabled = true
	skip_button = Button.new()
	skip_button.name = "SkipOpening"
	skip_button.text = "Skip opening  ·  Esc / Start / B"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.add_theme_font_size_override("font_size", 12)
	skip_button.add_theme_color_override("font_color", Color("a897a2"))
	skip_button.add_theme_color_override("font_outline_color", Color("100a13"))
	skip_button.add_theme_constant_override("outline_size", 3)
	skip_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	skip_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_child(skip_button)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -300
	skip_button.offset_right = -24
	skip_button.offset_top = -34
	skip_button.offset_bottom = -12
	skip_button.pressed.connect(skip)

func _panel_texture(panel: OpeningStoryPanel, index: int) -> Texture2D:
	if panel.artwork != null:
		return panel.artwork
	var path := panel_art_directory.path_join("panel_%02d.png" % (index + 1))
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _show_line(line: OpeningStoryLine) -> void:
	speaker.text = line.speaker
	speaker.visible = not line.speaker.is_empty()
	caption.text = line.text
	text_box.visible = not line.text.is_empty()

func _process(delta: float) -> void:
	if finishing or not phase.begins_with("panel_") or not artwork.visible:
		return
	motion_elapsed += delta
	var progress := smoothstep(0, 1, minf(1, motion_elapsed / motion_duration))
	# Start slightly inside the viewport, then grow toward the full image fit.
	# The complete source canvas remains visible even at maximum zoom/pan.
	var end_fit := .99 if motion_pan != Vector2.ZERO else 1.0
	var fit := lerpf(end_fit / (1 + motion_zoom), end_fit, progress)
	artwork.pivot_offset = artwork.size * .5
	artwork.scale = Vector2.ONE * fit
	var margin := artwork.size * (1 - fit) * .5
	var pan := motion_pan * progress
	artwork.position = Vector2(clampf(pan.x, -margin.x, margin.x), clampf(pan.y, -margin.y, margin.y))

func _music_level(volume_db: float) -> void:
	if music_level_tween != null and music_level_tween.is_valid():
		music_level_tween.kill()
	if AudioDirector.music_tween != null and AudioDirector.music_tween.is_valid():
		AudioDirector.music_tween.kill()
	music_level_tween = TRANSITIONS.fade(self, AudioDirector.music_player, ^"volume_db", volume_db, .5)

func _stop_audio_tweens() -> void:
	if music_level_tween != null and music_level_tween.is_valid():
		music_level_tween.kill()
	if ambience_tween != null and ambience_tween.is_valid():
		ambience_tween.kill()

func _spawn_petals(count: int, where: Vector2) -> void:
	if not story_petals_enabled:
		return
	# One or two faint static petal fragments, not a Wisp/trail emitter.
	var texture := load("res://assets/game_assets/moon_wisp/lily_trail/lily_trail_07.png") as Texture2D
	for index in range(count):
		var petal := Sprite2D.new()
		petal.texture = texture
		petal.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		petal.scale = Vector2.ONE * story_petal_scale
		petal.position = size * where + Vector2(index * -20, index * 14)
		petal.modulate.a = 0
		petal_layer.add_child(petal)
		var tween := petal.create_tween().set_ignore_time_scale(true)
		tween.tween_property(petal, "modulate:a", story_petal_opacity, .3)
		tween.parallel().tween_property(petal, "position", petal.position + Vector2(-18, -12), 1.9)
		tween.tween_property(petal, "modulate:a", 0.0, .7)
		tween.tween_callback(petal.queue_free)

func _exit_tree() -> void:
	_stop_audio_tweens()

func _wait_for_continue(duration: float) -> void:
	awaiting_continue = true
	next_button.disabled = false
	if auto_advance:
		active_tween = TRANSITIONS.hold(self, duration)
		active_tween.finished.connect(advance, CONNECT_ONE_SHOT)
	await continue_requested
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

func advance() -> void:
	if finishing or not awaiting_continue:
		return
	awaiting_continue = false
	next_button.disabled = true
	continue_requested.emit()

func _play_sequence() -> void:
	for index in range(panels.size()):
		if finishing:
			return
		var panel := panels[index] as OpeningStoryPanel
		if panel == null:
			continue
		var texture := _panel_texture(panel, index)
		var crossfade := index > 0 and artwork.visible and texture != null
		if crossfade:
			previous_artwork.texture = artwork.texture
			previous_artwork.scale = artwork.scale
			previous_artwork.position = artwork.position
			previous_artwork.pivot_offset = artwork.pivot_offset
			previous_artwork.modulate = artwork.modulate
			previous_artwork.show()
		elif index > 0:
			active_tween = TRANSITIONS.fade(self, black, ^"color:a", 1.0, panel_fade_out)
			await active_tween.finished
			if finishing:
				return
		for petal in petal_layer.get_children():
			petal.queue_free()
		current_panel = index
		current_line = 0
		phase = "panel_%d" % (index + 1)
		placeholder.set("panel_kind", panel.placeholder)
		placeholder.visible = texture == null
		artwork.texture = texture
		artwork.visible = texture != null
		artwork.modulate = Color(1, .98, .96) if index == 3 else Color.WHITE
		artwork.position = Vector2.ZERO
		motion_elapsed = 0
		motion_duration = panel.hold_seconds
		for entry in panel.lines:
			var beat := entry as OpeningStoryLine
			motion_duration += beat.hold_seconds if beat.hold_seconds > 0 else panel.hold_seconds
		motion_duration = maxf(motion_duration - panel.hold_seconds, 1)
		motion_zoom = panel.still_zoom
		motion_pan = panel.still_pan
		artwork.pivot_offset = artwork.size * .5
		artwork.scale = Vector2.ONE * ((.99 if motion_pan != Vector2.ZERO else 1.0) / (1 + motion_zoom))
		_music_level(panel.music_level_db)
		storyboard_note.visible = texture == null
		storyboard_note.text = "PLACEHOLDER · " + panel.shot_label
		panel_counter.text = "%02d / %02d" % [index + 1, panels.size()]
		panel_counter.visible = texture == null
		var lines: Array[Resource] = panel.lines.duplicate()
		if lines.is_empty():
			var legacy_line := STORY_LINE.new()
			legacy_line.text = panel.caption
			lines.append(legacy_line)
		_show_line(lines[0] as OpeningStoryLine)
		if crossfade:
			artwork.modulate.a = 0
			text_box.modulate.a = 0
			active_tween = TRANSITIONS.fade(self, artwork, ^"modulate:a", 1.0, panel_fade_in)
			active_tween.parallel().tween_property(previous_artwork, "modulate:a", 0.0, panel_fade_in)
			active_tween.parallel().tween_property(text_box, "modulate:a", 1.0, panel_fade_in)
		else:
			active_tween = TRANSITIONS.fade(self, black, ^"color:a", 0.0, panel_fade_in)
		await active_tween.finished
		previous_artwork.hide()
		for line_index in range(lines.size()):
			if finishing:
				return
			current_line = line_index
			var line := lines[line_index] as OpeningStoryLine
			if line == null:
				continue
			_show_line(line)
			if index == 3 and line_index == 2:
				_spawn_petals(2, Vector2(.71, .40))
			elif index == 4 and line_index == 1:
				_spawn_petals(1, Vector2(.72, .52))
			await _wait_for_continue(line.hold_seconds if line.hold_seconds > 0 else panel.hold_seconds)
			if finishing:
				return
	if finishing:
		return
	active_tween = TRANSITIONS.fade(self, black, ^"color:a", 1.0, panel_fade_out)
	await active_tween.finished
	phase = "title"
	text_box.hide()
	next_button.hide()
	panel_counter.hide()
	storyboard_note.hide()
	active_tween = TRANSITIONS.fade(self, title_group, ^"modulate:a", 1.0, .75)
	await active_tween.finished
	active_tween = TRANSITIONS.hold(self, title_hold)
	await active_tween.finished
	active_tween = TRANSITIONS.fade(self, title_group, ^"modulate:a", 0.0, .60)
	active_tween.parallel().tween_property(wind, "volume_db", -60.0, .60)
	await active_tween.finished
	if not finishing:
		finishing = true
		phase = "loading_stage"
		_stop_audio_tweens()
		GameSession.finish_opening(false)

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		advance()
	elif event.is_action_pressed("skip_opening"):
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	if finishing:
		return
	finishing = true
	_stop_audio_tweens()
	awaiting_continue = false
	next_button.disabled = true
	continue_requested.emit()
	phase = "skipping"
	skip_button.disabled = true
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	title_group.hide()
	active_tween = TRANSITIONS.fade(self, black, ^"color:a", 1.0, .25)
	active_tween.parallel().tween_property(wind, "volume_db", -60.0, .25)
	await active_tween.finished
	GameSession.finish_opening(true)
	GameSession.notify("Find your brother.")
