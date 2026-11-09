class_name BossColossus
extends CharacterBody3D
## Qoya Yurar — 15 metrlik Tosh Koloss (Mountain Stone Colossus).
## Bahaybat tosh gigant: zilzila to'lqinlari, qoya uloqtirish va runik zaif nuqta.

const ShockwaveScript = preload("res://scripts/enemies/shockwave.gd")
const CoinDropScript = preload("res://scripts/world/coin_drop.gd")
const FireballScript = preload("res://scripts/enemies/dragon_fireball.gd")

signal boss_activated(boss_name: String, cur_hp: float, max_hp: float)
signal boss_health_changed(cur_hp: float, max_hp: float, phase: int)
signal boss_phase_transition(phase: int)
signal boss_defeated

enum State {
	DORMANT,
	CHASE,
	EARTH_STOMP,
	BOULDER_HURL,
	DOUBLE_SMASH,
	STAGGERED,
	RECOVER,
	DEAD
}

@export var max_health := 500.0

var health := 500.0
var phase := 1
var state := State.DORMANT

var _player: CharacterBody3D
var _timer := 0.0
var _cooldown := 1.8
var _rune_core: MeshInstance3D
var _arms: Array[Node3D] = []


func _ready() -> void:
	max_health *= GameSettings.get_mult("enemy_hp")
	health = max_health
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("hurtable")
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1)

	_build_visuals()


func _build_visuals() -> void:
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.42, 0.44, 0.46) # Vulqonik qoya tosh
	stone_mat.roughness = 0.95

	var rune_mat := StandardMaterial3D.new()
	rune_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rune_mat.albedo_color = Color(0.2, 0.75, 1.0) # Moviy qadimiy runa nuri

	# 1. Ulkan tosh tana (Massive Stone Torso)
	var torso := MeshInstance3D.new()
	var tbox := BoxMesh.new()
	tbox.size = Vector3(3.2, 4.2, 2.4)
	torso.mesh = tbox
	torso.material_override = stone_mat
	torso.position.y = 4.8
	add_child(torso)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.4, 7.5, 2.6)
	col.shape = shape
	col.position.y = 4.2
	add_child(col)

	# 2. Ko'krakdagi moviy runik yadro (Runic Weakpoint Core)
	_rune_core = MeshInstance3D.new()
	var csph := SphereMesh.new()
	csph.radius = 0.65
	csph.height = 1.3
	_rune_core.mesh = csph
	_rune_core.material_override = rune_mat
	_rune_core.position = Vector3(0, 5.2, -1.25)
	add_child(_rune_core)

	# 3. Katta tosh bosh (Boulder Head)
	var head := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(1.6, 1.6, 1.6)
	head.mesh = hbox
	head.material_override = stone_mat
	head.position = Vector3(0, 7.6, -0.2)
	add_child(head)

	# 4. Gigant tosh qo'llar (Colossal Stone Fists)
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 2.4, 5.8, 0.0)
		add_child(arm)
		_arms.append(arm)

		var abox := BoxMesh.new()
		abox.size = Vector3(1.2, 4.5, 1.2)
		var arm_mesh := MeshInstance3D.new()
		arm_mesh.mesh = abox
		arm_mesh.material_override = stone_mat
		arm_mesh.position = Vector3(0, -1.8, 0)
		arm.add_child(arm_mesh)

	# 5. Tosh ustun oyoqlar (Pillar Legs)
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lcyl := CylinderMesh.new()
		lcyl.top_radius = 0.8
		lcyl.bottom_radius = 1.1
		lcyl.height = 3.2
		leg.mesh = lcyl
		leg.material_override = stone_mat
		leg.position = Vector3(side * 1.1, 1.6, 0.0)
		add_child(leg)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	if state == State.DORMANT:
		if dist < 25.0:
			_activate_boss()
		return

	var flat := Vector3(to_player.x, 0, to_player.z)
	if flat.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), 3.0 * delta)

	match state:
		State.CHASE:
			_tick_chase(delta, flat, dist)
		State.EARTH_STOMP:
			_tick_stomp(delta)
		State.BOULDER_HURL:
			_tick_boulder(delta, to_player)
		State.DOUBLE_SMASH:
			_tick_double_smash(delta)
		State.STAGGERED:
			_tick_stagger(delta)
		State.RECOVER:
			_tick_recover(delta, dist)

	move_and_slide()


func _activate_boss() -> void:
	state = State.CHASE
	_timer = 0.0
	boss_activated.emit("Qoya Yurar — Tosh Koloss", health, max_health)
	Audio.play_boss_slam()
	FX.camera_shake(0.5)
	FX.popup(global_position + Vector3.UP * 8.0, 0.0, Color(0.2, 0.8, 1.0))


