extends Area2D

# Damage belongs to the character, rather than this detection-only area.
func get_damage_receiver() -> Node2D:
	return get_parent() as Node2D
