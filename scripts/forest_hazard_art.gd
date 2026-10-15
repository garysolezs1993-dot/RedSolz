extends Node2D

# Source PNGs remain whole. Main silhouettes (alpha >= 20) set scale/pivot;
# very faint edge pixels are padding/fringe, not the platform contact line.
const ROOT := "res://assets/environment/stage1_hazards/"
const SINGLE = preload(ROOT + "ground_spike_single.png")
const CLUSTER = preload(ROOT + "ground_spikes_cluster.png")
const THORNS = preload(ROOT + "thorn_vines.png")
const BRANCH = preload(ROOT + "falling_branch.png")
const ROOTS_REST = preload(ROOT + "cursed_roots_rest.png")
const ROOTS_ACTIVE = preload(ROOT + "cursed_roots_active.png")

var hazard: Node2D
var active: Node2D
var resting: Sprite2D

func configure(owner_hazard: Node2D) -> void:
	hazard = owner_hazard
	name = "HazardArt"
	z_index = -1 # Warning marks draw above the art; Red remains in front.
	active = Node2D.new()
	active.name = "ActiveArt"
	add_child(active)
	match hazard.kind:
		0, 1:
			if hazard.width <= 40.0:
				var count := maxi(3, roundi(hazard.width / 12.0))
				var step: float = hazard.width / count
				for index in range(count):
					var spike := sprite(active, SINGLE, Vector2(65.5, 111), Vector2(step / 59.0, hazard.height / 86.0))
					spike.position.x = -hazard.width / 2.0 + step * (index + 0.5)
			else:
				sprite(active, CLUSTER, Vector2(129.5, 103), Vector2(hazard.width / 201.0, hazard.height / 68.0))
		2:
			# Match the solid trunk to the 12px collision band; fine twigs are decoration.
			sprite(active, BRANCH, Vector2(134, 68), Vector2.ONE * hazard.width / 200.0)
		3:
			sprite(active, THORNS, Vector2(124, 102), Vector2(hazard.width / 194.0, hazard.height / 73.0))
		4:
			var root_scale := Vector2(hazard.width / 162.0, hazard.height / 90.0)
			# Both states share one transform. The safe state has a wider, low root base.
			resting = sprite(self, ROOTS_REST, Vector2(129, 110), root_scale)
			sprite(active, ROOTS_ACTIVE, Vector2(129, 110), root_scale)
	update_art()

func sprite(parent: Node, texture: Texture2D, pivot: Vector2, art_scale: Vector2) -> Sprite2D:
	var visual := Sprite2D.new()
	visual.texture = texture
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.centered = false
	visual.offset = -pivot
	visual.scale = art_scale
	parent.add_child(visual)
	return visual

func update_art() -> void:
	if hazard.kind == 2:
		active.position = hazard.danger.position
		active.modulate.a = clampf(1.0 - hazard.age / 0.65, 0.0, 1.0) if hazard.state == "recovery" else 1.0
	else:
		active.visible = hazard.display_strength > 0.0
		active.scale.y = maxf(0.001, hazard.display_strength)
		if resting != null:
			resting.modulate.a = 1.0 - hazard.display_strength
