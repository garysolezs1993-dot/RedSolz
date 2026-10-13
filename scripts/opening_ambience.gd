extends RefCounted

static func make_wind() -> AudioStreamWAV:
	# Quiet procedural wind/rustle: no source audio files are rewritten.
	const RATE := 22050
	const SAMPLES := RATE * 6
	var data := PackedByteArray()
	data.resize(SAMPLES * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 71026
	var low := 0.0
	var softer := 0.0
	var samples := PackedFloat32Array()
	samples.resize(SAMPLES)
	for index in range(SAMPLES):
		low = lerpf(low, noise.randf_range(-1, 1), .06)
		softer = lerpf(softer, low, .018)
		var gust := .65 + .25 * sin(TAU * index / SAMPLES)
		samples[index] = (softer * .7 + (low - softer) * .3) * gust
	# Join the loop without a sudden sample discontinuity.
	for index in range(1024):
		var progress := float(index) / 1023
		samples[SAMPLES - 1024 + index] = lerpf(samples[SAMPLES - 1024 + index], samples[index], progress)
	for index in range(SAMPLES):
		var value := int(clampf(samples[index], -1, 1) * 32767)
		data[index * 2] = value & 255
		data[index * 2 + 1] = (value >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 1024
	stream.loop_end = SAMPLES
	return stream
