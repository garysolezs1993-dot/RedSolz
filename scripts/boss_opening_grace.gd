extends Node

# Red can act while the boss holds its first idle pose. This external, one-time
# handoff delay leaves the boss's attack patterns and combat timers untouched.
var boss: CharacterBody2D
var restore_mode: ProcessMode = Node.PROCESS_MODE_INHERIT
var duration := 1.0
var released := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().create_timer(duration, true, false, true).timeout
	_release()
	queue_free()

func _release() -> void:
	if released:
		return
	released = true
	if is_instance_valid(boss) and boss.is_inside_tree():
		boss.process_mode = restore_mode

func _exit_tree() -> void:
	_release()
