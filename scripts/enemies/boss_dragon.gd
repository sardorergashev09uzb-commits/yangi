class_name BossDragon
extends CharacterBody3D
## Yetti Boshli Qora Ajdaho (The 7-Headed Dark Dragon) — Qoraqum Sahrosi Mifologik Bossi.
## 3 bosqichli epik jang:
## 1-bosqich: Havoda uchish, olov sharlari otish va havoda sho'ng'ish zarbalari.
## 2-bosqich (HP <= 66%): Yerga qulash, 360 darajali dum zarbasi (Tail swipe) va 7 boshning birgalikdagi hujumi.
## 3-bosqich (HP <= 30%): Yetti Olov Quturishi (Inferno Enrage) — qizil olov to'lqinlari va yuqori tezlik.

const FireballScript = preload("res://scripts/enemies/dragon_fireball.gd")
const CoinDropScript = preload("res://scripts/world/coin_drop.gd")
const ShockwaveScript = preload("res://scripts/enemies/shockwave.gd")

signal boss_activated(boss_name: String, cur_hp: float, max_hp: float)
signal boss_health_changed(cur_hp: float, max_hp: float, phase: int)
signal boss_phase_transition(phase: int)
signal boss_defeated

enum State {
	DORMANT,
	HOVER_FIRE,
	DIVE_BOMB,
	GROUND_SLAM,
	TAIL_SWIPE,
	MULTI_BITE,
	ROAR,
	RECOVER,
	DEAD
}

@export var max_health := 450.0

var health := 450.0
var phase := 1
var state := State.DORMANT

var _player: CharacterBody3D
var _timer := 0.0
var _sub_timer := 0.0
var _cooldown := 1.2
var _spawn_pos := Vector3.ZERO
var _wings: Array[Node3D] = []
var _heads: Array[Node3D] = []
var _wing_angle := 0.0
var _flying := false


func _ready() -> void:
	max_health *= GameSettings.get_mult("enemy_hp")
	health = max_health
	_spawn_pos = global_position
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("hurtable")
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1)

	_build_visuals()


func _build_visuals() -> void:
	var dragon_mat := StandardMaterial3D.new()
	dragon_mat.albedo_color = Color(0.12, 0.12, 0.14) # Qora vulqon toshi
	dragon_mat.roughness = 0.5
	dragon_mat.metallic = 0.8
	dragon_mat.emission_enabled = true
	dragon_mat.emission = Color(0.95, 0.35, 0.05) # Olovli tomirlar
	dragon_mat.emission_energy_multiplier = 0.6

	var horn_mat := StandardMaterial3D.new()
	horn_mat.albedo_color = Color(0.85, 0.25, 0.05)
	horn_mat.metallic = 0.9

	# 1. Ulkan ajdaho gavdasi (Torso)
	var torso := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 1.4
	cap.height = 6.2
	torso.mesh = cap
	torso.material_override = dragon_mat
	torso.rotation_degrees.x = 75.0
	torso.position.y = 2.2
	add_child(torso)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 1.5
	shape.height = 6.2
	col.shape = shape
	col.position.y = 2.2
	add_child(col)

	# 2. Qanotlar (Colossal Wings)
	for side in [-1.0, 1.0]:
		var wing_pivot := Node3D.new()
		wing_pivot.position = Vector3(side * 1.5, 3.2, 0.5)
		add_child(wing_pivot)
		_wings.append(wing_pivot)

		var wing_mesh := MeshInstance3D.new()
		var pmesh := BoxMesh.new()
		pmesh.size = Vector3(4.5, 0.12, 2.5)
		wing_mesh.mesh = pmesh
		wing_mesh.material_override = dragon_mat
		wing_mesh.position = Vector3(side * 2.2, 0, 0)
		wing_mesh.rotation_degrees.z = side * 15.0
		wing_pivot.add_child(wing_mesh)

	# 3. Yetti Bosh (7 Heads with undulating necks)
	var head_offsets := [
		Vector3(0, 3.6, -3.2),    # Markaziy Katta Bosh
		Vector3(-1.4, 3.2, -2.8), # Chap 1
		Vector3(1.4, 3.2, -2.8),  # O'ng 1
		Vector3(-2.4, 2.6, -2.2), # Chap 2
		Vector3(2.4, 2.6, -2.2),  # O'ng 2
		Vector3(-0.9, 4.4, -2.6), # Chap tepa
		Vector3(0.9, 4.4, -2.6)   # O'ng tepa
	]

	for i in head_offsets.size():
		var h_pos: Vector3 = head_offsets[i]
		var neck := Node3D.new()
		neck.position = Vector3(h_pos.x * 0.4, 2.2, -0.8)
		add_child(neck)

		# Bo'yin segmenti
		var neck_mesh := MeshInstance3D.new()
		var n_cyl := CylinderMesh.new()
		n_cyl.top_radius = 0.22 if i > 0 else 0.35
		n_cyl.bottom_radius = 0.35 if i > 0 else 0.5
		n_cyl.height = 1.8
		neck_mesh.mesh = n_cyl
		neck_mesh.material_override = dragon_mat
		neck_mesh.position = Vector3(0, 0.9, -0.6)
		neck_mesh.rotation_degrees.x = -45.0
		neck.add_child(neck_mesh)

		# Bosh
		var head_mesh := MeshInstance3D.new()
		var h_box := BoxMesh.new()
		var h_scale := 1.25 if i == 0 else 0.85
		h_box.size = Vector3(0.6 * h_scale, 0.5 * h_scale, 1.2 * h_scale)
		head_mesh.mesh = h_box
		head_mesh.material_override = dragon_mat
		head_mesh.position = Vector3(h_pos.x, h_pos.y, h_pos.z)
		add_child(head_mesh)
		_heads.append(head_mesh)

		# Shoxlar
		var horn := MeshInstance3D.new()
		var hcyl := CylinderMesh.new()
		hcyl.top_radius = 0.02
		hcyl.bottom_radius = 0.1
		hcyl.height = 0.7
		horn.mesh = hcyl
		horn.material_override = horn_mat
		horn.position = Vector3(0, 0.4, -0.2)
		horn.rotation_degrees.x = -35.0
		head_mesh.add_child(horn)

	# 4. Tikonli Dum (Spiked Tail)
	var tail := MeshInstance3D.new()
	var t_cyl := CylinderMesh.new()
	t_cyl.top_radius = 0.15
	t_cyl.bottom_radius = 0.9
	t_cyl.height = 5.2
	tail.mesh = t_cyl
	tail.material_override = dragon_mat
	tail.position = Vector3(0, 1.8, 4.2)
	tail.rotation_degrees.x = 80.0
	add_child(tail)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		return

	_animate_wings(delta)
	_animate_heads(delta)

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	# Agar o'yinchi 28 metr masofaga kelsa, ajdaho uyg'onadi
	if state == State.DORMANT:
		if dist < 28.0:
			_activate_boss()
		return

	match state:
		State.HOVER_FIRE:
			_tick_hover_fire(delta, to_player, dist)
		State.DIVE_BOMB:
			_tick_dive_bomb(delta, to_player, dist)
		State.GROUND_SLAM:
			_tick_ground_slam(delta)
		State.TAIL_SWIPE:
			_tick_tail_swipe(delta)
		State.MULTI_BITE:
			_tick_multi_bite(delta, to_player, dist)
		State.ROAR:
			_tick_roar(delta)
		State.RECOVER:
			_tick_recover(delta)

	move_and_slide()


