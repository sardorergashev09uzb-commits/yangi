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
	_streams["coin"] = _gen_arpeggio([987.77, 1318.51, 1975.53], 0.05) # Tilla tanga jaranglashi
	_streams["chest"] = _gen_arpeggio([329.63, 440.0, 659.25, 880.0], 0.08) # Xazina ochilishi
	_streams["doyra_gum"] = _gen_doyra_gum()
	_streams["doyra_bak"] = _gen_doyra_bak()

	# Milliy o'zbek do'mbirasi akkord va notalari
	_streams["dom_d3"] = _gen_dombira(146.83, 0.42) # D3
	_streams["dom_f3"] = _gen_dombira(174.61, 0.40) # F3
	_streams["dom_g3"] = _gen_dombira(196.00, 0.40) # G3
	_streams["dom_a3"] = _gen_dombira(220.00, 0.38) # A3
	_streams["dom_c4"] = _gen_dombira(261.63, 0.36) # C4
	_streams["dom_d4"] = _gen_dombira(293.66, 0.35) # D4
	_streams["dom_strum"] = _gen_dombira_strum()


enum MusicState { CALM, BATTLE }
var current_music_state := MusicState.CALM
var _calm_beat := 0
var _combat_cooldown := 0.0

const CALM_MELODY := [
	"dom_d3", "", "dom_g3", "", "dom_a3", "dom_d4", "dom_c4", "",
	"dom_a3", "", "dom_g3", "", "dom_d3", "", "dom_g3", ""
]

const BATTLE_MELODY := [
	"dom_d3", "dom_d3", "dom_g3", "dom_a3", "dom_c4", "dom_d4", "dom_strum", "dom_c4",
	"dom_a3", "dom_a3", "dom_g3", "dom_f3", "dom_d3", "dom_strum", "dom_d3", ""
]
const BATTLE_DOYRA := [1, 0, 2, 2, 1, 0, 2, 1, 1, 0, 2, 2, 1, 2, 2, 0]


func _process(delta: float) -> void:
	if not is_music_enabled or get_tree().paused:
		return

	# Dushman yaqinligini aniqlash (Jang holatiga avtomatik o'tish)
	var player = get_tree().get_first_node_in_group("player")
	var in_combat := false
	if player and is_instance_valid(player):
		var p_pos: Vector3 = player.global_position
		for e in get_tree().get_nodes_in_group("enemies"):
			if e and is_instance_valid(e) and not e.is_queued_for_deletion():
				var d: float = p_pos.distance_to(e.global_position)
				if d < 18.0:
					in_combat = true
					break

	if in_combat:
		_combat_cooldown = 4.0
		current_music_state = MusicState.BATTLE
	elif _combat_cooldown > 0.0:
		_combat_cooldown -= delta
	else:
		current_music_state = MusicState.CALM

	# Milliy musiqani ijro etish
	_music_timer += delta
	var beat_len := 0.18 if current_music_state == MusicState.BATTLE else 0.36
	if _music_timer >= beat_len:
		_music_timer -= beat_len
		if current_music_state == MusicState.BATTLE:
			var idx := _music_beat % BATTLE_MELODY.size()
			_music_beat += 1
			# Doyra zarbi
			var doyra_type: int = BATTLE_DOYRA[idx % BATTLE_DOYRA.size()]
			if doyra_type == 1:
				play_sfx("doyra_gum", randf_range(0.96, 1.04), music_volume_db + 1.0)
			elif doyra_type == 2:
				play_sfx("doyra_bak", randf_range(0.95, 1.05), music_volume_db - 2.0)
			# Do'mbira kuyi
			var note_name: String = BATTLE_MELODY[idx]
			if note_name != "":
				play_sfx(note_name, randf_range(0.98, 1.02), music_volume_db + 2.0)
		else:
			var idx := _calm_beat % CALM_MELODY.size()
			_calm_beat += 1
			# Dasht nafasi: mayin do'mbira va vaqti-vaqti bilan mayin doyra
			if idx % 8 == 0:
				play_sfx("doyra_gum", 0.9, music_volume_db - 6.0)
			var note_name: String = CALM_MELODY[idx]
			if note_name != "":
				play_sfx(note_name, randf_range(0.98, 1.02), music_volume_db)


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


func play_coin() -> void:
	play_sfx("coin", randf_range(0.95, 1.08), 2.0)


func play_chest() -> void:
	play_sfx("chest", 1.0, 3.0)


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


func _gen_dombira(freq: float, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / rate
		# Tirnoq zarbasi (attack click)
		var attack_env := exp(-t * 85.0) * 0.45
		var click := randf_range(-1.0, 1.0) * attack_env

		# Sim tebranishi va garmonikalar (Asosiy, 2- va 3-garmonika)
		var decay := exp(-t * 8.5)
		var h1 := sin(TAU * freq * t) * 0.65
		var h2 := sin(TAU * freq * 2.0 * t) * 0.32 * exp(-t * 14.0)
		var h3 := sin(TAU * freq * 3.0 * t) * 0.18 * exp(-t * 22.0)

		# Qorin rezonansi (yog'och kosaning bo'g'iq tovushi)
		var body_res := sin(TAU * 220.0 * t) * 0.12 * exp(-t * 12.0)

		var s := (h1 + h2 + h3 + click + body_res) * decay
		var val := int(clampf(s, -1.0, 1.0) * 26000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)


func _gen_dombira_strum() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.48
	var samples := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	var f1 := 146.83 # D3
	var f2 := 196.00 # G3
	var f3 := 293.66 # D4

	for i in range(samples):
		var t := float(i) / rate
		var decay := exp(-t * 7.5)
		# Ketma-ket silkinish (12ms oraliq bilan zarb)
		var t1 := t
		var t2 := maxf(t - 0.012, 0.0)
		var t3 := maxf(t - 0.024, 0.0)

		var s1 := sin(TAU * f1 * t1) * 0.45 * exp(-t1 * 8.0)
		var s2 := sin(TAU * f2 * t2) * 0.40 * exp(-t2 * 9.0) if t >= 0.012 else 0.0
		var s3 := sin(TAU * f3 * t3) * 0.35 * exp(-t3 * 10.0) if t >= 0.024 else 0.0
		var click := randf_range(-0.35, 0.35) * exp(-t * 60.0)

		var s := (s1 + s2 + s3 + click) * decay
		var val := int(clampf(s, -1.0, 1.0) * 27000)
		bytes.encode_s16(i * 2, val)

	return _create_wav(bytes, rate)

