extends CharacterBody2D

const ART_ATLAS := preload("res://assets/game_assets/red_riding_hood_asset_atlas.png")
var health := 300
var timer := 0.0
var target: Node2D

func _ready() -> void:
    add_to_group("boss")
    target=get_tree().get_first_node_in_group("player")
    var portrait := AtlasTexture.new()
    portrait.atlas = ART_ATLAS
    portrait.region = Rect2(940, 680, 80, 100)
    portrait.filter_clip = true
    $Visual.texture = portrait

func _physics_process(delta: float) -> void:
    timer-=delta
    if timer<=0:
        timer=2.0
        if target and global_position.distance_to(target.global_position)<280:
            target.take_damage(15,sign(target.global_position.x-global_position.x)*260)
func take_damage(amount: int,knockback: float=0.0) -> void:
    health-=amount
    if health<=0:
        queue_free()
