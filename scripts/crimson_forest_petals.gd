extends Node2D

const ASSET_ROOT := "res://assets/environment/crimson_petals/"
const SOFT_SHADER := preload("res://shaders/crimson_petal_soft.gdshader")
const PARALLAX := [0.35, 0.8, 1.15]

@export var enabled := true
@export_group("Sparse Petal Pools")
@export_range(0, 24, 1) var background_count := 18
@export_range(0, 16, 1) var midground_count := 14
@export_range(0, 2, 1) var foreground_count := 2
@export_group("Ambient Outdoor Drift")
@export_range(0, 12, 1) var ambient_visible_target := 9
@export var ambient_spawn_interval := Vector2(.35, .75)
@export_group("Occasional Wind Clusters")
@export var gusts_enabled := true
@export var gust_interval := Vector2(8.0, 15.0)
@export var gust_duration := Vector2(1.5, 2.7)
@export_range(0.0, 60.0, 1.0) var gust_speed := 36.0
@export_range(1, 4, 1) var gust_burst_max := 4
@export_group("Visibility")
@export_range(0.0, 1.0, .02) var background_opacity := .32
@export_range(0.0, 1.0, .02) var midground_opacity := .48
@export_range(0.0, .6, .02) var foreground_opacity := .28
@export_range(0.0, 2.0, .1) var foreground_softness := 1.0
@export_range(0.0, 1.0, .05) var combat_opacity_multiplier := .3
@export_group("Movement")
@export_range(.2, 2.0, .1) var drift_speed := 1.0
@export_range(3.0, 12.0, .5) var foreground_spawn_interval := 5.5
@export_group("Canopy and Platform Shedding")
@export var shedding_interval := Vector2(2.0, 4.5)
@export_range(1, 3, 1) var shedding_burst_max := 3

class ShedSource:
	var position := Vector2.ZERO
	var platform := false
	var spread := Vector2(50, 12)

class Petal:
	var sprite: Sprite2D
	var depth := 0
	var active := false
	var world_position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var age := 0.0
	var lifetime := 24.0
	var phase := 0.0
	var spin := 0.0
	var base_scale := 1.0
	var parallax_factor := 1.0
	var acceleration := 0.0
	var terminal_speed := 60.0
	var flutter_strength := 4.0
	var flutter_frequency := 1.5
	var turn_sway := .2

var petals: Array[Petal] = []
var textures: Array[Texture2D] = []
var rng := RandomNumberGenerator.new()
var player: CharacterBody2D
var soft_material: ShaderMaterial
var shed_sources: Array[ShedSource] = []
var shedding_timer := 0.0
var burst_source: ShedSource
var burst_remaining := 0
var burst_timer := 0.0
var ambient_timer := 0.0
var foreground_timer := 0.0
var wind_timer := 0.0
var wind_target := 0.0
var wind_strength := 0.0
var gust_timer := 0.0
var gust_elapsed := 0.0
var current_gust_duration := 0.0
var gust_force := 0.0
var gust_remaining := 0
var gust_spawn_timer := 0.0
var gust_source: ShedSource
var camera_known := false
var last_camera_center := Vector2.ZERO
var warmed := false
var threat_clock := 0.0
var nearby_threat := false
var combat_blend := 0.0

func _ready() -> void:
	# Opening arrival keeps ambient drift alive while gameplay is paused.
	# Ordinary pauses still stop motion and spawning.
	process_mode = Node.PROCESS_MODE_ALWAYS
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rng.randomize() # Independent RNG leaves gameplay randomness unchanged.
	for index in range(1, 5):
		textures.append(load(ASSET_ROOT + "crimson_petal_%02d.png" % index) as Texture2D)
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	soft_material = ShaderMaterial.new()
	soft_material.shader = SOFT_SHADER
	soft_material.set_shader_parameter("blur_radius", foreground_softness)
	var capacities := [background_count, midground_count, foreground_count]
	var layers := [-6, -1, 6] # All world layers stay below the HUD CanvasLayer.
	for depth in range(3):
		var layer := Node2D.new()
		layer.name = ["BackgroundPetals", "MidgroundPetals", "ForegroundPetals"][depth]
		layer.z_index = layers[depth]
		add_child(layer)
		for index in range(capacities[depth]):
			var petal := Petal.new()
			petal.depth = depth
			petal.sprite = Sprite2D.new()
			petal.sprite.name = "Petal_%02d" % index
			petal.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if depth == 2 else CanvasItem.TEXTURE_FILTER_NEAREST
			petal.sprite.material = soft_material if depth == 2 else unlit
			petal.sprite.hide()
			layer.add_child(petal.sprite)
			petals.append(petal)
	foreground_timer = rng.randf_range(4.0, 8.0)
	ambient_timer = rng.randf_range(.15, .45)
	gust_timer = rng.randf_range(4.0, 8.0)
	call_deferred("_collect_shed_sources")
	call_deferred("_find_player")

