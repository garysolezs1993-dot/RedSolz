extends RefCounted

# Authored connections, not a grid of unrelated floating platforms.
var layout: Node2D

func build(target: Node2D) -> void:
	layout = target
	_safety_and_main_route()
	layout._build_opening()
	_camp_and_hub()
	_chapel_loop()
	_oak_and_cellar_loop()
	_bridge_and_ruins_loop()
	_upper_ruins_loop()
	_heartwood_and_gate()
	var scenery := Node2D.new()
	scenery.name = "HollowOakAndCellar"
	scenery.set_script(preload("res://scripts/stage1_exploration_scenery.gd"))
	scenery.set("use_environment_art", layout.environment_art_enabled)
	scenery.set("cellar_cleanup_enabled", layout.cellar_cleanup_enabled)
	layout.add_child(scenery)

func ground(x: float, y: float, width: float, id: int, drop: bool = false) -> void:
	layout._add_ground(x, y, width, 40, id, drop)

func shelves(markers: Array, first_id: int) -> void:
	for index in range(markers.size()):
		var marker: Array = markers[index]
		layout._add_platform(marker[0], marker[1], marker[2], 32, first_id + index)

func _safety_and_main_route() -> void:
	ground(5000, 860, 10400, 91)
	ground(1650, 590, 3300, 90)
	ground(5840, 590, 1200, 92)
	ground(8980, 590, 2040, 93)
	ground(1650, 500, 3300, 50)
	ground(4770, 500, 2540, 51, true)
	ground(6250, 500, 420, 52)
	ground(8300, 500, 3400, 53)
	layout._add_collision_box("LeftMapBoundary", Vector2(-36, 300), Vector2(40, 1800))
	layout._add_collision_box("RightMapBoundary", Vector2(10036, 300), Vector2(40, 1800))
	# Crossing the visible hollow is an ordinary jump. Walking below it enters
	# the cellar on supported steps, without requiring a drop-through command.
	shelves([[3400, 450, 240], [6530, 450, 240]], 400)
	# Recovery paths under the opening, bridge and final calm stretch.
	for x in [150, 2650, 5510, 7970, 9800]:
		if x == 5510 and layout.lift_approach_cleanup_enabled:
			# The lift serves the main ascent to its broad existing landing at
			# y=500. Two staggered ledges recover a missed ride from the catch
			# floor via the existing lower bridge floor at y=590. All rises are
			# 90 px, within Red's normal double jump; no dash/attack is needed.
			shelves([[5480, 770, 240], [5630, 680, 240]], 6010)
		elif x == 2650 and layout.camp_cleanup_enabled:
			# Broad landings reachable with Red's ordinary double jump. Keep the
			# original IDs of these retained shelves for references and saves.
			for step in [[758, 1], [654, 3], [550, 5]]:
				shelves([[x, step[0], 180]], 500 + int(x) + int(step[1]))
		else:
			shelves([[x, 810, 180], [x, 758, 180], [x, 706, 180], [x, 654, 180], [x, 602, 180], [x, 550, 180]], 500 + int(x))

func _camp_and_hub() -> void:
	# The three western shelves lead to a petal; the camp itself is a quiet
	# clearing around the tent and lantern rather than another platform stack.
	shelves([[1660, 445, 190], [1800, 369, 180], [1930, 425, 180]], 100)
	if not layout.camp_cleanup_enabled:
		shelves([[2380, 452, 220], [2560, 405, 200]], 103)
	layout._add_challenge("CampFallingBranch", "falling_branch", Vector2(2250, 330), {"warning_time": 1.1, "damage": 8})

func _chapel_loop() -> void:
	# Hub -> upper Chapel -> east return to the ruined bridge.
	shelves([[3080, 452, 220], [3240, 404, 220], [3400, 356, 220], [3560, 308, 220],
		[3720, 260, 220], [3780, 212, 220], [3900, 164, 260],
		[4080, 212, 220], [4260, 260, 240], [4440, 308, 220], [4620, 356, 220],
		[4800, 404, 220], [5000, 452, 260], [5240, 452, 240]], 200)
	# Optional upper balcony: the required Chapel floor does not crumble.
	shelves([[4040, 116, 200], [4180, 68, 220]], 220)
	layout._add_challenge("ChapelCrumblingShelf", "crumbling_platform", Vector2(4340, 20), {"width": 180.0, "collapse_delay": 1.2})

