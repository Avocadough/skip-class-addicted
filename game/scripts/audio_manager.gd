extends Node

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -17.0
	add_child(_music_player)
	for index in 4:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)
	_streams = {
		"jump": _make_tone(520.0, 0.10, 0.28, 760.0),
		"pickup": _make_tone(880.0, 0.13, 0.25, 1180.0),
		"alert": _make_tone(180.0, 0.22, 0.30, 120.0),
		"door": _make_tone(330.0, 0.18, 0.25, 490.0),
		"caught": _make_tone(210.0, 0.45, 0.30, 80.0),
		"complete": _make_tone(620.0, 0.42, 0.25, 1040.0),
		"click": _make_tone(720.0, 0.06, 0.18, 720.0),
	}
	apply_options()


func start_music() -> void:
	if _music_player.playing:
		return
	if _music_player.stream == null:
		_music_player.stream = _make_music_loop()
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_sfx(kind: String) -> void:
	if not GameState.sfx_enabled or not _streams.has(kind):
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = _streams[kind]
			player.play()
			return
	_sfx_players[0].stream = _streams[kind]
	_sfx_players[0].play()


func apply_options() -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if music_bus >= 0:
		AudioServer.set_bus_mute(music_bus, not GameState.music_enabled)
	if sfx_bus >= 0:
		AudioServer.set_bus_mute(sfx_bus, not GameState.sfx_enabled)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _make_tone(start_hz: float, duration: float, volume: float, end_hz: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var frames := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0
	for frame in frames:
		var progress := float(frame) / float(frames)
		var frequency := lerpf(start_hz, end_hz, progress)
		phase += TAU * frequency / SAMPLE_RATE
		var envelope := sin(PI * progress)
		var sample := int(sin(phase) * envelope * volume * 32767.0)
		data.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _make_music_loop() -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const DURATION := 8.0
	var frames := int(SAMPLE_RATE * DURATION)
	var notes := [220.0, 261.63, 329.63, 293.66, 246.94, 293.66, 369.99, 329.63]
	var data := PackedByteArray()
	data.resize(frames * 2)
	for frame in frames:
		var time := float(frame) / SAMPLE_RATE
		var note_index := int(time / 0.5) % notes.size()
		var frequency: float = notes[note_index]
		var beat := fmod(time, 0.5) / 0.5
		var envelope := minf(1.0, beat * 12.0) * (1.0 - beat * 0.45)
		var melody := sin(TAU * frequency * time) * 0.11
		var bass := sin(TAU * frequency * 0.5 * time) * 0.07
		var sample := int((melody + bass) * envelope * 32767.0)
		data.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	stream.data = data
	return stream
