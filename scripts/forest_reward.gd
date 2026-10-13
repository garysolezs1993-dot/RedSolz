extends Node2D

@export var identifier := "moon_petal"
@export var healing := 12
var elapsed := 0.0

func _ready() -> void:
	if GameSession.collected_petals.has(identifier):
		queue_free()
		return
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 5
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14
	collision.shape = circle
	area.add_child(collision)
	add_child(area)
	area.body_entered.connect(_collect)

func _collect(body: Node2D) -> void:
	if not body.is_in_group("player") or bool(body.get("dead")) or not GameSession.collect_petal(identifier):
		return
	var health := mini(int(body.get("maximum_health")), int(body.get("current_health")) + healing)
	body.set("current_health", health)
	body.emit_signal("health_updated", health, body.get("maximum_health"))
	if body.has_method("play_interaction"):
		body.play_interaction("pickup")
	GameSession.notify("A moon petal. A little hope restored.")
	AudioDirector.play_sfx("menu_confirm")
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var offset := Vector2(0, sin(elapsed * 1.5) * 2)
	draw_circle(offset, 16, Color(.8, .72, .58, .09))
	for petal in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
		draw_rect(Rect2(offset + petal - Vector2(2, 2), Vector2(4, 4)), Color("eee8df"))
	draw_rect(Rect2(offset - Vector2(1, 1), Vector2(2, 2)), Color("d6b273"))
