extends AnimatedSprite2D

signal activation_finished
const ROOT := "res://assets/game_assets/moon_seal/"
const ANCHORS := {"dormant": Vector2(561, 1361), "interact_ready": Vector2(181, 526), "activating": Vector2(627, 1239), "activated_idle": Vector2(230, 588)}
const SOURCE_HEIGHTS := {"dormant": 1313.0, "interact_ready": 507.0, "activating": 1207.0, "activated_idle": 562.0}
const ACTIVATION_FLOORS := [1239, 1218, 1208, 1225, 1231, 1233, 1228, 1235]
@export_range(60, 180, 1) var shrine_height := 110.0
@export_range(3, 12, .5) var interaction_fps := 6.0
@export_range(3, 12, .5) var activation_fps := 6.0
@export_range(3, 12, .5) var activated_idle_fps := 5.0
var state := ""

func _ready() -> void:
	# These textures use different source canvas sizes. Their compensating scale
	# must switch with the texture, not interpolate from the previous clip's scale.
	# The shrine is fixed scenery, so it does not need physics interpolation.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	sprite_frames.add_animation("dormant")
	sprite_frames.add_frame("dormant", load(ROOT + "dormant.png"))
	sprite_frames.set_animation_loop("dormant", false)
	_add_clip("interact_ready", "interact/moon_seal_interact_", 8, interaction_fps, true)
	_add_clip("activating", "activation/moon_seal_activation_clean_frames_for_codex/moon_seal_activation_", 8, activation_fps, false)
	_add_clip("activated_idle", "idle/moon_seal_idle_", 5, activated_idle_fps, true)
	frame_changed.connect(_align)
	animation_finished.connect(_finished)
	set_state("dormant")

func _add_clip(clip: String, prefix: String, count: int, fps: float, looping: bool) -> void:
	sprite_frames.add_animation(clip)
	sprite_frames.set_animation_speed(clip, fps)
	sprite_frames.set_animation_loop(clip, looping)
	for index in range(count):
		sprite_frames.add_frame(clip, load(ROOT + prefix + "%02d.png" % index))

func set_state(next: String) -> void:
	if state == next:
		return
	state = next
	scale = Vector2.ONE * shrine_height / float(SOURCE_HEIGHTS[state])
	modulate = Color(.67, .63, .72) if state == "dormant" else Color.WHITE
	if state == "dormant":
		stop()
		animation = "dormant"
		set_frame_and_progress(0, 0)
	else:
		play(state)
		set_frame_and_progress(0, 0)
	_align()

func _align() -> void:
	if not ANCHORS.has(state):
		return
	var anchor: Vector2 = ANCHORS[state]
	if state == "activating":
		anchor.y = ACTIVATION_FLOORS[frame]
	offset = -anchor

func activation_progress() -> float:
	return (float(frame) + frame_progress) / 8.0 if state == "activating" else 0.0

func _finished() -> void:
	if state == "activating":
		activation_finished.emit()
