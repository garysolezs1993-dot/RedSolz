extends Node2D

signal arrival_finished

const FRAME_ROOT := "res://assets/game_assets/moon_wisp/"
const TRAIL_POOL := preload("res://scripts/moon_wisp_trail_pool.gd")
# Authored glowing-core positions in the untouched 512px canvases. This keeps
# one world pivot even though the supplied core moves inside the source art.
# Once the arrival core dissolves, use the center of its dissipating burst.
const CORE_ANCHORS := {
	"idle": [Vector2(254, 300), Vector2(256, 288), Vector2(244, 292), Vector2(261, 300), Vector2(255, 287), Vector2(256, 286), Vector2(262, 284), Vector2(268, 283)],
	"move": [Vector2(382, 282), Vector2(402, 282), Vector2(402, 310), Vector2(395, 287), Vector2(403, 257), Vector2(416, 264), Vector2(410, 260), Vector2(410, 269)],
	"arrive": [Vector2(392, 346), Vector2(329, 317), Vector2(254, 276), Vector2(281, 280), Vector2(283, 249), Vector2(302, 268), Vector2(278, 270), Vector2(256, 256)],
}

@export_range(.01, .15, .005) var gameplay_scale := .045
@export_range(1, 24, .5) var idle_fps := 9.0
@export_range(1, 24, .5) var move_fps := 11.0
@export_range(1, 24, .5) var arrive_fps := 11.0
@export_group("Lingering Trail")
@export var trail_enabled := true
@export_range(10, 60, 1) var trail_spawn_distance := 20.0
@export_range(.05, .3, .01) var trail_min_interval := .08
@export_range(.2, 1, .05) var trail_lifetime := .5
@export_range(.05, .5, .05) var trail_fade_duration := .2
@export_range(.01, .15, .005) var trail_scale := .05
@export_range(.05, .65, .05) var trail_opacity := .35
@export_range(2, 24, 1) var max_trail_instances := 12
@export_group("White Lily Trail")
@export var lily_trail_enabled := false
@export_range(25, 60, 1) var lily_trail_spawn_distance := 32.0
@export_range(.2, 1, .05) var lily_trail_lifetime := .5
@export_range(.05, .5, .05) var lily_trail_fade_duration := .2
@export_range(.01, .15, .005) var lily_trail_scale := .085
@export_range(.05, .65, .05) var lily_trail_opacity := .28
@onready var sprite: AnimatedSprite2D = $Sprite
var arrival_complete := false
var appearing := false
var heading := Vector2.RIGHT
var trail_pool: Node2D
var lily_trail_pool: Node2D
var use_lily_trail := false
var last_trail_sample := Vector2.ZERO
var trail_distance := 0.0
var trail_time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.scale = Vector2.ONE * gameplay_scale
	sprite.sprite_frames = _make_frames()
	sprite.frame_changed.connect(_align_core)
	sprite.animation_finished.connect(_animation_finished)
	deactivate()
	call_deferred("_attach_trail_pool")

func _attach_trail_pool() -> void:
	if not is_inside_tree():
		return
	# A separate world parent lets trails finish after the guide hides.
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	if trail_enabled:
		trail_pool = TRAIL_POOL.new()
		trail_pool.name = "MoonWispTrailPool"
		trail_pool.capacity = max_trail_instances
		host.add_child(trail_pool)
	if lily_trail_enabled:
		lily_trail_pool = TRAIL_POOL.new()
		lily_trail_pool.name = "WhiteLilyTrailPool"
		lily_trail_pool.capacity = mini(max_trail_instances, 12)
		lily_trail_pool.frame_root = FRAME_ROOT + "lily_trail/"
		lily_trail_pool.file_prefix = "lily_trail"
		lily_trail_pool.canvas_size = Vector2(512, 512)
		# One fixed anchor for the entire diagonal, left-facing authored clip.
		# Full PNG canvases remain intact; orientation is a Godot transform.
		lily_trail_pool.front_pivot = Vector2(150, 350)
		lily_trail_pool.authored_direction = Vector2(-270, 150).normalized()
		host.add_child(lily_trail_pool)

func set_lily_trail_active(enabled: bool) -> void:
	use_lily_trail = enabled and lily_trail_enabled
	last_trail_sample = global_position
	trail_distance = 0.0
	trail_time = 0.0

