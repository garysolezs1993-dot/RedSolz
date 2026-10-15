extends Node2D

const HazardArt = preload("res://scripts/forest_hazard_art.gd")
enum Kind { GROUND_SPIKES, RETRACTABLE_SPIKES, FALLING_BRANCH, THORN_VINES, CURSED_ROOTS }
@export var use_hazard_art := true
@export var kind: Kind = Kind.GROUND_SPIKES
@export_range(24.0, 220.0, 2.0) var width := 60.0
@export_range(12.0, 64.0, 1.0) var height := 22.0
@export_range(1, 40, 1) var damage := 10
@export var warning_time := 0.85
@export var rest_time := 2.8
@export var active_time := 1.1
@export var phase_offset := 0.0
@export var fall_distance := 164.0
@export var trigger_range := 72.0

var danger: Area2D
var polygons: Array[PackedVector2Array] = []
var elapsed := 0.0
var state := "rest"
var age := 0.0
var fall_offset := 0.0
var fall_velocity := 0.0
var danger_enabled := false
var display_strength := 0.0
var art: Node2D

func _ready() -> void:
	add_to_group("forest_hazards")
	danger = Area2D.new()
	danger.name = "Danger"
	danger.collision_layer = 0
	danger.collision_mask = 5 # Red's normal and dash layers; take_damage owns i-frames.
	add_child(danger)
	_build_geometry()
	for polygon in polygons:
		var collider := CollisionPolygon2D.new()
		collider.polygon = polygon
		danger.add_child(collider)
	danger.body_entered.connect(_damage_body)
	age = phase_offset
	_update_visual_and_collision()
	if use_hazard_art:
		art = HazardArt.new()
		add_child(art)
		art.configure(self)

func _build_geometry() -> void:
	if kind == Kind.FALLING_BRANCH:
		polygons.append(PackedVector2Array([Vector2(-width/2, -6), Vector2(width/2, -6), Vector2(width/2, 6), Vector2(-width/2, 6)]))
	elif kind == Kind.THORN_VINES:
		polygons.append(PackedVector2Array([
			Vector2(-width/2, 0), Vector2(-width/2+6, -height*.45), Vector2(-width/2, -height*.65),
			Vector2(-width/2+15, -height*.60), Vector2(-width*.18, -height), Vector2(-width*.10, -height*.65),
			Vector2(width*.12, -height*.72), Vector2(width*.32, -height), Vector2(width*.32, -height*.54),
			Vector2(width/2, -height*.65), Vector2(width/2-4, -height*.3), Vector2(width/2, 0)]))
	else:
		var count := maxi(3, roundi(width / 12.0))
		var step := width / count
		for index in range(count):
			var left := -width/2 + index * step
			polygons.append(PackedVector2Array([Vector2(left, 0), Vector2(left + step*.5, -height), Vector2(left + step, 0)]))

func _physics_process(delta: float) -> void:
	elapsed += delta
	age += delta
	if kind == Kind.FALLING_BRANCH:
		_run_branch(delta)
	elif kind in [Kind.RETRACTABLE_SPIKES, Kind.CURSED_ROOTS]:
		var cycle := rest_time + warning_time + active_time
		var time := fposmod(elapsed + phase_offset, cycle)
		state = "rest" if time < rest_time else ("warning" if time < rest_time + warning_time else "active")
		age = time - rest_time - warning_time if state == "active" else time
	_update_visual_and_collision()
	if danger_enabled:
		for body in danger.get_overlapping_bodies():
			_damage_body(body)
	queue_redraw()

func _run_branch(delta: float) -> void:
	match state:
		"rest":
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if age >= rest_time and player != null and absf(player.global_position.x - global_position.x) <= trigger_range and player.global_position.y > global_position.y + 25:
				state = "warning"
				age = 0.0
		"warning":
			if age >= warning_time:
				state = "active"
				age = 0.0
				fall_velocity = 0.0
		"active":
			fall_velocity += 720.0 * delta
			fall_offset = minf(fall_distance, fall_offset + fall_velocity * delta)
			if fall_offset >= fall_distance:
				state = "recovery"
				age = 0.0
		"recovery":
			if age >= 0.65:
				fall_offset = 0.0
				state = "rest"
				age = 0.0

func _update_visual_and_collision() -> void:
	var permanent := kind in [Kind.GROUND_SPIKES, Kind.THORN_VINES]
	danger_enabled = permanent or state == "active"
	display_strength = 1.0 if permanent or state == "active" else 0.0
	if kind in [Kind.RETRACTABLE_SPIKES, Kind.CURSED_ROOTS] and state == "active":
		display_strength = clampf(minf(age / 0.18, (active_time - age) / 0.18), 0.0, 1.0)
		danger_enabled = display_strength > 0.04
	danger.scale.y = maxf(0.001, display_strength) if kind != Kind.FALLING_BRANCH else 1.0
	danger.position = Vector2(sin(elapsed * 43) * 3 if kind == Kind.FALLING_BRANCH and state == "warning" else 0.0, fall_offset)
	for collider in danger.get_children():
		collider.set_deferred("disabled", not danger_enabled)
	if art != null:
		art.update_art()

func _damage_body(body: Node2D) -> void:
	if danger_enabled and body.is_in_group("player") and body.has_method("take_damage"):
		var direction := signf(body.global_position.x - global_position.x)
		body.take_damage(damage, (1.0 if direction == 0.0 else direction) * 160.0)

func _draw() -> void:
	if danger == null:
		return
	if kind == Kind.FALLING_BRANCH:
		var origin := danger.position
		var alpha := 1.0 - age / 0.65 if state == "recovery" else 1.0
		if art == null:
			draw_rect(Rect2(origin + Vector2(-width/2, -6), Vector2(width, 12)), Color(0.34, 0.24, 0.25, maxf(0.0, alpha)))
			draw_line(origin + Vector2(-width/2+3, -3), origin + Vector2(width/2-4, -3), Color("987661"), 2)
		if state == "warning":
			draw_line(Vector2(-width/2, fall_distance+6), Vector2(width/2, fall_distance+6), Color("e4ba73"), 3)
			draw_string(ThemeDB.fallback_font, Vector2(-5, fall_distance-18), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f0cc86"))
		return
	if art == null:
		draw_rect(Rect2(-width/2, 0, width, 4), Color("56323c"))
	if state == "warning":
		var warning := Color(0.87, 0.48, 0.24, 0.45 + .35 * sin(elapsed * 8))
		draw_line(Vector2(-width/2, -2), Vector2(width/2, -2), warning, 3)
		draw_string(ThemeDB.fallback_font, Vector2(-4, -11), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, warning)
	if art != null or display_strength <= 0.0:
		return
	for polygon in polygons:
		var visible_polygon := PackedVector2Array()
		for point in polygon:
			visible_polygon.append(Vector2(point.x, point.y * display_strength))
		var color := Color("675c68") if kind in [Kind.GROUND_SPIKES, Kind.RETRACTABLE_SPIKES] else Color("593443")
		draw_colored_polygon(visible_polygon, color)
		draw_polyline(visible_polygon, Color("c7b0b4") if kind in [Kind.GROUND_SPIKES, Kind.RETRACTABLE_SPIKES] else Color("b94e5c"), 1)