func _activate_boss() -> void:
	state = State.HOVER_FIRE
	_timer = 0.0
	boss_activated.emit("Yetti Boshli Qora Ajdaho", health, max_health)
	Audio.play_boss_slam()
	FX.camera_shake(0.4)
	FX.popup(global_position + Vector3.UP * 4.0, 0.0, Color(1.0, 0.35, 0.05))


func _animate_wings(delta: float) -> void:
	var flap_spd := 8.0 if _flying else 2.5
	_wing_angle += delta * flap_spd
	var s := sin(_wing_angle)
	if _wings.size() >= 2:
		_wings[0].rotation_degrees.z = s * (35.0 if _flying else 12.0)
		_wings[1].rotation_degrees.z = -s * (35.0 if _flying else 12.0)


func _animate_heads(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.003
	for i in _heads.size():
		var h := _heads[i]
		if is_instance_valid(h):
			h.rotation_degrees.y = sin(t + i * 1.2) * 15.0
			h.rotation_degrees.x = cos(t * 1.5 + i * 0.8) * 10.0


func _face_player(to_player: Vector3, delta: float) -> void:
	var flat := Vector3(to_player.x, 0, to_player.z)
	if flat.length_squared() > 0.01:
		var target_yaw := atan2(-flat.x, -flat.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 5.0 * delta)


func _tick_hover_fire(delta: float, to_player: Vector3, _dist: float) -> void:
	_flying = true
	_face_player(to_player, delta)
	# Havoda muallaq turish (Y = 6.5)
	velocity.y = move_toward(velocity.y, (6.5 - position.y) * 3.0, 15.0 * delta)
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	_timer += delta
	_sub_timer += delta

	# Har 1.2 soniyada olov shari otadi
	if _sub_timer >= 1.2:
		_sub_timer = 0.0
		_shoot_fireball()

	if _timer >= 4.5:
		_timer = 0.0
		# Keyingi hujum: havoda sho'ng'ish (Dive bomb)
		state = State.DIVE_BOMB


func _shoot_fireball() -> void:
	if _player == null:
		return
	Audio.play_bow_shoot()
	var fb = FireballScript.new()
	var spawn_pos := global_position + Vector3(0, 3.5, 0) - global_basis.z * 3.0
	fb.global_position = spawn_pos
	var aim_dir := (_player.global_position + Vector3.UP * 1.0 - spawn_pos).normalized()
	fb.velocity = aim_dir * 22.0
	get_tree().current_scene.add_child(fb)
	FX.sparks(spawn_pos, aim_dir, Color(1.0, 0.5, 0.1), 14)


func _tick_dive_bomb(delta: float, to_player: Vector3, dist: float) -> void:
	_face_player(to_player, delta)
	var fwd := -global_basis.z
	velocity = fwd * 18.0 + Vector3.DOWN * 4.0

	_timer += delta
	if position.y <= 0.5 or dist < 4.0 or _timer >= 2.5:
		position.y = 0.0
		state = State.GROUND_SLAM


func _tick_ground_slam(delta: float) -> void:
	_flying = false
	velocity = Vector3.ZERO
	Audio.play_boss_slam()
	FX.camera_shake(0.5)
	FX.hit_stop(0.08)
	FX.shockwave_ring(global_position + Vector3.UP * 0.2, 11.0, Color(1.0, 0.45, 0.1, 0.9), 0.6)

	var sw = ShockwaveScript.new()
	sw.damage = 25.0
	sw.max_radius = 11.0
	sw.speed = 12.0
	sw.global_position = global_position
	get_tree().current_scene.add_child(sw)

	_timer = 0.0
	state = State.RECOVER


func _tick_tail_swipe(delta: float) -> void:
	_timer += delta
	rotation_degrees.y += 360.0 * delta * 1.5

	# Dumi bilan aylanma zarba berish
	if _player and global_position.distance_to(_player.global_position) < 6.5 and _timer < 0.6:
		_player.take_damage(28.0, global_position, 12.0)
		FX.impact_burst(_player.global_position, Color(1.0, 0.3, 0.1), 16)

	if _timer >= 0.7:
		_timer = 0.0
		state = State.RECOVER


func _tick_multi_bite(delta: float, to_player: Vector3, dist: float) -> void:
	_face_player(to_player, delta)
	velocity = -global_basis.z * 10.0
	_timer += delta

	if dist < 4.5 and _timer < 0.5:
		_player.take_damage(32.0, global_position, 8.0)
		FX.sparks(_player.global_position, Vector3.UP, Color(1.0, 0.2, 0.1), 18)

	if _timer >= 1.0:
		_timer = 0.0
		state = State.RECOVER


func _tick_roar(delta: float) -> void:
	_timer += delta
	velocity = Vector3.ZERO
	if _timer >= 1.5:
		_timer = 0.0
		state = State.HOVER_FIRE


func _tick_recover(delta: float) -> void:
	_timer += delta
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)

	if _timer >= _cooldown:
		_timer = 0.0
		var r := randf()
		if phase == 1:
			state = State.HOVER_FIRE if r < 0.6 else State.MULTI_BITE
		elif phase == 2:
			state = State.TAIL_SWIPE if r < 0.5 else State.MULTI_BITE
		else: # Phase 3 (Inferno Enrage)
			state = State.HOVER_FIRE if r < 0.4 else State.TAIL_SWIPE


