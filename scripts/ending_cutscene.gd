extends Node

const TRANSITIONS := preload("res://scripts/story_transitions.gd")
const UI := preload("res://scripts/menu_ui.gd")
const KEEP := preload("res://scripts/ending_keep_placeholder.gd")
const TRANSFORMATION_GLOW := preload("res://shaders/ending_transformation_glow.gdshader")
const CURSE_PROJECTILE := preload("res://scripts/ending_curse_projectile.gd")
const LILY_TRANSFORMATION := preload("res://scripts/ending_lily_transformation.gd")
const CURSE_IMPACT_ROOT := "res://assets/cutscenes/ending/curse_impact/"
const CURSE_IMPACT_CORES: Array[Vector2] = [Vector2(162.9,263.7),Vector2(196.1,366.0),Vector2(239.3,303.0),Vector2(205.6,373.3),Vector2(265.5,363.1),Vector2(161.3,366.1),Vector2(123.3,379.3),Vector2(83.9,382.9)]
const PANEL_NAMES: Array[String] = ["ending_01_lucidity.png", "ending_02_keep_reacts.png", "ending_03_sacrifice.png", "ending_04_final_words.png", "ending_05_white_lily.png", "ending_06_guardian_birth.png", "ending_07_guardian_touch.png", "ending_08_together.png", "ending_guardian_approach.png"]
signal continue_requested

@export var cutscene_enabled := true
@export_group("Replaceable Story Artwork")
@export_dir var panel_art_directory := "res://assets/cutscenes/ending/panels"
@export var lucidity_artwork: Texture2D
@export var keep_reacts_artwork: Texture2D
@export var sacrifice_artwork: Texture2D
@export var final_words_artwork: Texture2D
@export var lily_artwork: Texture2D
@export var guardian_birth_artwork: Texture2D
@export var guardian_touch_artwork: Texture2D
@export var together_artwork: Texture2D
@export var guardian_approach_artwork: Texture2D
@export_group("Replaceable Visual Effects")
@export var lily_texture: Texture2D
@export var curse_strike_texture: Texture2D
@export var curse_strike_scale := .35
@export_group("Pacing")
## Disabled: dialogue and story panels wait for Continue. Animation still runs normally.
@export var auto_advance := false
@export_range(.5, 5, .1) var dialogue_hold := 2.3
@export_range(.1, 3, .1) var collapse_hold := .6
@export_range(.5, 4, .1) var approach_duration := 2.0
@export_range(.3, 4, .1) var quiet_hold := 1.2
@export_range(.5, 6, .1) var guardian_formation_duration := 3.0
@export_range(.5, 4, .1) var guardian_touch_duration := 2.3
@export_range(.5, 5, .1) var wide_hold := 2.0
@export_group("Illustration Presentation")
@export_range(.3, .5, .05) var panel_transition_duration := .35
@export_range(.02, .04, .005) var panel_zoom := .03
@export_range(2.5, 5, .1) var sacrifice_panel_hold := 3.0
@export var staging_x := 1860.0
@export_group("Ending Curse Cinematic")
@export_range(.7, .8, .01) var curse_travel_fraction := .75
@export_range(.5, 1, .05) var curse_travel_duration := .78
@export_range(.2, .5, .05) var curse_intercept_duration := .35
@export_range(12, 24, 1) var curse_impact_fps := 16.0
@export_range(.1, .4, .01) var curse_impact_scale := .24
@export_range(.08, .2, .01) var sacrifice_picture_delay := .12
@export_group("Guardian Lily Transformation")
@export_range(.5, 4, .1) var transformation_lily_build_duration := 1.8
@export_range(.5, 3, .1) var transformation_linger_duration := 1.0
@export var transformation_lily_radius := Vector2(125,55)
@export_range(.05, .25, .01) var transformation_lily_scale := .12
@export_range(.1, .6, .02) var transformation_lily_opacity := .34

