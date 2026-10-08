@tool
extends ScrollContainer
# Sonilo Audio Generator - main dock panel.
#
# Music: structured prompt (game type, scenario, mood, dynamic behavior).
# SFX:   prompt-first Quick SFX panel with Auto duration; structured
#        sections below act as optional refinements.
#
# Generation calls the Sonilo API (async mode + task polling); the API key
# is stored via EditorSettings project metadata (see _get_api_key()).

const Data := preload("sonilo_audio_data.gd")
const COMPONENT_SCRIPT := preload("sonilo_audio_component.gd")

const API_BASE := "https://api.sonilo.com"
# Server-registered client identifier; must stay exactly "godot".
const CLIENT_NAME := "godot"
const POLL_INTERVAL := 2.0
const POLL_TIMEOUT := 600.0
const MAX_MOODS := 3
const MAX_SEARCH_RESULTS := 12
const GENERATED_DIR := "res://sonilo/generated_audio"
const PREFABS_DIR := "res://sonilo/prefabs"

const COLOR_INFO := Color(0.55, 0.75, 0.95)
const COLOR_WARN := Color(0.92, 0.76, 0.35)
const COLOR_DIM := Color(0.62, 0.62, 0.62)
const COLOR_ACCENT := Color(0.23, 0.46, 0.85)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var is_music := true

# All creative options start unselected; generating only requires
# at least one of them (see _has_any_selection()).
var primary_game_type := ""
var sub_game_type := ""
var custom_game_type := ""

var scenario_category := ""
var scenario := ""
var custom_scenario := ""

var mood_category := ""
var moods: Array[String] = []
var custom_moods := {}
var mood_warn := false

var dynamic_behavior := ""

var music_duration := 60.0
var music_variations := 1
var music_intensity := 7
var music_bpm := 140
var music_volume := 1.0

var sfx_prompt := ""
var sfx_duration_auto := true
var sfx_duration := 1.0
var sfx_category := ""
var sfx_intensity := 5
var sfx_one_shot := true
var sfx_spatial := false
var sfx_volume := 1.0
var sfx_pitch := 1.0

var generated_prompt := ""
var generated_streams: Array[AudioStream] = []
# Original downloaded bytes per stream: {"bytes": PackedByteArray, "extension": String}.
var generated_bytes: Array[Dictionary] = []
var saved_paths: PackedStringArray = []
var is_generating := false
var status_message := ""
var status_is_warning := false

# ---------------------------------------------------------------------------
# UI plumbing
# ---------------------------------------------------------------------------

var _updaters: Array[Callable] = []
var _section_setters := {} # key -> Callable(expanded: bool)
var _preview_player: AudioStreamPlayer
var _seek_slider: HSlider
var _seek_time_label: Label
var _seek_dragging := false
var _api_key_window: Window = null
var _balance_dialog: ConfirmationDialog = null
var _last_mood_category := ""


func _refresh() -> void:
	for updater in _updaters:
		updater.call()


func _set_status(message: String, warning := false) -> void:
	status_message = message
	status_is_warning = warning


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	custom_minimum_size = Vector2(320, 0)

	_preview_player = AudioStreamPlayer.new()
	# Flip the Play/Pause button back when playback ends on its own.
	_preview_player.finished.connect(_refresh)
	add_child(_preview_player)

	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 6)
	add_child(main)

	main.add_child(_build_top_bar())
	main.add_child(_build_audio_type_section())
	main.add_child(_build_quick_sfx_panel())
	main.add_child(_build_settings_section())
	main.add_child(_build_game_type_section())
	main.add_child(_build_scenario_section())
	main.add_child(_build_mood_section())
	main.add_child(_build_dynamic_section())
	main.add_child(_build_preview_export_section())

	_refresh()


# ---------------------------------------------------------------------------
# Small widget helpers
# ---------------------------------------------------------------------------

func _label(text: String, color := Color.WHITE, bold := false, size := 0) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if color != Color.WHITE:
		lbl.add_theme_color_override("font_color", color)
	if size > 0:
		lbl.add_theme_font_size_override("font_size", size)
	return lbl


func _row(label_text: String, control: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_label(label_text, COLOR_DIM))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)
	return box


## Progress label shown under a Generate button while a generation runs.
func _generating_status_label() -> Label:
	var lbl := _label("", COLOR_INFO)
	_updaters.append(func() -> void:
		lbl.text = status_message
		lbl.visible = is_generating and status_message != "")
	return lbl


func _button(text: String, on_pressed: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	# No focus: the editor theme's focus highlight lingers after a click.
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void:
		on_pressed.call()
		_refresh())
	return btn


## Applies a flat background + font color to every button state.
func _apply_button_bg(btn: Button, bg: Color, font: Color) -> void:
	for state_name in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = bg
		if state_name == "hover":
			style.bg_color = bg.lightened(0.12)
		elif state_name == "pressed":
			style.bg_color = bg.darkened(0.2)
		style.set_corner_radius_all(3)
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
		btn.add_theme_stylebox_override(state_name, style)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, font)


## Restores the theme's default button look.
func _clear_button_bg(btn: Button) -> void:
	for state_name in ["normal", "hover", "pressed", "focus"]:
		btn.remove_theme_stylebox_override(state_name)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.remove_theme_color_override(color_name)


## Highlights a call-to-action button in the accent color (or restores
## the default look when `active` is false).
func _set_button_accent(btn: Button, active: bool) -> void:
	if active:
		_apply_button_bg(btn, COLOR_ACCENT, Color.WHITE)
	else:
		_clear_button_bg(btn)


## Collapsible section. Returns the body container; registers an expand
## setter under `key` so audio-type switching can fold/unfold it.
func _section(title: String, key: String = "") -> Array: # [container, body]
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var body := PanelContainer.new()
	var body_box := VBoxContainer.new()
	body_box.add_theme_constant_override("separation", 5)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	margin.add_child(body_box)
	body.add_child(margin)

	# Lambdas capture locals by value in GDScript, so use a mutable box.
	var state := {"expanded": true}
	var head := Button.new()
	head.flat = true
	head.focus_mode = Control.FOCUS_NONE
	head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.text = "[-]  " + title
	head.pressed.connect(func() -> void:
		state["expanded"] = not state["expanded"]
		body.visible = state["expanded"]
		head.text = ("[-]  " if state["expanded"] else "[+]  ") + title)

	container.add_child(head)
	container.add_child(body)

	if key != "":
		_section_setters[key] = func(should_expand: bool) -> void:
			state["expanded"] = should_expand
			body.visible = should_expand
			head.text = ("[-]  " if should_expand else "[+]  ") + title

	return [container, body_box]


## OptionButton that supports an unselected state: while the bound value
## is "", nothing is selected and the button reads "Select...".
func _option_button(items: Array, get_value: Callable, set_value: Callable) -> OptionButton:
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	opt.add_item("None")
	for item in items:
		opt.add_item(item)
	opt.select(-1)
	opt.text = "Select..."
	opt.item_selected.connect(func(index: int) -> void:
		# "None" (index 0) clears the value; the box goes back to "Select...".
		set_value.call("" if index == 0 else opt.get_item_text(index))
		_refresh())
	_updaters.append(func() -> void:
		var value: String = get_value.call()
		# A filled selection is tinted so it reads differently from an
		# untouched "Select..." box.
		if value == "":
			_clear_button_bg(opt)
			if opt.selected != -1:
				opt.select(-1)
			opt.text = "Select..."
			return
		_apply_button_bg(opt, COLOR_ACCENT.darkened(0.3), Color.WHITE)
		for i in opt.item_count:
			if opt.get_item_text(i) == value:
				if opt.selected != i:
					opt.select(i)
				return)
	return opt


