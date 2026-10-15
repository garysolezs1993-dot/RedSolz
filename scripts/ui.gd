extends CanvasLayer

const HUD_ART := "res://assets/ui/red_hud/"
@export_range(0.0, 1.0, 0.05) var low_health_threshold := 0.25
@export_range(0.0, 1.0, 0.05) var damage_trail_delay := 0.35
@export_range(1.0, 300.0, 1.0) var damage_trail_speed := 65.0

@onready var hp=$HUD/HP
@onready var hp_label=$HUD/HPLabel
@onready var state=$HUD/State
@onready var boss=$HUD/BossHP
@onready var player: CharacterBody2D = get_node("../Player")
var exploration_label: Label
var dash_status: Label
var crescent_status: Label
var boss_name: Label
var stage_clear_presented := false
var dash_icon: TextureRect
var crescent_icon: TextureRect
var health_frame: TextureRect
var damage_trail: ProgressBar
var damage_trail_wait := 0.0
var pulse_time := 0.0

func _ready():
	# The opening can pause gameplay before the first _process update.
	boss.hide()
	player.health_updated.connect(_hp)
	_hp(player.current_health,player.maximum_health)
	_style_bar(hp,Color("a62936"))
	_style_bar(boss,Color("c04a52"))
	_build_health_hud()
	_add_ability_status()
	$HUD/Controls.hide()
	if _is_stage_one():
		_add_exploration_label()
	else:
		$HUD/State.hide()
		boss_name = Label.new()
		boss_name.name = "BossName"
		boss_name.text = "CURSED WOLF"
		boss_name.position = boss.position - Vector2(0, 23)
		boss_name.add_theme_font_size_override("font_size", 14)
		boss_name.add_theme_color_override("font_color", Color("e0b8bf"))
		boss_name.add_theme_color_override("font_outline_color", Color("16121e"))
		boss_name.add_theme_constant_override("outline_size", 3)
		boss_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss_name.hide()
		$HUD.add_child(boss_name)

func _art_texture(file_name: String, bounds: Rect2) -> AtlasTexture:
	# Ignore exported transparent padding in Godot; source PNGs stay intact.
	var atlas := AtlasTexture.new()
	atlas.atlas = load(HUD_ART + file_name)
	atlas.region = bounds
	return atlas

func _art(node_name: String, texture: Texture2D, at: Vector2, dimensions: Vector2, parent: Control) -> TextureRect:
	var image := TextureRect.new()
	image.name = node_name
	# Set minimum-size policy BEFORE assigning a large texture. Otherwise the
	# Control clamps its rectangle to the PNG's native dimensions.
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = texture
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	image.position = at
	image.size = dimensions
	return image

func _build_health_hud() -> void:
	$HUD/Title.hide()
	hp.position = Vector2(89, 44)
	hp.custom_minimum_size = Vector2.ZERO
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("17131c")
	hp.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("b32e43")
	hp.add_theme_stylebox_override("fill", fill)
	# Remove theme minimums before sizing either bar to the frame aperture.
	hp.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	hp.size = Vector2(255, 10)
	damage_trail = ProgressBar.new()
	damage_trail.name = "DamageTrail"
	damage_trail.position = hp.position
	damage_trail.show_percentage = false
	damage_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_trail.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var trailing_fill := StyleBoxFlat.new()
	trailing_fill.bg_color = Color("a97271")
	damage_trail.add_theme_stylebox_override("fill", trailing_fill)
	damage_trail.max_value = hp.max_value
	damage_trail.value = hp.value
	$HUD.add_child(damage_trail)
	damage_trail.size = hp.size
	$HUD.move_child(damage_trail, hp.get_index())
	# HP's background must allow the delayed damage segment beneath it to show.
	var well := ColorRect.new()
	well.name = "HealthWell"
	well.color = background.bg_color
	well.position = hp.position
	well.size = hp.size
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(well)
	$HUD.move_child(well, damage_trail.get_index())
	hp.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	health_frame = _art("HealthFrame", _art_texture("health_bar_frame.png", Rect2(15, 138, 2142, 448)), Vector2(56, 15), Vector2(320, 67), $HUD)
	_art("LilyCrest", _art_texture("lily_crescent_crest.png", Rect2(239, 10, 777, 1176)), Vector2(18, 16), Vector2(44, 66), $HUD)
	hp_label.position = Vector2(93, 19)
	hp_label.size = Vector2(245, 19)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.add_theme_color_override("font_outline_color", Color("17131c"))
	hp_label.add_theme_constant_override("outline_size", 3)
	state.position = Vector2(85, 121)
	state.add_theme_font_size_override("font_size", 11)
	state.add_theme_color_override("font_color", Color("ad929d"))
	state.add_theme_color_override("font_outline_color", Color("17131c"))
	state.add_theme_constant_override("outline_size", 3)

