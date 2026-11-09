class_name BanditChief
extends CharacterBody3D
## Sahro Qaroqchilari Sardori (Bandit Chief) - Qora Qoplon.
## Istehkomdagi mini-boss: og'ir zarbalar va quyun aylanishi (Whirlwind) hujumlari.

const CoinDropScript = preload("res://scripts/world/coin_drop.gd")

signal died(chief: BanditChief)

enum State { IDLE, CHASE, SLASH, WHIRLWIND, STAGGER, DEAD }

@export var max_health := 150.0
@export var speed := 4.2
@export var aggro_range := 22.0
@export var gravity := 20.0

var state := State.IDLE
var health := 150.0

var _player: CharacterBody3D
var _timer := 0.0
var _cooldown := 1.2
var _spin_angle := 0.0
var _whirlwind_hit_cooldown := 0.0
var _slash_tween: Tween
var _visual_root: Node3D
var _mat: StandardMaterial3D
var _hp_label: Label3D
var _weapons: Array[Node3D] = []


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	add_to_group("hurtable")
	add_to_group("bandit_boss")

	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1)

	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)

	_build_visuals()


func _build_visuals() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.55
	cap.height = 2.1
	col.shape = cap
	col.position.y = 1.05
	add_child(col)

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.25, 0.18, 0.15) # Qoramtir charm zirh
	_mat.roughness = 0.7

	# 1. Tana (Torso)
	var torso := MeshInstance3D.new()
	var tbox := BoxMesh.new()
	tbox.size = Vector3(0.9, 1.0, 0.5)
	torso.mesh = tbox
	torso.material_override = _mat
	torso.position.y = 1.2
	_visual_root.add_child(torso)

	# 2. Yelka zirhlari (Spiked Pauldrons)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.65, 0.65, 0.72)
	pmat.metallic = 0.9
	for s in [-1.0, 1.0]:
		var pauldron := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.35, 0.25, 0.4)
		pauldron.mesh = pbox
		pauldron.material_override = pmat
		pauldron.position = Vector3(s * 0.55, 1.65, 0)
		_visual_root.add_child(pauldron)

	# 3. Bosh va Temir Dubulg'a (Spiked Helmet)
	var head := MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 0.24
	s_mesh.height = 0.48
	head.mesh = s_mesh
	head.position.y = 1.95
	_visual_root.add_child(head)

	var helm := MeshInstance3D.new()
	var c_mesh := CylinderMesh.new()
	c_mesh.top_radius = 0.02
	c_mesh.bottom_radius = 0.26
	c_mesh.height = 0.4
	helm.mesh = c_mesh
	helm.material_override = pmat
	helm.position.y = 2.2
	_visual_root.add_child(helm)

	# 4. Qo'sh Shamshirlar (Dual Scimitars)
	for s in [-1.0, 1.0]:
		var wpivot := Node3D.new()
		wpivot.position = Vector3(s * 0.6, 1.1, 0.3)
		var blade := MeshInstance3D.new()
		var bbox := BoxMesh.new()
		bbox.size = Vector3(0.06, 0.9, 0.16)
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.85, 0.88, 0.95)
		bmat.metallic = 0.95
		blade.mesh = bbox
		blade.material_override = bmat
		blade.position = Vector3(0, 0.2, 0.2)
		blade.rotation_degrees.x = 45.0
		wpivot.add_child(blade)
		_visual_root.add_child(wpivot)
		_weapons.append(wpivot)

	# 5. Salomatlik ko'rsatkichi (Health Label)
	_hp_label = Label3D.new()
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.no_depth_test = true
	_hp_label.font_size = 18
	_hp_label.position = Vector3(0, 2.6, 0)
	_hp_label.text = "⚔️ QORA QOPLON (SARDOR)\n150 / 150 HP"
	_hp_label.modulate = Color(1.0, 0.3, 0.3)
	add_child(_hp_label)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if _player == null:
			move_and_slide()
			return

	var dist := global_position.distance_to(_player.global_position)

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if dist < aggro_range:
				state = State.CHASE
				var qs = get_tree().get_first_node_in_group("quest_system")
				if qs and qs.has_method("set_objective_completed"):
					qs.set_objective_completed("bandit_outpost", 0)

		State.CHASE:
			_cooldown = maxf(_cooldown - delta, 0.0)
			var dir := (_player.global_position - global_position).normalized()
			dir.y = 0.0
			if dir.length_squared() > 0.001:
				rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)

			if dist > 3.0:
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
				if _cooldown <= 0.0:
					if randf() < 0.45:
						_start_whirlwind()
					else:
						_start_slash()

		State.SLASH:
			_timer -= delta
			if _timer <= 0.0:
				_execute_slash()
				state = State.CHASE
				_cooldown = 1.4

		State.WHIRLWIND:
			_timer -= delta
			_whirlwind_hit_cooldown = maxf(_whirlwind_hit_cooldown - delta, 0.0)
			_spin_angle += 25.0 * delta
			_visual_root.rotation.y = _spin_angle
			var dir := (_player.global_position - global_position).normalized()
			dir.y = 0.0
			velocity.x = dir.x * (speed * 0.75)
			velocity.z = dir.z * (speed * 0.75)

			if int(_timer * 10) % 2 == 0:
				FX.sparks(global_position + Vector3.UP * 1.2, Vector3.UP, Color(1.0, 0.4, 0.2), 6)

			if dist < 2.6 and _timer > 0.2 and _whirlwind_hit_cooldown <= 0.0:
				_hit_player(22.0, 6.0)
				_whirlwind_hit_cooldown = 0.45

			if _timer <= 0.0:
				_visual_root.rotation.y = 0.0
				state = State.CHASE
				_cooldown = 2.0

		State.STAGGER:
			_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
			if _timer <= 0.0:
				state = State.CHASE

	move_and_slide()


