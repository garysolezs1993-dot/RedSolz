extends Node

const TRANSITIONS := preload("res://scripts/story_transitions.gd")
const PLACEHOLDER := preload("res://scripts/boss_intro_placeholder.gd")
const UI := preload("res://scripts/menu_ui.gd")
const OPENING_GRACE := preload("res://scripts/boss_opening_grace.gd")
const PANEL_FILENAMES: Array[String] = [
	"boss_intro_01_clearing.png",
	"boss_intro_02_silent_figure.png",
	"boss_intro_03_white_lily.png",
	"boss_intro_04_recognition.png",
	"boss_intro_05_memory.png",
	"boss_intro_06_brother.png",
	"boss_intro_07_run.png",
	"boss_intro_08_curse_awakens.png",
]

@export var cutscene_enabled := true
@export var trigger_x := 1000.0
@export var battle_spacing := 360.0
@export_node_path("CharacterBody2D") var player_path := NodePath("../Player")
@export_node_path("CharacterBody2D") var boss_path := NodePath("../Stage2BossLayout/CursedWolfBoss")
@export_group("Final Panel Slots (01-08)")
@export_dir var panel_art_directory := "res://assets/cutscenes/boss_intro/panels"
@export var clearing_artwork: Texture2D
@export var silent_figure_artwork: Texture2D
@export var lily_artwork: Texture2D
@export var recognition_artwork: Texture2D
@export var memory_artwork: Texture2D
@export var brother_artwork: Texture2D
@export var run_artwork: Texture2D
@export var curse_awakens_artwork: Texture2D
@export_group("Pacing")
@export var entry_duration := 2.2
@export var silent_hold := 2.0
@export var lily_hold := 1.75
@export var recognition_hold := 1.65
@export var memory_hold := 2.5
@export var brother_hold := 2.0
@export var run_hold := 1.7
@export var title_hold := 1.8
@export var curse_hold := 1.75
@export_range(0.0, 3.0, .1) var opening_breathing_window := 1.0
@export_group("Still Presentation")
@export_range(.02, .04, .005) var still_zoom := .03
@export var still_pan_pixels := 4.0
@export var illustration_letterbox_height := 0.0

var player: CharacterBody2D
var boss: CharacterBody2D
var red_visual: AnimatedSprite2D
var wolf_visual: AnimatedSprite2D
var hurtbox: Area2D
var normal_camera: Camera2D
var camera: Camera2D
var layer: CanvasLayer
var overlay: Control
var panel_root: Control
var placeholder: Control
var artwork: TextureRect
var panel_note: Label
var black: ColorRect
var dialogue: Label
var boss_title: VBoxContainer
var skip_button: Button
var hud: Control
var boss_bar: ProgressBar
var breath: AudioStreamPlayer
var roar: AudioStreamPlayer
var burst: AnimatedSprite2D
var active_tween: Tween
var phase := "waiting"
var active := false
var completed := false
var boss_held := false
var prior_pause := false
var shake_remaining := 0.0
var shake_elapsed := 0.0
var saved: Dictionary = {}
var panel_textures: Array[Texture2D] = []
var current_shot := -1
var letterbox_bars: Array[ColorRect] = []
var music_level_tween: Tween

func _load_panel_slots() -> void:
	panel_textures = [clearing_artwork, silent_figure_artwork, lily_artwork, recognition_artwork, memory_artwork, brother_artwork, run_artwork, curse_awakens_artwork]
	# Explicit Inspector resources win; otherwise resolve only these eight names.
	# Storyboards are stored outside this directory and are never runtime textures.
	for index in range(PANEL_FILENAMES.size()):
		if panel_textures[index] != null:
			continue
		var path := panel_art_directory.path_join(PANEL_FILENAMES[index])
		if ResourceLoader.exists(path):
			panel_textures[index] = load(path) as Texture2D