func _repopulate_option(opt: OptionButton, items: Array) -> void:
	opt.clear()
	opt.add_item("None")
	for item in items:
		opt.add_item(item)
	opt.select(-1)
	opt.text = "Select..."


# ---------------------------------------------------------------------------
# Top bar: API key
# ---------------------------------------------------------------------------

func _get_api_key() -> String:
	return EditorInterface.get_editor_settings().get_project_metadata(
		"sonilo", "api_key", "")


func _set_api_key(key: String) -> void:
	EditorInterface.get_editor_settings().set_project_metadata(
		"sonilo", "api_key", key)


func _build_top_bar() -> Control:
	var bar := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	var key_btn := _button("Add API Key", _show_api_key_window)
	_updaters.append(func() -> void:
		key_btn.text = "API Key Set" if _get_api_key() != "" else "Add API Key")
	bar.add_child(key_btn)
	return bar


func _show_api_key_window() -> void:
	if _api_key_window != null:
		_api_key_window.popup_centered()
		return

	_api_key_window = Window.new()
	_api_key_window.title = "Sonilo API Key"
	_api_key_window.size = Vector2i(840, 380)
	_api_key_window.unresizable = true
	_api_key_window.close_requested.connect(func() -> void: _api_key_window.hide())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	box.add_child(_label("API Key", COLOR_DIM))
	var key_edit := LineEdit.new()
	key_edit.placeholder_text = "Paste your Sonilo API key..."
	key_edit.secret = true
	key_edit.text = _get_api_key()
	box.add_child(key_edit)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	var get_key_btn := Button.new()
	get_key_btn.text = "Get the Key"
	get_key_btn.tooltip_text = "https://platform.sonilo.com/"
	get_key_btn.pressed.connect(func() -> void:
		OS.shell_open("https://platform.sonilo.com/"))
	bottom.add_child(get_key_btn)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(bottom_spacer)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.custom_minimum_size = Vector2(120, 0)
	save_btn.pressed.connect(func() -> void:
		_set_api_key(key_edit.text.strip_edges())
		_set_status("API key saved." if key_edit.text.strip_edges() != "" else "API key cleared.")
		_api_key_window.hide()
		_refresh())
	bottom.add_child(save_btn)
	box.add_child(bottom)

	margin.add_child(box)
	_api_key_window.add_child(margin)
	add_child(_api_key_window)
	_api_key_window.popup_centered()


# ---------------------------------------------------------------------------
# Section 1: Audio Type
# ---------------------------------------------------------------------------

func _set_audio_type(music: bool) -> void:
	if is_music == music:
		return
	is_music = music
	# SFX is prompt-first: fold structured sections; unfold for Music.
	for key in ["game_type", "scenario", "mood", "dynamic", "settings"]:
		if _section_setters.has(key):
			_section_setters[key].call(music)


func _build_audio_type_section() -> Control:
	var parts: Array = _section("1. Audio Type")
	var body: VBoxContainer = parts[1]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var music_btn := Button.new()
	music_btn.text = "Music"
	music_btn.toggle_mode = true
	music_btn.focus_mode = Control.FOCUS_NONE
	music_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_btn.pressed.connect(func() -> void:
		_set_audio_type(true)
		_refresh())

	var sfx_btn := Button.new()
	sfx_btn.text = "Sound Effect"
	sfx_btn.toggle_mode = true
	sfx_btn.focus_mode = Control.FOCUS_NONE
	sfx_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_btn.pressed.connect(func() -> void:
		_set_audio_type(false)
		_refresh())

	_updaters.append(func() -> void:
		music_btn.set_pressed_no_signal(is_music)
		sfx_btn.set_pressed_no_signal(not is_music)
		# Selected type: white background, black text.
		if is_music:
			_apply_button_bg(music_btn, Color.WHITE, Color.BLACK)
			_clear_button_bg(sfx_btn)
		else:
			_apply_button_bg(sfx_btn, Color.WHITE, Color.BLACK)
			_clear_button_bg(music_btn))

	row.add_child(music_btn)
	row.add_child(sfx_btn)
	body.add_child(row)
	return parts[0]


# ---------------------------------------------------------------------------
# Quick SFX panel (prompt-first)
# ---------------------------------------------------------------------------

func _build_quick_sfx_panel() -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	panel.add_child(margin)

	_updaters.append(func() -> void:
		panel.visible = not is_music)

	box.add_child(_label("Quick SFX", Color.WHITE, true))

	var prompt_edit := TextEdit.new()
	prompt_edit.placeholder_text = "Describe the sound effect you need, e.g. a crisp metallic unlock sound for opening a treasure chest, with a hint of magic sparkle"
	prompt_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	prompt_edit.custom_minimum_size = Vector2(0, 56)
	prompt_edit.text_changed.connect(func() -> void:
		sfx_prompt = prompt_edit.text)
	box.add_child(prompt_edit)

	var dur_row := HBoxContainer.new()
	dur_row.add_theme_constant_override("separation", 4)
	var dur_label := _label("Duration", COLOR_DIM)
	dur_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	dur_row.add_child(dur_label)

	var auto_btn := Button.new()
	auto_btn.text = "Auto"
	auto_btn.toggle_mode = true
	auto_btn.pressed.connect(func() -> void:
		sfx_duration_auto = true
		_refresh())
	dur_row.add_child(auto_btn)

	var preset_buttons: Array[Button] = []
	for preset in [0.5, 1.0, 2.0, 3.0, 5.0]:
		var preset_btn := Button.new()
		preset_btn.text = String.num(preset) + "s"
		preset_btn.toggle_mode = true
		preset_btn.set_meta("preset", preset)
		preset_btn.pressed.connect(func() -> void:
			sfx_duration_auto = false
			sfx_duration = preset
			_refresh())
		preset_buttons.append(preset_btn)
		dur_row.add_child(preset_btn)

	var dur_spin := SpinBox.new()
	dur_spin.min_value = 0.05
	dur_spin.max_value = 30.0
	dur_spin.step = 0.1
	dur_spin.value = sfx_duration
	dur_spin.value_changed.connect(func(value: float) -> void:
		sfx_duration_auto = false
		sfx_duration = value
		_refresh())
	dur_row.add_child(dur_spin)

	_updaters.append(func() -> void:
		auto_btn.set_pressed_no_signal(sfx_duration_auto)
		for preset_btn in preset_buttons:
			var preset: float = preset_btn.get_meta("preset")
			preset_btn.set_pressed_no_signal(
				not sfx_duration_auto and absf(sfx_duration - preset) < 0.001)
		if absf(dur_spin.value - sfx_duration) > 0.001:
			dur_spin.set_value_no_signal(sfx_duration))

	box.add_child(dur_row)
	var generate_sfx_btn := _button("Generate SFX", _generate_audio)
	_updaters.append(func() -> void:
		var can_generate := not is_generating and _has_any_selection()
		generate_sfx_btn.disabled = not can_generate
		generate_sfx_btn.text = "Generating..." if is_generating else "Generate SFX"
		generate_sfx_btn.tooltip_text = ("" if can_generate
			else "Describe the sound effect or select any option first.")
		_set_button_accent(generate_sfx_btn, can_generate and _get_api_key() != ""))
	box.add_child(generate_sfx_btn)
	box.add_child(_generating_status_label())
	box.add_child(_label("Optional: refine with the collapsed sections below (category, mood, intensity...).", COLOR_DIM))
	return panel