func take_damage(amount: float, from_pos: Vector3, knockback := 0.0) -> void:
	if state == State.DEAD:
		return

	health = maxf(health - amount, 0.0)
	boss_health_changed.emit(health, max_health, phase)
	FX.sparks(global_position + Vector3.UP * 2.0, (global_position - from_pos).normalized(), Color(1.0, 0.7, 0.2), 16)
	Audio.play_hit()

	if state == State.DORMANT:
		_activate_boss()

	# Bosqich o'zgarishlari (Phase Transitions)
	if phase == 1 and health <= max_health * 0.66:
		phase = 2
		_cooldown = 0.8
		boss_phase_transition.emit(phase)
		state = State.ROAR
		Audio.play_boss_slam()
		FX.popup(global_position + Vector3.UP * 4.0, 0.0, Color(1.0, 0.2, 0.1))
	elif phase == 2 and health <= max_health * 0.30:
		phase = 3
		_cooldown = 0.5
		boss_phase_transition.emit(phase)
		state = State.ROAR
		Audio.play_boss_slam()
		FX.popup(global_position + Vector3.UP * 4.0, 0.0, Color(1.0, 0.1, 0.05))

	if health <= 0.0:
		_die()


func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	Audio.play_boss_slam()
	FX.camera_shake(0.6)
	FX.impact_burst(global_position + Vector3.UP * 2.5, Color(1.0, 0.6, 0.1), 40)
	FX.shockwave_ring(global_position + Vector3.UP * 0.5, 14.0, Color(1.0, 0.4, 0.1, 0.9), 0.8)

	boss_defeated.emit()

	# Xazina tangalari
	for i in range(12):
		var coin = CoinDropScript.new()
		coin.gold_value = 20
		coin.position = global_position + Vector3(randf_range(-3, 3), 1.0, randf_range(-3, 3))
		get_tree().current_scene.add_child(coin)

	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 1.2)
	t.tween_callback(queue_free)


func reset_boss(spawn_pos: Vector3) -> void:
	global_position = spawn_pos
	velocity = Vector3.ZERO
	health = max_health
	phase = 1
	_cooldown = 1.2
	state = State.DORMANT
	_flying = false