var player: CharacterBody2D
var boss: CharacterBody2D
var red_visual: AnimatedSprite2D
var wolf_visual: AnimatedSprite2D
var normal_camera: Camera2D
var camera: Camera2D
var hud: Control
var world: Node2D
var keep_visual: Node2D
var transformation_lilies: Node2D
var curse_projectile: Node2D
var curse_impact: AnimatedSprite2D
var curse_impact_frames: SpriteFrames
var curse_target_position := Vector2.ZERO
var artwork: TextureRect
var outgoing_artwork: TextureRect
var panel_backdrop: ColorRect
var panel_motion: Tween
var black: ColorRect
var flash: ColorRect
var dialogue: VBoxContainer
var dialogue_backdrop: ColorRect
var speaker: Label
var words: Label
var panel_note: Label
var skip_button: Button
var next_button: Button
var awaiting_continue := false
var breath: AudioStreamPlayer
var active_tween: Tween
var saved: Dictionary = {}
var textures: Array[Texture2D] = []
var phase := "waiting"
var active := false
var finishing := false
var previous_pause := false
var red_landing := Vector2.ZERO
var wolf_landing := Vector2.ZERO
var shake_left := 0.0
var shake_clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent().get_node_or_null("Player") as CharacterBody2D
	boss = get_parent().get_node_or_null("Stage2BossLayout/CursedWolfBoss") as CharacterBody2D
	if not cutscene_enabled or player == null or boss == null:
		return
	red_visual = player.get_node("Visual")
	wolf_visual = boss.get_node("Visual")
	normal_camera = player.get_node("Camera2D")
	hud = get_parent().get_node("UI/HUD")
	boss.set("ending_managed", true)
	boss.defeated.connect(_on_defeated)
	get_parent().set_meta("ending_cutscene_pending", true)
	_install_controls()
	curse_impact_frames = SpriteFrames.new()
	curse_impact_frames.remove_animation("default")
	curse_impact_frames.add_animation("impact")
	curse_impact_frames.set_animation_loop("impact",false)
	curse_impact_frames.set_animation_speed("impact",curse_impact_fps)
	for index in range(8):
		curse_impact_frames.add_frame("impact",load(CURSE_IMPACT_ROOT + "cursed_attack_%02d.png" % index))
	textures = [lucidity_artwork, keep_reacts_artwork, sacrifice_artwork, final_words_artwork, lily_artwork, guardian_birth_artwork, guardian_touch_artwork, together_artwork, guardian_approach_artwork]
	for index in range(textures.size()):
		var path := panel_art_directory.path_join(PANEL_NAMES[index])
		if textures[index] == null and ResourceLoader.exists(path):
			textures[index] = load(path) as Texture2D