# ---------------------------------------------------------------------------
# Section 2: Game Type
# ---------------------------------------------------------------------------

func _sub_type_resolved() -> String:
	if custom_game_type != "":
		return custom_game_type
	return sub_game_type if sub_game_type != "" else primary_game_type


func _final_game_type() -> String:
	return custom_game_type if custom_game_type != "" else _sub_type_resolved()


func _final_scenario() -> String:
	return custom_scenario if custom_scenario != "" else scenario


## Generating requires at least one creative choice - any single one
## (game type, scenario, mood, dynamic behavior, or an SFX prompt) is enough.
func _has_any_selection() -> bool:
	if not is_music and (sfx_prompt.strip_edges() != "" or sfx_category != ""):
		return true
	return (_final_game_type() != ""
		or scenario_category != "" or _final_scenario() != ""
		or not moods.is_empty()
		or dynamic_behavior != "")


func _build_game_type_section() -> Control:
	var parts: Array = _section("3. Game Type", "game_type")
	var body: VBoxContainer = parts[1]

	var sub_opt: OptionButton = _option_button(
		Data.SUB_GAME_TYPES.get(primary_game_type, []),
		func() -> String: return sub_game_type,
		func(value: String) -> void:
			sub_game_type = value)

	var primary_opt: OptionButton = _option_button(
		Data.PRIMARY_GAME_TYPES,
		func() -> String: return primary_game_type,
		func(value: String) -> void:
			primary_game_type = value
			sub_game_type = ""
			_repopulate_option(sub_opt, Data.SUB_GAME_TYPES.get(value, [])))

	var results_box := VBoxContainer.new()
	results_box.add_theme_constant_override("separation", 2)

	var search := LineEdit.new()
	search.placeholder_text = "Type to filter, or enter a custom value..."

	var rebuild_results := func() -> void:
		for child in results_box.get_children():
			child.queue_free()
		var query := search.text.strip_edges()
		if query == "":
			return
		var exact := false
		var shown := 0
		for primary in Data.PRIMARY_GAME_TYPES:
			var entries: Array = [[primary, ""]]
			for sub in Data.SUB_GAME_TYPES.get(primary, []):
				entries.append([primary, sub])
			for entry in entries:
				var display: String = entry[1] if entry[1] != "" else entry[0]
				if display.findn(query) == -1:
					continue
				if display.nocasecmp_to(query) == 0:
					exact = true
				if shown >= MAX_SEARCH_RESULTS:
					continue
				shown += 1
				var text: String = entry[0] if entry[1] == "" else entry[0] + "  >  " + entry[1]
				var pick_primary: String = entry[0]
				var pick_sub: String = entry[1]
				results_box.add_child(_button(text, func() -> void:
					primary_game_type = pick_primary
					sub_game_type = pick_sub
					custom_game_type = ""
					_repopulate_option(sub_opt, Data.SUB_GAME_TYPES.get(pick_primary, []))
					search.text = ""
					search.text_changed.emit("")))
		if not exact:
			results_box.add_child(_button("Use \"%s\" as custom game type" % query, func() -> void:
				custom_game_type = query
				search.text = ""
				search.text_changed.emit("")))

	search.text_changed.connect(func(_t: String) -> void:
		rebuild_results.call())

	body.add_child(_row("Search / Custom", search))
	body.add_child(results_box)
	body.add_child(_row("Primary Game Type", primary_opt))
	body.add_child(_row("Sub Game Type", sub_opt))

	var selected_row := HBoxContainer.new()
	var selected_label := _label("", Color.WHITE, true)
	selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var clear_btn := _button("Clear Custom", func() -> void:
		custom_game_type = "")
	_updaters.append(func() -> void:
		var suffix := "  [Custom]" if custom_game_type != "" else ""
		var shown_type := _final_game_type()
		selected_label.text = "Selected: " + (shown_type if shown_type != "" else "(none)") + suffix
		clear_btn.visible = custom_game_type != "")
	selected_row.add_child(selected_label)
	selected_row.add_child(clear_btn)
	body.add_child(selected_row)
	return parts[0]


# ---------------------------------------------------------------------------
# Section 3: Scenario
# ---------------------------------------------------------------------------

func _build_scenario_section() -> Control:
	var parts: Array = _section("4. Scenario", "scenario")
	var body: VBoxContainer = parts[1]

	var detail_opt: OptionButton = _option_button(
		Data.SCENARIO_DETAILS.get(scenario_category, []),
		func() -> String: return scenario,
		func(value: String) -> void: scenario = value)

	var category_opt: OptionButton = _option_button(
		Data.SCENARIO_CATEGORIES,
		func() -> String: return scenario_category,
		func(value: String) -> void:
			scenario_category = value
			scenario = ""
			_repopulate_option(detail_opt, Data.SCENARIO_DETAILS.get(value, [])))

	var results_box := VBoxContainer.new()
	results_box.add_theme_constant_override("separation", 2)

	var search := LineEdit.new()
	search.placeholder_text = "Type to filter, or enter a custom value..."

	var rebuild_results := func() -> void:
		for child in results_box.get_children():
			child.queue_free()
		var query := search.text.strip_edges()
		if query == "":
			return
		var exact := false
		var shown := 0
		for category in Data.SCENARIO_CATEGORIES:
			for detail in Data.SCENARIO_DETAILS[category]:
				if detail.findn(query) == -1:
					continue
				if detail.nocasecmp_to(query) == 0:
					exact = true
				if shown >= MAX_SEARCH_RESULTS:
					continue
				shown += 1
				var pick_category: String = category
				var pick_detail: String = detail
				results_box.add_child(_button(category + "  >  " + detail, func() -> void:
					scenario_category = pick_category
					scenario = pick_detail
					custom_scenario = ""
					_repopulate_option(detail_opt, Data.SCENARIO_DETAILS.get(pick_category, []))
					search.text = ""
					search.text_changed.emit("")))
		if not exact:
			results_box.add_child(_button("Use \"%s\" as custom scenario" % query, func() -> void:
				custom_scenario = query
				search.text = ""
				search.text_changed.emit("")))

	search.text_changed.connect(func(_t: String) -> void:
		rebuild_results.call())

	body.add_child(_row("Search / Custom", search))
	body.add_child(results_box)
	body.add_child(_row("Scenario Category", category_opt))
	body.add_child(_row("Scenario", detail_opt))

	var selected_row := HBoxContainer.new()
	var selected_label := _label("", Color.WHITE, true)
	selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var clear_btn := _button("Clear Custom", func() -> void:
		custom_scenario = "")
	_updaters.append(func() -> void:
		var suffix := "  [Custom]" if custom_scenario != "" else ""
		var shown_scenario := _final_scenario()
		selected_label.text = "Selected: " + (shown_scenario if shown_scenario != "" else "(none)") + suffix
		clear_btn.visible = custom_scenario != "")
	selected_row.add_child(selected_label)
	selected_row.add_child(clear_btn)
	body.add_child(selected_row)
	return parts[0]


# ---------------------------------------------------------------------------
# Section 4: Mood / Atmosphere
# ---------------------------------------------------------------------------

func _try_add_mood(mood: String) -> bool:
	if mood == "" or moods.has(mood):
		return false
	if moods.size() >= MAX_MOODS:
		mood_warn = true
		return false
	moods.append(mood)
	mood_warn = false
	return true