func _select_shot(index: int, placeholder_kind: int = -1) -> void:
	current_shot = index
	var texture: Texture2D = panel_textures[index] if index >= 0 else null
	panel_root.scale = Vector2.ONE
	panel_root.position = Vector2.ZERO
	panel_root.pivot_offset = panel_root.size * .5
	artwork.texture = texture
	artwork.position = Vector2.ZERO
	artwork.modulate = Color(1, .98, .94) if index == 4 else Color.WHITE
	artwork.visible = texture != null
	placeholder.visible = texture == null and placeholder_kind >= 0
	if placeholder_kind >= 0:
		placeholder.set("shot", placeholder_kind)
	panel_note.visible = texture == null and placeholder_kind >= 0
	panel_root.visible = texture != null or placeholder_kind >= 0
	if texture != null and index == 7:
		panel_root.scale = Vector2.ONE * 1.015 # Cover edges during the brief shake.
	for position_index in range(letterbox_bars.size()):
		var bar := letterbox_bars[position_index]
		var height := illustration_letterbox_height if texture != null else 54.0
		bar.offset_top = 0 if position_index == 0 else -height
		bar.offset_bottom = height if position_index == 0 else 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not cutscene_enabled:
		return
	player = get_node_or_null(player_path) as CharacterBody2D
	boss = get_node_or_null(boss_path) as CharacterBody2D
	if player == null or boss == null:
		push_warning("Boss intro needs a player and a boss; leaving gameplay unchanged.")
		return
	TRANSITIONS.install_skip_action("skip_boss_intro")
	_load_panel_slots()
	red_visual = player.get_node("Visual") as AnimatedSprite2D
	wolf_visual = boss.get_node("Visual") as AnimatedSprite2D
	hurtbox = boss.get_node("Hurtbox") as Area2D
	normal_camera = player.get_node("Camera2D") as Camera2D
	hud = get_parent().get_node("UI/HUD") as Control
	boss_bar = hud.get_node("BossHP") as ProgressBar
	saved = {
		"boss_mode": boss.process_mode, "boss_layer": boss.collision_layer,
		"hurtbox_layer": hurtbox.collision_layer, "wolf_mode": wolf_visual.process_mode,
		"wolf_modulate": wolf_visual.modulate, "red_mode": red_visual.process_mode,
		"red_interpolation": player.physics_interpolation_mode,
		"hud_visible": hud.visible, "hud_modulate": hud.modulate, "bar_modulate": boss_bar.modulate,
		"region_labels": get_parent().get_node("Stage2BossLayout").get("region_labels_visible"),
	}
	# Presentation owns this temporary gate; the combat script is not changed.
	boss_held = true
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.collision_layer = 0
	hurtbox.collision_layer = 0
	wolf_visual.pause()
	wolf_visual.frame = 0
	wolf_visual.flip_h = false # Existing side view facing away from Red.
	get_parent().set_meta("boss_intro_pending", true)
	boss_bar.hide()
	AudioDirector.set_context("boss_intro")

func _physics_process(_delta: float) -> void:
	if phase != "waiting" or not boss_held or completed or not is_instance_valid(player):
		return
	if get_tree().paused or GameSession.transitioning or player.get("dead") == true:
		return
	if player.global_position.x >= trigger_x and player.is_on_floor():
		_begin()

func _begin() -> void:
	if active or completed:
		return
	active = true
	prior_pause = get_tree().paused
	get_tree().paused = true
	player.call("_cancel_action")
	player.velocity = Vector2.ZERO
	# The cinematic entry uses the continuous arena floor, even when Red reaches
	# the trigger by an upper ledge or overshoots it with a jump/dash.
	player.global_position = Vector2(minf(player.global_position.x, boss.global_position.x - battle_spacing), boss.global_position.y - 15)
	player.reset_physics_interpolation()
	boss.velocity = Vector2.ZERO
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	red_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	wolf_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	player.set("facing", 1)
	red_visual.flip_h = false
	hud.hide()
	get_parent().get_node("Stage2BossLayout").set("region_labels_visible", false)
	get_parent().get_node("Stage2BossLayout").queue_redraw()
	_build_presentation()
	call_deferred("_sequence")

