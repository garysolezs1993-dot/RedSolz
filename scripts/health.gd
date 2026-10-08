class_name Health
extends Node
signal health_changed(current, maximum)
signal died
@export var maximum_health=100
var current_health
func _ready():
    current_health=maximum_health
func damage(amount):
    current_health=max(0,current_health-amount)
    health_changed.emit(current_health,maximum_health)
    if current_health==0: died.emit()
