extends "res://scripts/crimson_forest_petals.gd"

# Pool/opacity/wind settings live on the scene's CrimsonPetals Inspector.
@export_group("Arena Battle")
@export_range(0, 10, 1) var active_battle_cap := 5
@export_range(0, 6, 1) var battle_ambient_target := 3

func _collect_shed_sources() -> void:
	for point: Vector2 in [Vector2(210, 275), Vector2(580, 315), Vector2(1050, 290), Vector2(1510, 265), Vector2(2230, 265), Vector2(2540, 310)]:
		_add_source(get_parent().to_global(point), false, Vector2(45, 10))

func _region_density() -> float:
	return 1.0

func _process(delta: float) -> void:
	super._process(delta)
	if not visible or combat_blend <= .45:
		return
	var remaining := active_battle_cap
	for petal in petals:
		if not petal.active:
			continue
		if remaining > 0:
			remaining -= 1
		else:
			_retire(petal)

func _refresh_threat() -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	nearby_threat = boss != null and not bool(boss.get("dead")) and not get_parent().get_meta("boss_intro_pending", false) and boss.process_mode != Node.PROCESS_MODE_DISABLED

func _update_ambient_drift(delta: float, view: Rect2, _density: float) -> void:
	ambient_timer -= delta
	if ambient_timer > 0.0:
		return
	ambient_timer = rng.randf_range(ambient_spawn_interval.x, ambient_spawn_interval.y)
	var target := battle_ambient_target if combat_blend > .45 else ambient_visible_target
	if _visible_small_petals(view) >= target:
		return
	for petal in petals:
		# Combat additions stay behind both characters and the attack cues.
		if not petal.active and (petal.depth == 0 or combat_blend < .45):
			_spawn(petal, view, null, true)
			return