func _find_player() -> void:
	player = get_parent().get_node_or_null("Player") as CharacterBody2D

func _add_source(where: Vector2, platform: bool, spread: Vector2) -> void:
	var source := ShedSource.new()
	source.position = where
	source.platform = platform
	source.spread = spread
	shed_sources.append(source)

func _collect_shed_sources() -> void:
	# Fixed canopy pockets along the existing quiet routes, not a viewport grid.
	var stage := get_parent() as Node2D
	for marker: Vector2 in [Vector2(480, 290), Vector2(1760, 285),
		Vector2(2480, 265), Vector2(2960, 270), Vector2(3770, 60), Vector2(4600, 160),
		Vector2(5010, 200), Vector2(5650, 240), Vector2(6960, -80),
		Vector2(6240, 160), Vector2(6600, 80), Vector2(7580, 80), Vector2(8120, -40), Vector2(8780, 90),
		Vector2(9180, 220), Vector2(9640, 235)]:
		_add_source(stage.to_global(marker), false, Vector2(50, 14))
	var layout := get_parent().get_node_or_null("Stage1Layout")
	if layout == null:
		return
	# Only stable terrain is used; moving/crumbling platforms never leave emitters.
	for body in layout.get_children():
		if not body is StaticBody2D:
			continue
		for art in body.get_children():
			if not art is Node2D or not str(art.name).begins_with("GothicPlatformArt"):
				continue
			var dimensions: Vector2 = art.get("dimensions")
			var surface_y: float = art.get("surface_y")
			var surface: Vector2 = art.to_global(Vector2(0, surface_y))
			if surface.y > 520.0:
				continue
			# A subset of short mossy ledges sheds from its outer edges.
			if dimensions.x <= 300.0 and int(art.get("variant")) % 3 == 0:
				for side in [-1.0, 1.0]:
					_add_source(art.to_global(Vector2(dimensions.x * .48 * side, surface_y - 4)), true, Vector2(12, 3))
			# Long terrain contributes its actual crimson bushes/vines/branches.
			for foliage in art.get_children():
				if not foliage is Sprite2D or foliage.texture == null:
					continue
				if str(foliage.name) not in ["CrimsonBush", "WideCrimsonSprig", "CrimsonBranchRoots", "CrimsonVines"]:
					continue
				var leaf_position: Vector2 = foliage.to_global(foliage.texture.get_size() * Vector2(.5, .2))
				if leaf_position.y <= 520.0:
					_add_source(leaf_position, true, Vector2(18, 6))

func _region_density() -> float:
	var where := player.global_position
	if where.y > 550.0:
		return .15 # Root Cellar and enclosed lower routes.
	if where.x >= 8900.0:
		return 1.1 # Quiet Moon Gate approach.
	if where.x >= 3000.0 and where.x <= 4400.0 and where.y < 350.0:
		return 1.1 # Broken Chapel and upper balconies.
	return 1.0 if where.y < 220.0 else .95

func _refresh_threat() -> void:
	nearby_threat = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or bool(enemy.get("dead")):
			continue
		var separation: Vector2 = enemy.global_position - player.global_position
		if absf(separation.x) < 420.0 and absf(separation.y) < 170.0:
			nearby_threat = true
			return

