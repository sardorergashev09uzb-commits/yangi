class_name BossSurxayil
extends CharacterBody3D
## Surxayil Alp - Qalmoq Botiri (1-chi Boss).
## 2 bosqichli jang:
## - 1-bosqich: Og'ir zarbalar, keng aylanma sweep, va yerga zarba (shockwave to'lqini).
## - 2-bosqich (HP <= 50%): Quturgan holat (qizil yonish, tezlik oshishi, Bo'ron aylanmasi - Whirlwind).

signal boss_activated(boss_name: String, cur_hp: float, max_hp: float)
signal boss_health_changed(cur_hp: float, max_hp: float, phase: int)
signal boss_phase_transition(phase: int)
signal boss_defeated

enum State {
	DORMANT,     # O'yinchi arenaga kirmaguncha tinch turadi
	CHASE,       # O'yinchi tomon yaqinlashadi
	SLAM,        # Yerga kuchli zarba (shockwave to'lqin tarqatadi)
	SWEEP,       # Keng aylanma zarba (180 daraja)
	ROAR,        # 2-bosqichga o'tish: baqiriq va silkinish
	WHIRLWIND,   # 2-bosqich maxsus: aylanib quvish
	RECOVER,     # Zarbadan keyingi tanaffus
	DEAD         # Mag'lub bo'ldi
}

@export var max_health := 280.0
@export var gravity := 20.0

var health := 280.0
var phase := 1
var state := State.DORMANT

var _player: CharacterBody3D
var _timer := 0.0
var _sub_timer := 0.0
var _cooldown := 1.0
var _struck := false
var _spin_count := 0
var _action_dir := Vector3.FORWARD

# Vizual qismlar
var _body: MeshInstance3D
var _mat: StandardMaterial3D
var _weapon_pivot: Node3D
var _weapon_mat: StandardMaterial3D


func _ready() -> void:
	max_health *= GameSettings.get_mult("enemy_hp")
	health = max_health
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("hurtable")
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1)

	# Surxayil uchun pog'onalardan silliq oshib o'tish
	floor_snap_length = 0.6
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(55.0)
	floor_stop_on_slope = false
	max_slides = 6

	_build_visuals()


func _build_visuals() -> void:
	# Surxayil oddiy askarlardan 1.8x katta, bahaybat alp
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.35, 0.12, 0.12)
	_mat.emission_enabled = true
	_mat.emission = Color(0.9, 0.2, 0.05)
	_mat.emission_energy_multiplier = 0.0

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.7
	capsule.height = 3.2
	capsule.material = _mat

	_body = MeshInstance3D.new()
	_body.mesh = capsule
	_body.position.y = 1.6
	add_child(_body)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.7
	shape.height = 3.2
	col.shape = shape
	col.position.y = 1.6
	add_child(col)

	# Og'ir po'lat cho'qmor / qilich
	_weapon_pivot = Node3D.new()
	_weapon_pivot.position = Vector3(0.8, 1.9, -0.4)
	add_child(_weapon_pivot)

	var club_mesh := CylinderMesh.new()
	club_mesh.top_radius = 0.22
	club_mesh.bottom_radius = 0.1
	club_mesh.height = 3.0
	_weapon_mat = StandardMaterial3D.new()
	_weapon_mat.albedo_color = Color(0.18, 0.18, 0.2)
	_weapon_mat.metallic = 0.9
	_weapon_mat.roughness = 0.3
	_weapon_mat.emission_enabled = true
	_weapon_mat.emission = Color(1.0, 0.3, 0.0)
	_weapon_mat.emission_energy_multiplier = 0.0
	club_mesh.material = _weapon_mat

	var club := MeshInstance3D.new()
	club.mesh = club_mesh
	club.rotation_degrees.x = 90.0
	club.position.z = -1.4
	_weapon_pivot.add_child(club)