func _remove_mood(mood: String) -> void:
	moods.erase(mood)
	custom_moods.erase(mood)
	mood_warn = false


func _build_mood_section() -> Control:
	var parts: Array = _section("5. Mood / Atmosphere", "mood")
	var body: VBoxContainer = parts[1]

	var count_label := _label("", Color.WHITE, true)
	_updaters.append(func() -> void:
		count_label.text = "Selected Moods (%d/%d):" % [moods.size(), MAX_MOODS])
	body.add_child(count_label)

	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	_updaters.append(func() -> void:
		for child in chips.get_children():
			child.queue_free()
		if moods.is_empty():
			# Autowrap labels collapse to ~1 character width inside a flow
			# container, rendering vertically - keep this one single-line.
			var none_label := _label("None selected.", COLOR_DIM)
			none_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			chips.add_child(none_label)
			return
		for mood in moods:
			var badge := " [Custom]" if custom_moods.has(mood) else ""
			var chip_mood := mood
			chips.add_child(_button(mood + badge + "  x", func() -> void:
				_remove_mood(chip_mood))))
	body.add_child(chips)

	var warn_label := _label("You can select up to 3 mood tags. Remove one first.", COLOR_WARN)
	_updaters.append(func() -> void:
		warn_label.visible = mood_warn)
	body.add_child(warn_label)

	# Search / custom
	var results_box := VBoxContainer.new()
	results_box.add_theme_constant_override("separation", 2)
	var search := LineEdit.new()
	search.placeholder_text = "Type to filter, or enter a custom value..."

	var rebuild_results := func() -> void:
		for child in results_box.get_children():
			child.queue_free()
		var query := search.text.strip_edges()
		if query == "":
			return
		var exact := false
		var shown := 0
		var seen := {}
		for category in Data.MOOD_CATEGORIES:
			for mood in Data.MOOD_DETAILS[category]:
				if mood.findn(query) == -1 or seen.has(mood):
					continue
				seen[mood] = true
				if mood.nocasecmp_to(query) == 0:
					exact = true
				if shown >= MAX_SEARCH_RESULTS:
					continue
				shown += 1
				var pick_mood: String = mood
				results_box.add_child(_button(mood, func() -> void:
					if moods.has(pick_mood):
						_remove_mood(pick_mood)
					else:
						_try_add_mood(pick_mood)))
		if not exact:
			results_box.add_child(_button("Add \"%s\" as custom mood" % query, func() -> void:
				if _try_add_mood(query):
					custom_moods[query] = true
					search.text = ""
					search.text_changed.emit("")))

	search.text_changed.connect(func(_t: String) -> void:
		rebuild_results.call())

	body.add_child(_row("Search / Custom", search))
	body.add_child(results_box)

	body.add_child(_row("Mood Category", _option_button(
		Data.MOOD_CATEGORIES,
		func() -> String: return mood_category,
		func(value: String) -> void: mood_category = value)))

	var grid := GridContainer.new()
	grid.columns = 3
	_updaters.append(func() -> void:
		if _last_mood_category != mood_category:
			_last_mood_category = mood_category
			for child in grid.get_children():
				child.queue_free()
			for mood in Data.MOOD_DETAILS.get(mood_category, []):
				var toggle := Button.new()
				toggle.text = mood
				toggle.toggle_mode = true
				toggle.clip_text = true
				toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var toggle_mood: String = mood
				toggle.pressed.connect(func() -> void:
					if moods.has(toggle_mood):
						_remove_mood(toggle_mood)
					else:
						_try_add_mood(toggle_mood)
					_refresh())
				grid.add_child(toggle)
		for child in grid.get_children():
			if child is Button:
				child.set_pressed_no_signal(moods.has(child.text)))
	body.add_child(grid)
	return parts[0]


# ---------------------------------------------------------------------------
# Section 5: Dynamic Behavior
# ---------------------------------------------------------------------------

func _build_dynamic_section() -> Control:
	var parts: Array = _section("6. Dynamic Behavior", "dynamic")
	var body: VBoxContainer = parts[1]
	body.add_child(_row("Behavior", _option_button(
		Data.DYNAMIC_BEHAVIORS,
		func() -> String: return dynamic_behavior,
		func(value: String) -> void: dynamic_behavior = value)))
	return parts[0]


# ---------------------------------------------------------------------------
# Section 6: Audio Settings
# ---------------------------------------------------------------------------

func _spin(min_v: float, max_v: float, step: float, get_value: Callable, set_value: Callable) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.step = step
	spin.value = get_value.call()
	spin.value_changed.connect(func(value: float) -> void:
		set_value.call(value))
	_updaters.append(func() -> void:
		if absf(spin.value - float(get_value.call())) > 0.0001:
			spin.set_value_no_signal(get_value.call()))
	return spin


func _check(text: String, get_value: Callable, set_value: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(pressed: bool) -> void:
		set_value.call(pressed))
	_updaters.append(func() -> void:
		check.set_pressed_no_signal(get_value.call()))
	return check


func _build_settings_section() -> Control:
	var parts: Array = _section("2. Audio Settings", "settings")
	var body: VBoxContainer = parts[1]

	# Music settings
	var music_box := VBoxContainer.new()
	music_box.add_theme_constant_override("separation", 5)
	# Duration as minutes + seconds; total clamped to 5s - 6min.
	var dur_box := HBoxContainer.new()
	dur_box.add_theme_constant_override("separation", 4)
	var min_spin := SpinBox.new()
	min_spin.min_value = 0
	min_spin.max_value = 6
	min_spin.step = 1
	min_spin.suffix = "min"
	min_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sec_spin := SpinBox.new()
	sec_spin.min_value = 0
	sec_spin.max_value = 59
	sec_spin.step = 1
	sec_spin.suffix = "s"
	sec_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dur_box.add_child(min_spin)
	dur_box.add_child(sec_spin)

	var apply_duration := func() -> void:
		music_duration = clampf(min_spin.value * 60.0 + sec_spin.value, 5.0, 360.0)
		_refresh()
	min_spin.value_changed.connect(func(_v: float) -> void: apply_duration.call())
	sec_spin.value_changed.connect(func(_v: float) -> void: apply_duration.call())
	_updaters.append(func() -> void:
		var total := int(music_duration)
		var minutes := floori(total / 60.0)
		var seconds := total % 60
		if int(min_spin.value) != minutes:
			min_spin.set_value_no_signal(minutes)
		if int(sec_spin.value) != seconds:
			sec_spin.set_value_no_signal(seconds))
	music_box.add_child(_row("Duration (5s - 6min)", dur_box))
	music_box.add_child(_row("Number of Results", _spin(1, 10, 1,
		func() -> float: return music_variations,
		func(v: float) -> void: music_variations = int(v))))
	body.add_child(music_box)

	# SFX refinements (duration + generate live in the Quick SFX panel)
	var sfx_box := VBoxContainer.new()
	sfx_box.add_theme_constant_override("separation", 5)
	sfx_box.add_child(_label("Refinements (optional - appended to the prompt)", Color.WHITE, true))
	sfx_box.add_child(_row("SFX Category", _option_button(
		Data.SFX_CATEGORIES,
		func() -> String: return sfx_category,
		func(value: String) -> void: sfx_category = value)))
	sfx_box.add_child(_row("Intensity (1-10)", _spin(1, 10, 1,
		func() -> float: return sfx_intensity,
		func(v: float) -> void: sfx_intensity = int(v))))
	sfx_box.add_child(_check("One-Shot",
		func() -> bool: return sfx_one_shot,
		func(v: bool) -> void: sfx_one_shot = v))
	sfx_box.add_child(_check("Spatial Audio",
		func() -> bool: return sfx_spatial,
		func(v: bool) -> void: sfx_spatial = v))
	sfx_box.add_child(_row("Volume", _spin(0, 1, 0.01,
		func() -> float: return sfx_volume,
		func(v: float) -> void: sfx_volume = v)))
	sfx_box.add_child(_row("Pitch", _spin(0.1, 3, 0.05,
		func() -> float: return sfx_pitch,
		func(v: float) -> void: sfx_pitch = v)))
	body.add_child(sfx_box)

	_updaters.append(func() -> void:
		music_box.visible = is_music
		sfx_box.visible = not is_music)
	return parts[0]


