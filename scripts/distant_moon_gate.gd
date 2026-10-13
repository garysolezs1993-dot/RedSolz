extends Node2D

const GATE_VISUAL := preload("res://scenes/moon_gate_visual.tscn")
var visual: Node2D

func _ready() -> void:
	visual = GATE_VISUAL.instantiate()
	visual.gameplay_scale = .14
	visual.position.y = 12
	visual.modulate = Color(.65, .55, .65)
	add_child(visual)
	call_deferred("_connect_progress")

func _connect_progress() -> void:
	if not is_inside_tree():
		return
	var objectives := get_parent().get_parent().get_node_or_null("StageObjectives")
	if objectives != null:
		objectives.progress_changed.connect(_progress_changed)
		_progress_changed(objectives.completed_count(), objectives.required_seal_ids.size())

func _progress_changed(completed: int, _required: int) -> void:
	visual.set_seal_count(completed)
