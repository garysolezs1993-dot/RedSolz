extends AudioStreamPlayer

const MUSIC_PATH := "res://audio/bgm/silent_forest_theme.wav"

func _ready() -> void:
	var stream := load(MUSIC_PATH) as AudioStreamWAV
	if stream == null:
		push_warning("Could not load story-screen music: %s" % MUSIC_PATH)
		return
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * float(stream.mix_rate))
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	self.stream = stream
	bus = "Master"
	volume_db = -10.0
	play()

