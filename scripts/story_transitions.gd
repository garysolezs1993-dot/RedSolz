extends RefCounted

# Shared, cancellation-friendly presentation helpers for story panels and shots.
static func fade(owner_node: Node, target: Object, property: NodePath, value: Variant, duration: float) -> Tween:
	var tween := owner_node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, property, value, duration)
	return tween

static func hold(owner_node: Node, duration: float) -> Tween:
	var tween := owner_node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	tween.tween_interval(duration)
	return tween

static func install_skip_action(action_name: String = "skip_opening") -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for code in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		var key := InputEventKey.new()
		key.keycode = code
		InputMap.action_add_event(action_name, key)
	for code in [JOY_BUTTON_START, JOY_BUTTON_B]:
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = code
		InputMap.action_add_event(action_name, button)
