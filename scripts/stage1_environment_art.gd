extends Node2D

# Decorative sprites only. Authored bodies, routes and interactions own gameplay.
const ROOT := "res://assets/environment/stage1_v2/"
@export_range(.4, 1.0, .02) var brightness := .82
var props: Array[Sprite2D] = []
var lights: Array[PointLight2D] = []
var elapsed := 0.0

# Main visible object bounds ignore faint export remnants when choosing anchors.
# These do not crop source textures. Camp base-strip regions are explicit below.
const BOUNDS := {
	"broken_chapel_back_wall": Rect2(97, 150, 1101, 693),
	"chapel_arch": Rect2(163, 50, 711, 877),
	"chapel_pillar_left": Rect2(66, 61, 138, 862),
	"chapel_pillar_right": Rect2(37, 104, 187, 828),
	"chapel_fallen_bell": Rect2(48, 126, 416, 294),
	"chapel_rubble": Rect2(44, 76, 433, 118),
	"chapel_torn_banner": Rect2(42, 105, 168, 805),
	"hollow_oak": Rect2(79, 72, 866, 874),
	"hollow_oak_branch": Rect2(70, 81, 413, 362),
	"hollow_oak_root": Rect2(49, 92, 424, 321),
	"cellar_root_large": Rect2(305, 73, 419, 390),
	"cellar_root_medium": Rect2(61, 150, 407, 233),
	"cellar_root_small": Rect2(58, 62, 428, 132),
	"cellar_root_stalactite": Rect2(102, 53, 73, 855),
	"bridge_main": Rect2(218, 154, 609, 228),
	"bridge_segment": Rect2(28, 30, 455, 196),
	"bridge_pillar": Rect2(83, 28, 86, 423),
	"burial_tombstone_large": Rect2(83, 28, 346, 455),
	"burial_tombstone_medium": Rect2(14, 40, 227, 432),
	"burial_tombstone_small": Rect2(43, 14, 170, 227),
	"burial_cross": Rect2(17, 28, 222, 455),
	"burial_fence": Rect2(150, 14, 212, 227),
	"burial_rubble": Rect2(60, 14, 391, 227),
	"camp_tent": Rect2(90, 28, 844, 455),
	"camp_fire": Rect2(14, 43, 227, 192),
	"camp_lantern": Rect2(30, 28, 195, 455),
	"camp_crates": Rect2(32, 14, 447, 216),
	"camp_stool": Rect2(29, 14, 197, 216),
	"ruin_arch": Rect2(125, 28, 261, 455),
	"ruin_wall": Rect2(94, 28, 323, 455),
	"ruin_column": Rect2(14, 119, 227, 273),
	"ruin_platform": Rect2(28, 27, 455, 202),
	"ruin_ledge": Rect2(28, 25, 455, 205),
}

func _ready() -> void:
	name = "Stage1EnvironmentArt"
	z_index = -3
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_meta("visual_only", true)
	_build_chapel()
	_build_camp()
	_build_oak_and_cellar()
	_build_bridge()
	_build_burial()
	_build_upper_ruins()
	_prop("camp_lantern", "EntranceWayLantern", Vector2(175, 500), 60, true)
	_prop("camp_lantern", "CampWayLantern", Vector2(2490, 500), 60, true)
	_prop("camp_lantern", "OakWayLantern", Vector2(3810, 500), 60, true)
	# Actual landmarks are separated by quiet stretches; no evenly spaced props.
	_prop("hollow_oak_branch", "HeartwoodSilhouette", Vector2(8535, 500), 270, false, false, -2, .55)
	_prop("hollow_oak_root", "HeartwoodRoots", Vector2(8700, 500), 105, false, false, -1, .75)
	set_brightness(brightness)

func set_brightness(value: float) -> void:
	brightness = value
	modulate = Color(value, value, value, 1)

