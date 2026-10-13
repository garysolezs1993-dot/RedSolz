extends Node2D

const VISUAL := preload("res://scripts/moon_seal_visual.gd")
const WISP := preload("res://scenes/moon_wisp_visual.tscn")
@export var identifier := "moon_seal"
@export var region_name := "Quiet Forest"
@export var objective_manager_path := NodePath("../StageObjectives")
@export var guard_names: Array[String] = []
@export_range(60, 180, 1) var shrine_height := 110.0
@export_group("Released Wisp")
@export var full_cinematic := false
@export var guide_route: Array[Vector2] = []
@export var guide_target := Vector2.ZERO
@export_range(.3, .8, .05) var guide_release_delay := .5
var state := "dormant"
var activated := false
var activation_count := 0
var elapsed := 0.0
var manager: Node2D
var art: AnimatedSprite2D
var spirit: Node2D
var wisp_state := "seal_hover"
var player: CharacterBody2D
var actor: CharacterBody2D
var release_remaining := -1.0
var blocked_message_cooldown := 0.0
var last_blocked_reason := ""
var reaction_origin := Vector2.ZERO

func living_guard_count() -> int:
	var count := 0
	for guard_name in guard_names:
		var guard := get_parent().get_node_or_null(NodePath(guard_name))
		if is_instance_valid(guard) and not guard.is_queued_for_deletion() and not bool(guard.get("dead")):
			count += 1
	return count

func blocked_reason() -> String:
	if manager == null:
		return "The seal is dormant."
	var previous: Node2D = manager.prerequisite_seal(identifier)
	if previous != null:
		return "Awaken the seal in %s first." % previous.region_name
	var guards := living_guard_count()
	return "Defeat the seal guardians — %d remaining" % guards if guards > 0 else ""

func _ready() -> void:
	add_to_group("moon_seals")
	z_index = 0
	manager = get_node_or_null(objective_manager_path)
	if manager != null:
		manager.register_seal(self)
		activated = GameSession.objective_completed(manager.stage_scene_path, identifier)
	art = VISUAL.new()
	art.name = "SealVisual"
	art.shrine_height = shrine_height
	add_child(art)
	art.activation_finished.connect(_activation_finished)
	spirit = WISP.instantiate()
	spirit.name = "SealSpirit"
	spirit.gameplay_scale = .03
	spirit.trail_enabled = false
	spirit.z_index = 2
	add_child(spirit)
	var interaction := Node2D.new()
	interaction.name = "SealInteraction"
	interaction.set_script(preload("res://scripts/world_interactable.gd"))
	interaction.set("prompt_text", "E — Awaken Moon Seal")
	interaction.set("interaction_range", Vector2(65, 38))
	interaction.set("priority", 5)
	interaction.position.y = -15
	add_child(interaction)
	_set_state("activated_idle" if activated else "dormant")

func _set_state(next: String) -> void:
	state = next
	art.set_state(next)
	if next == "activated_idle":
		wisp_state = ""
		spirit.deactivate()
	elif next == "activating":
		wisp_state = "seal_react"
	else:
		wisp_state = "seal_hover"

func in_interaction_range(body: Node2D) -> bool:
	var difference := body.global_position - (global_position + Vector2(0, -15))
	return absf(difference.x) <= 65 and absf(difference.y) <= 38

func can_interact(body: Node2D) -> bool:
	return manager != null and not activated and state != "activating" and not bool(body.get("dead")) and body.get("action_state") == 0 and body.is_on_floor()

func interact(body: Node2D) -> void:
	if not can_interact(body):
		return
	var reason := blocked_reason()
	if not reason.is_empty():
		if blocked_message_cooldown <= 0 or reason != last_blocked_reason:
			GameSession.notify(reason)
			blocked_message_cooldown = 1.8
			last_blocked_reason = reason
		return
	actor = body as CharacterBody2D
	actor._cancel_action()
	actor.facing = 1 if actor.global_position.x < global_position.x else -1
	actor.visual.flip_h = actor.facing < 0
	# Keep the current Red artwork rather than switching to an older interaction skin.
	actor._play_visual("idle")
	actor.action_state = actor.Action.INTERACT
	actor.seal_interaction = self
	actor.velocity = Vector2.ZERO
	var guide := get_parent().get_node_or_null("MoonWispGuide")
	if guide != null:
		guide.suspend_for_seal()
	spirit.play_state("idle")
	reaction_origin = spirit.position if spirit.position.length_squared() > 1 else Vector2(-10, -shrine_height * .85)
	_set_state("activating")
	AudioDirector.play_sfx("menu_confirm")