func activate() -> void:
	if state == State.DORMANT:
		state = State.CHASE
		boss_activated.emit("SURXAYIL ALP", health, max_health)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	_cooldown -= delta

	var player_dead: bool = _player == null or _player.get("state") == 4 # State.DEAD
	if state == State.DEAD or state == State.DORMANT or player_dead:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		velocity.y -= gravity * delta
		move_and_slide()
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var dir := to_player / dist if dist > 0.01 else Vector3.FORWARD

	# 2-bosqich tekshiruvi
	if phase == 1 and health <= max_health * 0.5:
		_enter_phase_two()
		return

	match state:
		State.CHASE:
			_tick_chase(dir, dist, delta)
		State.SLAM:
			_tick_slam(dir, delta)
		State.SWEEP:
			_tick_sweep(dir, delta)
		State.ROAR:
			_tick_roar(delta)
		State.WHIRLWIND:
			_tick_whirlwind(dir, delta)
		State.RECOVER:
			_tick_recover(delta)

	velocity.y -= gravity * delta

	# Pog'onalar va yo'laklardan sakramasdan chiqish (Step-up assist)
	_apply_step_up(delta, 0.70)

	move_and_slide()


func _apply_step_up(delta: float, max_step_height := 0.70) -> void:
	if not is_on_floor():
		return
	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	if horiz.length_squared() < 0.01:
		return

	var move_step := horiz * delta
	var col_fwd := KinematicCollision3D.new()
	if test_move(global_transform, move_step, col_fwd):
		var wall_norm := col_fwd.get_normal()
		if wall_norm.y < 0.5:
			var up_vec := Vector3(0.0, max_step_height, 0.0)
			if not test_move(global_transform, up_vec):
				var up_xform := global_transform.translated(up_vec)
				if not test_move(up_xform, move_step):
					var col_down := KinematicCollision3D.new()
					if test_move(up_xform.translated(move_step), -up_vec, col_down):
						if col_down.get_normal().y >= 0.5:
							var step_up := max_step_height - col_down.get_travel().length()
							if step_up > 0.005 and step_up <= max_step_height:
								global_position.y += step_up
								apply_floor_snap()


# ---------------------------------------------------------------- Harakat va tanlov

func _tick_chase(dir: Vector3, dist: float, delta: float) -> void:
	_face(dir, delta, 6.0 if phase == 1 else 9.0)
	var speed := 4.2 if phase == 1 else 5.8
	var target_vel := dir * speed
	velocity.x = move_toward(velocity.x, target_vel.x, 25.0 * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, 25.0 * delta)

	if _cooldown <= 0.0:
		if phase == 2 and randf() < 0.4 and dist < 12.0:
			_start_whirlwind(dir)
		elif dist <= 4.2:
			# Yaqinda: sweep yoki slam
			if randf() < 0.5:
				_start_sweep(dir)
			else:
				_start_slam(dir)
		elif dist <= 9.0 and randf() < 0.6:
			# O'rtacha masofa: sakrab yerga urish
			_start_slam(dir)


func _enter_phase_two() -> void:
	phase = 2
	state = State.ROAR
	_timer = 2.2
	velocity = Vector3.ZERO
	boss_phase_transition.emit(phase)
	FX.hit_stop(0.2)


func _tick_roar(delta: float) -> void:
	_timer -= delta
	# Quturgan charaqlash
	_mat.emission_energy_multiplier = 3.5
	_weapon_mat.emission_energy_multiplier = 4.0
	_body.scale = Vector3.ONE * (1.0 + sin(_timer * 18.0) * 0.08)

	# Atrofdagi o'yinchini orqaga surish to'lqini
	var to_p := _player.global_position - global_position
	to_p.y = 0.0
	if to_p.length() < 7.0 and _timer > 0.5:
		_player.velocity += to_p.normalized() * 15.0 * delta

	if _timer <= 0.0:
		_body.scale = Vector3.ONE
		_cooldown = 0.3
		state = State.CHASE


# ---------------------------------------------------------------- Hujum 1: SLAM (Yerga zarba)

func _start_slam(dir: Vector3) -> void:
	state = State.SLAM
	_timer = 0.0
	_struck = false
	_action_dir = dir
	velocity = _action_dir * (5.0 if phase == 1 else 8.0)
	velocity.y = 5.0 # Sakrash effekti