func _prop(key: String, node_name: String, anchor: Vector2, size: float,
	fit_height: bool = false, hanging: bool = false, depth: int = 0,
	opacity: float = 1.0, flip: bool = false) -> Sprite2D:
	var bounds: Rect2 = BOUNDS[key]
	var texture := load(ROOT + key + ".png") as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = false
	sprite.flip_h = flip
	var factor := size / (bounds.size.y if fit_height else bounds.size.x)
	sprite.scale = Vector2.ONE * factor
	var center_x := bounds.get_center().x
	if flip:
		center_x = texture.get_width() - center_x
	sprite.position = anchor - Vector2(center_x, bounds.position.y if hanging else bounds.end.y) * factor
	sprite.z_index = depth
	sprite.modulate.a = opacity
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if key in ["camp_crates", "camp_stool"]:
		# Exclude only the straight export strip in Godot; actual PNGs stay intact.
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, texture.get_width(), 230)
	sprite.set_meta("source_file", key + ".png")
	sprite.set_meta("visual_only", true)
	add_child(sprite)
	props.append(sprite)
	return sprite

func _build_chapel() -> void:
	_prop("broken_chapel_back_wall", "ChapelBackWall", Vector2(3970, 212), 470, false, false, -2, .82)
	_prop("chapel_arch", "ChapelMainArch", Vector2(3900, 164), 270, true, false, -1, .9)
	_prop("chapel_pillar_left", "ChapelWestPillar", Vector2(3700, 260), 165, true)
	_prop("chapel_pillar_right", "ChapelEastPillar", Vector2(4265, 260), 170, true)
	_prop("chapel_torn_banner", "ChapelBanner", Vector2(4078, 212), 145, true, false, 0, .85)
	_prop("chapel_fallen_bell", "FallenBell", Vector2(3788, 212), 50)
	_prop("chapel_rubble", "ChapelEastRubble", Vector2(4125, 212), 95)
	_prop("chapel_rubble", "ChapelApproachRubble", Vector2(3585, 308), 50, false, false, 0, .85, true)

func _build_camp() -> void:
	_prop("camp_tent", "AbandonedTent", Vector2(2485, 500), 255, false, false, -1)
	_prop("camp_crates", "CampSupplyCrates", Vector2(2635, 500), 48)
	_prop("camp_stool", "CampStool", Vector2(2440, 500), 23)
	_prop("camp_fire", "CampFire", Vector2(2285, 500), 32)
	_prop("camp_lantern", "CampLantern", Vector2(2680, 500), 78, true)
	_light(Vector2(2285, 486), .18, 40)
	_light(Vector2(2674, 460), .14, 45)

func _build_oak_and_cellar() -> void:
	_prop("hollow_oak", "HollowOakLandmark", Vector2(4310, 500), 515, true, false, -2, .82)
	_prop("hollow_oak_branch", "HollowEntranceRoots", Vector2(3380, 550), 220, false, false, -1, .85)
	_prop("hollow_oak_branch", "OakCanopyBranch", Vector2(4870, 340), 180, false, false, -2, .7, true)
	_prop("hollow_oak_root", "OakEasternRoots", Vector2(5100, 500), 135)
	_prop("cellar_root_large", "CellarWestCeilingRoots", Vector2(3770, 542), 110, true, true)
	_prop("cellar_root_large", "CellarEastCeilingRoots", Vector2(4680, 542), 125, true, true, -1, .85, true)
	_prop("cellar_root_medium", "CellarMiddleCeilingRoot", Vector2(4310, 544), 170, false, true)
	_prop("cellar_root_small", "CellarWestGroundRoots", Vector2(3980, 740), 110)
	_prop("cellar_root_small", "CellarSealRoots", Vector2(4995, 740), 85, false, false, -1, .85, true)
	_prop("cellar_root_stalactite", "CellarShaftRoot", Vector2(5050, 538), 112, true, true, -1, .75)
	_prop("hollow_oak_root", "CellarWestExitRoots", Vector2(3465, 740), 100, false, false, -2, .8)

