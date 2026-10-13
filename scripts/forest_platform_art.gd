extends Node2D

# Visual-only kit. The parent owns the existing rectangle/one-way collision.
# Whole source PNGs are combined, never stretched or cropped into tiles.
@export var dimensions := Vector2(220, 32)
@export var surface_y := -9.0
@export var variant := 0
@export var area_style := "entrance"
@export var compact_surface := false
const ROOT := "res://assets/environment/gothic_forest/"
const ART_SCALE := .6
const DEPTH_SHADER := preload("res://shaders/forest_platform_depth.gdshader")
const PIECES := [
	["platform_large/thin_moss_shelf.png", 34.0],
	["platform_medium/thin_quiet_moss.png", 29.0],
	["platform_medium/quiet_moss_shelf.png", 47.0],
	["platform_large/low_moss_shelf.png", 50.0],
]
# Contact rows refer to the moss/stone top, not the highest leaf pixel.
const KIT := {
	"moss": ["platform_large/thin_moss_shelf.png", 34.0],
	"quiet": ["platform_medium/thin_quiet_moss.png", 29.0],
	"low": ["platform_large/low_moss_shelf.png", 50.0],
	"wood": ["platform_medium/wood_braced_rock.png", 48.0],
	"wood_roots": ["platform_medium/wood_braced_roots.png", 46.0],
	"rock": ["platform_small/thin_rock_shelf.png", 33.0],
	"crimson": ["platform_medium/thin_crimson_shelf.png", 43.0],
	"crimson_small": ["platform_small/thin_crimson_ledge.png", 31.0],
	"roots": ["platform_large/crimson_root_shelf.png", 45.0],
	"cascade": ["platform_medium/hanging_moss_cascade.png", 27.0],
}
const POOLS := {
	"camp": ["wood", "quiet", "wood_roots", "low"],
	"chapel": ["wood", "rock", "moss", "quiet"],
	"creek": ["moss", "cascade", "quiet", "rock"],
	"oak": ["wood_roots", "quiet", "roots", "cascade"],
	"cellar": ["crimson", "quiet", "wood", "crimson_small"],
	"burial": ["rock", "quiet", "wood", "moss"],
	"heartwood": ["crimson", "roots", "wood_roots", "moss"],
	"gate": ["moss", "crimson", "quiet", "low"],
}
const AREA_BOUNDARIES := [2300.0, 3000.0, 5400.0, 6400.0, 8000.0, 8900.0]
var piece_count := 0

func set_lighting(top: float, underside: float) -> void:
	for child in get_children():
		if child is Sprite2D and str(child.name).begins_with("MossShelf_"):
			var depth := child.material as ShaderMaterial
			if depth == null:
				depth = ShaderMaterial.new()
				depth.shader = DEPTH_SHADER
				depth.set_shader_parameter("surface_row", child.get_meta("contact_row") / float(child.texture.get_height()))
				depth.set_shader_parameter("top_band", 12.0 / float(child.texture.get_height()))
				child.material = depth
			depth.set_shader_parameter("top_brightness", top)
			depth.set_shader_parameter("underside_brightness", underside)

static func style_at(x: float, y: float) -> String:
	if x >= 8900: return "gate"
	if x >= 8000: return "heartwood"
	if x >= 6400: return "burial"
	if x >= 5400: return "creek"
	if x >= 3300 and y > 550: return "cellar"
	if x >= 3000 and x <= 4400 and y <= 356: return "chapel"
	if x >= 3500: return "oak"
	if x >= 2300: return "camp"
	return "entrance"

func _pool() -> Array:
	if area_style == "entrance":
		return PIECES
	var result: Array = []
	for key in POOLS.get(area_style, POOLS["creek"]):
		# Thin pieces leave space between tightly stacked return steps.
		if compact_surface and key in ["roots", "wood_roots", "cascade", "low"]:
			continue
		result.append(KIT[key])
	return result


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -1
	if area_style == "cellar":
		modulate = Color(.84, .84, .92, 1)
	if dimensions.x <= 240.0:
		_build_ledge()
	else:
		_build_long_surface()
	_add_dressing()
	# A fine moss contact line makes the unchanged flat collision explicit.
	var lip := Line2D.new()
	lip.name = "WalkableMossLip"
	lip.width = 1.0
	lip.default_color = Color("626f62")
	# A restrained contact highlight stays readable in the darkest cellar.
	var edge_material := CanvasItemMaterial.new()
	edge_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	lip.material = edge_material
	lip.points = PackedVector2Array([Vector2(-dimensions.x * .5, surface_y), Vector2(dimensions.x * .5, surface_y)])
	lip.z_index = 1
	lip.antialiased = false
	add_child(lip)
	set_meta("visual_only", true)
	set_meta("kit_piece_count", piece_count)
	set_meta("area_style", area_style)

func _piece(entry: Array, left: float, scale_factor: float, flip: bool = false) -> float:
	var texture := load(ROOT + str(entry[0])) as Texture2D
	var width := (texture.get_width() - 32.0) * scale_factor
	var sprite := Sprite2D.new()
	sprite.name = "MossShelf_%02d" % piece_count
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2.ONE * scale_factor
	sprite.flip_h = flip
	sprite.position = Vector2(left - 16.0 * scale_factor, surface_y - float(entry[1]) * scale_factor)
	sprite.set_meta("contact_row", float(entry[1]))
	add_child(sprite)
	piece_count += 1
	return width

