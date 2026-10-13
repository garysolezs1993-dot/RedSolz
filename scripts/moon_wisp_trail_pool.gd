extends Node2D

const FRAME_ROOT := "res://assets/game_assets/moon_wisp/trail/"
const CANVAS_SIZE := Vector2(444, 444)
# Front of the whole authored clip, not an alpha crop or per-frame recenter.
const FRONT_PIVOT := Vector2(420, 300)
var frame_root := FRAME_ROOT
var file_prefix := "wisp_trail"
var canvas_size := CANVAS_SIZE
var front_pivot := FRONT_PIVOT
var authored_direction := Vector2.RIGHT
var capacity := 12
var slots: Array[Dictionary] = []
var spawned_count := 0
var active_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	z_index = 6
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("trail")
	frames.set_animation_loop("trail", false)
	frames.set_animation_speed("trail", 16.0)
	for index in range(8):
		frames.add_frame("trail", load(frame_root + file_prefix + "_%02d.png" % index) as Texture2D)
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for index in range(capacity):
		var sprite := AnimatedSprite2D.new()
		sprite.name = "Trail%02d" % index
		sprite.centered = false
		sprite.sprite_frames = frames
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.material = unlit
		sprite.hide()
		add_child(sprite)
		slots.append({"sprite": sprite, "active": false, "age": 0.0,
			"lifetime": .5, "fade": .2, "opacity": .35})
	set_process(false)

func emit_trail(where: Vector2, direction: Vector2, size: float,
		opacity: float, lifetime: float, fade: float) -> bool:
	for slot in slots:
		if slot.active:
			continue
		var sprite := slot.sprite as AnimatedSprite2D
		slot.active = true
		slot.age = 0.0
		slot.lifetime = maxf(.1, lifetime)
		slot.fade = clampf(fade, .001, slot.lifetime)
		slot.opacity = clampf(opacity, 0, .65)
		sprite.stop()
		sprite.scale = Vector2.ONE * size
		sprite.flip_h = (direction.x < 0) != (authored_direction.x < 0)
		var source_direction := authored_direction
		var pivot := front_pivot
		if sprite.flip_h:
			pivot.x = canvas_size.x - pivot.x
			source_direction.x = -source_direction.x
		sprite.rotation = direction.angle() - source_direction.angle()
		sprite.offset = -pivot
		# The pool is a sibling in the world, never a child of the moving Wisp.
		# Position and orientation are assigned once and never updated afterward.
		sprite.global_position = where
		sprite.modulate = Color(1, 1, 1, slot.opacity)
		sprite.speed_scale = .5 / float(slot.lifetime)
		sprite.play("trail")
		sprite.show()
		active_count += 1
		spawned_count += 1
		set_process(true)
		return true
	return false # Preserve old effects when the bounded pool is full.

func _process(delta: float) -> void:
	for slot in slots:
		if not slot.active:
			continue
		slot.age = float(slot.age) + delta
		var sprite := slot.sprite as AnimatedSprite2D
		if float(slot.age) >= float(slot.lifetime):
			sprite.hide()
			sprite.stop()
			slot.active = false
			active_count -= 1
		else:
			var fade_start: float = slot.lifetime - slot.fade
			var progress := clampf((float(slot.age) - fade_start) / float(slot.fade), 0, 1)
			sprite.modulate.a = float(slot.opacity) * (1.0 - smoothstep(0, 1, progress))
	if active_count == 0:
		set_process(false)