func _install_controls() -> void:
	# Continue and Skip have separate bindings; Enter/Space must never skip.
	for action in ["continue_ending","skip_ending"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
	for code in [KEY_ENTER,KEY_SPACE,KEY_E]:
		var key := InputEventKey.new()
		key.keycode = code
		InputMap.action_add_event("continue_ending",key)
	var accept := InputEventJoypadButton.new()
	accept.device = -1
	accept.button_index = JOY_BUTTON_A
	InputMap.action_add_event("continue_ending",accept)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	InputMap.action_add_event("skip_ending",escape)
	for code in [JOY_BUTTON_START,JOY_BUTTON_B]:
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = code
		InputMap.action_add_event("skip_ending",button)

func _landing(body: CharacterBody2D, feet_offset: float) -> Vector2:
	if body.is_on_floor():
		return body.global_position
	var feet := body.global_position + Vector2(0, feet_offset)
	var query := PhysicsRayQueryParameters2D.create(feet - Vector2(0,2), feet + Vector2(0,1000), 1, [player.get_rid(), boss.get_rid()])
	var hit := body.get_world_2d().direct_space_state.intersect_ray(query)
	var floor_y := float(hit.position.y) if not hit.is_empty() else float(boss.get("arena_floor_y"))
	return Vector2(body.global_position.x, floor_y - feet_offset)

func _on_defeated() -> void:
	if active or finishing:
		return
	if player.dead or GameSession.death_in_progress:
		# A simultaneous player defeat keeps the existing game-over path.
		boss.set("ending_managed", false)
		get_parent().set_meta("ending_cutscene_pending", false)
		return
	active = true
	phase = "collapse"
	previous_pause = get_tree().paused
	red_landing = _landing(player, 15)
	wolf_landing = _landing(boss, 0)
	saved = {"player_mode": player.process_mode, "boss_mode": boss.process_mode,
		"red_mode": red_visual.process_mode, "wolf_mode": wolf_visual.process_mode,
		"red_interpolation": player.physics_interpolation_mode,
		"boss_interpolation": boss.physics_interpolation_mode,
		"invulnerable": player.get("invulnerable"), "hud_visible": hud.visible, "music_context": AudioDirector.current_context,
		"region_labels": get_parent().get_node("Stage2BossLayout").get("region_labels_visible")}
	saved["wolf_z_index"] = wolf_visual.z_index
	saved["wolf_material"] = wolf_visual.material
	saved["wolf_modulate"] = wolf_visual.modulate
	GameSession.ending_in_progress = true
	get_parent().set_meta("ending_cutscene_active", true)
	player.call("_cancel_action")
	_clear_combat_projectiles()
	player.set("invulnerable", 10000.0)
	player.velocity = Vector2.ZERO
	boss.velocity = Vector2.ZERO
	player.process_mode = Node.PROCESS_MODE_DISABLED
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	boss.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	red_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	wolf_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	wolf_visual.pause()
	player.call("_play_visual", "idle")
	hud.hide()
	get_parent().get_node("Stage2BossLayout").set("region_labels_visible", false)
	get_parent().get_node("Stage2BossLayout").queue_redraw()
	if GameSession.toast_tween != null and GameSession.toast_tween.is_valid():
		GameSession.toast_tween.kill()
	GameSession.toast.modulate.a = 0
	AudioDirector.fade_for_death(.8)
	_build()
	get_tree().paused = true
	call_deferred("_sequence")

func _clear_combat_projectiles() -> void:
	# Defeat can occur inside a projectile's damage callback. Hide immediately,
	# then free safely, before the paused world can freeze its hit/flight pose.
	for projectile in get_tree().get_nodes_in_group("red_projectiles"):
		if projectile is CanvasItem:
			projectile.hide()
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		projectile.queue_free()

func _full(control: Control, parent: Node) -> void:
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build() -> void:
	world = Node2D.new()
	world.name = "EndingVisualsOnly"
	add_child(world)
	keep_visual = Node2D.new()
	keep_visual.set_script(KEEP)
	keep_visual.position = Vector2(2280,335)
	keep_visual.z_index = 0
	keep_visual.hide()
	world.add_child(keep_visual)
	camera = Camera2D.new()
	camera.name = "EndingCamera"
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position = normal_camera.get_screen_center_position()
	camera.zoom = normal_camera.zoom
	add_child(camera)
	camera.make_current()
	breath = AudioStreamPlayer.new()
	breath.bus = "SFX"
	breath.volume_db = -22
	breath.stream = load("res://audio/sfx/wolf_huff.wav")
	add_child(breath)
	var layer := CanvasLayer.new()
	layer.layer = 105
	add_child(layer)
	var screen := Control.new()
	_full(screen, layer)
	panel_backdrop = ColorRect.new()
	panel_backdrop.color = Color("09070d")
	_full(panel_backdrop, screen)
	panel_backdrop.hide()
	outgoing_artwork = TextureRect.new()
	outgoing_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	outgoing_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	outgoing_artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_full(outgoing_artwork, screen)
	outgoing_artwork.hide()
	artwork = TextureRect.new()
	artwork.name = "EndingArtwork"
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_full(artwork, screen)
	artwork.hide()
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		screen.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_bottom = 36 if top else 0
		bar.offset_top = 0 if top else -36
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_backdrop = ColorRect.new()
	dialogue_backdrop.color = Color(.035,.02,.045,.8)
	dialogue_backdrop.modulate.a = 0
	screen.add_child(dialogue_backdrop)
	dialogue_backdrop.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_backdrop.offset_left = 64
	dialogue_backdrop.offset_right = -64
	dialogue_backdrop.offset_top = -145
	dialogue_backdrop.offset_bottom = -55
	dialogue_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue = VBoxContainer.new()
	dialogue.modulate.a = 0
	screen.add_child(dialogue)
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue.offset_left = 80
	dialogue.offset_right = -80
	dialogue.offset_top = -140
	dialogue.offset_bottom = -55
	speaker = UI.label("",15,Color("c7b5c9"))
	words = UI.label("",23,Color("eee5e2"))
	for label in [speaker,words]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_outline_color",Color("100a15"))
		label.add_theme_constant_override("outline_size",4)
		dialogue.add_child(label)
	black = ColorRect.new()
	black.color = Color(0.01,0.006,0.02,0)
	_full(black,screen)
	flash = ColorRect.new()
	flash.color = Color(1,.87,.92,0)
	_full(flash,screen)
	panel_note = UI.label("ENDING PROTOTYPE — COLLAPSE",11,Color("918491"))
	panel_note.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel_note.position = Vector2(24,12)
	screen.add_child(panel_note)
	next_button = Button.new()
	next_button.name = "ContinueEnding"
	next_button.text = "Continue  ·  Enter / Space / E / A"
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.add_theme_font_size_override("font_size",12)
	next_button.add_theme_color_override("font_color",Color("e4c5cd"))
	next_button.add_theme_color_override("font_outline_color",Color("100a13"))
	next_button.add_theme_constant_override("outline_size",3)
	next_button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	next_button.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
	screen.add_child(next_button)
	next_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	next_button.offset_left = 40
	next_button.offset_right = 340
	next_button.offset_top = -35
	next_button.offset_bottom = -12
	next_button.disabled = true
	next_button.pressed.connect(advance)
	skip_button = Button.new()
	skip_button.text = "Skip ending  ·  Esc / Start / B"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.add_theme_font_size_override("font_size",12)
	skip_button.add_theme_color_override("font_color",Color("a897a2"))
	skip_button.add_theme_color_override("font_outline_color",Color("100a13"))
	skip_button.add_theme_constant_override("outline_size",3)
	skip_button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	skip_button.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
	screen.add_child(skip_button)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -310
	skip_button.offset_right = -24
	skip_button.offset_top = -30
	skip_button.offset_bottom = -8
	skip_button.pressed.connect(skip)

func _wait(seconds: float) -> void:
	active_tween = TRANSITIONS.hold(self,seconds)
	await active_tween.finished

func _wait_for_continue(duration: float) -> void:
	# Ignore held/repeated keys while the preceding fade settles.
	await _wait(.15)
	if finishing or not active:
		return
	awaiting_continue = true
	next_button.disabled = false
	var timeout: Tween
	if auto_advance:
		timeout = TRANSITIONS.hold(self,duration)
		active_tween = timeout
		timeout.finished.connect(advance,CONNECT_ONE_SHOT)
	await continue_requested
	if timeout != null and timeout.is_valid():
		timeout.kill()

func advance() -> void:
	if not active or finishing or not awaiting_continue:
		return
	awaiting_continue = false
	next_button.disabled = true
	continue_requested.emit()

func _fade(target: Object, property: NodePath, value: Variant, seconds: float) -> void:
	active_tween = TRANSITIONS.fade(self,target,property,value,seconds)
	await active_tween.finished

func _say(who: String, text: String, hold: float = -1) -> void:
	speaker.text = who
	speaker.visible = not who.is_empty()
	words.text = text
	active_tween = TRANSITIONS.fade(self,dialogue,^"modulate:a",1.0,.18)
	active_tween.parallel().tween_property(dialogue_backdrop,"modulate:a",1.0,.18)
	await active_tween.finished
	await _wait_for_continue(dialogue_hold if hold < 0 else hold)
	active_tween = TRANSITIONS.fade(self,dialogue,^"modulate:a",0.0,.18)
	active_tween.parallel().tween_property(dialogue_backdrop,"modulate:a",0.0,.18)
	await active_tween.finished

func _shot(index: int, label: String, immediate: bool = false) -> void:
	phase = label
	var next_texture: Texture2D = textures[index] if index >= 0 else null
	var crossfade: bool = not immediate and artwork.visible and next_texture != null
	if panel_motion != null and panel_motion.is_valid():
		panel_motion.kill()
	if crossfade:
		outgoing_artwork.texture = artwork.texture
		outgoing_artwork.scale = artwork.scale
		outgoing_artwork.position = artwork.position
		outgoing_artwork.modulate.a = 1
		outgoing_artwork.show()
	elif not immediate and (artwork.visible or next_texture != null):
		await _fade(black,^"color:a",1.0,panel_transition_duration)
	if immediate:
		black.color.a = 0
		outgoing_artwork.hide()
	artwork.texture = next_texture
	artwork.visible = next_texture != null
	panel_backdrop.visible = next_texture != null
	artwork.scale = Vector2.ONE * (1.0-panel_zoom)
	artwork.position = artwork.size * panel_zoom * .5
	artwork.modulate.a = 0 if crossfade else 1
	panel_note.visible = next_texture == null
	panel_note.text = "ENDING PROTOTYPE — " + label.to_upper().replace("_"," ")
	if crossfade:
		active_tween = TRANSITIONS.fade(self,outgoing_artwork,^"modulate:a",0.0,panel_transition_duration)
		active_tween.parallel().tween_property(artwork,"modulate:a",1.0,panel_transition_duration)
		await active_tween.finished
	elif black.color.a > 0:
		await _fade(black,^"color:a",0.0,panel_transition_duration)
	outgoing_artwork.hide()
	if next_texture != null:
		# A 3% grow towards fitted size preserves every pixel of the full composition.
		var motion_seconds := 4.0
		if index == 2:
			motion_seconds = sacrifice_panel_hold + 1.4
		elif index == 3:
			motion_seconds = 4 * (dialogue_hold+.36) + .8 + quiet_hold
		elif index == 5:
			motion_seconds = guardian_formation_duration + quiet_hold
		elif index == 6:
			motion_seconds = guardian_touch_duration + 3.36 + quiet_hold
		elif index == 7:
			motion_seconds = 1.5 + wide_hold + 5 * (dialogue_hold + .36) + quiet_hold
		panel_motion = TRANSITIONS.fade(self,artwork,^"scale",Vector2.ONE,motion_seconds)
		panel_motion.parallel().tween_property(artwork,"position",Vector2.ZERO,motion_seconds)

func _impact_sound() -> void:
	var impact := AudioStreamPlayer.new()
	impact.bus = "SFX"
	impact.stream = load("res://audio/sfx/execution.wav")
	impact.volume_db = -15
	impact.pitch_scale = .8
	add_child(impact)
	impact.finished.connect(impact.queue_free)
	impact.play()
func _petals(where: Vector2, count: int) -> void:
	for index in range(count):
		var petal: Node2D
		if lily_texture != null:
			var sprite := Sprite2D.new()
			sprite.texture = lily_texture
			sprite.scale = Vector2.ONE * .055
			petal = sprite
		else:
			# Detached petals keep the one-lily identity; no repeated whole flowers.
			var fragment := Polygon2D.new()
			fragment.polygon = PackedVector2Array([Vector2(0,-6),Vector2(-3,0),Vector2(0,5),Vector2(3,0)])
			fragment.color = Color("e1e8f1")
			fragment.rotation = index * .7
			petal = fragment
		var unlit := CanvasItemMaterial.new()
		unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		petal.material = unlit
		petal.position = where + Vector2((index % 3 - 1) * 15, (index / 3) * 8)
		petal.modulate.a = 0
		petal.z_index = 4
		world.add_child(petal)
		var tween := petal.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
		tween.tween_property(petal,"modulate:a",.32,.3)
		tween.parallel().tween_property(petal,"position",petal.position + Vector2((index % 2 * 2 - 1) * 35,-70-index*5),1.7)
		tween.tween_property(petal,"modulate:a",0.0,.8)
		tween.tween_callback(petal.queue_free)

func _make_curse_projectile(origin: Vector2) -> void:
	curse_projectile = Node2D.new()
	curse_projectile.name = "KeepCurseTravelOnly"
	curse_projectile.position = origin
	curse_projectile.z_index = 6
	curse_projectile.rotation = (curse_target_position-origin).angle()
	if curse_strike_texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = curse_strike_texture
		sprite.scale = Vector2.ONE * curse_strike_scale
		curse_projectile.add_child(sprite)
	else:
		curse_projectile.set_script(CURSE_PROJECTILE)
	world.add_child(curse_projectile)

func _align_curse_impact() -> void:
	if not is_instance_valid(curse_impact):
		return
	var index := clampi(curse_impact.frame,0,7)
	var texture := curse_impact_frames.get_frame_texture("impact",index)
	var offset := texture.get_size() * .5 - CURSE_IMPACT_CORES[index]
	if curse_impact.flip_h:
		offset.x *= -1
	curse_impact.offset = offset

func _play_curse_attack() -> void:
	# World-space travel is aimed at Red, never at the brother.
	phase = "curse_launch"
	curse_target_position = player.global_position + Vector2(0,-23)
	var origin := keep_visual.global_position + Vector2(0,-75)
	_make_curse_projectile(origin)
	var stop_short := origin.lerp(curse_target_position,curse_travel_fraction)
	active_tween = TRANSITIONS.fade(self,curse_projectile,^"global_position",stop_short,curse_travel_duration)
	active_tween.set_trans(Tween.TRANS_LINEAR)
	await active_tween.finished
	# No arrival or burst in the wide shot: cut while the projectile is mid-flight.
	curse_projectile.hide()
	phase = "curse_intercept"
	camera.position = player.global_position + Vector2(40,-55)
	camera.zoom = Vector2.ONE * 2.0
	# Staging changes occur on the cut. Red stays put; brother steps across her.
	boss.global_position = player.global_position + Vector2(-155,15)
	wolf_visual.flip_h = false
	wolf_visual.z_index = -1 # Red remains visible in front of the broad wolf sprite.
	wolf_visual.play("pounce")
	await _wait(.10)
	await _fade(boss,^"global_position",player.global_position+Vector2(90,15),curse_intercept_duration)
	# Keep a forward lunge pose while the final projectile approach reaches him.
	wolf_visual.set_frame_and_progress(mini(3,wolf_visual.sprite_frames.get_frame_count("pounce")-1),0)
	wolf_visual.pause()
	var contact_position := boss.global_position + Vector2(80,-60)
	# Resume a short approach from the Keep-facing edge of the close shot.
	curse_projectile.global_position = contact_position + Vector2(160,-50)
	curse_projectile.rotation = (contact_position-curse_projectile.global_position).angle()
	curse_projectile.show()
	active_tween = TRANSITIONS.fade(self,curse_projectile,^"global_position",contact_position,.18)
	active_tween.set_trans(Tween.TRANS_LINEAR)
	await active_tween.finished
	curse_projectile.hide()
	phase = "curse_impact"
	curse_impact = AnimatedSprite2D.new()
	curse_impact.name = "BrotherInterceptionImpactOnly"
	curse_impact.sprite_frames = curse_impact_frames
	curse_impact.position = contact_position
	curse_impact.scale = Vector2.ONE * curse_impact_scale
	curse_impact.flip_h = true
	curse_impact.z_index = 6
	curse_impact.process_mode = Node.PROCESS_MODE_ALWAYS
	curse_impact.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	curse_impact.material = unlit
	curse_impact.frame_changed.connect(_align_curse_impact)
	world.add_child(curse_impact)
	curse_impact.play("impact")
	_align_curse_impact()
	shake_left = .35
	_impact_sound()
	# Hold the shielding pose through contact, rather than showing the fallen pose.
	wolf_visual.pause()
	# Cut under the flash while the burst starts; sound/flash bridge into the art.
	active_tween = TRANSITIONS.fade(self,flash,^"color:a",.20,.06)
	await active_tween.finished
	await _wait(maxf(0,sacrifice_picture_delay-.06))
	await _shot(2,"sacrifice",true)
	await _fade(flash,^"color:a",0.0,.18)
	await _wait(maxf(0,float(curse_impact_frames.get_frame_count("impact"))/curse_impact_fps-sacrifice_picture_delay-.18))
	curse_impact.hide()
	if textures[2] != null:
		await _wait_for_continue(sacrifice_panel_hold)
	# Collapse belongs after the protective action has been held in the artwork.
	wolf_visual.animation = "death"
	wolf_visual.set_frame_and_progress(wolf_visual.sprite_frames.get_frame_count("death")-1,0)
	wolf_visual.pause()

func _stop_curse_effects() -> void:
	if is_instance_valid(curse_projectile):
		curse_projectile.hide()
	if is_instance_valid(curse_impact):
		curse_impact.stop()
		curse_impact.hide()
func _play_guardian_transformation() -> void:
	# Lilies and growing moonlight lead directly into the Guardian artwork.
	await _shot(-1,"guardian_transformation")
	active_tween = TRANSITIONS.fade(self,camera,^"position",boss.global_position+Vector2(-35,-75),.5)
	active_tween.parallel().tween_property(camera,"zoom",Vector2.ONE*1.5,.5)
	await active_tween.finished
	transformation_lilies = LILY_TRANSFORMATION.new()
	transformation_lilies.name = "FallenWolfLilyTransformation"
	transformation_lilies.position = boss.global_position+Vector2(-10,-45)
	transformation_lilies.orbit_radius = transformation_lily_radius
	transformation_lilies.trail_scale = transformation_lily_scale
	transformation_lilies.trail_opacity = transformation_lily_opacity
	world.add_child(transformation_lilies)
	# First let the rings build visibly around the still-present cursed body.
	active_tween = TRANSITIONS.fade(self,transformation_lilies,^"intensity",1.0,transformation_lily_build_duration)
	active_tween.parallel().tween_property(wolf_visual,"modulate",Color(.8,.88,1,1),transformation_lily_build_duration)
	await active_tween.finished
	var glow_material := ShaderMaterial.new()
	glow_material.shader = TRANSFORMATION_GLOW
	glow_material.set_shader_parameter("glow_amount",0.0)
	wolf_visual.material = glow_material
	active_tween = TRANSITIONS.fade(self,glow_material,^"shader_parameter/glow_amount",1.0,guardian_formation_duration)
	active_tween.parallel().tween_property(transformation_lilies,"reveal_glow",1.0,guardian_formation_duration)
	await active_tween.finished
	transformation_lilies.stop_emitting()
	# A brief soft flash bridges the peak glow into the next illustrated shot.
	active_tween = TRANSITIONS.fade(self,flash,^"color",Color(.94,.98,1,.16),.12)
	await active_tween.finished

func _sequence() -> void:
	# Land onto the actual terrain snapshot before playing all collapse frames.
	active_tween = TRANSITIONS.fade(self,boss,^"global_position",wolf_landing,.4)
	active_tween.parallel().tween_property(player,"global_position",red_landing,.4)
	await active_tween.finished
	boss.set("death_animation_started",true)
	wolf_visual.stop()
	wolf_visual.play("death")
	await _wait(float(wolf_visual.sprite_frames.get_frame_count("death")) / wolf_visual.sprite_frames.get_animation_speed("death") + collapse_hold)
	# Quiet fade allows safe ground staging even after an aerial finishing blow.
	await _fade(black,^"color:a",1.0,.25)
	boss.global_position = Vector2(staging_x,500)
	player.global_position = Vector2(staging_x-285,485)
	camera.position = Vector2(staging_x-130,410)
	camera.zoom = Vector2.ONE * 1.15
	player.set("facing",1)
	red_visual.flip_h = false
	wolf_visual.flip_h = true
	await _fade(black,^"color:a",0.0,.35)
	await _shot(-1,"red_approaches")
	player.call("_play_visual","run")
	active_tween = TRANSITIONS.fade(self,player,^"global_position",Vector2(staging_x-150,485),approach_duration)
	active_tween.parallel().tween_property(camera,"zoom",Vector2.ONE*1.45,approach_duration)
	await active_tween.finished
	player.call("_play_visual","idle")
	breath.play()
	AudioDirector.set_context("ending")
	await _say("Red","Brother...")
	await _shot(0,"lucidity")
	await _fade(wolf_visual,^"modulate",Color(.88,.92,1,1),.6)
	await _say("Brother","...You never listen.")
	await _say("Red","You said you'd come back.")
	await _say("Brother","You kept the light on.")
	await _say("Red","Of course I did.")
	await _shot(1,"keep_reacts")
	keep_visual.show()
	# Include both the visible Keep source and Red in the launch composition.
	var wide_center := Vector2((keep_visual.global_position.x+player.global_position.x)*.5,380)
	active_tween = TRANSITIONS.fade(self,camera,^"position",wide_center,.18)
	active_tween.parallel().tween_property(camera,"zoom",Vector2.ONE*.95,.18)
	await active_tween.finished
	shake_left = .35
	active_tween = TRANSITIONS.fade(self,keep_visual,^"pulse_strength",1.0,.4)
	active_tween.parallel().tween_property(flash,"color:a",.18,.25)
	await active_tween.finished
	await _fade(flash,^"color:a",0.0,.35)
	await _say("Brother","Red... move!",1.5)
	await _play_curse_attack()
	await _shot(3,"final_words")
	player.call("_play_visual","run")
	await _fade(player,^"global_position",boss.global_position+Vector2(-50,-15),.8)
	player.call("_play_visual","crouch_hold")
	await _say("Brother","See...?")
	await _say("Brother","I came back.")
	await _say("Red","Idiot...")
	await _say("Brother","Keep the lily safe.")
	await _wait(quiet_hold)
	await _shot(4,"white_lily")
	_petals(boss.global_position+Vector2(-25,-35),2)
	await _play_guardian_transformation()
	await _shot(5,"guardian_birth",true)
	wolf_visual.modulate.a = 0.0
	# Remaining lilies finish behind the panel instead of delaying the reveal.
	var glow_fade := transformation_lilies.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glow_fade.tween_property(transformation_lilies,"intensity",0.0,transformation_linger_duration)
	glow_fade.parallel().tween_property(transformation_lilies,"reveal_glow",0.0,transformation_linger_duration)
	await _fade(flash,^"color:a",0.0,.25)
	await _say("Red","Brother…?")
	# The Guardian does not answer. Hold the silence before the hand-touch panel.
	await _wait(quiet_hold)
	# Recognition uses the original reveal. The new contact paintings follow it.
	if textures[8] != null:
		await _shot(8,"guardian_approach")
		await _wait(guardian_touch_duration)
	await _shot(6,"guardian_touch")
	player.call("_play_visual","idle")
	player.set("facing",1)
	red_visual.flip_h = false
	await _wait(guardian_touch_duration)
	await _say("Red","…You don’t remember me, do you?",3.0)
	await _wait(quiet_hold)
	await _shot(7,"together")
	active_tween = TRANSITIONS.fade(self,camera,^"position",Vector2(1950,365),1.5)
	active_tween.parallel().tween_property(camera,"zoom",Vector2.ONE,.1+1.4)
	await active_tween.finished
	await _wait(wide_hold)
	await _say("Red","…Still protecting me.",2.5)
	await _say("Red","Come on.",1.2)
	await _say("Red","This time… we go together.",3.0)
	await _wait(quiet_hold)
	await _say("","The curse remains.",2.5)
	await _say("","And the Silent Keep still waits.",2.8)
	await _fade(black,^"color:a",1.0,1.0)
	_complete()

func _process(delta: float) -> void:
	if not active or camera == null:
		return
	shake_left = maxf(0,shake_left-delta)
	shake_clock += delta
	camera.offset = Vector2(sin(shake_clock*67),cos(shake_clock*51))*4*minf(1,shake_left/.3)

func _input(event: InputEvent) -> void:
	if not active or finishing or event.is_echo():
		return
	if event.is_action_pressed("continue_ending"):
		get_viewport().set_input_as_handled()
		advance()
	elif event.is_action_pressed("skip_ending"):
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	if not active or finishing:
		return
	finishing = true
	awaiting_continue = false
	next_button.disabled = true
	_stop_curse_effects()
	if is_instance_valid(transformation_lilies):
		transformation_lilies.stop_emitting()
		transformation_lilies.hide()
	phase = "skipping"
	skip_button.disabled = true
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	if panel_motion != null and panel_motion.is_valid():
		panel_motion.kill()
	await _fade(black,^"color:a",1.0,.25)
	_complete()

func _complete() -> void:
	if not active:
		return
	active = false
	finishing = true
	_stop_curse_effects()
	if is_instance_valid(transformation_lilies):
		transformation_lilies.stop_emitting()
	phase = "complete"
	GameSession.complete_objective(GameSession.STAGE_TWO,"prototype_complete")
	GameSession.ending_in_progress = false
	if is_instance_valid(boss):
		boss.remove_from_group("boss")
		boss.queue_free()
	get_tree().paused = false
	GameSession.transition_to(GameSession.PROTOTYPE_COMPLETE)

func _exit_tree() -> void:
	if is_instance_valid(get_parent()):
		get_parent().set_meta("ending_cutscene_active",false)
		get_parent().set_meta("ending_cutscene_pending",false)
	if not saved.is_empty():
		get_tree().paused = false if finishing else previous_pause
		GameSession.ending_in_progress = false
	if active and not finishing:
		AudioDirector.set_context(str(saved["music_context"]))
		if is_instance_valid(player):
			player.process_mode = saved["player_mode"]
			player.physics_interpolation_mode = saved["red_interpolation"]
			player.set("invulnerable",saved["invulnerable"])
			red_visual.process_mode = saved["red_mode"]
		if is_instance_valid(boss):
			boss.process_mode = saved["boss_mode"]
			boss.physics_interpolation_mode = saved["boss_interpolation"]
			wolf_visual.process_mode = saved["wolf_mode"]
			wolf_visual.z_index = saved["wolf_z_index"]
			wolf_visual.material = saved["wolf_material"]
			wolf_visual.modulate = saved["wolf_modulate"]
			boss.set("ending_managed",false)
			boss.call_deferred("_on_visual_animation_finished")
		if is_instance_valid(hud):
			hud.visible = saved["hud_visible"]
		if is_instance_valid(normal_camera):
			normal_camera.make_current()
		var layout := get_parent().get_node_or_null("Stage2BossLayout")
		if layout != null:
			layout.set("region_labels_visible",saved["region_labels"])
			layout.queue_redraw()
	elif not finishing and is_instance_valid(boss):
		boss.set("ending_managed",false)
