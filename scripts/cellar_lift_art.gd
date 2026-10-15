extends Node2D

const ROOT := "res://assets/environment/stage1_v2/"
const CHAIN_REGION := Rect2(17, 8, 30, 226)
const CHAIN_SCALE := .42
const CHAIN_OVERLAP := 2.0
@export var beam_clearance := 58.0
var body: AnimatableBody2D
var rig: Node2D
var deck: Sprite2D
var chain_sprites: Array[Sprite2D] = []
var attachments := 0.0

func _ready() -> void:
	body = get_parent() as AnimatableBody2D
	set_meta("visual_only", true)
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var width: float = body.get("width")
	var factor := width / 426.0
	deck = _sprite("cellar_lift_deck", "MovingDeck", Vector2(-253, -128) * factor, factor, self)
	attachments = 200.0 * factor
	rig = Node2D.new()
	rig.name = "CellarLiftFixedRig"
	rig.z_index = -1
	rig.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rig.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rig.set_meta("visual_only", true)
	var origin: Vector2 = body.get("origin")
	var travel: Vector2 = body.get("travel")
	rig.position = origin + Vector2(0, minf(0.0, travel.y) - beam_clearance)
	var beam_factor := attachments * 2.0 / 398.0
	_sprite("cellar_lift_top_beam", "FixedTopBeam", Vector2(-255, -62) * beam_factor, beam_factor, rig)
	var frame_scale := (absf(travel.y) + beam_clearance + 18.0) / 335.0
	for side in [-1.0, 1.0]:
		var frame := _sprite("cellar_lift_side_frame", "FixedSideFrame_%s" % str(side),
			Vector2(side * (width * .5 + 43.0) - 116.0 * frame_scale, -87.0 * frame_scale), frame_scale, rig)
		if side > 0:
			frame.flip_h = true
			frame.position.x = side * (width * .5 + 43.0) - (256.0 - 116.0) * frame_scale
		frame.modulate = Color(.72, .72, .8, 1)
		for index in range(8):
			var chain := Sprite2D.new()
			chain.name = "Chain_%s_%02d" % [str(side), index]
			var atlas := AtlasTexture.new()
			atlas.atlas = load(ROOT + "cellar_lift_chain_tile.png") as Texture2D
			atlas.region = CHAIN_REGION
			atlas.filter_clip = true
			chain.texture = atlas
			chain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			chain.centered = false
			chain.scale = Vector2.ONE * CHAIN_SCALE
			chain.modulate = Color(.82, .82, .9, 1)
			chain.hide()
			rig.add_child(chain)
			chain_sprites.append(chain)
	body.get_parent().add_child.call_deferred(rig)

func _sprite(key: String, node_name: String, where: Vector2, factor: float, parent: Node) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(ROOT + key + ".png") as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.position = where
	sprite.scale = Vector2.ONE * factor
	sprite.set_meta("source_file", key + ".png")
	parent.add_child(sprite)
	return sprite

func _process(_delta: float) -> void:
	if not is_instance_valid(rig) or not rig.is_inside_tree():
		return
	var attachment_y: float = body.global_position.y + 2.0
	var length := maxf(0.0, attachment_y - (rig.global_position.y + 8.0))
	var stride := CHAIN_REGION.size.y * CHAIN_SCALE - CHAIN_OVERLAP
	for side_index in range(2):
		var side := -1.0 if side_index == 0 else 1.0
		for index in range(8):
			var sprite := chain_sprites[side_index * 8 + index]
			var remaining := length - index * stride
			sprite.visible = remaining > 0.0
			if remaining <= 0.0:
				continue
			sprite.position = Vector2(side * attachments - CHAIN_REGION.size.x * CHAIN_SCALE * .5, 8.0 + index * stride)
			var atlas := sprite.texture as AtlasTexture
			atlas.region = Rect2(CHAIN_REGION.position, Vector2(CHAIN_REGION.size.x, minf(CHAIN_REGION.size.y, remaining / CHAIN_SCALE)))

func _exit_tree() -> void:
	if is_instance_valid(rig) and not rig.is_queued_for_deletion():
		rig.queue_free()
