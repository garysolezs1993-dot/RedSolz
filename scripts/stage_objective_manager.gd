extends Node2D

signal progress_changed(completed: int, required: int)
signal seal_awakened(seal: Node2D, introduction: bool)

@export_file("*.tscn") var stage_scene_path := "res://scenes/main.tscn"
@export var required_seal_ids: Array[String] = []
@export var gate_path := NodePath("../StageTwoGate")
var seals: Dictionary = {}

func register_seal(seal: Node2D) -> void:
	seals[seal.identifier] = seal

func completed_count() -> int:
	var count := 0
	for identifier in required_seal_ids:
		if GameSession.objective_completed(stage_scene_path, identifier):
			count += 1
	return count

func is_complete() -> bool:
	return not required_seal_ids.is_empty() and completed_count() == required_seal_ids.size()

func prerequisite_seal(identifier: String) -> Node2D:
	for required_id in required_seal_ids:
		if required_id == identifier:
			return null
		if not GameSession.objective_completed(stage_scene_path, required_id):
			return seals.get(required_id) as Node2D
	return null

func awaken(seal: Node2D, release_guidance: bool = true) -> bool:
	if not required_seal_ids.has(seal.identifier):
		return false
	if prerequisite_seal(seal.identifier) != null or seal.living_guard_count() > 0:
		return false
	if not GameSession.complete_objective(stage_scene_path, seal.identifier):
		return false
	var count := completed_count()
	progress_changed.emit(count, required_seal_ids.size())
	GameSession.notify("Moon Seals awakened: %d/%d" % [count, required_seal_ids.size()])
	if release_guidance:
		seal_awakened.emit(seal, seal.full_cinematic)
	if is_complete():
		_announce_gate()
	return true

func _announce_gate() -> void:
	await get_tree().create_timer(2.9).timeout
	if is_inside_tree() and not GameSession.death_in_progress and not GameSession.transitioning:
		GameSession.notify("The Moon Gate awakens.")

func missing_seal(from: Vector2) -> Node2D:
	# Story order is independent of proximity, including a premature gate visit.
	for identifier in required_seal_ids:
		if GameSession.objective_completed(stage_scene_path, identifier):
			continue
		var seal: Node2D = seals.get(identifier)
		if not is_instance_valid(seal):
			continue
		return seal
	return null

func guidance_target(from: Vector2) -> Vector2:
	var seal := missing_seal(from)
	var gate := get_node_or_null(gate_path) as Node2D
	var destination: Vector2 = gate.global_position + Vector2(0, 45) if gate != null else from
	# Leave each loop through its connecting exit before suggesting another one.
	if from.y < 330 and from.x >= 3600 and from.x < 5300 and GameSession.objective_completed(stage_scene_path, "camp_moon_seal"):
		destination = Vector2(from.x + 240, minf(452, from.y + 48))
	elif from.y > 550 and from.x >= 3330 and from.x <= 5270 and GameSession.objective_completed(stage_scene_path, "oak_moon_seal"):
		destination = Vector2(5140, 675 if from.x < 4900 else 460)
	elif from.y > 550 and from.x >= 6400 and from.x < 8000:
		destination = Vector2(7540, 590) if from.x < 7450 else Vector2(from.x + 160, from.y - 50)
	elif from.x >= 7800 and from.y < 300 and GameSession.objective_completed(stage_scene_path, "heartwood_moon_seal"):
		destination = Vector2(from.x + 220, minf(450, from.y + 54))
	elif seal != null:
		var route: Array = preload("res://scripts/stage1_definition.gd").GUIDANCE_ROUTES.get(seal.identifier, [])
		if not route.is_empty():
			destination = route[0]
			if seal.identifier == "camp_moon_seal" and from.y <= 500 and from.x >= 3000 and from.x < 4400:
				for waypoint: Vector2 in route:
					if waypoint.x > from.x + 60:
						destination = waypoint
						break
			elif seal.identifier == "oak_moon_seal" and from.y > 530 and from.x >= 3300 and from.x < 5270:
				destination = Vector2(3820, 700) if from.x < 3700 else Vector2(4800, 700)
			elif seal.identifier == "heartwood_moon_seal" and from.x >= 6000 and from.x < 7700:
				destination = Vector2(7480, 202)
				for waypoint: Vector2 in route:
					if waypoint.x > from.x + 60:
						destination = waypoint
						break
	# These are branch/return landmarks, never the seal itself. Limit every cue
	# to a small part of the screen, including when backtracking from the gate.
	return from + (destination - Vector2(0, 32) - from).limit_length(280)
