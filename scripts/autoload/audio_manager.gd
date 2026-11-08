extends Node
## Alpomish dostoni: Ovoz effektlari va jang musiqa tizimi (Procedural Audio Synthesizer).
## Godot 4.3 da hech qanday tashqi kutubxonasiz, sof PCM 16-bit to'lqinlarini sintez qiladi.

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_timer: float = 0.0
var _music_beat: int = 0

var sfx_volume_db := -2.0
var music_volume_db := -8.0
var is_music_enabled := true

# Doyra (Usul) ritm naqshi: 1 = GUM (chuqur zarba), 2 = BAK (yuqori jarang), 0 = jimlik
const USUL_BEATS := [1, 0, 2, 0, 2, 1, 0, 2, 0, 1, 2, 0]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# SFX pleerlar hovuzi (bir nechta ovoz birdan eshitilishi uchun)
	for i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	_generate_all_sounds()


func _generate_all_sounds() -> void:
	_streams["swing"] = _gen_swing()
	_streams["hit"] = _gen_clang(540.0, 880.0, 0.22)
	_streams["heavy_hit"] = _gen_clang(320.0, 640.0, 0.35, 1.4)
	_streams["bow_draw"] = _gen_bow_draw()
	_streams["bow_shoot"] = _gen_bow_shoot()
	_streams["arrow_hit"] = _gen_arrow_hit()
	_streams["hoof"] = _gen_hoofbeat()
	_streams["dodge"] = _gen_whoosh(0.18, 0.6)
	_streams["jump"] = _gen_sweep(180.0, 360.0, 0.15)
	_streams["boss_slam"] = _gen_sub_slam()
	_streams["level_up"] = _gen_arpeggio([293.66, 349.23, 392.0, 440.0, 587.33], 0.12) # D, F, G, A, D5
	_streams["victory"] = _gen_arpeggio([220.0, 293.66, 369.99, 440.0, 587.33, 739.99], 0.18)
	_streams["doyra_gum"] = _gen_doyra_gum()
	_streams["doyra_bak"] = _gen_doyra_bak()


func _process(delta: float) -> void:
	if not is_music_enabled or get_tree().paused:
		return

	# Sharqona jang usuli (ritmik doyra pulsi)
	_music_timer += delta
	var beat_len := 0.22 # ~136 BPM jangovar shiddat
	if _music_timer >= beat_len:
		_music_timer -= beat_len
		var beat_type: int = USUL_BEATS[_music_beat % USUL_BEATS.size()]
		_music_beat += 1
		if beat_type == 1:
			play_sfx("doyra_gum", randf_range(0.96, 1.04), music_volume_db)
		elif beat_type == 2:
			play_sfx("doyra_bak", randf_range(0.95, 1.05), music_volume_db - 3.0)


# ---------------------------------------------------------------- Ijro usullari

func play_sfx(sname: String, pitch := 1.0, vol_offset := 0.0) -> void:
	if not _streams.has(sname):
		return
	var stream: AudioStreamWAV = _streams[sname]
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = clampf(pitch, 0.5, 2.0)
			p.volume_db = sfx_volume_db + vol_offset
			p.play()
			return
	# Bo'sh joy topilmasa, birinchisini ishlatamiz
	_players[0].stream = stream
	_players[0].pitch_scale = pitch
	_players[0].volume_db = sfx_volume_db + vol_offset
	_players[0].play()


func play_sword_swing() -> void:
	play_sfx("swing", randf_range(0.9, 1.15))


func play_hit() -> void:
	play_sfx("hit", randf_range(0.92, 1.08))


func play_heavy_hit() -> void:
	play_sfx("heavy_hit", randf_range(0.88, 1.05), 2.0)


func play_bow_draw() -> void:
	play_sfx("bow_draw", randf_range(0.95, 1.05), -2.0)


func play_bow_shoot() -> void:
	play_sfx("bow_shoot", randf_range(0.95, 1.1), 1.0)


func play_arrow_hit() -> void:
	play_sfx("arrow_hit", randf_range(0.9, 1.1))


func play_horse_step() -> void:
	play_sfx("hoof", randf_range(0.88, 1.12), -1.0)


func play_dodge() -> void:
	play_sfx("dodge", randf_range(0.95, 1.15))


func play_jump() -> void:
	play_sfx("jump", randf_range(0.95, 1.05))


func play_level_up() -> void:
	play_sfx("level_up", 1.0, 3.0)


