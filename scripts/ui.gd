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
