extends CharacterBody2D

const ANIMATIONS := preload("res://scripts/red_animation_library.gd")
const SPEED := 420.0
const MAX_RANGE := 560.0
# Authored bounds of the main arc in the unchanged source PNGs. Ignore stray
# embers; retain the last arc's reach while its final dissipation frame plays.
const ARC_BOUNDS := [
	Rect2(150, 205, 205, 155),
	Rect2(100, 160, 255, 200),
	Rect2(85, 130, 320, 250),
	Rect2(75, 115, 345, 280),
	Rect2(130, 95, 285, 250),
	Rect2(180, 130, 240, 220),
	Rect2(215, 155, 195, 185),
	Rect2(210, 155, 195, 190),
]
@export var hitbox_padding := Vector2(2, 2)
var direction := 1
var damage := 20
var source: Node2D
var travelled := 0.0
var impacting := false
var visual: AnimatedSprite2D
var enemy_hitbox: Area2D
var enemy_shape: CollisionShape2D
var enemy_rectangle: RectangleShape2D

func _ready() -> void:
	add_to_group("red_projectiles")
	collision_layer = 0
	collision_mask = 1 # Compact terrain collision; EnemyHitbox handles damage.
	if is_instance_valid(source) and source is PhysicsBody2D:
		add_collision_exception_with(source as PhysicsBody2D)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16, 18)
	shape.shape = rectangle
	add_child(shape)
	# A broad enemy hitbox must not make the low-flying wave hit the floor.
	enemy_hitbox = Area2D.new()
	enemy_hitbox.name = "EnemyHitbox"
	enemy_hitbox.collision_layer = 0
	enemy_hitbox.collision_mask = 2
	enemy_hitbox.body_entered.connect(_on_enemy_entered)
	enemy_hitbox.area_entered.connect(_on_enemy_entered)
	enemy_shape = CollisionShape2D.new()
	enemy_rectangle = RectangleShape2D.new()
	enemy_shape.shape = enemy_rectangle
	enemy_hitbox.add_child(enemy_shape)
	add_child(enemy_hitbox)
	visual = AnimatedSprite2D.new()
	visual.name = "ProjectileVisual"
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.sprite_frames = ANIMATIONS.projectile_frames()
	visual.flip_h = direction < 0
	visual.z_index = 2
	visual.animation_finished.connect(_on_animation_finished)
	visual.frame_changed.connect(_update_visual_transform)
	add_child(visual)
	visual.play("flight")
	_update_visual_transform()

func _update_visual_transform() -> void:
	visual.transform = ANIMATIONS.projectile_transform(visual.animation, visual.frame)
	# Full source frames use a different scale than the retained impact art.
	visual.reset_physics_interpolation()
	if visual.animation == "flight" and not impacting:
		var bounds: Rect2 = ARC_BOUNDS[clampi(visual.frame, 0, 7)]
		var texture := visual.sprite_frames.get_frame_texture("flight", visual.frame)
		var scale := visual.scale
		var center := (bounds.get_center() - texture.get_size() * .5) * scale
		center.x *= direction
		enemy_shape.position = visual.position + center
		enemy_rectangle.size = bounds.size * scale + hitbox_padding * 2.0

func _on_enemy_entered(target: Node2D) -> void:
	if target.has_method("get_damage_receiver"):
		target = target.get_damage_receiver() as Node2D
	if is_instance_valid(target) and not impacting and target != source and target.has_method("take_damage"):
		_impact(target)

func _impact(target: Node2D) -> void:
	if impacting:
		return
	impacting = true
	collision_mask = 0
	enemy_hitbox.set_deferred("monitoring", false)
	if target != null and target != source and target.has_method("take_damage"):
		target.take_damage(damage, direction * 180.0)
		# A lethal boss hit may synchronously start the ending and remove this shot.
		if is_queued_for_deletion():
			return
		if is_instance_valid(source) and source.has_method("_start_hitstop"):
			source._start_hitstop(.08, .055)
	visual.play("impact")
	_update_visual_transform()

func _physics_process(delta: float) -> void:
	if impacting:
		return
	var distance := minf(SPEED * delta, MAX_RANGE - travelled)
	var contact := move_and_collide(Vector2(direction * distance, 0))
	travelled += distance
	if contact != null:
		var target := contact.get_collider() as Node2D
		_impact(target)
	elif travelled >= MAX_RANGE:
		queue_free()

func _on_animation_finished() -> void:
	if impacting:
		queue_free()
