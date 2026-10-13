extends CanvasLayer
@onready var hp=$HUD/HP
@onready var hp_label=$HUD/HPLabel
@onready var state=$HUD/State
@onready var boss=$HUD/BossHP
@onready var player: CharacterBody2D = get_node("../Player")
var exploration_label: Label
var dash_status: Label
var crescent_status: Label
var stage_clear_presented := false
func _ready():
	# The opening can pause gameplay before the first _process update.
	boss.hide()
	player.health_updated.connect(_hp)
	_hp(player.current_health,player.maximum_health)
	_style_bar(hp,Color("a62936"))
	_style_bar(boss,Color("c04a52"))
	_add_ability_status()
	if _is_stage_one():
		$HUD/Controls.hide()
		_add_boss_test_button()
		_add_exploration_label()

func _add_ability_status() -> void:
	var row := HBoxContainer.new()
	row.name = "AbilityCooldowns"
	row.position = Vector2(hp.position.x, hp.position.y + hp.size.y + 5.0)
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(row)
	dash_status = _ability_label("DashStatus", 190.0)
	crescent_status = _ability_label("CrescentStatus", 155.0)
	row.add_child(dash_status)
	row.add_child(crescent_status)
	# Make room between HP and the existing story/control labels in both stages.
	state.position.y += 20.0
	$HUD/Controls.position.y += 20.0
	_update_ability_status()

func _ability_label(node_name: String, width: float) -> Label:
	var label := Label.new()
	label.name = node_name
	label.custom_minimum_size = Vector2(width, 20.0)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_outline_color", Color("16121e"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _update_ability_status() -> void:
	var ready_color := Color("d2c1cc")
	var waiting_color := Color("b07987")
	dash_status.add_theme_color_override("font_color", ready_color if player.dash_available else waiting_color)
	crescent_status.add_theme_color_override("font_color", ready_color if not player.dead and player.crescent_cooldown_remaining <= 0.0 else waiting_color)
	if player.dead:
		dash_status.text = "DASH [L] —"
		crescent_status.text = "CRESCENT [R] —"
		return
	if player.dash_cooldown_remaining > 0.0:
		dash_status.text = "DASH [L] %.1fs" % (ceilf(player.dash_cooldown_remaining * 10.0) / 10.0)
	elif not player.is_on_floor() and player.air_dash_used:
		dash_status.text = "DASH [L] LAND TO REFILL"
	else:
		dash_status.text = "DASH [L] READY"
	crescent_status.text = "CRESCENT [R] %.1fs" % (ceilf(player.crescent_cooldown_remaining * 10.0) / 10.0) if player.crescent_cooldown_remaining > 0.0 else "CRESCENT [R] READY"

func _add_exploration_label() -> void:
	exploration_label = Label.new()
	exploration_label.name = "ExplorationStatus"
	exploration_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	exploration_label.offset_left = 24
	exploration_label.offset_top = -48
	exploration_label.offset_right = 675
	exploration_label.offset_bottom = -18
	exploration_label.add_theme_font_size_override("font_size", 13)
	exploration_label.add_theme_color_override("font_color", Color("d2c1cc"))
	exploration_label.add_theme_color_override("font_outline_color", Color("16121e"))
	exploration_label.add_theme_constant_override("outline_size", 3)
	exploration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(exploration_label)

func _is_stage_one() -> bool:
	# The parent path is available during _ready, before current_scene is set.
	return get_parent().scene_file_path == "res://scenes/main.tscn"

func _add_boss_test_button() -> void:
	var button := Button.new()
	button.name = "TestSkipToBossButton"
	button.text = "TEST: SKIP TO BOSS  [F7]"
	button.tooltip_text = "Testing shortcut: jump directly to Stage 2"
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = -235.0
	button.offset_top = -54.0
	button.offset_right = -20.0
	button.offset_bottom = -18.0
	button.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("451b27")
	normal.border_color = Color("a62936")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("702536")
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(_skip_to_boss_stage)
	$HUD.add_child(button)

func _input(event: InputEvent) -> void:
	if _is_stage_one() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		_skip_to_boss_stage()

func _skip_to_boss_stage() -> void:
	if player != null:
		get_tree().root.set_meta("stage_transition_health", int(player.current_health))
	var error := get_tree().change_scene_to_file("res://scenes/stage2_boss.tscn")
	if error != OK:
		push_error("Could not load Stage 2 test scene (error %s)." % error)

func _style_bar(bar,fill_color):
	var background=StyleBoxFlat.new()
	background.bg_color=Color("211b22")
	background.set_corner_radius_all(5)
	background.set_border_width_all(2)
	background.border_color=Color("53313a")
	bar.add_theme_stylebox_override("background",background)
	var fill=StyleBoxFlat.new()
	fill.bg_color=fill_color
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill",fill)
func _process(_d):
	state.text="RED HAS FALLEN" if player.dead else "THE FOREST REMEMBERS..."
	_hp(player.current_health,player.maximum_health)
	_update_ability_status()
	if exploration_label != null:
		var layout := get_parent().get_node_or_null("Stage1Layout")
		if layout != null:
			exploration_label.text = layout.exploration_status(player.global_position)
	var g=get_tree().get_first_node_in_group("boss")
	boss.visible=not _is_stage_one() and g!=null and not get_parent().get_meta("boss_intro_pending", false) and not get_parent().get_meta("ending_cutscene_active", false)
	if g:
		var maximum = g.get("maximum_health")
		boss.max_value = float(maximum) if maximum != null else 300.0
		boss.value=g.health
		if g.health <= 0 and not stage_clear_presented and not get_parent().get_meta("ending_cutscene_pending", false):
			stage_clear_presented = true
			player.play_victory("stage1_bittersweet")
func _hp(c: int,m: int) -> void:
	hp.max_value=float(m)
	hp.value=float(c)
	hp_label.text="HP  %d / %d" % [c,m]