func _build_bridge() -> void:
	# RootedLedge_280/281 already supply a continuous flat crossing:
	# x=5380..5860, surface y=424. Frame that surface, without a second painted
	# deck above/below it suggesting a different place to stand.
	_prop("bridge_pillar", "BridgeWestSupport", Vector2(5394, 556), 132, true, false, -1)
	_prop("bridge_pillar", "BridgeEastSupport", Vector2(5846, 556), 132, true, false, -1)
	var rail := Line2D.new()
	rail.name = "BridgeBackRope"
	rail.width = 2.0
	rail.default_color = Color("6d4e4b")
	rail.antialiased = true
	for index in range(17):
		var t := float(index) / 16.0
		rail.add_point(Vector2(lerpf(5394, 5846, t), 395 + sin(t * PI) * 10))
	add_child(rail)
	for index in range(7):
		var t := float(index) / 6.0
		var x := lerpf(5394, 5846, t)
		var tie := Line2D.new()
		tie.name = "BridgeRopeTie_%d" % index
		tie.width = 1.0
		tie.default_color = Color("5d4244")
		tie.antialiased = true
		tie.points = PackedVector2Array([Vector2(x, 395 + sin(t * PI) * 10), Vector2(x, 424)])
		add_child(tie)

func _build_burial() -> void:
	_prop("burial_tombstone_large", "BurialMainGrave", Vector2(7120, 680), 86, true)
	_prop("burial_tombstone_medium", "BurialEastGrave", Vector2(7225, 680), 61, true)
	_prop("burial_tombstone_small", "BurialWestGrave", Vector2(7045, 680), 35, true)
	_prop("burial_cross", "BurialCross", Vector2(7315, 680), 70, true)
	_prop("burial_fence", "BurialFence", Vector2(6935, 680), 57, true, false, -1, .85)
	_prop("burial_rubble", "BurialRubble", Vector2(7390, 680), 68)
	_prop("ruin_arch", "BurialCryptArch", Vector2(7475, 680), 175, true, false, -2, .7)
	_prop("burial_tombstone_small", "BurialViewpointGrave", Vector2(7420, 356), 38, true)

func _build_upper_ruins() -> void:
	_prop("ruin_wall", "UpperRuinsWestWall", Vector2(6835, 288), 155, true, false, -2, .8)
	_prop("ruin_column", "UpperRuinsWestColumn", Vector2(7000, 288), 60, true)
	_prop("ruin_arch", "SanctuaryWestArch", Vector2(7835, 126), 210, true, false, -2, .8)
	_prop("ruin_wall", "SanctuaryEastWall", Vector2(8490, 126), 170, true, false, -2, .75)
	_prop("ruin_column", "SanctuaryEastColumn", Vector2(8440, 126), 68, true)
	_prop("chapel_rubble", "UpperLookoutRubble", Vector2(7295, 18), 60)
	# Keep the finished terrain kit on the two upper ledges. The v2 ruin
	# surface images contain coarse resampled detail; enlarging them cannot
	# match the cleaner existing platform artwork.

func _light(where: Vector2, energy: float, radius: float) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5, .5)
	texture.fill_to = Vector2(1, .5)
	texture.width = 128
	texture.height = 128
	var light := PointLight2D.new()
	light.name = "CampWarmLight_%d" % lights.size()
	light.position = where
	light.texture = texture
	light.texture_scale = radius / 64.0
	light.color = Color("dc9260")
	light.energy = energy
	light.set_meta("base_energy", energy)
	light.range_item_cull_mask = 1
	add_child(light)
	lights.append(light)

func _process(delta: float) -> void:
	elapsed += delta
	for index in range(lights.size()):
		lights[index].energy = float(lights[index].get_meta("base_energy")) * (1.0 + sin(elapsed * 3.7 + index) * .06)
