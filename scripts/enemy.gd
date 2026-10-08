extends CharacterBody2D

const ART_ATLAS := preload("res://assets/game_assets/red_riding_hood_asset_atlas.png")
@export var sprite_frame_x := PackedInt32Array([833, 865, 895])
@export var sprite_frame_y := 688
@export var sprite_frame_width := 32
@export var sprite_frame_height := 32
var hp := 50
var target: Node2D
@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
    add_to_group("enemies")
    target=get_tree().get_first_node_in_group("player")
    visual.sprite_frames = _make_frames()
    visual.play("walk")

func _make_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    frames.add_animation("walk")
    frames.set_animation_speed("walk", 7.0)
    frames.set_animation_loop("walk", true)
    for x in sprite_frame_x:
        var texture := AtlasTexture.new()
        texture.atlas = ART_ATLAS
        texture.region = Rect2(x, sprite_frame_y, sprite_frame_width, sprite_frame_height)
        texture.filter_clip = true
        frames.add_frame("walk", texture)
    return frames

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y+=1000*delta
    if target:
        var d=target.global_position.x-global_position.x
        if abs(d)<240 and abs(d)>30: velocity.x=sign(d)*55
        else: velocity.x=move_toward(velocity.x,0,300*delta)
        if abs(d)>30:
            visual.flip_h = d < 0
        if abs(d)<34: target.take_damage(8,sign(d)*150)
    move_and_slide()

func take_damage(amount: int,knockback: float=0.0) -> void:
    hp-=amount
    var audio=get_tree().get_first_node_in_group("audio_manager")
    if audio: audio.play_sfx("hit")
    velocity.x=knockback
    velocity.y=-100
    if hp<=0: queue_free()
