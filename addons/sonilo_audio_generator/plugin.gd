@tool
extends EditorPlugin
# Sonilo Audio Generator - editor plugin entry point.
# Adds the Sonilo dock to the right dock area.

const SoniloDock := preload("sonilo_dock.gd")

var _dock: Control


func _enter_tree() -> void:
	_dock = SoniloDock.new()
	_dock.name = "Sonilo"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_dock = null
