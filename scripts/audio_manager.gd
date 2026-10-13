extends Node

func _ready() -> void:
	add_to_group("audio_manager")
	# Legacy scene players stay silent; the autoload owns the only music player.
	var local_music := get_node_or_null("Music") as AudioStreamPlayer
	if local_music != null:
		local_music.stop()
	var path: String = get_parent().scene_file_path
	AudioDirector.set_context("stage_two" if path == GameSession.STAGE_TWO else "stage_one")

func play_sfx(sound_name: String) -> void:
	AudioDirector.play_sfx(sound_name)