func _full_rect(control: Control, parent: Node) -> void:
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_presentation() -> void:
	camera = Camera2D.new()
	camera.name = "BossIntroCamera"
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position = normal_camera.get_screen_center_position()
	camera.zoom = normal_camera.zoom
	camera.limit_left = normal_camera.limit_left
	camera.limit_right = normal_camera.limit_right
	camera.limit_top = normal_camera.limit_top
	camera.limit_bottom = normal_camera.limit_bottom
	add_child(camera)
	camera.make_current()
	layer = CanvasLayer.new()
	layer.name = "BossStoryPresentation"
	layer.layer = 105
	add_child(layer)
	overlay = Control.new()
	_full_rect(overlay, layer)
	for bottom in [false, true]:
		var bar := ColorRect.new()
		bar.color = Color(.009, .004, .015, .88)
		bar.z_index = 2 # Letterboxing belongs to the controller, above panel art.
		overlay.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
		bar.offset_top = -54 if bottom else 0
		bar.offset_bottom = 0 if bottom else 54
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letterbox_bars.append(bar)
	panel_root = Control.new()
	panel_root.name = "IllustratedPanel"
	_full_rect(panel_root, overlay)
	panel_root.hide()
	placeholder = Control.new()
	placeholder.name = "Placeholder"
	placeholder.set_script(PLACEHOLDER)
	_full_rect(placeholder, panel_root)
	artwork = TextureRect.new()
	artwork.name = "ArtworkSlot"
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_full_rect(artwork, panel_root)
	panel_note = UI.label("TEMPORARY STORYBOARD", 11, Color("8d7e88"))
	panel_note.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel_note.position = Vector2(24, 66)
	panel_root.add_child(panel_note)
	black = ColorRect.new()
	black.color = Color(.006, .003, .012, 0)
	black.z_index = 3
	_full_rect(black, overlay)
	dialogue = UI.label("", 25, Color("f0e2d9"))
	dialogue.name = "Dialogue"
	dialogue.z_index = 4
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.add_theme_color_override("font_outline_color", Color("130c17"))
	dialogue.add_theme_constant_override("outline_size", 5)
	overlay.add_child(dialogue)
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue.offset_top = -113
	dialogue.offset_bottom = -62
	var center := CenterContainer.new()
	center.z_index = 4
	_full_rect(center, overlay)
	boss_title = VBoxContainer.new()
	boss_title.name = "BossTitle"
	boss_title.custom_minimum_size.x = 500
	boss_title.add_theme_constant_override("separation", 10)
	boss_title.modulate.a = 0
	center.add_child(boss_title)
	for item in [["CURSED WOLF", 43, Color("eedbd4")], ["The Lost Brother", 18, Color("bd919d")]]:
		var caption := UI.label(str(item[0]), int(item[1]), item[2])
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_title.add_child(caption)
	skip_button = Button.new()
	skip_button.name = "SkipBossIntro"
	skip_button.z_index = 5
	skip_button.text = "Skip intro  ·  Esc / Enter / Start"
	skip_button.add_theme_font_size_override("font_size", 12)
	skip_button.add_theme_color_override("font_outline_color", Color("130c17"))
	skip_button.add_theme_constant_override("outline_size", 3)
	skip_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	overlay.add_child(skip_button)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -290
	skip_button.offset_right = -24
	skip_button.offset_top = -36
	skip_button.offset_bottom = -12
	skip_button.pressed.connect(skip)
	breath = AudioStreamPlayer.new()
	breath.name = "QuietBreathing"
	breath.bus = "SFX"
	breath.volume_db = -22
	breath.stream = load("res://audio/sfx/wolf_huff.wav")
	add_child(breath)
	roar = AudioStreamPlayer.new()
	roar.name = "CurseRoar"
	roar.bus = "SFX"
	roar.volume_db = -12
	roar.stream = load(boss.get("boss_howl_sound"))
	add_child(roar)
	burst = AnimatedSprite2D.new()
	burst.name = "CinematicCurseBurst"
	burst.sprite_frames = wolf_visual.sprite_frames
	burst.animation = "howl_aoe"
	burst.frame_changed.connect(_on_curse_frame)
	burst.scale = Vector2.ONE * .35
	burst.global_position = boss.global_position + boss.get("howl_aoe_base_position")
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	burst.z_index = 1 # Behind the wolf, as in the existing howl attack setup.
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	burst.material = material
	burst.hide()
	add_child(burst)

