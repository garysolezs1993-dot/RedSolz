extends AnimatableBody2D

enum Kind { MOVING, CRUMBLING }
const GOTHIC_ART := preload("res://scripts/forest_platform_art.gd")
const TERRAIN := preload("res://scripts/terrain_visual.gd")
@export var kind: Kind = Kind.MOVING
@export var width := 150.0
@export var travel := Vector2(220, 0)
@export var period := 5.5
@export var collapse_delay := 0.85
@export var respawn_delay := 4.0
@export var use_gothic_art := false
@export var art_area_style := "creek"

var elapsed := 0.0
var origin := Vector2.ZERO
var state := "stable"
var timer := 0.0
var shape: CollisionShape2D
var visual: Node2D
var sensor: Area2D

func _ready() -> void:
	add_to_group("forest_platforms")
	add_to_group("drop_through_platform")
	origin = position
	collision_layer = 1
	collision_mask = 0
	shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 16)
	shape.shape = rectangle
	shape.position.y = 8
	shape.one_way_collision = true
	shape.one_way_collision_margin = 8
	add_child(shape)
	visual = Node2D.new()
	visual.name = "GothicPlatformArt" if use_gothic_art else "TerrainVisual"
	visual.set_script(GOTHIC_ART if use_gothic_art else TERRAIN)
	visual.set("dimensions", Vector2(width, 30))
	visual.set("surface_y", 0.0)
	visual.set("variant", 76 if kind == Kind.MOVING else 77)
	if use_gothic_art:
		visual.set("area_style", art_area_style)
		visual.set("compact_surface", origin.y > 500)
	add_child(visual)
	sensor = Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 5
	var sensor_shape := CollisionShape2D.new()
	var sensor_box := RectangleShape2D.new()
	sensor_box.size = Vector2(width - 8, 10)
	sensor_shape.shape = sensor_box
	sensor_shape.position.y = -16
	sensor.add_child(sensor_shape)
	add_child(sensor)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if kind == Kind.MOVING:
		position = origin + travel * (0.5 - 0.5 * cos(TAU * elapsed / maxf(period, 0.5)))
		return
	if state == "stable":
		for body in sensor.get_overlapping_bodies():
			if body is CharacterBody2D and body.is_in_group("player") and body.is_on_floor():
				for index in range(body.get_slide_collision_count()):
					if body.get_slide_collision(index).get_collider() == self:
						state = "warning"
						timer = collapse_delay
	elif state == "warning":
		timer -= delta
		visual.position.x = sin(elapsed * 45) * 2
		if timer <= 0:
			state = "collapsed"
			timer = respawn_delay
			shape.set_deferred("disabled", true)
			visual.hide()
	elif state == "collapsed":
		timer -= delta
		if timer <= 0:
			state = "stable"
			visual.position.x = 0
			visual.show()
			shape.set_deferred("disabled", false)
	queue_redraw()

func _draw() -> void:
	if kind == Kind.CRUMBLING and state != "collapsed":
		var color := Color("b67861") if state == "warning" else Color("806b62")
		for x in [-width * .3, 0.0, width * .3]:
			draw_line(Vector2(x, 3), Vector2(x + 4, 13), color, 2)