func _add_ability_status() -> void:
	var row := HBoxContainer.new()
	row.name = "AbilityCooldowns"
	row.position = Vector2(84, 76)
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(row)
	var dash_slot := Control.new()
	dash_slot.name = "DashSlot"
	dash_slot.custom_minimum_size = Vector2(122, 40)
	dash_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dash_slot)
	var crescent_slot := Control.new()
	crescent_slot.name = "CrescentSlot"
	crescent_slot.custom_minimum_size = Vector2(150, 40)
	crescent_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(crescent_slot)
	dash_icon = _art("DashIcon", _art_texture("dash_icon.png", Rect2(207, 307, 833, 671)), Vector2.ZERO, Vector2(40, 40), dash_slot)
	crescent_icon = _art("CrescentIcon", _art_texture("crescent_slash_icon.png", Rect2(38, 30, 1178, 1177)), Vector2.ZERO, Vector2(40, 40), crescent_slot)
	dash_status = _ability_label("DashStatus", 80.0)
	crescent_status = _ability_label("CrescentStatus", 108.0)
	dash_status.position = Vector2(46, 2)
	crescent_status.position = Vector2(46, 2)
	dash_slot.add_child(dash_status)
	crescent_slot.add_child(crescent_status)
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
	dash_icon.modulate = Color.WHITE if player.dash_available else Color(0.55, 0.48, 0.52, 0.7)
	crescent_icon.modulate = Color.WHITE if not player.dead and player.crescent_cooldown_remaining <= 0.0 else Color(0.55, 0.48, 0.52, 0.7)
	if player.dead:
		dash_status.text = "DASH [L]\n—"
		crescent_status.text = "CRESCENT [R]\n—"
		return
	if player.dash_cooldown_remaining > 0.0:
		dash_status.text = "DASH [L]\n%.1fs" % (ceilf(player.dash_cooldown_remaining * 10.0) / 10.0)
	elif not player.is_on_floor() and player.air_dash_used:
		dash_status.text = "DASH [L]\nLAND FIRST"
	else:
		dash_status.text = "DASH [L]"
	crescent_status.text = "CRESCENT [R]\n%.1fs" % (ceilf(player.crescent_cooldown_remaining * 10.0) / 10.0) if player.crescent_cooldown_remaining > 0.0 else "CRESCENT [R]"

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
	_update_health_feedback(_d)
	if exploration_label != null:
		var layout := get_parent().get_node_or_null("Stage1Layout")
		if layout != null:
			exploration_label.text = layout.exploration_status(player.global_position)
	var g=get_tree().get_first_node_in_group("boss")
	boss.visible=not _is_stage_one() and g!=null and not get_parent().get_meta("boss_intro_pending", false) and not get_parent().get_meta("ending_cutscene_active", false)
	if boss_name != null:
		boss_name.visible = boss.visible
	if g:
		var maximum = g.get("maximum_health")
		boss.max_value = float(maximum) if maximum != null else 300.0
		boss.value=g.health
		if g.health <= 0 and not stage_clear_presented and not get_parent().get_meta("ending_cutscene_pending", false):
			stage_clear_presented = true
			player.play_victory("stage1_bittersweet")
func _hp(c: int,m: int) -> void:
	if damage_trail != null:
		damage_trail.max_value = float(m)
		if c < hp.value:
			damage_trail_wait = damage_trail_delay
		elif c > hp.value:
			damage_trail.value = float(c)
	hp.max_value=float(m)
	hp.value=float(c)
	hp_label.text="HP  %d / %d" % [c,m]

func _update_health_feedback(delta: float) -> void:
	damage_trail_wait = maxf(0.0, damage_trail_wait - delta)
	if damage_trail_wait <= 0.0:
		damage_trail.value = move_toward(damage_trail.value, hp.value, damage_trail_speed * delta)
	pulse_time += delta
	var low: bool = not player.dead and hp.value / maxf(hp.max_value, 1.0) <= low_health_threshold
	health_frame.modulate = Color(1.0, 0.76 + 0.18 * sin(pulse_time * 3.0), 0.8) if low else Color.WHITE