func _wait(duration: float) -> void:
	active_tween = TRANSITIONS.hold(self, duration)
	if panel_root.visible:
		_animate_still(active_tween, duration)
	await active_tween.finished

func _animate_still(tween: Tween, duration: float) -> void:
	var zoom := still_zoom if artwork.texture != null else .015
	tween.parallel().tween_property(panel_root, "scale", Vector2.ONE * (1 + zoom), duration)
	if artwork.texture != null:
		tween.parallel().tween_property(artwork, "position", Vector2(-still_pan_pixels, 0), duration)

func _music_level(volume_db: float) -> void:
	if music_level_tween != null and music_level_tween.is_valid():
		music_level_tween.kill()
	if AudioDirector.music_tween != null and AudioDirector.music_tween.is_valid():
		AudioDirector.music_tween.kill()
	music_level_tween = TRANSITIONS.fade(self, AudioDirector.music_player, ^"volume_db", volume_db, .3)

func _fade(target: Object, property: NodePath, value: Variant, duration: float) -> void:
	active_tween = TRANSITIONS.fade(self, target, property, value, duration)
	await active_tween.finished

func _panel(index: int, kind: int, duration: float) -> void:
	await _fade(black, ^"color:a", 1.0, .25)
	_select_shot(index, kind)
	await _fade(black, ^"color:a", 0.0, .25)
	active_tween = TRANSITIONS.hold(self, duration)
	_animate_still(active_tween, duration)
	await active_tween.finished

func _say(text: String, duration: float) -> void:
	dialogue.text = text
	dialogue.modulate.a = 0
	await _fade(dialogue, ^"modulate:a", 1.0, .2)
	await _wait(duration)
	await _fade(dialogue, ^"modulate:a", 0.0, .2)
	dialogue.text = ""

