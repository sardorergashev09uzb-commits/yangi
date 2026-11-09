class_name BossShaman
extends CharacterBody3D
## Qalmoq Bosh Shomoni — Qora Ko'rpasht (Dark Sorcerer / Shaman).
## Teleportatsiya, qarg'alar to'dasi va soya klonlari bilan jang qiluvchi jodugar boss.

const CoinDropScript = preload("res://scripts/world/coin_drop.gd")
const FireballScript = preload("res://scripts/enemies/dragon_fireball.gd")

signal boss_activated(boss_name: String, cur_hp: float, max_hp: float)
signal boss_health_changed(cur_hp: float, max_hp: float, phase: int)
signal boss_phase_transition(phase: int)
signal boss_defeated

enum State {
	DORMANT,
	CAST_ORB,
	TELEPORT,
	SUMMON_CLONES,
	DARK_VORTEX,
	RECOVER,
	DEAD
}

@export var max_health := 320.0
@export var is_clone := false

var health := 320.0
var phase := 1
var state := State.DORMANT

var _player: CharacterBody3D
var _timer := 0.0
var _cooldown := 1.4
var _staff_orb: MeshInstance3D
var _clones: Array[Node3D] = []


func _ready() -> void:
	if is_clone:
		max_health = 25.0
		health = max_health
	else:
		max_health *= GameSettings.get_mult("enemy_hp")
		health = max_health
		add_to_group("bosses")

	add_to_group("enemies")
	add_to_group("hurtable")
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1)

	_build_visuals()


func _build_visuals() -> void:
	var robe_mat := StandardMaterial3D.new()
	robe_mat.albedo_color = Color(0.18, 0.12, 0.28) if not is_clone else Color(0.35, 0.2, 0.45, 0.6)
	if is_clone:
		robe_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var bone_mat := StandardMaterial3D.new()
	bone_mat.albedo_color = Color(0.85, 0.82, 0.75)

	# 1. Shomon tanasi va joma (Robe Body)
	var body_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.65
	cyl.height = 2.4
	body_mesh.mesh = cyl
	body_mesh.material_override = robe_mat
	body_mesh.position.y = 1.2
	add_child(body_mesh)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.55
	shape.height = 2.4
	col.shape = shape
	col.position.y = 1.2
	add_child(col)

	# 2. Bo'ri bosh chanog'i (Wolf Skull Mask)
	var mask := MeshInstance3D.new()
	var mbox := BoxMesh.new()
	mbox.size = Vector3(0.5, 0.45, 0.7)
	mask.mesh = mbox
	mask.material_override = bone_mat
	mask.position = Vector3(0, 2.3, -0.2)
	add_child(mask)

	# Ko'zlar (Glowing violet eyes)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_mat.albedo_color = Color(0.75, 0.2, 1.0)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var esph := SphereMesh.new()
		esph.radius = 0.06
		esph.height = 0.12
		eye.mesh = esph
		eye.material_override = eye_mat
		eye.position = Vector3(side * 0.15, 2.35, -0.55)
		add_child(eye)

	# 3. Sehrli Shomon Asosi (Bone Staff with Glowing Orb)
	var staff := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.04
	scyl.bottom_radius = 0.05
	scyl.height = 2.6
	staff.mesh = scyl
	staff.material_override = bone_mat
	staff.position = Vector3(0.65, 1.3, -0.3)
	staff.rotation_degrees.z = -10.0
	add_child(staff)

	_staff_orb = MeshInstance3D.new()
	var osph := SphereMesh.new()
	osph.radius = 0.18
	osph.height = 0.36
	_staff_orb.mesh = osph
	var omat := StandardMaterial3D.new()
	omat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	omat.albedo_color = Color(0.85, 0.2, 1.0) # Binafsha jodugarlik nuri
	_staff_orb.material_override = omat
	_staff_orb.position = Vector3(0, 1.35, 0)
	staff.add_child(_staff_orb)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	if state == State.DORMANT:
		if dist < 22.0:
			_activate_boss()
		return

	# Doimo o'yinchiga yuzlanadi
	var flat := Vector3(to_player.x, 0, to_player.z)
	if flat.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), 8.0 * delta)

	match state:
		State.CAST_ORB:
			_tick_cast_orb(delta, to_player)
		State.TELEPORT:
			_tick_teleport(delta)
		State.SUMMON_CLONES:
			_tick_summon_clones(delta)
		State.DARK_VORTEX:
			_tick_dark_vortex(delta, dist)
		State.RECOVER:
			_tick_recover(delta)


func _activate_boss() -> void:
	state = State.CAST_ORB
	_timer = 0.0
	if not is_clone:
		boss_activated.emit("Qalmoq Bosh Shomoni — Qora Ko'rpasht", health, max_health)
		Audio.play_boss_slam()
		FX.popup(global_position + Vector3.UP * 3.0, 0.0, Color(0.85, 0.2, 1.0))