func advance_player(body: CharacterBody2D, delta: float) -> bool:
	if state != "activating" or actor != body:
		return false
	if body.dead or body.action_state != body.Action.INTERACT or GameSession.transitioning or not in_interaction_range(body):
		cancel_activation()
		return false
	body.velocity = Vector2(0, body.GRAVITY * delta)
	body.move_and_slide()
	if not body.is_on_floor():
		cancel_activation()
		return false
	return true

func _release_actor() -> void:
	if is_instance_valid(actor) and actor.seal_interaction == self:
		actor.seal_interaction = null
		if not actor.dead and actor.action_state == actor.Action.INTERACT:
			actor.action_state = actor.Action.NONE
			actor.velocity.x = 0
			actor._play_visual("idle")
	actor = null

func cancel_activation() -> void:
	if state != "activating":
		return
	_release_actor()
	_set_state("dormant")

func _activation_finished() -> void:
	if state != "activating":
		return
	if not is_instance_valid(actor) or actor.dead or GameSession.transitioning or not manager.awaken(self, false):
		cancel_activation()
		return
	activated = true
	activation_count += 1
	_set_state("activated_idle")
	_release_actor()
	release_remaining = guide_release_delay

func wisp_release_position() -> Vector2:
	return global_position + Vector2(0, -shrine_height * .53)

func _process(delta: float) -> void:
	elapsed += delta
	blocked_message_cooldown = maxf(0, blocked_message_cooldown - delta)
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if release_remaining >= 0:
		release_remaining -= delta
		if release_remaining < 0 and is_instance_valid(player) and not player.dead and not GameSession.transitioning:
			manager.seal_awakened.emit(self, full_cinematic)
	if state == "activating":
		_react_spirit()
		return
	if activated:
		return
	var nearby: bool = is_instance_valid(player) and not player.dead and in_interaction_range(player)
	var next := "interact_ready" if nearby else "dormant"
	if state != next:
		_set_state(next)
	var reason := blocked_reason()
	$SealInteraction.prompt_text = "E — Awaken Moon Seal" if reason.is_empty() else "E — " + reason
	_update_hover(nearby)

func _update_hover(nearby: bool) -> void:
	var guide := get_parent().get_node_or_null("MoonWispGuide")
	if not is_instance_valid(player) or player.dead or player.global_position.distance_to(global_position) > 350 or (guide != null and guide.phase != "hidden"):
		spirit.deactivate()
		return
	spirit.play_state("idle")
	spirit.modulate = Color(1, .85, .95, .45 if nearby else .22)
	if nearby:
		var points := [Vector2(-10, -shrine_height * .85), Vector2(20, -shrine_height * .5), Vector2(-24, -shrine_height * .28)]
		var progress := fmod(elapsed / 2.0, 3.0)
		var index := int(progress)
		spirit.position = points[index].lerp(points[(index + 1) % 3], smoothstep(0, 1, progress - index))
	else:
		spirit.position = Vector2(-10 + sin(elapsed * .7) * 4, -shrine_height * .82 + cos(elapsed * .6) * 3)

func _react_spirit() -> void:
	var progress: float = art.activation_progress()
	var rune := Vector2(0, -shrine_height * .53)
	spirit.modulate = Color(1, .8, .9, .55)
	if progress < .16:
		spirit.position = reaction_origin
	elif progress < .46:
		var angle := (progress - .16) / .30 * TAU - PI * .5
		spirit.position = rune + Vector2(cos(angle), sin(angle)) * 22
	else:
		spirit.position = (rune + Vector2(0, -22)).lerp(rune, smoothstep(.46, .58, progress))
		spirit.modulate.a = .55 * (1 - smoothstep(.46, .58, progress))
		if progress >= .58:
			spirit.deactivate()

func _exit_tree() -> void:
	_release_actor()