func _oak_and_cellar_loop() -> void:
	ground(4300, 740, 1940, 46)
	shelves([[3380, 550, 220], [3540, 610, 220], [3700, 670, 240],
		[4570, 698, 240], [4800, 698, 200]], 240)
	# Broad combat floor with escape shelves; no damaging hazards on this floor.
	shelves([[3880, 688, 210], [4220, 688, 210]], 270)
	# The existing three descent shelves also form the western return. They
	# connect the combat floor to the surface using normal movement/double jump.
	# The former four-shelf staircase overlapped this route at the same entrance.
	if not layout.cellar_cleanup_enabled:
		shelves([[3510, 690, 200], [3510, 635, 200], [3510, 580, 200], [3510, 525, 200]], 250)
	# The distinct eastern exit becomes a fast lift after the cellar objective.
	var lift := AnimatableBody2D.new()
	lift.name = "CellarReturnLift"
	lift.set_script(preload("res://scripts/seal_shortcut_lift.gd"))
	lift.position = Vector2(5140, 740)
	lift.set("travel", Vector2(0, -240))
	lift.set("period", 6.0)
	lift.set("width", 220.0)
	lift.set("use_gothic_art", layout.platform_art_enabled)
	lift.set("art_area_style", "cellar")
	lift.set("use_environment_kit", layout.environment_art_enabled)
	layout.add_child(lift)
	# Hollow Oak crown/viewpoint remains optional and meets the Chapel return.
	shelves([[4420, 450, 220], [4580, 400, 220], [4740, 350, 220], [4900, 300, 220], [5060, 250, 240]], 260)
	layout._add_challenge("OakCrumblingA", "crumbling_platform", Vector2(4900, 200), {"width": 180.0, "collapse_delay": 1.1})
	layout._add_challenge("OakCrumblingB", "crumbling_platform", Vector2(4740, 150), {"width": 180.0, "collapse_delay": 1.1})
	# Hazards sit in optional alcoves, away from the required cellar floor.
	layout._add_challenge("CellarSpikes", "ground_spikes", Vector2(4570, 698), {"width": 32.0, "damage": 6})
	layout._add_challenge("CellarCursedRoots", "cursed_roots", Vector2(4800, 698), {"width": 40.0, "phase_offset": 1.8, "damage": 6})

func _bridge_and_ruins_loop() -> void:
	shelves([[5500, 424, 240], [5740, 424, 240], [6080, 450, 220]], 280)
	layout._add_challenge("CreekLift", "moving_platform", Vector2(5960, 452), {"travel": Vector2(0, -120), "period": 6.5, "width": 170.0})
	layout._add_challenge("CreekThorns", "thorn_vines", Vector2(6000, 500), {"width": 48.0, "damage": 6})
	layout._add_challenge("CreekFallingBranch", "falling_branch", Vector2(6200, 330), {"warning_time": 1.1, "damage": 8})
	ground(7160, 680, 1440, 47)
	# Entry and a different eastern exit form the deeper side-ruins loop.
	shelves([[6520, 550, 220], [6660, 610, 220], [7160, 680, 240],
		[7540, 630, 220], [7700, 580, 220], [7860, 530, 220], [8020, 480, 220]], 290)
	# Optional burial viewpoint above the main route.
	shelves([[7000, 450, 220], [7160, 398, 220], [7340, 356, 240]], 310)

func _heartwood_and_gate() -> void:
	shelves([[8100, 452, 220], [8280, 404, 220], [8460, 356, 220], [8640, 308, 240],
		[9360, 452, 220], [9520, 404, 220]], 320)

func _upper_ruins_loop() -> void:
	# Required ascent: ordinary jumps, broad landings, then horizontal breathing room.
	shelves([[6240, 396, 220], [6400, 342, 220], [6560, 288, 220]], 600)
	ground(6820, 288, 380, 60)
	# Stable hazard crossing; waiting/jumping works without a dash or advanced combo.
	ground(7240, 288, 460, 61)
	layout._add_challenge("UpperRuinsThorns", "ground_spikes", Vector2(7140, 288), {"width": 52.0, "damage": 6})
	layout._add_challenge("UpperRuinsRoots", "cursed_roots", Vector2(7340, 288), {"width": 40.0, "warning_time": 1.1, "rest_time": 3.5, "damage": 6})
	shelves([[7480, 234, 220], [7640, 180, 220]], 610)
	# A stable, spacious fight terrace after the traversal, well clear of hazards.
	ground(8120, 126, 840, 62)
	# Optional lookout branches above the canopy and reconnects before the tower.
	shelves([[6800, 234, 200], [6800, 180, 200], [6940, 126, 220],
		[7080, 72, 220], [7240, 18, 240], [7400, 126, 220]], 620)
	# Quiet eastern return: no enemies/hazards after awakening the final seal.
	shelves([[8600, 180, 240], [8760, 234, 240], [8920, 288, 240],
		[9080, 342, 240], [9240, 396, 240], [9400, 450, 240]], 640)
