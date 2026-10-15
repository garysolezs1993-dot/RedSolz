extends "res://scripts/forest_platform.gd"

@export var required_seal_id := "oak_moon_seal"
@export_file("*.tscn") var stage_scene_path := "res://scenes/main.tscn"
@export var use_environment_kit := false
var unlocked := false

func _ready() -> void:
	super._ready()
	if use_environment_kit:
		visual.hide()
		var art := Node2D.new()
		art.name = "CellarLiftArt"
		art.set_script(preload("res://scripts/cellar_lift_art.gd"))
		add_child(art)
	add_to_group("seal_shortcuts")
	unlocked = GameSession.objective_completed(stage_scene_path, required_seal_id)
	call_deferred("_connect_objectives")

func _connect_objectives() -> void:
	if not is_inside_tree():
		return
	var objectives := get_parent().get_node_or_null("StageObjectives")
	if objectives != null:
		objectives.progress_changed.connect(_refresh_unlock)

func _refresh_unlock(_count: int, _required: int) -> void:
	unlocked = GameSession.objective_completed(stage_scene_path, required_seal_id)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if unlocked:
		super._physics_process(delta)
	else:
		elapsed = 0
		position = origin
		queue_redraw()

func _draw() -> void:
	if use_environment_kit:
		return
	super._draw()
	var tint := Color("bba4bf") if unlocked else Color("534354")
	draw_line(Vector2(-width * .35, 0), Vector2(-width * .35, -240 - position.y + origin.y), tint, 2)
	draw_line(Vector2(width * .35, 0), Vector2(width * .35, -240 - position.y + origin.y), tint, 2)
	draw_circle(Vector2(0, -8), 4, Color("c7b5e0") if unlocked else Color("59405e"))