func _start_slash() -> void:
	state = State.SLASH
	_timer = 0.45
	Audio.play_sword_swing()
	if _slash_tween and _slash_tween.is_valid():
		_slash_tween.kill()
	_slash_tween = create_tween()
	if _weapons.size() >= 2:
		_slash_tween.tween_property(_weapons[0], "rotation_degrees:x", -60.0, 0.2)
		_slash_tween.parallel().tween_property(_weapons[1], "rotation_degrees:x", -60.0, 0.2)
		_slash_tween.tween_property(_weapons[0], "rotation_degrees:x", 30.0, 0.2)
		_slash_tween.parallel().tween_property(_weapons[1], "rotation_degrees:x", 30.0, 0.2)
		_slash_tween.tween_property(_weapons[0], "rotation_degrees:x", 0.0, 0.05)
		_slash_tween.parallel().tween_property(_weapons[1], "rotation_degrees:x", 0.0, 0.05)
	elif _weapons.size() == 1:
		_slash_tween.tween_property(_weapons[0], "rotation_degrees:x", -60.0, 0.2)
		_slash_tween.tween_property(_weapons[0], "rotation_degrees:x", 30.0, 0.2)
		_slash_tween.tween_property(_weapons[0], "rotation_degrees:x", 0.0, 0.05)


func _execute_slash() -> void:
	if _player and global_position.distance_to(_player.global_position) < 2.8:
		_hit_player(18.0, 5.0)


func _start_whirlwind() -> void:
	state = State.WHIRLWIND
	_timer = 1.8
	_spin_angle = 0.0
	_whirlwind_hit_cooldown = 0.0
	Audio.play_sword_swing()
	FX.impact_burst(global_position + Vector3.UP * 1.0, Color(1.0, 0.5, 0.2), 16)


func _hit_player(amount: float, knockback := 5.0) -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(amount, global_position, knockback)


func take_damage(amount: float, from_pos := Vector3.ZERO, knockback := 4.0) -> void:
	if state == State.DEAD:
		return

	health -= amount
	Audio.play_hit()
	FX.sparks(global_position + Vector3.UP * 1.2, Vector3.UP, Color(1.0, 0.2, 0.2), 12)
	FX.popup(global_position + Vector3.UP * 2.5, amount, Color(1.0, 0.3, 0.3))

	_hp_label.text = "⚔️ QORA QOPLON (SARDOR)\n%d / %d HP" % [maxi(int(health), 0), int(max_health)]

	if health <= 0.0:
		_die()
	else:
		state = State.STAGGER
		_timer = 0.35
		var away := global_position - from_pos
		away.y = 0.0
		away = away.normalized() if away.length() > 0.01 else -global_basis.z
		velocity = away * knockback


func get_parried(from_pos: Vector3) -> void:
	if state == State.DEAD:
		return
	state = State.STAGGER
	_timer = 0.8
	Audio.play_heavy_hit()
	FX.sparks(global_position + Vector3.UP * 1.2, Vector3.UP, Color(0.3, 0.8, 1.0), 20)
	var away := global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -global_basis.z
	velocity = away * 5.0


func _die() -> void:
	state = State.DEAD
	collision_layer = 0
	collision_mask = 0
	_hp_label.visible = false

	Audio.play_victory()
	FX.impact_burst(global_position + Vector3.UP * 1.0, Color(1.0, 0.85, 0.2), 24)

	# 45 ta tilla tanga tushishi
	CoinDropScript.spawn_coins(get_tree(), global_position + Vector3.UP * 1.0, 45, 6)

	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_method("set_objective_completed"):
		qs.set_objective_completed("bandit_outpost", 0)
		qs.set_objective_completed("bandit_outpost", 1)
	if qs and qs.has_method("complete_quest"):
		qs.complete_quest("bandit_outpost")
	if qs and qs.has_method("emit_signal"):
		qs.banner_requested.emit("QAROQCHILAR SARDORI YENGILDI!", "Sahro qaroqchilari tor-mor qilindi! (+160 XP, 45 Tilla)")

	died.emit(self)

	var t := create_tween()
	t.tween_property(_visual_root, "rotation_degrees:z", 90.0, 0.5)
	t.tween_property(_visual_root, "position:y", -0.4, 0.5)
	t.tween_interval(2.0)
	t.tween_callback(queue_free)
