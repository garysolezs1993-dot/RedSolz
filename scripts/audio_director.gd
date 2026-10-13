extends Node

const MUSIC := {
	"title": ["res://audio/bgm/witchs_lullaby.wav", -10.0],
	"opening": ["res://audio/bgm/witchs_lullaby.wav", -17.0],
	"game_over": ["res://audio/bgm/promise_to_rise.wav", -11.0],
	"stage_one": ["res://audio/bgm/silent_forest_theme.wav", -10.0],
	"stage_two": ["res://audio/bgm/alpha_wolf_boss_theme.wav", -14.0],
	"boss_intro": ["res://audio/bgm/silent_forest_theme.wav", -23.0],
	"ending": ["res://audio/bgm/promise_to_rise.wav", -29.0],
	"prototype_complete": ["res://audio/bgm/promise_to_rise.wav", -20.0],
}
const SFX_LEVELS := {
	"jump": -7.0, "dash": -5.0, "slash": -7.0, "spin": -8.0,
	"thrust": -6.0, "hit": -5.0, "blood_blossom": -7.0,
	"execution": -6.0, "wolf_summon": -8.0, "wolf_howl": -10.0,
	"wolf_huff": -16.0, "wolf_attack": -9.0,
	"menu_hover": -18.0, "menu_confirm": -14.0,
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var current_context := ""
var next_player := 0
var request_serial := 0
var music_tween: Tween
var last_hover_ms := -1000

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	music_player.bus = "Music"
	add_child(music_player)
	for index in range(16):
		var player := AudioStreamPlayer.new()
		player.name = "SFX%d" % index
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	for sound_name: String in SFX_LEVELS:
		var path := "res://audio/sfx/%s.wav" % sound_name
		if ResourceLoader.exists(path):
			streams[sound_name] = load(path)
	apply_volumes()

func apply_volumes() -> void:
	for channel: String in ["Music", "SFX"]:
		var value := GameSession.music_volume if channel == "Music" else GameSession.sfx_volume
		var index := AudioServer.get_bus_index(channel)
		if index >= 0:
			AudioServer.set_bus_mute(index, value <= 0.001)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.001, value)))

func set_context(context: String) -> void:
	if context == current_context or not MUSIC.has(context):
		return
	current_context = context
	request_serial += 1
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	music_tween = create_tween().set_ignore_time_scale(true)
	if music_player.playing:
		music_tween.tween_property(music_player, "volume_db", -60.0, 0.28)
	music_tween.tween_callback(_start_track.bind(context, request_serial))

func fade_for_death(duration: float = 0.8) -> void:
	request_serial += 1
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	for player in sfx_players:
		player.stop()
	music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	music_tween.tween_property(music_player, "volume_db", -60.0, duration)

func _start_track(context: String, serial: int) -> void:
	if serial != request_serial:
		return
	# One persistent player: old music stops before the new stream starts.
	music_player.stop()
	var profile: Array = MUSIC[context]
	var path := str(profile[0])
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		push_warning("Missing music for %s: %s" % [context, path])
		return
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * float(stream.mix_rate))
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.stream = stream
	music_player.volume_db = -60.0
	music_player.play()
	music_tween = create_tween().set_ignore_time_scale(true)
	music_tween.tween_property(music_player, "volume_db", float(profile[1]), 0.55)

func play_sfx(sound_name: String) -> void:
	if not streams.has(sound_name):
		return
	if sound_name == "menu_hover":
		var now := Time.get_ticks_msec()
		if now - last_hover_ms < 95:
			return
		last_hover_ms = now
	var player := sfx_players[next_player]
	next_player = (next_player + 1) % sfx_players.size()
	player.stream = streams[sound_name] as AudioStream
	player.volume_db = float(SFX_LEVELS.get(sound_name, -6.0))
	player.play()
