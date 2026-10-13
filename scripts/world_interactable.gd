extends Node2D

# Receiver implements interact(player), optionally can_interact(player).
# Reuse this component for NPCs, doors, checkpoints and switches.
@export var receiver_path := NodePath("..")
@export var prompt_text := "E — Interact"
@export var interaction_range := Vector2(80, 70)
@export var priority := 0

func _ready() -> void:
	add_to_group("world_interactables")

func available_to(player: Node2D) -> bool:
	var receiver := get_node_or_null(receiver_path)
	if receiver == null or not receiver.has_method("interact"):
		return false
	var offset := player.global_position - global_position
	if absf(offset.x) > interaction_range.x or absf(offset.y) > interaction_range.y:
		return false
	return not receiver.has_method("can_interact") or receiver.can_interact(player)

func activate(player: Node2D) -> void:
	if available_to(player):
		get_node(receiver_path).interact(player)