func _tick_slam(dir: Vector3, delta: float) -> void:
	_timer += delta
	var windup := 0.75 if phase == 1 else 0.55

	if _timer < windup:
		# Cho'qmor tepaga ko'tariladi, signal beradi
		var t := _timer / windup
		_weapon_pivot.rotation_degrees.x = lerpf(0.0, 110.0, t)
		_weapon_mat.emission_energy_multiplier = t * 3.0
		_face(dir, delta, 5.0)
	elif not _struck:
		# ZARBA ANI!
		_struck = true
		_weapon_pivot.rotation_degrees.x = -40.0
		_weapon_mat.emission_energy_multiplier = 0.0
		_spawn_shockwave()
		FX.hit_stop(0.08)
		# Bevosita cho'qmor tagida qolgan o'yinchiga katta zarar
		var to_p := _player.global_position - (global_position + -global_basis.z * 2.2)
		to_p.y = 0.0
		if to_p.length() < 2.5:
			_player.take_damage((20.0 if phase == 1 else 28.0) * GameSettings.get_mult("enemy_dmg"), global_position, 10.0)
	elif _timer >= windup + 0.3:
		_start_recover(0.8 if phase == 1 else 0.5)


func _spawn_shockwave() -> void:
	var sw := Shockwave.new()
	sw.damage = 12.0 if phase == 1 else 16.0
	sw.speed = 9.0 if phase == 1 else 12.0
	sw.max_radius = 11.0
	get_tree().current_scene.add_child(sw)
	var impact_pt := global_position + -global_basis.z * 1.5 + Vector3.UP * 0.1
	sw.global_position = impact_pt
	FX.dust(impact_pt, 20, 2.2)
	FX.sparks(impact_pt, Vector3.UP, Color(1.0, 0.45, 0.15), 18)
	FX.camera_shake(0.45)
	Audio.play_boss_slam()


# ---------------------------------------------------------------- Hujum 2: SWEEP (Keng aylanma)

func _start_sweep(dir: Vector3) -> void:
	state = State.SWEEP
	_timer = 0.0
	_struck = false
	_action_dir = dir


func _tick_sweep(dir: Vector3, delta: float) -> void:
	_timer += delta
	var windup := 0.6 if phase == 1 else 0.42
	var strike := 0.18

	if _timer < windup:
		var t := _timer / windup
		_weapon_pivot.rotation_degrees = Vector3(10.0, 95.0 * t, 0.0)
		_weapon_mat.emission_energy_multiplier = t * 2.0
		_face(dir, delta, 7.0)
	elif _timer < windup + strike:
		var st := (_timer - windup) / strike
		_weapon_pivot.rotation_degrees = Vector3(10.0, lerpf(95.0, -95.0, st), 0.0)
		if not _struck:
			_check_sweep_hit()
	elif _timer >= windup + strike + 0.15:
		_start_recover(0.6 if phase == 1 else 0.35)


func _check_sweep_hit() -> void:
	var to_p := _player.global_position - global_position
	to_p.y = 0.0
	if to_p.length() <= 4.2:
		var forward := -global_basis.z
		if forward.angle_to(to_p) < deg_to_rad(100.0):
			_struck = true
			_player.take_damage((16.0 if phase == 1 else 22.0) * GameSettings.get_mult("enemy_dmg"), global_position, 8.0)
			FX.hit_stop(0.06)


# ---------------------------------------------------------------- Hujum 3: WHIRLWIND (2-bosqich)

func _start_whirlwind(dir: Vector3) -> void:
	state = State.WHIRLWIND
	_timer = 0.0
	_sub_timer = 0.0
	_spin_count = 0
	_action_dir = dir
	_weapon_pivot.rotation_degrees = Vector3(15.0, 90.0, 0.0)
	_weapon_mat.emission_energy_multiplier = 4.0