func _sequence() -> void:
	if not active:
		return
	phase = "entry"
	_select_shot(0)
	player.call("_play_visual", "run")
	var destination := Vector2(boss.global_position.x - battle_spacing, player.global_position.y)
	active_tween = TRANSITIONS.fade(self, player, ^"global_position", destination, entry_duration)
	active_tween.parallel().tween_property(camera, "position", boss.global_position + Vector2(-30, -95), entry_duration)
	active_tween.parallel().tween_property(camera, "zoom", Vector2.ONE * 1.45, entry_duration)
	if panel_root.visible:
		_animate_still(active_tween, entry_duration)
	await active_tween.finished
	player.call("_play_visual", "idle")
	phase = "silent_wolf"
	_select_shot(1)
	breath.play()
	await _wait(silent_hold)
	phase = "lily"
	_music_level(-38)
	await _panel(2, PLACEHOLDER.Shot.LILY, lily_hold)
	phase = "recognition"
	_music_level(-27)
	await _panel(3, PLACEHOLDER.Shot.RECOGNITION, recognition_hold)
	phase = "memory"
	_music_level(-33)
	await _panel(4, PLACEHOLDER.Shot.MEMORY, memory_hold)
	await _fade(black, ^"color:a", 1.0, .25)
	_select_shot(5)
	camera.position = Vector2((player.global_position.x + boss.global_position.x) * .5, 415)
	camera.zoom = Vector2.ONE * 1.18
	await _fade(black, ^"color:a", 0.0, .25)
	phase = "brother"
	_music_level(-27)
	await _say("...Brother?", brother_hold)
	phase = "wolf_turn"
	await _wait(.45)
	wolf_visual.flip_h = true
	await _wait(.2)
	phase = "run"
	if panel_textures[6] != null:
		await _fade(black, ^"color:a", 1.0, .25)
		_select_shot(6)
		await _fade(black, ^"color:a", 0.0, .25)
	else:
		_select_shot(6)
	# Muted curse tone for the lucid beat; never alter the source sprite pixels.
	await _fade(wolf_visual, ^"modulate", Color(.86, .82, .90, 1), .2)
	await _say("Run.", run_hold)
	phase = "curse_takeover"
	if panel_textures[7] != null:
		await _fade(black, ^"color:a", 1.0, .25)
	_select_shot(7)
	if panel_textures[7] != null:
		await _fade(black, ^"color:a", 0.0, .25)
	wolf_visual.modulate = saved["wolf_modulate"]
	# The still shows the curse takeover. Save the one full howl/voice for the
	# visible in-engine wolf immediately before the battle reveal.
	await _wait(curse_hold if panel_textures[7] != null else 1.15)
	phase = "return_camera"
	if panel_root.visible:
		await _fade(black, ^"color:a", 1.0, .25)
	_select_shot(-1)
	await _fade(black, ^"color:a", 0.0, .25)
	var half_view := get_viewport().get_visible_rect().size / (normal_camera.zoom * 2)
	var target := normal_camera.global_position + normal_camera.offset
	target.x = clampf(target.x, normal_camera.limit_left + half_view.x, normal_camera.limit_right - half_view.x)
	target.y = clampf(target.y, normal_camera.limit_top + half_view.y, normal_camera.limit_bottom - half_view.y)
	var howl_center := Vector2((player.global_position.x + boss.global_position.x) * .5, target.y)
	howl_center.x = clampf(howl_center.x, normal_camera.limit_left + half_view.x, normal_camera.limit_right - half_view.x)
	active_tween = TRANSITIONS.fade(self, camera, ^"position", howl_center, 1.1)
	active_tween.parallel().tween_property(camera, "zoom", normal_camera.zoom, 1.1)
	await active_tween.finished
	phase = "cinematic_howl"
	wolf_visual.play("howl")
	burst.flip_h = wolf_visual.flip_h
	burst.show()
	burst.play("howl_aoe")
	roar.play()
	shake_remaining = 0
	shake_elapsed = 0
	# Presentation plays the visuals directly; AI remains disabled, the tree
	# stays paused and the damage receivers stay gated. No attack state begins.
	var howl_frames := wolf_visual.sprite_frames
	var howl_duration := float(howl_frames.get_frame_count("howl")) / howl_frames.get_animation_speed("howl")
	await _wait(howl_duration)
	burst.hide()
	wolf_visual.play("idle")
	wolf_visual.pause()
	camera.offset = Vector2.ZERO
	shake_remaining = 0
	phase = "boss_title"
	active_tween = TRANSITIONS.fade(self, boss_title, ^"modulate:a", 1.0, .3)
	active_tween.parallel().tween_property(camera, "position", target, .3)
	await active_tween.finished
	await _wait(title_hold)
	await _fade(boss_title, ^"modulate:a", 0.0, .3)
	phase = "hud_reveal"
	get_parent().set_meta("boss_intro_pending", false)
	hud.visible = saved["hud_visible"]
	hud.modulate.a = 0
	boss_bar.show()
	boss_bar.modulate.a = 0
	active_tween = TRANSITIONS.fade(self, hud, ^"modulate", saved["hud_modulate"], .65)
	active_tween.parallel().tween_property(boss_bar, "modulate", saved["bar_modulate"], .65)
	active_tween.parallel().tween_property(overlay, "modulate:a", 0.0, .65)
	await active_tween.finished
	_finish()

func _on_curse_frame() -> void:
	# Release frame 4 matches the current 8-frame howl and its darkest sound swell.
	if active and phase == "cinematic_howl" and burst.frame == 4:
		shake_remaining = .4
		shake_elapsed = 0

func _process(delta: float) -> void:
	if not active or camera == null:
		return
	if shake_remaining > 0:
		shake_remaining = maxf(0, shake_remaining - delta)
		shake_elapsed += delta
		camera.offset = Vector2(sin(shake_elapsed * 71), cos(shake_elapsed * 53)) * 3 * (shake_remaining / .4)
	else:
		camera.offset = Vector2.ZERO
	if panel_root != null:
		panel_root.position = camera.offset if panel_root.visible and current_shot == 7 else Vector2.ZERO

