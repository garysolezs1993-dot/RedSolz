extends "res://scripts/stage1_environment_art.gd"

# Reuse the measured kit anchors and uniform scaling from Stage 1.
# Every prop is background dressing; the original arena owns all collision.
func _ready() -> void:
	name = "Stage2EnvironmentArt"
	z_index = -3
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_meta("visual_only", true)
	_prop("ruin_wall", "EntranceBrokenWall", Vector2(82, 500), 180, true, false, -2, .65)
	_prop("chapel_arch", "EntranceArch", Vector2(190, 500), 235, true, false, -1, .8)
	_prop("chapel_rubble", "EntranceRubble", Vector2(340, 500), 95)
	_prop("hollow_oak_root", "EntranceRoots", Vector2(540, 500), 165, false, false, -1, .7)
	_prop("ruin_wall", "ApproachRuins", Vector2(875, 500), 190, true, false, -2, .5, true)
	_prop("chapel_rubble", "ApproachRubble", Vector2(1190, 500), 80, false, false, -1, .8)
	# A recessed altar composition frames the boss without adding a playable ledge.
	_prop("broken_chapel_back_wall", "AltarBackWall", Vector2(1900, 520), 560, false, false, -3, .55)
	_prop("chapel_arch", "AltarBrokenArch", Vector2(1880, 510), 300, true, false, -2, .65)
	_prop("ruin_platform", "AltarStoneBase", Vector2(1880, 560), 300, false, false, -1, .6)
	_prop("chapel_pillar_left", "AltarWestPillar", Vector2(1670, 500), 160, true, false, -1, .65)
	_prop("chapel_pillar_right", "AltarEastPillar", Vector2(2130, 500), 185, true, false, -1, .65, true)
	_prop("chapel_rubble", "AltarWestRubble", Vector2(1740, 500), 90, false, false, 0, .75)
	_prop("chapel_rubble", "AltarEastRubble", Vector2(2040, 500), 115, false, false, 0, .7, true)
	_prop("hollow_oak_branch", "WestCrimsonRoots", Vector2(1545, 500), 235, false, false, -2, .55)
	_prop("cellar_root_large", "AltarWindingRoots", Vector2(2200, 500), 210, true, false, -2, .7, true)
	_prop("hollow_oak_branch", "EastCrimsonRoots", Vector2(2420, 500), 280, false, false, -2, .55, true)
	_prop("ruin_wall", "EastRuinedWall", Vector2(2660, 500), 200, true, false, -3, .5)
	_prop("chapel_rubble", "EastRubble", Vector2(2570, 500), 95)
	# The first/last positions match the existing ForestEnvironment light pools.
	for x in [175.0, 1120.0, 1590.0, 2490.0]:
		_prop("camp_lantern", "ArenaLantern_%d" % int(x), Vector2(x, 500), 60, true)
	_light(Vector2(1120, 461), .16, 45)
	_light(Vector2(1590, 461), .12, 42)
	set_brightness(brightness)
