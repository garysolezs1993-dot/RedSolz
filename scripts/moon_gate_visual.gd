extends Node2D

const ASSET_ROOT := "res://assets/game_assets/moon_gate/"
const STATES: Array[StringName] = [&"dormant", &"awakening_1", &"awakening_2", &"fully_awakened"]

@export_group("Presentation")
@export_range(.1, 2.0, .01) var gameplay_scale := .55
@export_range(1.0, 15.0, .1) var awakening_1_fps := 6.0
@export_range(1.0, 15.0, .1) var awakening_2_fps := 7.0
@export_range(1.0, 15.0, .1) var fully_awakened_fps := 8.0
@export_range(.1, 1.0, .01) var awakening_1_brightness := .78
@export_range(.1, 1.0, .01) var awakening_2_brightness := .9
@export_group("Source Canvas Alignment")
# Source-space anchors identify the center of the walkable stone sill.
# They affect presentation only; the world-space floor anchor never moves.
@export var source_anchors: Array[Vector2] = [Vector2(627, 945), Vector2(256, 520), Vector2(256, 534), Vector2(256, 538)]
# Dormant is a differently exported 1254px square. Its gate occupies the
# whole width, whereas the animated gate occupies about 432px of 512px.
# This fixed canvas calibration is separate from the shared gameplay scale.
@export var dormant_canvas_scale := 432.0 / 1254.0

var seal_count := -1
var state_changes := 0
@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	var clips := SpriteFrames.new()
	clips.remove_animation(&"default")
	clips.add_animation(&"dormant")
	clips.add_frame(&"dormant", load(ASSET_ROOT + "moon_gate_inactive_static_clean.png"))
	clips.set_animation_loop(&"dormant", false)
	_add_loop(clips, &"awakening_1", "moon_gate_awakening1", awakening_1_fps)
	_add_loop(clips, &"awakening_2", "moon_gate_awakening2", awakening_2_fps)
	_add_loop(clips, &"fully_awakened", "moon_gate_fully_awakened", fully_awakened_fps)
	sprite.sprite_frames = clips
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = unshaded
	set_seal_count(0)

func _add_loop(clips: SpriteFrames, clip: StringName, folder: String, fps: float) -> void:
	clips.add_animation(clip)
	clips.set_animation_loop(clip, true)
	clips.set_animation_speed(clip, fps)
	for index in range(5):
		var path := ASSET_ROOT + folder + "/" + folder + "_%02d.png" % index
		clips.add_frame(clip, load(path))

func set_seal_count(completed: int) -> void:
	var next_count := clampi(completed, 0, 3)
	if next_count == seal_count:
		return
	seal_count = next_count
	state_changes += 1
	# Use every complete source texture, including its transparent padding.
	sprite.centered = false
	sprite.offset = -source_anchors[seal_count]
	sprite.scale = Vector2.ONE * gameplay_scale * (dormant_canvas_scale if seal_count == 0 else 1.0)
	var brightness := awakening_1_brightness if seal_count == 1 else (awakening_2_brightness if seal_count == 2 else 1.0)
	sprite.modulate = Color(brightness, brightness, brightness, 1.0)
	if seal_count == 0:
		sprite.stop()
		sprite.animation = &"dormant"
		sprite.set_frame_and_progress(0, 0.0)
	else:
		sprite.play(STATES[seal_count])
		sprite.set_frame_and_progress(0, 0.0)

func floor_anchor() -> Vector2:
	return sprite.to_global(source_anchors[seal_count] + sprite.offset)
