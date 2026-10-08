extends Node
class_name SoniloAudioComponent
## Runtime component that stores Sonilo generation metadata alongside the
## generated audio, and provides simple playback / fading helpers.
##
## Added automatically by the Sonilo Audio Generator dock, but can also be
## added and configured manually. Assign [member audio_player] to an
## AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D.

## "Music" or "SoundEffect".
@export var audio_type: String = "Music"

@export_group("Sonilo Metadata")
@export var primary_game_type: String = ""
@export var sub_game_type: String = ""
@export var final_game_type: String = ""
@export var scenario_category: String = ""
@export var scenario: String = ""
@export var mood_tags: PackedStringArray = []
@export var dynamic_behavior: String = ""

@export_group("Audio Settings")
@export var is_spatial_audio: bool = false
@export_range(1, 10) var intensity: int = 5
@export var bpm: int = 120
@export_range(0.0, 1.0) var volume: float = 1.0
@export_range(0.1, 3.0) var pitch: float = 1.0

@export_group("References")
@export var audio_stream: AudioStream
## AudioStreamPlayer / AudioStreamPlayer2D / AudioStreamPlayer3D.
@export var audio_player: Node

var _fade_tween: Tween


## Plays the assigned stream using the configured settings.
func play() -> void:
	if not _ensure_player():
		return
	# set()/call() are used because the player may be an AudioStreamPlayer,
	# AudioStreamPlayer2D, or AudioStreamPlayer3D.
	if audio_stream != null:
		audio_player.set("stream", audio_stream)
	if audio_player.get("stream") == null:
		push_warning("[Sonilo] No audio stream assigned. Nothing to play.")
		return
	_set_linear_volume(volume)
	audio_player.set("pitch_scale", pitch)
	audio_player.call("play")


## Stops playback immediately.
func stop() -> void:
	_kill_fade()
	if _ensure_player():
		audio_player.call("stop")


## Sets the playback volume (clamped to 0..1) and applies it.
func set_volume(new_volume: float) -> void:
	volume = clampf(new_volume, 0.0, 1.0)
	if audio_player != null:
		_set_linear_volume(volume)


## Starts playback (if needed) and fades from silence up to the configured
## volume over the given duration in seconds.
func fade_in(duration: float) -> void:
	if not _ensure_player():
		return
	_kill_fade()
	_set_linear_volume(0.0)
	if not audio_player.get("playing"):
		if audio_stream != null:
			audio_player.set("stream", audio_stream)
		audio_player.set("pitch_scale", pitch)
		audio_player.call("play")
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_linear_volume, 0.0, volume, maxf(0.0, duration))


## Fades the volume down to silence over the given duration in seconds,
## stopping playback when the fade completes.
func fade_out(duration: float) -> void:
	if not _ensure_player():
		return
	_kill_fade()
	var start: float = db_to_linear(audio_player.get("volume_db"))
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_linear_volume, start, 0.0, maxf(0.0, duration))
	_fade_tween.tween_callback(Callable(audio_player, "stop"))


func _set_linear_volume(linear: float) -> void:
	if audio_player != null:
		audio_player.set("volume_db", linear_to_db(maxf(linear, 0.0001)))


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _ensure_player() -> bool:
	if audio_player == null:
		# Convenience: look for a sibling/child stream player.
		for child in get_parent().get_children() if get_parent() != null else []:
			if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
				audio_player = child
				break
	if audio_player == null:
		push_warning("[Sonilo] No AudioStreamPlayer found or assigned.")
		return false
	return true