# ---------------------------------------------------------------------------
# Prompt building + mock generation
# ---------------------------------------------------------------------------

func _build_prompt() -> String:
	var lines: PackedStringArray = []
	lines.append("Audio Type: " + ("Music" if is_music else "Sound Effect"))

	# The free-text description leads the prompt for sound effects.
	var trimmed := sfx_prompt.strip_edges()
	if not is_music and trimmed != "":
		lines.append("Description: " + trimmed)

	# Only selected options make it into the prompt.
	var game_type := _final_game_type()
	if game_type != "":
		lines.append("Game Type: " + game_type)
		if primary_game_type != "" and primary_game_type != game_type:
			lines.append("Primary Game Type: " + primary_game_type)
	if scenario_category != "":
		lines.append("Scenario Category: " + scenario_category)
	var final_scenario := _final_scenario()
	if final_scenario != "":
		lines.append("Scenario: " + final_scenario)
	if not moods.is_empty():
		lines.append("Mood: " + ", ".join(moods))
	if dynamic_behavior != "":
		lines.append("Dynamic Behavior: " + dynamic_behavior)

	if is_music:
		lines.append("Duration: " + String.num(music_duration) + "s")
	else:
		lines.append("Duration: Auto" if sfx_duration_auto else "Duration: " + String.num(sfx_duration) + "s")
		lines.append("Intensity: %d/10" % sfx_intensity)
		lines.append("Volume: %.2f" % sfx_volume)
		if sfx_category != "":
			lines.append("SFX Category: " + sfx_category)
		lines.append("Spatial Audio: " + str(sfx_spatial))
		lines.append("Pitch: %.2f" % sfx_pitch)

	return "\n".join(lines)


func _generate_audio() -> void:
	if is_generating:
		return
	var api_key := _get_api_key()
	if api_key == "":
		_set_status("Add your Sonilo API key first (button at the top).", true)
		_show_api_key_window()
		return

	generated_prompt = _build_prompt()
	generated_streams.clear()
	generated_bytes.clear()
	saved_paths.clear()
	is_generating = true
	_set_status("Contacting Sonilo API...")
	_refresh()

	if is_music:
		await _run_music_generation(api_key)
	else:
		await _run_sfx_generation(api_key)

	is_generating = false
	_refresh()


func _run_music_generation(api_key: String) -> void:
	# One task per requested result; Sonilo bills per generated second.
	# output_format=wav (16-bit PCM) requires mode=async and lets Godot
	# decode the download directly.
	var task_ids: Array[String] = []
	for i in music_variations:
		var fields := {
			"prompt": generated_prompt,
			"duration": str(int(music_duration)),
			"mode": "async",
			"output_format": "wav",
		}
		var response := await _post_form(api_key, "/v1/text-to-music", fields)
		if response.has("error"):
			_set_status("Sonilo error: " + str(response["error"]), true)
			break
		if not response.has("task_id"):
			_set_status("Unexpected Sonilo response (no task_id).", true)
			break
		task_ids.append(str(response["task_id"]))
		_set_status("Generating music... (%d/%d tasks started)" % [task_ids.size(), music_variations])
		_refresh()
	if not task_ids.is_empty():
		await _collect_tasks(api_key, task_ids)


func _run_sfx_generation(api_key: String) -> void:
	var fields := {
		"prompt": generated_prompt,
		"audio_format": "wav",
	}
	# The API documents duration as required (1-180s). Auto omits it and,
	# if the API rejects that, retries with a short default.
	if not sfx_duration_auto:
		fields["duration"] = str(maxi(1, int(ceilf(sfx_duration))))
	var response := await _post_form(api_key, "/v1/text-to-sfx", fields)
	if response.has("error") and sfx_duration_auto:
		fields["duration"] = "2"
		response = await _post_form(api_key, "/v1/text-to-sfx", fields)
	if response.has("error"):
		_set_status("Sonilo error: " + str(response["error"]), true)
		return
	if not response.has("task_id"):
		_set_status("Unexpected Sonilo response (no task_id).", true)
		return
	_set_status("Generating sound effect...")
	_refresh()
	await _collect_tasks(api_key, [str(response["task_id"])])


## Polls every task until it succeeds or fails, then downloads and decodes
## the resulting audio into generated_streams.
func _collect_tasks(api_key: String, task_ids: Array) -> void:
	var headers := PackedStringArray(["Authorization: Bearer " + api_key])
	var pending: Array = task_ids.duplicate()
	var audio_entries: Array = []
	var failure := ""
	var deadline := Time.get_ticks_msec() + int(POLL_TIMEOUT * 1000.0)

	while not pending.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(POLL_INTERVAL).timeout
		var still_pending: Array = []
		for task_id in pending:
			var reply: Array = await _await_request(
				API_BASE + "/v1/tasks/" + str(task_id), headers,
				HTTPClient.METHOD_GET, PackedByteArray(), 30.0)
			var data := _parse_json_reply(reply)
			if data.has("error"):
				# 4xx is fatal; anything else is treated as transient.
				if str(data["error"]).begins_with("HTTP 4"):
					failure = str(data["error"])
				else:
					still_pending.append(task_id)
				continue
			match str(data.get("status", "")):
				"succeeded":
					var audio_value: Variant = data.get("audio")
					if audio_value is Array:
						audio_entries.append_array(audio_value)
					elif audio_value is Dictionary:
						audio_entries.append(audio_value)
				"failed":
					var error_value: Variant = data.get("error", {})
					if error_value is Dictionary:
						failure = str(error_value.get("message", "generation failed"))
						if str(error_value.get("code", "")) == "payment_required":
							_show_insufficient_balance(failure)
					else:
						failure = str(error_value)
				_:
					still_pending.append(task_id)
		pending = still_pending
		if not pending.is_empty():
			_set_status("Generating... (%d task(s) remaining)" % pending.size())
			_refresh()

	if not pending.is_empty():
		_set_status("Timed out waiting for Sonilo generation.", true)
		return
	if audio_entries.is_empty():
		_set_status("Sonilo generation failed: "
			+ (failure if failure != "" else "no audio returned"), true)
		return

	_set_status("Downloading %d audio file(s)..." % audio_entries.size())
	_refresh()
	for entry in audio_entries:
		if not (entry is Dictionary):
			continue
		var url := str(entry.get("url", ""))
		if url == "":
			continue
		var reply: Array = await _await_request(
			url, PackedStringArray(), HTTPClient.METHOD_GET, PackedByteArray(), 120.0)
		if reply[0] != HTTPRequest.RESULT_SUCCESS or reply[1] >= 400:
			failure = "download failed (HTTP %d)" % reply[1]
			continue
		var content_type := str(entry.get("content_type", ""))
		var stream := _bytes_to_stream(reply[3], content_type)
		if stream != null:
			generated_streams.append(stream)
			generated_bytes.append({
				"bytes": reply[3],
				"extension": _raw_extension(content_type, reply[3]),
			})
		else:
			var extension := _raw_extension(content_type, reply[3])
			var raw_path := _save_raw_audio(reply[3], extension)
			failure = ("unexpected audio format (%s); raw file saved to %s"
				% [extension, raw_path])

	if generated_streams.is_empty():
		if failure == "":
			failure = "could not decode the returned audio"
		_set_status("Sonilo generation failed: " + failure, true)
	else:
		_set_status("Generated %d audio stream(s). Preview or save below."
			% generated_streams.size())


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