func _build_ledge() -> void:
	# Choose the closest native width before applying a small uniform fit.
	var entry: Array = PIECES[1] if dimensions.x <= 160.0 else PIECES[2]
	if dimensions.x >= 195.0:
		entry = PIECES[0]
	if area_style != "entrance":
		# Fit the closest native width; no independent X/Y stretching.
		var candidates := _pool()
		var best_error := INF
		var fits: Array = []
		for candidate in candidates:
			var candidate_texture := load(ROOT + str(candidate[0])) as Texture2D
			var fit := dimensions.x / (candidate_texture.get_width() - 32.0)
			var error := absf(fit - ART_SCALE)
			if error < best_error:
				best_error = error
				entry = candidate
		for candidate in candidates:
			var candidate_texture := load(ROOT + str(candidate[0])) as Texture2D
			var fit := dimensions.x / (candidate_texture.get_width() - 32.0)
			if absf(fit - ART_SCALE) <= best_error + .1:
				fits.append(candidate)
		entry = fits[posmod(int(variant / 7), fits.size())]
	var texture := load(ROOT + str(entry[0])) as Texture2D
	var scale_factor := dimensions.x / (texture.get_width() - 32.0)
	_piece(entry, -dimensions.x * .5, scale_factor, variant % 2 == 1)

func _build_long_surface() -> void:
	var left := -dimensions.x * .5
	var right := dimensions.x * .5
	var index := 0
	var pool := _pool()
	while left < right:
		var entry: Array = pool[posmod(index + variant, pool.size())]
		var texture := load(ROOT + str(entry[0])) as Texture2D
		var width := (texture.get_width() - 32.0) * ART_SCALE
		var last := left + width >= right
		var placed_left := right - width if last else left
		_piece(entry, placed_left, ART_SCALE, (index + variant) % 3 == 1)
		if last:
			break
		left += width * .8
		index += 1

func _prop(path: String, x: float, y: float, scale_factor: float, hanging: bool = false, flip: bool = false) -> void:
	var texture := load(ROOT + path) as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = path.get_file().get_basename().to_pascal_case()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2.ONE * scale_factor
	sprite.flip_h = flip
	sprite.position = Vector2(x - texture.get_width() * scale_factor * .5, y - (16.0 if hanging else texture.get_height() - 16.0) * scale_factor)
	sprite.z_index = -1
	add_child(sprite)

func _add_dressing() -> void:
	if area_style == "entrance":
		if dimensions.x > 300:
			_prop("root_hanging/bare_branch_roots.png", -dimensions.x * .28, surface_y + 16, .28, true, variant % 2 == 0)
			_prop("rock_cluster/mossy_crimson_stones.png", dimensions.x * .32, surface_y + 1, .22)
			if variant % 2 == 0:
				_prop("foliage/crimson_bush.png", -dimensions.x * .12, surface_y, .16)
		elif variant == 780:
			_prop("wood_support/carved_brace.png", dimensions.x * .15, surface_y + 12, .3, true)
		return
	# Small return ledges stay clear; their different stone pieces supply variety.
	if dimensions.x <= 240:
		if not compact_surface and variant % 3 == 0:
			var support := "wood_support/carved_brace.png" if area_style in ["camp", "chapel"] else "root_hanging/bare_branch_roots.png"
			_prop(support, 0, surface_y + 15, .25, true, variant % 2 == 0)
		return
	var left := -dimensions.x * .5
	# Deliberate asymmetric groups, with broad gaps around combat and lanterns.
	match area_style:
		"camp":
			_prop("wood_support/carved_brace.png", left + dimensions.x * .27, surface_y + 14, .38, true)
			_prop("wood_support/carved_post.png", left + dimensions.x * .72, surface_y + 12, .35, true)
			_prop("rock_cluster/large_mossy_stones.png", left + dimensions.x * .57, surface_y, .23)
		"chapel":
			_prop("wood_support/carved_post.png", left + dimensions.x * .23, surface_y + 13, .4, true, true)
			_prop("rock_cluster/large_mossy_stones.png", left + dimensions.x * .68, surface_y, .25)
		"creek":
			_prop("root_hanging/bare_branch_roots.png", left + dimensions.x * .34, surface_y + 15, .3, true)
			_prop("rock_cluster/small_crimson_stones.png", left + dimensions.x * .76, surface_y, .24)
		"oak", "cellar":
			_prop("root_hanging/crimson_branch_roots.png", left + dimensions.x * .29, surface_y + 14, .34, true)
			_prop("root_hanging/bare_branch_roots.png", left + dimensions.x * .73, surface_y + 16, .32, true, true)
			if not compact_surface:
				_prop("root_cluster/crimson_stump.png", left + dimensions.x * .54, surface_y, .23)
		"burial":
			_prop("rock_cluster/large_mossy_stones.png", left + dimensions.x * .25, surface_y, .25)
			_prop("root_hanging/bare_branch_roots.png", left + dimensions.x * .72, surface_y + 16, .28, true)
		"heartwood":
			_prop("root_hanging/crimson_branch_roots.png", left + dimensions.x * .21, surface_y + 14, .38, true)
			_prop("root_hanging/crimson_vines.png", left + dimensions.x * .81, surface_y + 12, .36, true)
			_prop("foliage/wide_crimson_sprig.png", left + dimensions.x * .12, surface_y, .21)
		"gate":
			_prop("root_hanging/crimson_vines.png", left + dimensions.x * .18, surface_y + 16, .3, true)
			_prop("foliage/crimson_bush.png", left + dimensions.x * .84, surface_y, .22)
