extends CanvasLayer
@onready var hp=$HUD/HP
@onready var hp_label=$HUD/HPLabel
@onready var state=$HUD/State
@onready var boss=$HUD/BossHP
@onready var player: CharacterBody2D = get_node("../Player")
func _ready():
	player.health_updated.connect(_hp)
	_hp(player.current_health,player.maximum_health)
	_style_bar(hp,Color("a62936"))
	_style_bar(boss,Color("c04a52"))
	if _is_stage_one():
		_add_boss_test_button()

func _is_stage_one() -> bool:
	var current = get_tree().current_scene
	return current != null and current.scene_file_path == "res://scenes/main.tscn"

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
	state.text="RED HAS FALLEN — PRESS R" if player.dead else "THE FOREST REMEMBERS..."
	_hp(player.current_health,player.maximum_health)
	var g=get_tree().get_first_node_in_group("boss")
	boss.visible=g!=null
	if g:
		var maximum = g.get("maximum_health")
		boss.max_value = float(maximum) if maximum != null else 300.0
		boss.value=g.health
func _hp(c: int,m: int) -> void:
	hp.max_value=float(m)
	hp.value=float(c)
	hp_label.text="HP  %d / %d" % [c,m]
