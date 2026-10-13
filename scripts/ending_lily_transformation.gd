extends Node2D

const TRAIL_POOL := preload("res://scripts/moon_wisp_trail_pool.gd")

var orbit_radius := Vector2(125,55)
var spawn_interval := .14
var trail_scale := .12
var trail_opacity := .34
var trail_lifetime := .95
var intensity := 0.0:
	set(value):
		intensity = value
		queue_redraw()
var emitting := true
var elapsed := 0.0
var emit_clock := 0.0
var pool: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	z_index = -2
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit
	pool = TRAIL_POOL.new()
	pool.name = "EndingOrbitLilyPool"
	pool.capacity = 18
	pool.frame_root = "res://assets/game_assets/moon_wisp/lily_trail/"
	pool.file_prefix = "lily_trail"
	pool.canvas_size = Vector2(512,512)
	pool.front_pivot = Vector2(150,350)
	pool.authored_direction = Vector2(-270,150).normalized()
	add_child(pool)

func _process(delta: float) -> void:
	if not emitting:
		return
	elapsed += delta
	emit_clock += delta
	if emit_clock < spawn_interval:
		return
	emit_clock = fmod(emit_clock,spawn_interval)
	for ribbon in range(2):
		var angle := elapsed * 1.8 + ribbon * PI
		var point := Vector2(cos(angle)*orbit_radius.x,sin(angle)*orbit_radius.y)
		var tangent := Vector2(-sin(angle)*orbit_radius.x,cos(angle)*orbit_radius.y).normalized()
		# Each pooled afterimage stays at its emission point and fades independently.
		pool.emit_trail(global_position+point,tangent,trail_scale,
			trail_opacity * lerpf(.4,1,intensity),trail_lifetime,.35)

func _draw() -> void:
	# Restrained moonlight beneath the body, building with the orbiting lilies.
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.55))
	for index in range(5):
		draw_circle(Vector2.ZERO,125-index*14,Color(.72,.84,1,.022*intensity))
	draw_set_transform(Vector2.ZERO)

func stop_emitting() -> void:
	emitting = false
	# Already spawned lilies finish their own animation and fade naturally.
