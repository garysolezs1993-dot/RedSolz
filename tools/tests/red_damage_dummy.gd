extends CharacterBody2D

var hits := 0
var health := 1000
var last_knockback := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("enemies")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 28)
	shape.shape = rect
	add_child(shape)

func take_damage(amount: int, knockback: float = 0.0) -> void:
	hits += 1
	health -= amount
	last_knockback = knockback