func _spawn(petal: Petal, view: Rect2, source: ShedSource = null, ambient: bool = false) -> void:
	petal.active = true
	petal.age = 0.0
	petal.phase = rng.randf_range(0.0, TAU)
	petal.spin = rng.randf_range(-1.1, 1.1)
	petal.flutter_frequency = rng.randf_range(1.2, 2.6)
	petal.flutter_strength = rng.randf_range(4.0, 13.0)
	petal.turn_sway = rng.randf_range(.12, .5)
	petal.acceleration = rng.randf_range(4.0, 9.0)
	petal.terminal_speed = rng.randf_range(45.0, 70.0)
	petal.parallax_factor = 1.0 if source != null or ambient else float(PARALLAX[petal.depth])
	petal.sprite.z_index = 0
	petal.sprite.texture = textures[rng.randi_range(0, textures.size() - 1)]
	petal.sprite.rotation = rng.randf_range(0.0, TAU)
	petal.sprite.flip_h = rng.randf() < .5
	petal.world_position = Vector2(
		rng.randf_range(view.position.x, view.end.x),
		view.position.y - 35.0)
	if source != null:
		petal.world_position = source.position + Vector2(
			rng.randf_range(-source.spread.x, source.spread.x),
			rng.randf_range(-source.spread.y, source.spread.y))
		# Some pass behind the stone; others skim its front edge, below Red.
		if source.platform and petal.depth == 1 and rng.randf() < .5:
			petal.sprite.z_index = -2
	elif ambient:
		# Sparse world-space drift keeps outdoor traversal alive between local
		# canopy bursts. Starting high lets petals naturally fall through ledges.
		petal.world_position = Vector2(
			rng.randf_range(view.position.x + 18.0, view.end.x - 18.0),
			rng.randf_range(view.position.y - 8.0, view.position.y + view.size.y * .18))
	var wind := 13.0 if player.global_position.x >= 8900.0 else -7.0
	match petal.depth:
		0:
			petal.base_scale = rng.randf_range(.32, .48)
			petal.velocity = Vector2(wind * .55 + rng.randf_range(-10.0, 10.0), rng.randf_range(12.0, 23.0))
			petal.acceleration *= .45
			petal.terminal_speed *= .65
			petal.lifetime = rng.randf_range(12.0, 20.0)
		1:
			petal.base_scale = rng.randf_range(.65, 1.0)
			petal.velocity = Vector2(wind + rng.randf_range(-15.0, 18.0), rng.randf_range(19.0, 35.0))
			petal.lifetime = rng.randf_range(10.0, 17.0)
		2:
			var left_side := rng.randf() < .5
			var edge_x := rng.randf_range(.025, .10) if left_side else rng.randf_range(.90, .975)
			petal.world_position = view.position + view.size * Vector2(edge_x, rng.randf_range(.2, .65))
			petal.base_scale = rng.randf_range(1.4, 2.0)
			petal.velocity = Vector2(12.0 if left_side else -12.0, rng.randf_range(25.0, 36.0))
			petal.lifetime = rng.randf_range(8.0, 12.0)
	petal.sprite.modulate.a = 0.0
	petal.sprite.global_position = petal.world_position
	petal.sprite.show()

func _retire(petal: Petal) -> void:
	petal.active = false
	petal.sprite.hide()

func _emit_shed_petal(view: Rect2) -> void:
	if burst_source == null:
		return
	var preferred_depth := 1 if burst_source.platform or rng.randf() < .4 else 0
	for depth in [preferred_depth, 1 - preferred_depth]:
		for petal in petals:
			if not petal.active and petal.depth == depth:
				_spawn(petal, view, burst_source)
				return

func _visible_small_petals(view: Rect2) -> int:
	var count := 0
	for petal in petals:
		if petal.active and petal.depth < 2 and view.has_point(petal.world_position):
			count += 1
	return count

func _update_ambient_drift(delta: float, view: Rect2, density: float) -> void:
	if ambient_visible_target <= 0 or player.global_position.y > 550.0:
		return
	ambient_timer -= delta * density * lerpf(1.0, .55, combat_blend)
	if ambient_timer > 0.0:
		return
	var low := maxf(.2, ambient_spawn_interval.x)
	ambient_timer = rng.randf_range(low, maxf(low, ambient_spawn_interval.y))
	if combat_blend > .45:
		return
	var target := clampi(roundi(float(ambient_visible_target) * minf(density, 1.25)), 1, 12)
	if _visible_small_petals(view) >= target:
		return
	var preferred_depth := 0 if rng.randf() < .5 else 1
	for depth in [preferred_depth, 1 - preferred_depth]:
		for petal in petals:
			if not petal.active and petal.depth == depth:
				_spawn(petal, view, null, true)
				return

