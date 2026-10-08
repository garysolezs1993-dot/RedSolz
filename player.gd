extends CharacterBody2D

signal attack_requested

const RUN_SPEED := 285.0
const ACCELERATION := 1800.0
const GRAVITY := 1450.0
const JUMP_SPEED := -530.0
const DASH_SPEED := 640.0

var facing := 1.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var attack_timer := 0.0
var step_phase := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var shape := CapsuleShape2D.new()
	shape.radius = 12.0
	shape.height = 38.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -90)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_right = 3400
	camera.limit_top = 0
	camera.limit_bottom = 930
	add_child(camera)

func _physics_process(delta: float) -> void:
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if attack_timer > 0.0:
		attack_timer -= delta
	if Input.is_action_just_pressed("attack"):
		attack_timer = 0.20
		attack_requested.emit()
	var direction := Input.get_axis("move_left", "move_right")
	if abs(direction) > 0.05:
		facing = sign(direction)
	if Input.is_action_just_pressed("sprint") and dash_cooldown <= 0.0:
		dash_timer = 0.17
		dash_cooldown = 0.62
		velocity.y = 0.0
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = facing * DASH_SPEED
		move_and_slide()
		queue_redraw()
		return
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, ACCELERATION * delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_SPEED
	if abs(velocity.x) > 10.0:
		step_phase += delta * 12.0
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var bob := sin(step_phase * 2.0) * 1.5 if is_on_floor() and abs(velocity.x) > 10 else 0.0
	# Pool of pale lantern light and a soft foot shadow.
	draw_circle(Vector2(0, 1), 37, Color(0.82, 0.72, 0.56, 0.055))
	_draw_ellipse(Vector2(0, 19), Vector2(17, 5), Color(0.015, 0.015, 0.025, 0.58))
	# Back cloak, boots and face in a clean side silhouette.
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -9 + bob), Vector2(4, -14 + bob), Vector2(12, -4 + bob), Vector2(9, 13 + bob), Vector2(-3, 18 + bob), Vector2(-16, 15 + bob), Vector2(-11, 2 + bob)]), Color("493341"))
	var leg_swing := sin(step_phase) * 3.0 if is_on_floor() and abs(velocity.x) > 10 else 0.0
	draw_line(Vector2(-4, 11 + bob), Vector2(-7 + leg_swing, 19 + bob), Color("1c1b25"), 4, true)
	draw_line(Vector2(4, 11 + bob), Vector2(7 - leg_swing, 19 + bob), Color("28212b"), 4, true)
	draw_circle(Vector2(2 * facing, -9 + bob), 7.5, Color("d7b28f"))
	# Hood brim and one bright eye.
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -13 + bob), Vector2(2, -20 + bob), Vector2(11 * facing, -14 + bob), Vector2(8 * facing, -7 + bob), Vector2(-6, -7 + bob)]), Color("211e2b"))
	draw_circle(Vector2(6 * facing, -9 + bob), 1.4, Color("ffe2a0"))
	# Small spirit blade and an arc while attacking.
	draw_line(Vector2(8 * facing, 1 + bob), Vector2(20 * facing, 5 + bob), Color("c7a06c"), 2.5, true)
	if attack_timer > 0.0:
		var start_angle := -1.15 if facing > 0 else PI - 1.15
		draw_arc(Vector2(17 * facing, -5 + bob), 28, start_angle, start_angle + 2.3, 20, Color("d8e6e4"), 4, true)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