## POSTs multipart/form-data fields and returns the parsed JSON response
## (or {"error": <message>}).
func _post_form(api_key: String, path: String, fields: Dictionary) -> Dictionary:
	var boundary := "SoniloBoundary%d" % Time.get_ticks_usec()
	var body := PackedByteArray()
	for field_name in fields:
		body.append_array(("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n"
			% [boundary, field_name, str(fields[field_name])]).to_utf8_buffer())
	body.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())
	var headers := PackedStringArray([
		"Authorization: Bearer " + api_key,
		"Content-Type: multipart/form-data; boundary=" + boundary,
	])
	var reply: Array = await _await_request(
		API_BASE + path, headers, HTTPClient.METHOD_POST, body, 30.0)
	return _parse_json_reply(reply)


## Client-identification headers sent with every Sonilo API request.
## X-Sonilo-Client-Version comes from plugin.cfg; omitted if unavailable
## or longer than 64 characters.
func _client_headers() -> PackedStringArray:
	var headers := PackedStringArray(["X-Sonilo-Client: " + CLIENT_NAME])
	var cfg := ConfigFile.new()
	var cfg_path: String = (get_script() as Script).resource_path.get_base_dir() \
		.path_join("plugin.cfg")
	if cfg.load(cfg_path) == OK:
		var version := str(cfg.get_value("plugin", "version", ""))
		if version != "" and version.length() <= 64:
			headers.append("X-Sonilo-Client-Version: " + version)
	return headers


## Runs one HTTPRequest and returns [result, response_code, headers, body].
## Requests to the Sonilo API (not e.g. audio download URLs) also get the
## client-identification headers.
func _await_request(url: String, headers: PackedStringArray, method: int,
		body: PackedByteArray, timeout: float) -> Array:
	if url.begins_with(API_BASE):
		headers = headers.duplicate()
		headers.append_array(_client_headers())
	var req := HTTPRequest.new()
	req.timeout = timeout
	add_child(req)
	var err := req.request_raw(url, headers, method, body)
	if err != OK:
		req.queue_free()
		return [err, 0, PackedStringArray(), PackedByteArray()]
	var reply: Array = await req.request_completed
	req.queue_free()
	return reply


func _parse_json_reply(reply: Array) -> Dictionary:
	if reply[0] != HTTPRequest.RESULT_SUCCESS:
		return {"error": "network error (result %d)" % reply[0]}
	var code: int = reply[1]
	var parsed: Variant = JSON.parse_string(reply[3].get_string_from_utf8())
	var data: Dictionary = parsed if parsed is Dictionary else {}
	if code >= 400:
		var message := ""
		var api_code := str(data.get("code", ""))
		var error_value: Variant = data.get("error")
		if error_value is Dictionary:
			message = str(error_value.get("message", ""))
			if api_code == "":
				api_code = str(error_value.get("code", ""))
		elif data.has("message"):
			message = str(data["message"])
		if message == "":
			message = "request failed"
		if code == 402 or api_code == "payment_required":
			_show_insufficient_balance(message)
		return {"error": "HTTP %d - %s" % [code, message]}
	return data


## Popup shown when the Sonilo API reports an insufficient balance
## ({"code": "payment_required"} / HTTP 402).
func _show_insufficient_balance(message: String) -> void:
	if _balance_dialog == null:
		_balance_dialog = ConfirmationDialog.new()
		_balance_dialog.title = "Sonilo - Insufficient Balance"
		_balance_dialog.ok_button_text = "Open Sonilo Platform"
		_balance_dialog.cancel_button_text = "Close"
		_balance_dialog.confirmed.connect(func() -> void:
			OS.shell_open("https://platform.sonilo.com/"))
		add_child(_balance_dialog)
	if _balance_dialog.visible:
		return
	_balance_dialog.dialog_text = (message
		+ "\n\nYour Sonilo balance is not enough for this generation."
		+ "\nTop up on the Sonilo platform, then try again.")
	_balance_dialog.popup_centered()


# ---------------------------------------------------------------------------
# Audio decoding
# ---------------------------------------------------------------------------

## Builds an AudioStream from downloaded bytes (WAV / MP3 / Ogg Vorbis).
## Returns null for formats Godot cannot decode at runtime (e.g. AAC).
func _bytes_to_stream(bytes: PackedByteArray, content_type: String) -> AudioStream:
	if bytes.size() < 12:
		return null
	if bytes.slice(0, 4) == "RIFF".to_ascii_buffer():
		return _wav_to_stream(bytes)
	if bytes.slice(0, 4) == "OggS".to_ascii_buffer():
		return AudioStreamOggVorbis.load_from_buffer(bytes)
	var looks_mp3 := (bytes.slice(0, 3) == "ID3".to_ascii_buffer()
		or (bytes[0] == 0xFF and (bytes[1] & 0xE0) == 0xE0))
	if looks_mp3 or content_type.contains("mpeg") or content_type.contains("mp3"):
		var mp3 := AudioStreamMP3.new()
		mp3.data = bytes
		return mp3
	return null


## Minimal RIFF/WAV parser (16-bit PCM only, which is what Sonilo returns
## for wav output).
func _wav_to_stream(bytes: PackedByteArray) -> AudioStreamWAV:
	var pos := 12
	var format_code := 0
	var channels := 1
	var mix_rate := 44100
	var bits := 0
	var data := PackedByteArray()
	while pos + 8 <= bytes.size():
		var chunk_id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var chunk_size := bytes.decode_u32(pos + 4)
		var chunk_start := pos + 8
		if chunk_id == "fmt " and chunk_start + 16 <= bytes.size():
			format_code = bytes.decode_u16(chunk_start)
			channels = bytes.decode_u16(chunk_start + 2)
			mix_rate = bytes.decode_u32(chunk_start + 4)
			bits = bytes.decode_u16(chunk_start + 14)
		elif chunk_id == "data":
			data = bytes.slice(chunk_start, mini(chunk_start + chunk_size, bytes.size()))
		pos = chunk_start + chunk_size + (chunk_size & 1)
	if data.is_empty() or format_code != 1 or bits != 16:
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = channels >= 2
	stream.data = data
	return stream


# ---------------------------------------------------------------------------
# Raw audio files - Sonilo is asked for WAV, which Godot decodes directly;
# these helpers keep/save the downloaded bytes as-is.
# ---------------------------------------------------------------------------