func play_boss_slam() -> void:
	play_sfx("boss_slam", randf_range(0.9, 1.05), 4.0)


func play_victory() -> void:
	play_sfx("victory", 1.0, 4.0)


# ---------------------------------------------------------------- To'lqin generatorlari (PCM 16-bit)

func _create_wav(data: PackedByteArray, mix_rate: int = 22050) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav


func _gen_swing() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.2
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var env := sin((float(i) / samples) * PI) # Parabolik konvert
		var freq := lerpf(420.0, 110.0, float(i) / samples)
		var s := sin(TAU * freq * t) * 0.6 + randf_range(-0.4, 0.4)
		var val := int(clampf(s * env, -1.0, 1.0) * 26000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_whoosh(dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var env := sin((float(i) / samples) * PI)
		var s := randf_range(-1.0, 1.0) * amp
		var val := int(clampf(s * env, -1.0, 1.0) * 24000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_clang(f1: float, f2: float, dur: float, amp := 1.0) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var decay := exp(-t * 14.0)
		var s := (sin(TAU * f1 * t) * 0.5 + sin(TAU * f2 * t) * 0.35 + randf_range(-0.15, 0.15)) * decay * amp
		var val := int(clampf(s, -1.0, 1.0) * 28000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_bow_draw() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.28
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var f := lerpf(180.0, 420.0, float(i) / samples)
		var env := sin((float(i) / samples) * PI)
		var s := (sin(TAU * f * t) * 0.5 + randf_range(-0.25, 0.25)) * env
		var val := int(clampf(s, -1.0, 1.0) * 20000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_bow_shoot() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.22
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var f := lerpf(520.0, 160.0, float(i) / samples)
		var env := exp(-t * 15.0)
		var s := (sin(TAU * f * t) * 0.7 + randf_range(-0.3, 0.3) * (1.0 - t / dur)) * env
		var val := int(clampf(s, -1.0, 1.0) * 29000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_arrow_hit() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.14
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var decay := exp(-t * 28.0)
		var s := (sin(TAU * 220.0 * t) * 0.6 + randf_range(-0.4, 0.4)) * decay
		var val := int(clampf(s, -1.0, 1.0) * 26000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_hoofbeat() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.16
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var decay := exp(-t * 26.0)
		var f := lerpf(140.0, 65.0, float(i) / samples)
		var s := (sin(TAU * f * t) * 0.8 + randf_range(-0.2, 0.2)) * decay
		var val := int(clampf(s, -1.0, 1.0) * 24000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_sub_slam() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.65
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var decay := exp(-t * 5.0)
		var f := lerpf(120.0, 38.0, float(i) / samples)
		var s := (sin(TAU * f * t) * 0.75 + randf_range(-0.25, 0.25) * exp(-t * 12.0)) * decay
		var val := int(clampf(s, -1.0, 1.0) * 31000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_sweep(f_start: float, f_end: float, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var frac := float(i) / samples
		var f := lerpf(f_start, f_end, frac)
		var env := sin(frac * PI)
		var s := sin(TAU * f * t) * env
		var val := int(clampf(s, -1.0, 1.0) * 24000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_doyra_gum() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.25
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var decay := exp(-t * 12.0)
		var f := lerpf(90.0, 48.0, float(i) / samples)
		var s := (sin(TAU * f * t) * 0.85 + randf_range(-0.15, 0.15) * exp(-t * 22.0)) * decay
		var val := int(clampf(s, -1.0, 1.0) * 27000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_doyra_bak() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.16
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var decay := exp(-t * 22.0)
		var f := lerpf(360.0, 180.0, float(i) / samples)
		var s := (sin(TAU * f * t) * 0.6 + randf_range(-0.4, 0.4) * exp(-t * 30.0)) * decay
		var val := int(clampf(s, -1.0, 1.0) * 25000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_arpeggio(notes: Array, note_dur: float) -> AudioStreamWAV:
	var rate := 22050
	var total_dur := notes.size() * note_dur + 0.35
	var samples := int(rate * total_dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		var note_idx := clampi(int(t / note_dur), 0, notes.size() - 1)
		var note_start := note_idx * note_dur
		var note_t := t - note_start
		var f: float = notes[note_idx]
		var decay := exp(-note_t * 6.0)
		var s := (sin(TAU * f * t) * 0.6 + sin(TAU * f * 2.0 * t) * 0.25) * decay
		var val := int(clampf(s, -1.0, 1.0) * 26000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)