func _update_gusts(delta: float, view: Rect2, density: float) -> float:
	if not gusts_enabled or player.global_position.y > 550.0 or combat_blend > .25:
		current_gust_duration = 0.0
		gust_remaining = 0
		return 0.0
	if current_gust_duration <= 0.0:
		gust_timer -= delta * density
		if gust_timer > 0.0:
			return 0.0
		var low := maxf(3.0, gust_interval.x)
		gust_timer = rng.randf_range(low, maxf(low, gust_interval.y))
		var duration_low := maxf(.5, gust_duration.x)
		current_gust_duration = rng.randf_range(duration_low, maxf(duration_low, gust_duration.y))
		gust_elapsed = 0.0
		# Creek and Gate winds favor rightward drift; other canopy pockets vary.
		var creek := player.global_position.x >= 5400.0 and player.global_position.x <= 6300.0
		var direction := 1.0 if creek or player.global_position.x >= 8900.0 or rng.randf() < .5 else -1.0
		gust_force = direction * gust_speed * rng.randf_range(.75, 1.15)
		var burst_max := clampi(gust_burst_max, 1, 4)
		gust_remaining = rng.randi_range(mini(2, burst_max), burst_max)
		gust_spawn_timer = 0.0
		gust_source = ShedSource.new()
		# A wind-carried cluster enters from an upwind edge. The source stays in
		# world space and cannot follow Red or fill the center of the screen.
		gust_source.position = Vector2(view.position.x - 6.0 if direction > 0.0 else view.end.x + 6.0,
			view.position.y + view.size.y * rng.randf_range(.16, .4))
		gust_source.spread = Vector2(12, 32)
	gust_elapsed += delta
	gust_spawn_timer -= delta
	if gust_remaining > 0 and gust_spawn_timer <= 0.0:
		# Local shedding and gusts share the same small pool. Limit the combined
		# visible amount to a few above the ambient target during a gust.
		var visible_limit := mini(14, roundi(float(ambient_visible_target) * density) + 3)
		if _visible_small_petals(view) < visible_limit and view.grow(45.0).has_point(gust_source.position):
			var emitted := false
			for depth in [1, 0]:
				for petal in petals:
					if not petal.active and petal.depth == depth:
						_spawn(petal, view, gust_source)
						petal.velocity.x = gust_force * rng.randf_range(.7, 1.0)
						emitted = true
						break
				if emitted:
					break
		gust_remaining -= 1
		gust_spawn_timer = rng.randf_range(.18, .38)
	var strength := sin(PI * clampf(gust_elapsed / current_gust_duration, 0.0, 1.0)) * gust_force
	if gust_elapsed >= current_gust_duration:
		current_gust_duration = 0.0
		gust_remaining = 0
	return strength

func _update_shedding(delta: float, view: Rect2, density: float) -> void:
	if burst_remaining > 0:
		burst_timer -= delta
		if burst_timer <= 0.0:
			_emit_shed_petal(view)
			burst_remaining -= 1
			burst_timer = rng.randf_range(.1, .28)
		return
	# Longer pauses during combat, with no large bursts over attack telegraphs.
	shedding_timer -= delta * density * lerpf(1.0, .4, combat_blend)
	if shedding_timer > 0.0:
		return
	var low := maxf(1.5, shedding_interval.x)
	shedding_timer = rng.randf_range(low, maxf(low, shedding_interval.y))
	var visible_sources: Array[ShedSource] = []
	for source in shed_sources:
		if view.grow(45.0).has_point(source.position):
			visible_sources.append(source)
	if not visible_sources.is_empty():
		burst_source = visible_sources[rng.randi_range(0, visible_sources.size() - 1)]
		burst_remaining = 1 if combat_blend > .4 else rng.randi_range(1, clampi(shedding_burst_max, 1, 3))
		burst_timer = 0.0