func _exit_tree() -> void:
	if is_instance_valid(trail_pool):
		trail_pool.queue_free()
	if is_instance_valid(lily_trail_pool):
		lily_trail_pool.queue_free()

func _process(delta: float) -> void:
	var step := global_position.distance_to(last_trail_sample)
	last_trail_sample = global_position
	var enabled := lily_trail_enabled if use_lily_trail else trail_enabled
	if not enabled or not is_visible_in_tree() or sprite.animation != "move" or appearing or step > 120.0:
		trail_distance = 0.0
		trail_time = 0.0
		return
	trail_time += delta
	trail_distance += step
	var spacing := lily_trail_spawn_distance if use_lily_trail else trail_spawn_distance
	var pool := lily_trail_pool if use_lily_trail else trail_pool
	if step > .001 and trail_distance >= spacing and trail_time >= trail_min_interval and is_instance_valid(pool):
		if use_lily_trail:
			pool.emit_trail(global_position, heading, lily_trail_scale, lily_trail_opacity, lily_trail_lifetime, lily_trail_fade_duration)
		else:
			pool.emit_trail(global_position, heading, trail_scale, trail_opacity, trail_lifetime, trail_fade_duration)
		trail_distance = 0.0
		trail_time = 0.0

func _make_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for clip: String in ["idle", "move", "arrive"]:
		frames.add_animation(clip)
		frames.set_animation_loop(clip, clip != "arrive")
		frames.set_animation_speed(clip, idle_fps if clip == "idle" else (move_fps if clip == "move" else arrive_fps))
		var prefix := "arrival" if clip == "arrive" else clip
		for index in range(8):
			var path := FRAME_ROOT + clip + "/wisp_" + prefix + "_%02d.png" % index
			frames.add_frame(clip, load(path) as Texture2D)
	return frames

func play_state(clip: String, duration: float = 0.0) -> void:
	if not sprite.sprite_frames.has_animation(clip):
		return
	show()
	arrival_complete = false
	appearing = false
	if sprite.animation != clip or not sprite.is_playing():
		last_trail_sample = global_position
		trail_distance = 0.0
		trail_time = 0.0
		sprite.stop()
		sprite.speed_scale = 1.0
		if clip == "arrive" and duration > 0:
			# Keep the established guidance cadence; the whole eight-frame clip
			# completes before hiding, rather than fading it off halfway through.
			sprite.speed_scale = 8.0 / (arrive_fps * duration)
		sprite.play(clip)
	_update_orientation()
	_align_core()

func play_appearance(duration: float = .28) -> void:
	show()
	arrival_complete = false
	appearing = true
	sprite.stop()
	sprite.speed_scale = 8.0 / (arrive_fps * maxf(duration, .1))
	# Reuse the vanish art in reverse: embers gather into the Wisp core.
	sprite.play_backwards("arrive")
	_update_orientation()
	_align_core()

func face_travel(displacement: Vector2) -> void:
	if displacement.length_squared() < .0001:
		return
	heading = displacement.normalized()
	_update_orientation()
	_align_core()

func _update_orientation() -> void:
	# Move artwork faces right. Mirroring also mirrors its authored pivot, so
	# the head stays at this node's origin and the tail always stays behind.
	sprite.flip_h = heading.x < 0
	if sprite.animation == "move":
		sprite.rotation = heading.angle() - (PI if sprite.flip_h else 0.0)
	elif sprite.animation == "arrive":
		# Arrival starts with a diagonal comet before dissolving into a swirl.
		sprite.rotation = heading.angle() - (PI * .75 if sprite.flip_h else PI * .25)
	else:
		sprite.rotation = 0.0

func core_anchor() -> Vector2:
	return CORE_ANCHORS[sprite.animation][sprite.frame]

func _align_core() -> void:
	if not CORE_ANCHORS.has(sprite.animation):
		return
	var pivot := core_anchor()
	if sprite.flip_h:
		pivot.x = 512.0 - pivot.x
	sprite.offset = -pivot

func _animation_finished() -> void:
	if appearing:
		play_state("idle")
	elif sprite.animation == "arrive":
		arrival_complete = true
		hide()
		arrival_finished.emit()

func deactivate() -> void:
	sprite.stop()
	arrival_complete = false
	appearing = false
	hide()
