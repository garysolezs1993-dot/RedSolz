extends AudioStreamPlayer

@export_enum("title", "game_over") var context := "title"

func _ready() -> void:
	stop()
	AudioDirector.set_context(context)