func _process(delta: float) -> void:
	var opening_arrival := GameSession.opening_arrival_active
	if not enabled or (get_tree().paused and not opening_arrival) or GameSession.death_in_progress or GameSession.ending_in_progress or GameSession.transitioning:
		hide()
		camera_known = false
		return
	if not is_instance_valid(player):
		_find_player()
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null or bool(player.get("dead")):
		hide()
		return
	show()
	var center := camera.get_screen_center_position()
	var view_size := get_viewport().get_visible_rect().size / camera.zoom
	var view := Rect2(center - view_size * .5, view_size)
	var camera_delta := center - last_camera_center if camera_known else Vector2.ZERO
	last_camera_center = center
	camera_known = true
	if camera_delta.length() > view_size.length() * .6:
		for petal in petals:
			_retire(petal)
		camera_delta = Vector2.ZERO
		warmed = false
	if not warmed:
		# Start with a nearby shedding event instead of filling the viewport.
		shedding_timer = rng.randf_range(.2, .9)
		ambient_timer = rng.randf_range(.15, .45)
		burst_remaining = 0
		current_gust_duration = 0.0
		gust_remaining = 0
		gust_timer = rng.randf_range(4.0, 8.0)
		warmed = true
	threat_clock -= delta
	if threat_clock <= 0.0:
		_refresh_threat()
		threat_clock = .3
	var in_combat := not opening_arrival and (nearby_threat or bool(player.get("attacking")) or float(player.get("hurt_timer")) > 0.0 or float(player.get("skill_timer")) > 0.0)
	combat_blend = move_toward(combat_blend, 1.0 if in_combat else 0.0, delta * 2.0)
	var density := _region_density()
	wind_timer -= delta
	if wind_timer <= 0.0:
		wind_timer = rng.randf_range(4.0, 9.0)
		wind_target = rng.randf_range(-14.0, 18.0) + (8.0 if player.global_position.x >= 8900.0 else 0.0)
	wind_strength = lerpf(wind_strength, wind_target, 1.0 - exp(-delta * .7))
	var gust_strength := _update_gusts(delta, view, density)
	soft_material.set_shader_parameter("blur_radius", foreground_softness)
	var opacities := [background_opacity, midground_opacity, foreground_opacity]
	for petal in petals:
		if not petal.active:
			continue
		petal.age += delta
		petal.world_position += camera_delta * (1.0 - petal.parallax_factor)
		petal.velocity.y = minf(petal.terminal_speed, petal.velocity.y + petal.acceleration * delta * drift_speed)
		var flutter := sin(petal.age * petal.flutter_frequency + petal.phase) * petal.flutter_strength
		var gust_motion := gust_strength * (.3 if petal.depth == 2 else 1.0)
		petal.world_position += (petal.velocity + Vector2(flutter + wind_strength + gust_motion, 0)) * delta * drift_speed
		if petal.age >= petal.lifetime or not view.grow(160.0).has_point(petal.world_position):
			_retire(petal)
			continue
		var fade_in := .9 if petal.depth == 2 else .22
		var alpha := clampf(petal.age / fade_in, 0.0, 1.0) * clampf((petal.lifetime - petal.age) / 1.5, 0.0, 1.0)
		alpha *= float(opacities[petal.depth]) * minf(density, 1.2)
		alpha *= lerpf(1.0, combat_opacity_multiplier, combat_blend)
		if petal.depth == 2:
			var uv := (petal.world_position - view.position) / view.size
			# The center, HUD band and Red's immediate surroundings stay clear.
			alpha *= smoothstep(.29, .41, absf(uv.x - .5))
			alpha *= smoothstep(.12, .22, uv.y) * (1.0 - smoothstep(.85, .97, uv.y))
			alpha *= smoothstep(70.0, 130.0, petal.world_position.distance_to(player.global_position) * camera.zoom.y)
		petal.sprite.global_position = petal.world_position
		petal.sprite.rotation += (petal.spin + cos(petal.age * petal.flutter_frequency + petal.phase) * petal.turn_sway) * delta
		petal.sprite.scale = Vector2(petal.base_scale * (.78 + .22 * sin(petal.age * petal.flutter_frequency + petal.phase)), petal.base_scale)
		petal.sprite.modulate = Color(.85, .72, .8, alpha)
	_update_shedding(delta, view, density)
	_update_ambient_drift(delta, view, density)
	foreground_timer -= delta * density
	if foreground_timer <= 0.0:
		foreground_timer = foreground_spawn_interval * rng.randf_range(.75, 1.5)
		if combat_blend > .25:
			return
		for petal in petals:
			if not petal.active and petal.depth == 2:
				_spawn(petal, view)
				break