func _raw_extension(content_type: String, bytes: PackedByteArray) -> String:
	if bytes.size() >= 12:
		if bytes.slice(0, 4) == "RIFF".to_ascii_buffer():
			return "wav"
		if bytes.slice(0, 4) == "OggS".to_ascii_buffer():
			return "ogg"
		if bytes.slice(4, 8) == "ftyp".to_ascii_buffer():
			return "m4a"
		if bytes.slice(0, 3) == "ID3".to_ascii_buffer() \
				or (bytes[0] == 0xFF and (bytes[1] & 0xE0) == 0xE0):
			return "mp3"
	if content_type.contains("wav"):
		return "wav"
	if content_type.contains("mpeg") or content_type.contains("mp3"):
		return "mp3"
	if content_type.contains("aac") or content_type.contains("mp4"):
		return "m4a"
	if content_type.contains("flac"):
		return "flac"
	return "bin"


## Writes undecodable audio bytes next to the generated resources so the
## user still gets the file. Returns the saved path.
func _save_raw_audio(bytes: PackedByteArray, extension: String) -> String:
	DirAccess.make_dir_recursive_absolute(GENERATED_DIR)
	var base_name := _generated_base_name()
	var asset_name := base_name
	var suffix := 1
	while FileAccess.file_exists("%s/%s.%s" % [GENERATED_DIR, asset_name, extension]):
		asset_name = "%s_%d" % [base_name, suffix]
		suffix += 1
	var path := "%s/%s.%s" % [GENERATED_DIR, asset_name, extension]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return path
	file.store_buffer(bytes)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	return path


# ---------------------------------------------------------------------------
# Save / naming
# ---------------------------------------------------------------------------

func _sanitize_name(value: String) -> String:
	if value == "":
		return "Unnamed"
	var result := ""
	for character in value:
		if character.is_valid_identifier() or character.is_valid_int():
			result += character
		elif character in [" ", "-", "/", "_"]:
			result += "_"
	while result.contains("__"):
		result = result.replace("__", "_")
	result = result.trim_prefix("_").trim_suffix("_")
	return result if result != "" else "Unnamed"


func _generated_base_name() -> String:
	if is_music:
		return "Sonilo_Music_" + _sanitize_name(_final_scenario())
	return "Sonilo_SFX_" + _sanitize_name(sfx_category)


## Saves the downloaded audio files exactly as Sonilo returned them
## (normally WAV) under res://sonilo/generated_audio.
func _save_generated_audio_files() -> void:
	if generated_bytes.is_empty():
		_set_status("Nothing to save. Generate audio first.", true)
		return
	var paths := PackedStringArray()
	for entry in generated_bytes:
		paths.append(_save_raw_audio(entry["bytes"], entry["extension"]))
	_set_status("Saved: " + ", ".join(paths))


## Saves every generated stream as a .tres resource under
## res://sonilo/generated_audio. Cached after the first save.
func _save_generated_streams() -> bool:
	if generated_streams.is_empty():
		_set_status("Nothing to save. Generate audio first.", true)
		return false
	if not saved_paths.is_empty():
		return true

	DirAccess.make_dir_recursive_absolute(GENERATED_DIR)
	var base_name := _generated_base_name()
	var suffix := 1
	for stream in generated_streams:
		var asset_name := base_name
		while FileAccess.file_exists("%s/%s.tres" % [GENERATED_DIR, asset_name]):
			asset_name = "%s_%d" % [base_name, suffix]
			suffix += 1
		var path := "%s/%s.tres" % [GENERATED_DIR, asset_name]
		var err := ResourceSaver.save(stream, path)
		if err != OK:
			_set_status("Failed to save resource (error %d)." % err, true)
			saved_paths.clear()
			return false
		stream.take_over_path(path)
		saved_paths.append(path)
	EditorInterface.get_resource_filesystem().scan()
	_set_status("Saved: " + ", ".join(saved_paths))
	return true


# ---------------------------------------------------------------------------
# Section 7: Preview & Export
# ---------------------------------------------------------------------------

