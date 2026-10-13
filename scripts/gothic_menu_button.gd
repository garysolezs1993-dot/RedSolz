extends Button

const FONT := preload("res://assets/menu_font.tres")
var focus_glow := 0.0
var focus_tween: Tween
var press_tween: Tween
var transitioning := false

func _ready() -> void:
	custom_minimum_size = Vector2(330, 46)
	add_theme_font_override("font", FONT)
	add_theme_font_size_override("font_size", 18)
	for state: String in ["normal", "hover", "focus", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(.035, .012, .026, .48) if state in ["normal", "disabled"] else Color(.10, .012, .026, .58)
		if state == "focus":
			style.bg_color = Color(.12, .012, .026, .16)
		add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_disabled_color"]:
		add_theme_color_override(state, Color("66565e") if state == "font_disabled_color" else (Color("dfd0cc") if state == "font_color" else Color("fff1df")))
	mouse_entered.connect(_refresh_focus)
	mouse_exited.connect(_refresh_focus)
	focus_entered.connect(_refresh_focus)
	focus_exited.connect(_refresh_focus)
	resized.connect(func(): pivot_offset = size * .5; queue_redraw())
	pivot_offset = size * .5
	pressed.connect(func(): AudioDirector.play_sfx("menu_confirm"))

func _refresh_focus() -> void:
	if transitioning:
		return
	var highlighted := not disabled and (has_focus() or is_hovered())
	if highlighted and focus_glow < .2:
		AudioDirector.play_sfx("menu_hover")
	if focus_tween != null and focus_tween.is_valid():
		focus_tween.kill()
	focus_tween = create_tween().set_parallel(true)
	focus_tween.tween_property(self, "focus_glow", 1.0 if highlighted else 0.0, .12)
	focus_tween.tween_property(self, "scale", Vector2.ONE * (1.02 if highlighted else 1.0), .12).set_trans(Tween.TRANS_SINE)
	focus_tween.tween_method(func(_value: float): queue_redraw(), 0.0, 1.0, .12)

func confirm_response(lock_focus: bool = true) -> void:
	transitioning = true
	if focus_tween != null and focus_tween.is_valid():
		focus_tween.kill()
	press_tween = create_tween()
	press_tween.tween_property(self, "scale", Vector2.ONE * .98, .07)
	press_tween.tween_property(self, "scale", Vector2.ONE, .08)
	if not lock_focus:
		press_tween.tween_callback(func(): transitioning = false; _refresh_focus())

func _draw() -> void:
	var glow := 0.0 if disabled else focus_glow
	var border := Color("382b34") if disabled else Color("4e303c").lerp(Color("dc7e84"), glow)
	var box := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	for index in range(3, 0, -1):
		draw_rect(box.grow(float(index) * 1.5), Color(.72, .15, .25, glow * .028), false, 2)
	draw_rect(box, border, false, 1)
	for side in [-1, 1]:
		var x := 1.0 if side == -1 else size.x - 1.0
		for lower in [false, true]:
			var y := size.y - 1.0 if lower else 1.0
			var dy := -1.0 if lower else 1.0
			draw_polyline(PackedVector2Array([Vector2(x - side * 13, y), Vector2(x - side * 7, y + dy * 5), Vector2(x, y + dy * 13)]), border, 1, true)
		var center := Vector2(30 if side == -1 else size.x - 30, size.y * .5)
		draw_polyline(PackedVector2Array([center + Vector2(-4, 0), center + Vector2(0, -5), center + Vector2(4, 0), center + Vector2(0, 5), center + Vector2(-4, 0)]), border, 1, true)
		draw_line(center + Vector2(-7, 0), center + Vector2(7, 0), border, 1, true)