func _tick_chase(delta: float, flat: Vector3, dist: float) -> void:
	var dir := flat.normalized()
	velocity.x = dir.x * 4.0
	velocity.z = dir.z * 4.0

	_timer += delta
	if dist <= 7.0:
		velocity = Vector3.ZERO
		state = State.EARTH_STOMP
	elif _timer >= 3.0:
		_timer = 0.0
		state = State.BOULDER_HURL if dist > 10.0 else State.DOUBLE_SMASH


func _tick_stomp(delta: float) -> void:
	_timer += delta
	velocity = Vector3.ZERO
	if _timer >= 0.8:
		_timer = 0.0
		Audio.play_boss_slam()
		FX.camera_shake(0.55)
		FX.shockwave_ring(global_position + Vector3.UP * 0.2, 12.0, Color(0.3, 0.7, 1.0, 0.9), 0.6)

		var sw = ShockwaveScript.new()
		sw.damage = 30.0
		sw.max_radius = 12.0
		sw.speed = 10.0
		sw.global_position = global_position
		get_tree().current_scene.add_child(sw)

		state = State.RECOVER


func _tick_boulder(delta: float, to_player: Vector3) -> void:
	_timer += delta
	velocity = Vector3.ZERO
	if _timer >= 1.0:
		_timer = 0.0
		Audio.play_boss_slam()
		var fb = FireballScript.new()
		fb.damage = 35.0
		var spawn_pos := global_position + Vector3(0, 6.0, -1.8)
		fb.global_position = spawn_pos
		var dir := (to_player + Vector3.UP * 1.0 - spawn_pos).normalized()
		fb.velocity = dir * 18.0
		get_tree().current_scene.add_child(fb)
		FX.impact_burst(spawn_pos, Color(0.6, 0.5, 0.4), 20)

		state = State.RECOVER


func _tick_double_smash(delta: float) -> void:
	_timer += delta
	velocity = Vector3.ZERO
	if _timer >= 0.9:
		_timer = 0.0
		Audio.play_boss_slam()
		FX.camera_shake(0.6)
		var impact_pos := global_position - global_basis.z * 4.0
		FX.impact_burst(impact_pos, Color(0.5, 0.6, 0.7), 30)
		FX.shockwave_ring(impact_pos, 8.0, Color(0.2, 0.8, 1.0, 0.85), 0.45)

		if _player and global_position.distance_to(_player.global_position) < 8.0:
			_player.take_damage(38.0, global_position, 14.0)

		state = State.RECOVER


func _tick_stagger(delta: float) -> void:
	_timer += delta
	velocity = Vector3.ZERO
	if _timer >= 3.5:
		_timer = 0.0
		state = State.CHASE


func _tick_recover(delta: float, dist: float) -> void:
	_timer += delta
	velocity = Vector3.ZERO
	if _timer >= _cooldown:
		_timer = 0.0
		state = State.CHASE if dist > 8.0 else State.EARTH_STOMP


func take_damage(amount: float, from_pos: Vector3, _knockback := 0.0) -> void:
	if state == State.DEAD:
		return

	# Agar koloss stagger (gangigan) holatda bo'lsa 2x kritik zarar oladi
	if state == State.STAGGERED:
		amount *= 2.0
		FX.popup(global_position + Vector3.UP * 6.0, 0.0, Color(1.0, 0.9, 0.1))

	health = maxf(health - amount, 0.0)
	boss_health_changed.emit(health, max_health, phase)
	FX.sparks(global_position + Vector3.UP * 4.0, Vector3.UP, Color(0.3, 0.8, 1.0), 16)
	Audio.play_heavy_hit()

	if state == State.DORMANT:
		_activate_boss()

	# Runik yadroga kuchli zarba tushganda gangish (Stagger)
	if amount >= 30.0 and randf() < 0.35 and state != State.STAGGERED:
		state = State.STAGGERED
		_timer = 0.0
		FX.popup(global_position + Vector3.UP * 6.0, 0.0, Color(0.2, 0.9, 1.0))
		Audio.play_hit()

	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		_cooldown = 1.2
		boss_phase_transition.emit(phase)
		FX.popup(global_position + Vector3.UP * 6.0, 0.0, Color(1.0, 0.4, 0.1))

	if health <= 0.0:
		_die()


func _die() -> void:
	state = State.DEAD
	Audio.play_boss_slam()
	FX.camera_shake(0.7)
	FX.impact_burst(global_position + Vector3.UP * 4.0, Color(0.5, 0.5, 0.6), 45)
	FX.shockwave_ring(global_position + Vector3.UP * 0.3, 16.0, Color(0.3, 0.7, 1.0, 0.9), 0.8)

	boss_defeated.emit()
	for i in range(15):
		var coin = CoinDropScript.new()
		coin.gold_value = 20
		coin.position = global_position + Vector3(randf_range(-3, 3), 1.0, randf_range(-3, 3))
		get_tree().current_scene.add_child(coin)

	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 1.5)
	t.tween_callback(queue_free)
