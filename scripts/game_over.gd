extends Node2D

const RETRY_FALLBACK := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const UI := preload("res://scripts/menu_ui.gd")

@onready var red_sprite: Sprite2D = $RedFallen
@onready var wolf_sprite: Sprite2D = $WolfSilhouette

var elapsed := 0.0
var eye_glows: Array[Polygon2D] = []
var menu_ui: Control
var menu_buttons: Array[Button] = []

func _ready() -> void:
	_build_eye_glows()
	_build_sword()
	_build_ui()
	GameSession.reveal()

func _process(delta: float) -> void:
	elapsed += delta
	red_sprite.position.y = get_viewport_rect().size.y - 102.0 + sin(elapsed * 0.42) * 0.8
	red_sprite.rotation = sin(elapsed * 0.31) * 0.006
	var reveal_time := fposmod(elapsed, 9.0)
	var reveal := 0.0
	if reveal_time < 0.45:
		reveal = reveal_time / 0.45
	elif reveal_time < 1.35:
		reveal = 1.0
	elif reveal_time < 1.8:
		reveal = 1.0 - (reveal_time - 1.35) / 0.45
	wolf_sprite.modulate.a = reveal * 0.28
	for eye in eye_glows:
		eye.color.a = reveal * 0.40
	queue_redraw()

func _build_eye_glows() -> void:
	for local_position: Vector2 in [Vector2(6.0, -5.0), Vector2(10.0, -5.0)]:
		var eye := Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(-1.0, -1.0), Vector2(1.0, -1.0),
			Vector2(1.0, 1.0), Vector2(-1.0, 1.0),
		])
		eye.position = wolf_sprite.position + local_position * wolf_sprite.scale
		eye.color = Color(0.94, 0.18, 0.24, 0.0)
		eye.z_index = 2
		add_child(eye)
		eye_glows.append(eye)

func _build_sword() -> void:
	var screen_size := get_viewport_rect().size
	var sword_origin := Vector2(screen_size.x * 0.715, screen_size.y - 51.0)
	var hilt := Polygon2D.new()
	hilt.position = sword_origin
	hilt.polygon = PackedVector2Array([
		Vector2(-31.0, 9.0), Vector2(-25.0, 5.0),
		Vector2(-17.0, 9.0), Vector2(-23.0, 13.0),
	])
	hilt.color = Color(0.20, 0.09, 0.11, 1.0)
	add_child(hilt)
	var guard := Polygon2D.new()
	guard.position = sword_origin
	guard.polygon = PackedVector2Array([
		Vector2(-23.0, 2.0), Vector2(-20.0, 5.0),
		Vector2(-14.0, 14.0), Vector2(-17.0, 16.0),
	])
	guard.color = Color(0.55, 0.36, 0.34, 1.0)
	add_child(guard)
	var blade := Polygon2D.new()
	blade.position = sword_origin
	blade.polygon = PackedVector2Array([
		Vector2(-22.0, 7.0), Vector2(18.0, -6.0),
		Vector2(27.0, -11.0), Vector2(21.0, -2.0),
		Vector2(-18.0, 10.0),
	])
	blade.color = Color(0.58, 0.63, 0.70, 0.86)
	add_child(blade)
	var blade_edge := Line2D.new()
	blade_edge.points = PackedVector2Array([Vector2(-17.0, 9.0), Vector2(21.0, -2.0)])
	blade_edge.position = sword_origin
	blade_edge.width = 1.0
	blade_edge.default_color = Color(0.84, 0.81, 0.78, 0.9)
	add_child(blade_edge)

func _build_ui() -> void:
	var ui := UI.build_canvas(self)
	menu_ui = ui
	var column := UI.build_panel(ui, "THE FOREST CLAIMS YOU", "But your story is not yet over...", 26)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 28
	column.add_child(spacer)
	var retry_button := UI.button("TRY AGAIN", "TryAgain")
	retry_button.pressed.connect(_on_try_again)
	column.add_child(retry_button)
	var title_button := UI.button("RETURN TO TITLE", "ReturnToTitle")
	title_button.pressed.connect(_on_return_to_title)
	column.add_child(title_button)
	column.add_child(UI.label("A quiet promise waits beneath the moon.", 16, Color("bfb4cd")))
	UI.link_focus([retry_button, title_button])
	menu_buttons = [retry_button, title_button]
	if GameSession.death_in_progress:
		ui.modulate.a = 0.0
		for button in menu_buttons:
			button.disabled = true
			button.modulate.a = 0.0
	else:
		retry_button.grab_focus()

func reveal_death_menu() -> void:
	var intro := create_tween().set_ignore_time_scale(true)
	intro.tween_property(menu_ui, "modulate:a", 1.0, 0.55)
	intro.set_parallel(true)
	for button in menu_buttons:
		intro.tween_property(button, "modulate:a", 1.0, 0.25).set_delay(0.55)
	await intro.finished
	for button in menu_buttons:
		button.disabled = false
	menu_buttons[0].grab_focus()

func _draw() -> void:
	var size := get_viewport_rect().size
	var flower := Vector2(size.x * 0.82, size.y - 60.0)
	for layer in range(5):
		draw_circle(Vector2(size.x * 0.77, size.y - 115.0), 28.0 + layer * 17.0, Color(0.63, 0.69, 0.90, 0.015))
	draw_line(flower + Vector2(0, 3), flower + Vector2(-2, 12), Color("6d8269"), 2)
	for petal in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
		draw_rect(Rect2(flower + petal - Vector2(2, 2), Vector2(4, 4)), Color("eee8df"))
	draw_rect(Rect2(flower - Vector2(1, 1), Vector2(2, 2)), Color("d6b273"))

func _on_try_again() -> void:
	var retry_path := str(get_tree().root.get_meta("retry_scene_path", RETRY_FALLBACK))
	GameSession.retry_stage(retry_path)

func _on_return_to_title() -> void:
	GameSession.transition_to(TITLE_SCENE)
