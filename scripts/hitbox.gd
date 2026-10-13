class_name DamageHitbox
extends Area2D
signal hit_confirmed(target: Node2D)
@export var damage=20
var active=false
var owner_node
var hit_targets={}
func _ready():
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_body_entered)
func _physics_process(_delta):
    if active:
        for body in get_overlapping_bodies():
            _hit(body)
        for area in get_overlapping_areas():
            _hit(area)
func activate():
    active=true
    hit_targets.clear()
    for body in get_overlapping_bodies():
        _hit(body)
    for area in get_overlapping_areas():
        _hit(area)
func deactivate():
    active=false
    hit_targets.clear()
func _on_body_entered(body):
    _hit(body)
func _hit(candidate):
    if not active or not is_instance_valid(candidate):
        return
    # A character can overlap through its body and hurtbox simultaneously.
    # Resolve both to one receiver so a swing still damages it only once.
    var body = candidate.get_damage_receiver() if candidate.has_method("get_damage_receiver") else candidate
    if is_instance_valid(body) and body!=owner_node and body.has_method("take_damage") and not hit_targets.has(body.get_instance_id()):
        hit_targets[body.get_instance_id()]=true
        body.take_damage(damage,sign(body.global_position.x-global_position.x)*180.0)
        hit_confirmed.emit(body)