func _tick_whirlwind(dir: Vector3, delta: float) -> void:
	_timer += delta
	_sub_timer += delta
	_face(dir, delta, 8.0)

	# Oldinga intilib aylanadi
	var fwd := -global_basis.z
	velocity.x = fwd.x * 6.5
	velocity.z = fwd.z * 6.5

	# Tez aylanma
	_weapon_pivot.rotation_degrees.y += 720.0 * delta

	# Har 0.35 soniyada bitta aylanma zarba tekshiruvi
	if _sub_timer >= 0.32:
		_sub_timer = 0.0
		_spin_count += 1
		var to_p := _player.global_position - global_position
		to_p.y = 0.0
		if to_p.length() <= 4.5:
			_player.take_damage(12.0 * GameSettings.get_mult("enemy_dmg"), global_position, 8.0)
			FX.hit_stop(0.05)

	if _spin_count >= 4 or _timer >= 1.6:
		_start_recover(1.1)


# ---------------------------------------------------------------- Tiklanish

func _start_recover(duration: float) -> void:
	state = State.RECOVER
	_timer = duration
	_weapon_mat.emission_energy_multiplier = 0.0


func _tick_recover(delta: float) -> void:
	_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	_weapon_pivot.rotation_degrees = _weapon_pivot.rotation_degrees.lerp(Vector3.ZERO, 1.0 - exp(-10.0 * delta))
	if _timer <= 0.0:
		_cooldown = randf_range(0.5, 1.0)
		state = State.CHASE


func _face(dir: Vector3, delta: float, speed := 6.0) -> void:
	if dir.length() < 0.01:
		return
	var goal := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, goal, 1.0 - exp(-speed * delta))


# ---------------------------------------------------------------- Zarar olish va mag'lubiyat

func take_damage(amount: float, from_pos := Vector3.ZERO, knockback := 2.0) -> void:
	if state == State.DEAD:
		return
	if state == State.DORMANT:
		activate()

	health = maxf(health - amount, 0.0)
	boss_health_changed.emit(health, max_health, phase)
	FX.popup(global_position + Vector3.UP * 3.0, amount, Color(1.0, 0.3, 0.2))
	FX.sparks(global_position + Vector3.UP * 2.2, Vector3.UP, Color(1.0, 0.35, 0.15), 14)

	# Zarba yeganda miltillash
	_mat.emission_energy_multiplier = 2.0
	create_tween().tween_property(_mat, "emission_energy_multiplier", 0.0 if phase == 1 else 1.5, 0.2)

	# Bahaybat bo'lgani uchun uncha surilmaydi, lekin zarba effekti bor
	if state == State.RECOVER and knockback > 5.0:
		var away := (global_position - from_pos).normalized()
		velocity.x += away.x * knockback * 0.4
		velocity.z += away.z * knockback * 0.4

	if health <= 0.0:
		_die()


func _die() -> void:
	state = State.DEAD
	collision_layer = 0
	remove_from_group("enemies")
	remove_from_group("bosses")
	remove_from_group("hurtable")
	_mat.emission_energy_multiplier = 0.0
	_weapon_mat.emission_energy_multiplier = 0.0
	FX.dust(global_position, 28, 2.5)
	FX.sparks(global_position + Vector3.UP * 1.5, Vector3.UP, Color(1.0, 0.8, 0.2), 24)
	boss_defeated.emit()
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem and qsystem.has_method("complete_quest"):
		qsystem.complete_quest("boss")
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.has_method("add_xp"):
		prog.add_xp(250)

	FX.hit_stop(0.25)
	var t := create_tween()
	t.tween_property(_body, "rotation:x", -PI / 2.0, 0.8)
	t.parallel().tween_property(_body, "position:y", 0.5, 0.8)
	t.parallel().tween_property(_weapon_pivot, "position:y", 0.4, 0.8)


func reset_boss(spawn_pos: Vector3) -> void:
	if state == State.DEAD:
		return
	global_position = spawn_pos
	velocity = Vector3.ZERO
	health = max_health
	phase = 1
	state = State.DORMANT
	_timer = 0.0
	_cooldown = 1.0
	_body.rotation = Vector3.ZERO
	_body.scale = Vector3.ONE
	_body.position.y = 1.6
	_weapon_pivot.rotation_degrees = Vector3.ZERO
	_mat.emission_energy_multiplier = 0.0
	_weapon_mat.emission_energy_multiplier = 0.0

