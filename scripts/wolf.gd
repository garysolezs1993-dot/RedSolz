extends Node2D

const ART_ATLAS := preload("res://assets/game_assets/red_riding_hood_asset_atlas.png")
@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
    add_to_group("wolf_guardian")
    visual.sprite_frames = _make_frames()
    visual.play("idle")
    visual.visible = false

func _make_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    frames.add_animation("idle")
    frames.set_animation_speed("idle", 7.0)
    frames.set_animation_loop("idle", true)
    for x in [15, 55, 101, 158, 200, 245]:
        var texture := AtlasTexture.new()
        texture.atlas = ART_ATLAS
        texture.region = Rect2(x, 700, 48, 40)
        texture.filter_clip = true
        frames.add_frame("idle", texture)
    frames.add_animation("attack")
    frames.set_animation_speed("attack", 12.0)
    frames.set_animation_loop("attack", false)
    for x in [35, 86, 154, 210, 278, 319]:
        var texture := AtlasTexture.new()
        texture.atlas = ART_ATLAS
        texture.region = Rect2(x, 758, 48, 48)
        texture.filter_clip = true
        frames.add_frame("attack", texture)
    return frames

func perform_guardian_attack(origin: Vector2, facing: int) -> void:
    if visual.visible: return
    global_position=origin+Vector2(52*facing,-6)
    visual.flip_h = facing < 0
    visual.visible=true
    visual.play("attack")
    var targets=get_tree().get_nodes_in_group("enemies")
    targets.append_array(get_tree().get_nodes_in_group("boss"))
    for enemy in targets:
        if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position)<180:
            enemy.take_damage(35,facing*280)
    await get_tree().create_timer(1.0).timeout
    visual.visible=false
    visual.play("idle")