func _build_preview_export_section() -> Control:
	var parts: Array = _section("7. Preview & Export")
	var body: VBoxContainer = parts[1]

	var generate_btn := _button("Generate", _generate_audio)
	_updaters.append(func() -> void:
		var can_generate := not is_generating and _has_any_selection()
		generate_btn.disabled = not can_generate
		generate_btn.text = ("Generating..." if is_generating
			else ("Generate Music" if is_music else "Generate SFX"))
		generate_btn.tooltip_text = ("" if can_generate
			else "Select at least one option (game type, scenario, mood...) first.")
		_set_button_accent(generate_btn, can_generate and _get_api_key() != ""))
	body.add_child(generate_btn)
	body.add_child(_generating_status_label())

	body.add_child(_label("Generated Sonilo Prompt:", Color.WHITE, true))
	var prompt_edit := TextEdit.new()
	prompt_edit.editable = false
	prompt_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	prompt_edit.custom_minimum_size = Vector2(0, 150)
	_updaters.append(func() -> void:
		var text := generated_prompt if generated_prompt != "" else "(No prompt generated yet.)"
		if prompt_edit.text != text:
			prompt_edit.text = text)
	body.add_child(prompt_edit)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)

	var play_btn := _button("Play", func() -> void:
		if generated_streams.is_empty():
			return
		if _preview_player.playing and not _preview_player.stream_paused:
			_preview_player.stream_paused = true
			_set_status("Preview paused.")
		elif _preview_player.playing:
			_preview_player.stream_paused = false
			_set_status("Playing preview...")
		else:
			_preview_player.stream = generated_streams[0]
			_preview_player.volume_db = linear_to_db(maxf(0.0001, music_volume if is_music else sfx_volume))
			_preview_player.pitch_scale = 1.0 if is_music else sfx_pitch
			_preview_player.stream_paused = false
			_preview_player.play()
			_set_status("Playing preview..."))
	var stop_btn := _button("Stop", func() -> void:
		_preview_player.stop()
		_preview_player.stream_paused = false
		_set_status(""))
	for btn in [play_btn, stop_btn]:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(btn)
	body.add_child(row1)

	var seek_row := HBoxContainer.new()
	seek_row.add_theme_constant_override("separation", 6)
	_seek_slider = HSlider.new()
	_seek_slider.min_value = 0.0
	_seek_slider.max_value = 0.001
	_seek_slider.step = 0.01
	_seek_slider.editable = false
	_seek_slider.focus_mode = Control.FOCUS_NONE
	_seek_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seek_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_seek_slider.drag_started.connect(func() -> void:
		_seek_dragging = true)
	_seek_slider.drag_ended.connect(func(value_changed: bool) -> void:
		_seek_dragging = false
		if value_changed:
			_preview_seek(_seek_slider.value))
	# Mouse wheel changes the value without a drag.
	_seek_slider.value_changed.connect(func(value: float) -> void:
		if not _seek_dragging:
			_preview_seek(value))
	seek_row.add_child(_seek_slider)
	_seek_time_label = _label("0:00 / 0:00", COLOR_DIM)
	# No autowrap: the HBox would otherwise crush it to one char per line.
	_seek_time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	seek_row.add_child(_seek_time_label)
	body.add_child(seek_row)

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 4)
	var save_audio_btn := _button("Save Audio File", func() -> void:
		_save_generated_audio_files())
	var save_tres_btn := _button("Save as .tres", func() -> void:
		_save_generated_streams())
	save_audio_btn.tooltip_text = "Save the audio exactly as Sonilo returned it (wav)."
	save_tres_btn.tooltip_text = "Save as a Godot AudioStream .tres resource\n(used by the prefab / node integration below)."
	for btn in [save_audio_btn, save_tres_btn]:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		save_row.add_child(btn)
	body.add_child(save_row)

	_updaters.append(func() -> void:
		var previewing := _preview_player.playing and not _preview_player.stream_paused
		play_btn.text = "Pause" if previewing else "Play"
		if is_inside_tree():
			play_btn.icon = get_theme_icon("Pause" if previewing else "Play", "EditorIcons")
			stop_btn.icon = get_theme_icon("Stop", "EditorIcons"))

	var integrate_row := HBoxContainer.new()
	integrate_row.add_theme_constant_override("separation", 4)
	var add_btn := _button("Add to Selected Node", func() -> void:
		if not _save_generated_streams():
			return
		var stream: AudioStream = generated_streams[0]
		var selected := EditorInterface.get_selection().get_selected_nodes()
		if selected.is_empty():
			_set_status("No node selected. Select a node in the scene tree first.", true)
			return
		var target: Node = selected[0]
		var scene_root := EditorInterface.get_edited_scene_root()
		if scene_root == null:
			_set_status("No scene is open.", true)
			return

		var player := _new_player_node()
		player.name = "SoniloAudio"
		_configure_player(player, stream)
		target.add_child(player)
		player.owner = scene_root

		var comp := _make_component(player, stream)
		target.add_child(comp)
		comp.owner = scene_root

		_set_status("Sonilo audio added under '%s'." % target.name))
	add_btn.tooltip_text = ("Add a configured audio player plus a SoniloAudioComponent\n"
		+ "under the node selected in the scene tree.")
	var prefab_btn := _button("Create Prefab", func() -> void:
		if not _save_generated_streams():
			return
		var stream: AudioStream = generated_streams[0]
		DirAccess.make_dir_recursive_absolute(PREFABS_DIR)

		var base_name := _generated_base_name()
		var asset_name := base_name
		var suffix := 1
		while FileAccess.file_exists("%s/%s.tscn" % [PREFABS_DIR, asset_name]):
			asset_name = "%s_%d" % [base_name, suffix]
			suffix += 1

		var root := Node.new()
		root.name = asset_name
		var player := _new_player_node()
		player.name = "SoniloAudio"
		_configure_player(player, stream)
		root.add_child(player)
		player.owner = root
		var comp := _make_component(player, stream)
		root.add_child(comp)
		comp.owner = root

		var packed := PackedScene.new()
		var pack_err := packed.pack(root)
		if pack_err != OK:
			_set_status("Failed to pack the scene (error %d)." % pack_err, true)
			root.free()
			return
		var path := "%s/%s.tscn" % [PREFABS_DIR, asset_name]
		var save_err := ResourceSaver.save(packed, path)
		root.free()
		if save_err != OK:
			_set_status("Failed to save the scene (error %d)." % save_err, true)
			return
		EditorInterface.get_resource_filesystem().scan()
		_set_status("Prefab scene created: " + path))
	prefab_btn.tooltip_text = "Save a self-contained audio scene under %s." % PREFABS_DIR
	for btn in [add_btn, prefab_btn]:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		integrate_row.add_child(btn)
	body.add_child(integrate_row)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	var copy_btn := _button("Copy Generated Prompt", func() -> void:
		DisplayServer.clipboard_set(generated_prompt)
		_set_status("Prompt copied to clipboard."))
	var clear_btn := _button("Clear", func() -> void:
		_preview_player.stop()
		generated_prompt = ""
		generated_streams.clear()
		generated_bytes.clear()
		saved_paths.clear()
		_set_status(""))
	for btn in [copy_btn, clear_btn]:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(btn)
	body.add_child(row2)

	var status_label := _label("", COLOR_INFO)
	_updaters.append(func() -> void:
		status_label.text = status_message
		# While generating, progress is shown under the Generate button.
		status_label.visible = status_message != "" and not is_generating
		status_label.add_theme_color_override("font_color",
			COLOR_WARN if status_is_warning else COLOR_INFO))
	body.add_child(status_label)

	_updaters.append(func() -> void:
		var has_audio := not generated_streams.is_empty()
		play_btn.disabled = not has_audio
		stop_btn.disabled = not has_audio
		save_audio_btn.disabled = generated_bytes.is_empty()
		save_tres_btn.disabled = not has_audio
		add_btn.disabled = not has_audio
		prefab_btn.disabled = not has_audio
		_seek_slider.editable = has_audio
		copy_btn.disabled = generated_prompt == "")
	return parts[0]


func _process(_delta: float) -> void:
	if _seek_slider == null:
		return
	var stream: AudioStream = generated_streams[0] if not generated_streams.is_empty() else null
	var length: float = stream.get_length() if stream != null else 0.0
	_seek_slider.max_value = maxf(length, 0.001)
	var pos: float = _seek_slider.value
	if not _seek_dragging:
		pos = _preview_player.get_playback_position() if _preview_player.playing else 0.0
		_seek_slider.set_value_no_signal(clampf(pos, 0.0, _seek_slider.max_value))
	_seek_time_label.text = "%s / %s" % [_fmt_time(pos), _fmt_time(length)]


func _preview_seek(position_sec: float) -> void:
	if generated_streams.is_empty():
		return
	if _preview_player.playing:
		# Works both while playing and while stream-paused.
		_preview_player.seek(position_sec)
	else:
		_preview_player.stream = generated_streams[0]
		_preview_player.volume_db = linear_to_db(maxf(0.0001, music_volume if is_music else sfx_volume))
		_preview_player.pitch_scale = 1.0 if is_music else sfx_pitch
		_preview_player.stream_paused = false
		_preview_player.play(position_sec)
		_set_status("Playing preview...")
		_refresh()


func _fmt_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]


# ---------------------------------------------------------------------------
# Node / scene integration helpers (used by Section 7's buttons)
# ---------------------------------------------------------------------------

func _configure_player(player: Node, stream: AudioStream) -> void:
	# set() is used because the player may be AudioStreamPlayer / 2D / 3D.
	player.set("stream", stream)
	player.set("autoplay", false)
	player.set("volume_db", linear_to_db(maxf(0.0001, music_volume if is_music else sfx_volume)))
	player.set("pitch_scale", 1.0 if is_music else sfx_pitch)


func _make_component(player: Node, stream: AudioStream) -> Node:
	var comp := Node.new()
	comp.name = "SoniloAudioComponent"
	comp.set_script(COMPONENT_SCRIPT)
	comp.set("audio_type", "Music" if is_music else "SoundEffect")
	comp.set("primary_game_type", primary_game_type)
	comp.set("sub_game_type", _sub_type_resolved())
	comp.set("final_game_type", _final_game_type())
	comp.set("scenario_category", scenario_category)
	comp.set("scenario", _final_scenario())
	comp.set("mood_tags", PackedStringArray(moods))
	comp.set("dynamic_behavior", dynamic_behavior)
	comp.set("is_spatial_audio", (not is_music) and sfx_spatial)
	comp.set("intensity", music_intensity if is_music else sfx_intensity)
	comp.set("bpm", music_bpm if is_music else 0)
	comp.set("volume", music_volume if is_music else sfx_volume)
	comp.set("pitch", 1.0 if is_music else sfx_pitch)
	comp.set("audio_stream", stream)
	comp.set("audio_player", player)
	return comp


func _new_player_node() -> Node:
	# Spatial SFX -> 3D positional player; everything else non-positional.
	if not is_music and sfx_spatial:
		return AudioStreamPlayer3D.new()
	return AudioStreamPlayer.new()
