extends Node

var prompt: Label
var focused: Node2D
@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)
	prompt = Label.new()
	prompt.name = "WorldInteractionPrompt"
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -82
	prompt.offset_bottom = -56
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color("eed8c7"))
	prompt.add_theme_color_override("font_outline_color", Color("16121e"))
	prompt.add_theme_constant_override("outline_size", 4)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.hide()
	layer.add_child(prompt)

func select_target() -> Node2D:
	if player.dead or player.action_state not in [player.Action.NONE, player.Action.INTERACT] or GameSession.transitioning:
		return null
	var selected: Node2D
	var best_priority := -2147483648
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("world_interactables"):
		if not candidate.available_to(player):
			continue
		var distance: float = player.global_position.distance_squared_to(candidate.global_position)
		if candidate.priority > best_priority or candidate.priority == best_priority and distance < best_distance:
			selected = candidate
			best_priority = candidate.priority
			best_distance = distance
	return selected

func _process(_delta: float) -> void:
	focused = select_target()
	if focused != null:
		var receiver := focused.get_node_or_null(focused.receiver_path)
		if receiver != null and receiver.has_method("preview_interaction"):
			receiver.preview_interaction(player)
	prompt.visible = focused != null
	if focused != null:
		prompt.text = focused.prompt_text
		if player.lantern_sequence.phase == "waiting":
			prompt.text += "   ·   Esc — Cancel"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		var selected := select_target()
		if selected != null:
			selected.activate(player)
			get_viewport().set_input_as_handled()