func _tick_cast_orb(delta: float, to_player: Vector3) -> void:
	_timer += delta
	if _timer >= 0.8:
		_timer = 0.0
		Audio.play_bow_shoot()
		var fb = FireballScript.new()
		fb.damage = 18.0
		var spawn_pos := global_position + Vector3(0.65, 2.6, -0.3)
		fb.global_position = spawn_pos
		var dir := (_player.global_position + Vector3.UP * 1.0 - spawn_pos).normalized()
		fb.velocity = dir * 18.0
		get_tree().current_scene.add_child(fb)
		FX.sparks(spawn_pos, dir, Color(0.8, 0.2, 1.0), 12)

		# Otgandan so'ng qayta tiklanish
		state = State.RECOVER


func _tick_teleport(delta: float) -> void:
	_timer += delta
	if _timer >= 0.25:
		_timer = 0.0
		# Teleportatsiya effekti (Chaqnash va tutun)
		FX.impact_burst(global_position + Vector3.UP * 1.0, Color(0.7, 0.1, 0.9), 20)
		Audio.play_dodge()

		# O'yinchidan 8-12 metr uzoqlikdagi tasodifiy nuqtaga ko'chish
		if _player:
			var rand_angle := randf_range(0, TAU)
			var offset := Vector3(cos(rand_angle), 0, sin(rand_angle)) * randf_range(8.0, 12.0)
			global_position = _player.global_position + offset
			global_position.y = maxf(global_position.y, 0.0)

		FX.impact_burst(global_position + Vector3.UP * 1.0, Color(0.8, 0.2, 1.0), 20)
		state = State.RECOVER


func _tick_summon_clones(_delta: float) -> void:
	# 3 ta illyuziya klonini chaqirish
	for i in range(3):
		var clone: CharacterBody3D = (load("res://scripts/enemies/boss_shaman.gd") as GDScript).new()
		clone.is_clone = true
		var rand_angle := (TAU / 3.0) * i
		clone.position = global_position + Vector3(cos(rand_angle), 0, sin(rand_angle)) * 4.5
		get_tree().current_scene.add_child(clone)
		_clones.append(clone)
		FX.impact_burst(clone.global_position + Vector3.UP * 1.0, Color(0.6, 0.1, 0.8), 16)

	state = State.TELEPORT


func _tick_dark_vortex(delta: float, dist: float) -> void:
	_timer += delta
	FX.shockwave_ring(global_position + Vector3.UP * 0.1, 8.0, Color(0.6, 0.1, 0.9, 0.8), 0.4)

	# O'yinchini o'ziga tortish (Gravity vortex)
	if _player and dist < 12.0:
		var pull_dir := (global_position - _player.global_position).normalized()
		_player.velocity += pull_dir * 12.0 * delta

	if _timer >= 1.5:
		_timer = 0.0
		state = State.RECOVER


func _tick_recover(delta: float) -> void:
	_timer += delta
	if _timer >= _cooldown:
		_timer = 0.0
		var r := randf()
		if r < 0.4:
			state = State.CAST_ORB
		elif r < 0.75:
			state = State.TELEPORT
		else:
			state = State.DARK_VORTEX


func take_damage(amount: float, from_pos: Vector3, _knockback := 0.0) -> void:
	if state == State.DEAD:
		return

	health = maxf(health - amount, 0.0)
	if not is_clone:
		boss_health_changed.emit(health, max_health, phase)
	FX.sparks(global_position + Vector3.UP * 1.5, Vector3.UP, Color(0.8, 0.2, 1.0), 12)
	Audio.play_hit()

	if state == State.DORMANT:
		_activate_boss()

	# Agar klon bo'lsa darhol parchalanadi
	if is_clone and health <= 0.0:
		FX.impact_burst(global_position + Vector3.UP * 1.0, Color(0.7, 0.2, 0.9), 16)
		queue_free()
		return

	# Zarba olgach darhol qochib teleportatsiya qiladi
	if randf() < 0.45:
		state = State.TELEPORT

	# 2-bosqich: Klonlar chaqirish
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		_cooldown = 1.0
		boss_phase_transition.emit(phase)
		state = State.SUMMON_CLONES
		Audio.play_boss_slam()
		FX.popup(global_position + Vector3.UP * 3.0, 0.0, Color(0.9, 0.1, 0.8))

	if health <= 0.0:
		_die()


func _die() -> void:
	state = State.DEAD
	Audio.play_boss_slam()
	FX.camera_shake(0.4)
	FX.impact_burst(global_position + Vector3.UP * 1.5, Color(0.85, 0.2, 1.0), 30)
	FX.shockwave_ring(global_position + Vector3.UP * 0.2, 10.0, Color(0.8, 0.1, 0.9, 0.9), 0.6)

	if not is_clone:
		boss_defeated.emit()
		for i in range(8):
			var coin = CoinDropScript.new()
			coin.gold_value = 20
			coin.position = global_position + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2))
			get_tree().current_scene.add_child(coin)

	# Barcha soxta klonlarni tozalash
	for c in _clones:
		if is_instance_valid(c):
			c.queue_free()

	queue_free()