func _input(event: InputEvent) -> void:
	if active and event.is_action_pressed("skip_boss_intro") and not event.is_echo():
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	if completed or not boss_held:
		return
	if not active:
		_begin()
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	player.global_position = Vector2(boss.global_position.x - battle_spacing, boss.global_position.y - 15)
	_finish()

func _finish() -> void:
	if completed:
		return
	completed = true
	active = false
	phase = "battle"
	if music_level_tween != null and music_level_tween.is_valid():
		music_level_tween.kill()
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
	if is_instance_valid(normal_camera):
		normal_camera.make_current()
		normal_camera.reset_smoothing()
		normal_camera.force_update_scroll()
	player.velocity = Vector2.ZERO
	player.call("_cancel_action")
	player.call("_play_visual", "idle")
	player.physics_interpolation_mode = saved["red_interpolation"]
	red_visual.process_mode = saved["red_mode"]
	player.reset_physics_interpolation()
	boss.velocity = Vector2.ZERO
	wolf_visual.modulate = saved["wolf_modulate"]
	wolf_visual.process_mode = saved["wolf_mode"]
	wolf_visual.flip_h = true
	wolf_visual.play("idle")
	boss.get_node("HowlAOEEffect").hide()
	boss.collision_layer = saved["boss_layer"]
	hurtbox.collision_layer = saved["hurtbox_layer"]
	if opening_breathing_window > 0:
		var grace := OPENING_GRACE.new()
		grace.name = "BossOpeningGrace"
		grace.boss = boss
		grace.restore_mode = saved["boss_mode"]
		grace.duration = opening_breathing_window
		get_parent().add_child(grace)
	else:
		boss.process_mode = saved["boss_mode"]
	boss_held = false
	hud.visible = saved["hud_visible"]
	hud.modulate = saved["hud_modulate"]
	boss_bar.modulate = saved["bar_modulate"]
	boss_bar.max_value = float(boss.get("maximum_health"))
	boss_bar.value = float(boss.get("health"))
	boss_bar.show()
	get_parent().set_meta("boss_intro_pending", false)
	get_parent().get_node("Stage2BossLayout").set("region_labels_visible", saved["region_labels"])
	get_parent().get_node("Stage2BossLayout").queue_redraw()
	AudioDirector.set_context("stage_two")
	get_tree().paused = prior_pause
	queue_free()

func _exit_tree() -> void:
	if music_level_tween != null and music_level_tween.is_valid():
		music_level_tween.kill()
	if saved.is_empty():
		return
	if active:
		get_tree().paused = prior_pause
		if is_instance_valid(normal_camera) and normal_camera.is_inside_tree():
			normal_camera.make_current()
			normal_camera.reset_smoothing()
	if boss_held and is_instance_valid(boss) and boss.is_inside_tree():
		boss.process_mode = saved["boss_mode"]
		boss.collision_layer = saved["boss_layer"]
		wolf_visual.process_mode = saved["wolf_mode"]
		wolf_visual.modulate = saved["wolf_modulate"]
		wolf_visual.play("idle")
		if is_instance_valid(hurtbox):
			hurtbox.collision_layer = saved["hurtbox_layer"]
	if not completed and is_instance_valid(player) and player.is_inside_tree():
		player.physics_interpolation_mode = saved["red_interpolation"]
		red_visual.process_mode = saved["red_mode"]
	if not completed and is_instance_valid(hud):
		hud.visible = saved.get("hud_visible", true)
		hud.modulate = saved.get("hud_modulate", Color.WHITE)
	if not completed and is_instance_valid(get_parent()):
		get_parent().set_meta("boss_intro_pending", false)
		var layout := get_parent().get_node_or_null("Stage2BossLayout")
		if layout != null:
			layout.set("region_labels_visible", saved["region_labels"])
			layout.queue_redraw()
