extends Node2D

# World-fixed visual dressing, using the existing seal's moon/rune palette.
# This is not an interactable, collider, or extra objective.
@export var objective_manager_path := NodePath("../../StageObjectives")
@export var entrance_offset := Vector2(-820, 320)
@export_range(8, 24, 1) var crescent_radius := 14.0
@export_range(.1, 1, .05) var glow_strength := .7
var manager: Node2D
var first_seal_awake := false
var elapsed := 0.0

func _ready() -> void:
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	manager = get_node_or_null(objective_manager_path)
	if manager != null:
		manager.progress_changed.connect(_progress_changed)
		_progress_changed(manager.completed_count(), manager.required_seal_ids.size())

func _progress_changed(_completed: int, _required: int) -> void:
	first_seal_awake = manager != null and GameSession.objective_completed(manager.stage_scene_path, "camp_moon_seal")
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	# The entrance rune and chapel crest share a motif, making the ascending
	# steps recognizable before the high chapel itself is within the camera view.
	_draw_crescent(Vector2.ZERO, crescent_radius, .25 if first_seal_awake else 1.0)
	if not first_seal_awake:
		_draw_crescent(entrance_offset, 6.0, .8)

func _draw_crescent(at: Vector2, radius: float, strength: float) -> void:
	var pulse := 1.0 if first_seal_awake else .86 + sin(elapsed * 1.4) * .14
	var glow := glow_strength * strength * pulse
	# Small transparent halos, matching the existing Moon Seal effect.
	draw_circle(at, radius * 2.6, Color(.64, .40, .86, glow * .025))
	draw_circle(at, radius * 1.9, Color(.78, .32, .48, glow * .045))
	draw_circle(at, radius * 1.4, Color(.84, .55, .67, glow * .065))
	var ink := Color("e9d0e7")
	ink.a = .45 if first_seal_awake else .88
	# Integer scanlines give the crest crisp pixel edges, without creating art files.
	var inner_radius := radius * .88
	var cutout_center := Vector2(radius * .36, -radius * .18)
	for row in range(-int(radius), int(radius) + 1):
		var outer_half := sqrt(maxf(0, radius * radius - row * row))
		var left := ceili(-outer_half)
		var right := floori(outer_half)
		var inner_y := float(row) - cutout_center.y
		if absf(inner_y) < inner_radius:
			var inner_half := sqrt(inner_radius * inner_radius - inner_y * inner_y)
			var cut_left := floori(cutout_center.x - inner_half)
			var cut_right := ceili(cutout_center.x + inner_half)
			if cut_left > left:
				draw_rect(Rect2(at + Vector2(left, row), Vector2(mini(cut_left, right + 1) - left, 1)), ink)
			if cut_right <= right:
				draw_rect(Rect2(at + Vector2(maxi(cut_right, left), row), Vector2(right - maxi(cut_right, left) + 1, 1)), ink)
		else:
			draw_rect(Rect2(at + Vector2(left, row), Vector2(right - left + 1, 1)), ink)
