class_name DamageHitbox
extends Area2D
signal hit_confirmed(target: Node2D)
@export var damage=20
var active=false
var owner_node
var hit_targets={}
func _ready():
    body_entered.connect(_on_body_entered)
func activate():
    active=true
    hit_targets.clear()
    for body in get_overlapping_bodies():
        _hit(body)
func deactivate():
    active=false
    hit_targets.clear()
func _on_body_entered(body):
    _hit(body)
func _hit(body):
    if active and body!=owner_node and body.has_method("take_damage") and not hit_targets.has(body.get_instance_id()):
        hit_targets[body.get_instance_id()]=true
        body.take_damage(damage,sign(body.global_position.x-global_position.x)*180.0)
        hit_confirmed.emit(body)
