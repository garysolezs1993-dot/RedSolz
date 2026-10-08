extends Node

const SFX_PATHS := {
	"jump": "res://audio/sfx/jump.wav",
	"dash": "res://audio/sfx/dash.wav",
	"slash": "res://audio/sfx/slash.wav",
	"spin": "res://audio/sfx/spin.wav",
	"thrust": "res://audio/sfx/thrust.wav",
	"hit": "res://audio/sfx/hit.wav",
	"blood_blossom": "res://audio/sfx/blood_blossom.wav",
	"execution": "res://audio/sfx/execution.wav",
	"wolf_summon": "res://audio/sfx/wolf_summon.wav",
	"wolf_howl": "res://audio/sfx/wolf_howl.wav",
	"wolf_huff": "res://audio/sfx/wolf_huff.wav",
	"wolf_attack": "res://audio/sfx/wolf_attack.wav",
}
const SFX_LEVELS := {
	"jump": -7.0,
	"dash": -5.0,
	"slash": -7.0,
	"spin": -8.0,
	"thrust": -6.0,
	"hit": -5.0,
	"blood_blossom": -7.0,
	"execution": -6.0,
	"wolf_summon": -8.0,
	"wolf_howl": -10.0,
	"wolf_huff": -16.0,
	"wolf_attack": -9.0,
}

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0

func _ready() -> void:
	add_to_group("audio_manager")
	var music_stream := $Music.stream as AudioStreamWAV
	var music_path: String = "<empty Music stream>"
	if $Music.stream != null:
		music_path = $Music.stream.resource_path
	if music_stream == null:
		push_error("Could not load background music: %s" % music_path)
	else:
		# Loop points are measured in samples; set the end explicitly so a zero
		# loop_end from a stale import cannot stop the track near its beginning.
		music_stream.loop_begin = 0
		music_stream.loop_end = int(music_stream.get_length() * float(music_stream.mix_rate))
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		$Music.stream = music_stream
		$Music.bus = "Master"
		# Keep the forest ambience underneath the combat SFX.
		$Music.volume_db = -14.0 if music_path.ends_with("alpha_wolf_boss_theme.wav") else -10.0
		if not $Music.playing:
			$Music.play()
		if $Music.playing:
			print("Background music started: %s" % music_path)
		else:
			push_warning("Background music did not start playing.")
	for sound_name in SFX_PATHS:
		streams[sound_name] = load(SFX_PATHS[sound_name])
	for index in range(16):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		add_child(player)
		players.append(player)

func play_sfx(sound_name: String) -> void:
	if not streams.has(sound_name) or players.is_empty():
		return
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = streams[sound_name]
	player.volume_db = SFX_LEVELS.get(sound_name, -6.0)
	player.play()
