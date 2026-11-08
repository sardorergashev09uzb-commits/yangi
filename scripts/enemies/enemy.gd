class_name Enemy
extends CharacterBody3D
## Qalmoq dushmani: qilichchi, nayzachi yoki kamonchi.
## Holatlar: IDLE -> CHASE -> WINDUP (ogohlantirish) -> STRIKE -> RECOVER, zarba yesa STAGGER.
## Hujum "tokeni": bir vaqtda faqat MAX_ATTACKERS ta yaqin jangchi hujum qiladi, qolganlari aylanib turadi.

signal died(enemy: Enemy)

enum Kind { SWORD, SPEAR, ARCHER }
enum State { IDLE, CHASE, WINDUP, STRIKE, RECOVER, STAGGER, DEAD }

const MAX_ATTACKERS := 2
const STATS := {
	Kind.SWORD: {
		"name": "Qalmoq qilichchi", "hp": 60.0, "speed": 3.8, "reach": 2.1, "damage": 12.0,
		"windup": 0.55, "strike": 0.15, "recover": 0.75, "lunge": 3.0,
		"color": Color(0.55, 0.2, 0.2), "weapon_len": 1.1,
	},
	Kind.SPEAR: {
		"name": "Qalmoq nayzachisi", "hp": 50.0, "speed": 3.4, "reach": 3.2, "damage": 14.0,
		"windup": 0.7, "strike": 0.15, "recover": 0.9, "lunge": 6.0,
		"color": Color(0.2, 0.3, 0.55), "weapon_len": 2.4,
	},
	Kind.ARCHER: {
		"name": "Qalmoq kamonchisi", "hp": 35.0, "speed": 3.0, "reach": 16.0, "damage": 10.0,
		"windup": 0.9, "strike": 0.1, "recover": 1.4, "lunge": 0.0,
		"color": Color(0.2, 0.45, 0.25), "weapon_len": 0.8,
	},
}

static var _attackers := 0

@export var kind: Kind = Kind.SWORD
@export var aggro_range := 14.0
@export var lose_range := 26.0
@export var gravity := 20.0

var state := State.IDLE
var health := 60.0
var max_health := 60.0

var _stats: Dictionary
var _player: Player
var _timer := 0.0
var _cooldown := 0.5
var _has_token := false
var _struck := false
var _strafe_sign := 1.0
var _lock_facing := false
var _avoid_sign := 1.0   # To'siqni qaysi tomondan aylanib o'tish (eslab qolinadi)
var _avoid_timer := 0.0
var _avoid_dir := Vector3.ZERO
var _body: MeshInstance3D
var _mat: StandardMaterial3D
var _weapon: Node3D
var _label: Label3D


func _ready() -> void:
	_stats = STATS[kind]
	max_health = _stats.hp * GameSettings.get_mult("enemy_hp")
	health = max_health
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	add_to_group("enemies")
	add_to_group("hurtable")
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1) | (1 << 2)

	# Pog'onalar, tosh yo'laklar va qiyaliklardan sakramasdan silliq oshib o'tish
	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(55.0)
	floor_stop_on_slope = false
	max_slides = 6

	_build_visuals()


func _build_visuals() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _stats.color
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.45, 0.1)
	_mat.emission_energy_multiplier = 0.0
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	capsule.material = _mat
	_body = MeshInstance3D.new()
	_body.mesh = capsule
	_body.position.y = 0.9
	add_child(_body)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)

	_weapon = Node3D.new()
	_weapon.position = Vector3(0.45, 1.1, -0.2)
	add_child(_weapon)
	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	var length: float = _stats.weapon_len
	blade_mesh.size = Vector3(0.07, 0.07, length)
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.25, 0.22, 0.2)
	blade_mesh.material = blade_mat
	blade.mesh = blade_mesh
	blade.position.z = -length * 0.5
	_weapon.add_child(blade)

	_label = Label3D.new()
	_label.position.y = 2.4
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	add_child(_label)
	_update_label()


func _update_label() -> void:
	if _label == null or not is_instance_valid(_label):
		return
	var pct := clampf(health / max_health, 0.0, 1.0)
	var total_bars := 12
	var filled := int(round(pct * total_bars))
	var empty := total_bars - filled
	var bar_str := "█".repeat(filled) + "░".repeat(empty)
	var icon := "⚔"
	if kind == Kind.SPEAR:
		icon = "🗡"
	elif kind == Kind.ARCHER:
		icon = "🏹"
	_label.text = "%s %s\n[%s] %d/%d" % [icon, _stats.name, bar_str, int(ceil(health)), int(max_health)]
	if pct > 0.6:
		_label.modulate = Color(0.3, 1.0, 0.45)
	elif pct > 0.3:
		_label.modulate = Color(1.0, 0.85, 0.25)
	else:
		_label.modulate = Color(1.0, 0.3, 0.3)


# ---------------------------------------------------------------- Asosiy sikl

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	_cooldown -= delta

	# Masofaga qarab sog'liq panelini ko'rsatish/yashirish (25 metrgacha)
	if _label and is_instance_valid(_label):
		if state == State.DEAD:
			_label.visible = false
		elif _player and is_instance_valid(_player):
			_label.visible = global_position.distance_to(_player.global_position) < 25.0

	var player_alive := _player != null and _player.state != Player.State.DEAD

	if state == State.DEAD or _player == null or not player_alive:
		_release_token()
		if state != State.DEAD and state != State.IDLE:
			state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		velocity.y -= gravity * delta
		_apply_step_up(delta)
		move_and_slide()
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var dir := to_player / dist if dist > 0.01 else Vector3.ZERO

	match state:
		State.IDLE:
			_stop(delta)
			if player_alive and dist < aggro_range and _can_see_player():
				_alert()
		State.CHASE:
			if not player_alive or dist > lose_range:
				_release_token()
				state = State.IDLE
			else:
				_face(dir, delta, 10.0)
				_chase(dir, dist, delta)
		State.WINDUP:
			_windup(dir, delta)
		State.STRIKE:
			_strike(dir, delta)
		State.RECOVER:
			_stop(delta)
			_timer -= delta
			_weapon.rotation_degrees.x = lerpf(_weapon.rotation_degrees.x, 0.0, 1.0 - exp(-10.0 * delta))
			_mat.emission_energy_multiplier = 0.0
			if _timer <= 0.0:
				_cooldown = randf_range(0.3, 0.9)
				state = State.CHASE
		State.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE

	velocity.y -= gravity * delta

	# Pog'ona va tosh yo'laklardan sakramasdan chiqish (Step-up assist)
	_apply_step_up(delta)

	move_and_slide()


# ---------------------------------------------------------------- Harakat

func _alert() -> void:
	state = State.CHASE
	# Yaqin do'stlarni ham ogohlantiradi
	for e in get_tree().get_nodes_in_group("enemies"):
		var other := e as Enemy
		if other != null and other.state == State.IDLE \
				and other.global_position.distance_to(global_position) < 10.0:
			other.state = State.CHASE


func _chase(dir: Vector3, dist: float, delta: float) -> void:
	var speed: float = _stats.speed
	var move := Vector3.ZERO
	if kind == Kind.ARCHER:
		if dist < 8.0:
			move = -dir * speed * 1.2          # orqaga chekinadi
		elif dist > 13.0:
			move = dir * speed                 # yaqinlashadi
		else:
			move = dir.rotated(Vector3.UP, PI / 2.0) * _strafe_sign * speed * 0.5
		if _cooldown <= 0.0 and dist < 16.0 and _can_see_player():
			_begin_attack()
			return
	else:
		var reach: float = _stats.reach
		var start_range := reach - 0.3
		if _cooldown <= 0.0 and not _has_token:
			_try_token()
		if _has_token:
			move = dir * speed
			if dist <= start_range:
				_begin_attack()
				return
		else:
			# Token yo'q: o'yinchi atrofida aylanadi
			var side := dir.rotated(Vector3.UP, PI / 2.0) * _strafe_sign
			if dist > 7.0:
				move = dir * speed
			elif dist < 4.0:
				move = -dir * speed * 0.6 + side * speed * 0.4
			else:
				move = side * speed * 0.55
	move = _avoid_obstacles(move, delta)
	move += _separation() * 2.0
	velocity.x = move_toward(velocity.x, move.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, move.z, 30.0 * delta)


func _separation() -> Vector3:
	var push := Vector3.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not e is Node3D:
			continue
		var d: Vector3 = global_position - (e as Node3D).global_position
		d.y = 0.0
		var l := d.length()
		if l > 0.01 and l < 1.4:
			push += d / l * (1.4 - l)
	return push


func _stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)


func _face(dir: Vector3, delta: float, speed := 10.0) -> void:
	if dir.length() < 0.01:
		return
	var goal := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, goal, 1.0 - exp(-speed * delta))


func _can_see_player() -> bool:
	var from := global_position + Vector3.UP * 1.5
	var to := _player.global_position + Vector3.UP * 1.2
	var q := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## To'siqdan qochish: dushmanning o'z tanasi bilan yo'nalishni sinaydi. To'siq bo'lsa,
## bo'sh yo'nalishni tanlaydi va uni biroz vaqt ushlab turadi (to'siq oldida titrab qolmaslik uchun).
func _avoid_obstacles(move: Vector3, delta: float) -> Vector3:
	var flat := Vector3(move.x, 0.0, move.z)
	var spd := flat.length()
	if spd < 0.1:
		return move
	_avoid_timer = maxf(_avoid_timer - delta, 0.0)
	# Tanlangan aylanib o'tish yo'nalishi hali kuchda va bo'sh bo'lsa, davom etamiz
	if _avoid_timer > 0.0 and _avoid_dir.length() > 0.1 and _path_clear(_avoid_dir):
		return _avoid_dir * spd + Vector3(0.0, move.y, 0.0)
	var dir := flat / spd
	if _path_clear(dir):
		return move
	for a: float in [35.0, 70.0, 110.0, 150.0]:
		for sgn: float in [_avoid_sign, -_avoid_sign]:
			var cand := dir.rotated(Vector3.UP, deg_to_rad(a) * sgn)
			if _path_clear(cand):
				_avoid_sign = sgn
				_avoid_dir = cand
				_avoid_timer = 0.9
				return cand * spd + Vector3(0.0, move.y, 0.0)
	return move


func _path_clear(dir: Vector3) -> bool:
	var col := KinematicCollision3D.new()
	if not test_move(global_transform, dir * 1.0, col):
		return true
	if col.get_normal().y > 0.6:
		return true
	# Kichik pog'ona (yo'laklar, toshlar) dushman uchun to'siq emas, ustidan oshib o'tadi
	var up_vec := Vector3(0.0, 0.45, 0.0)
	if not test_move(global_transform, up_vec):
		if not test_move(global_transform.translated(up_vec), dir * 1.0):
			return true
	return false


func _apply_step_up(delta: float, max_step_height := 0.45) -> void:
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



# ---------------------------------------------------------------- Hujum tokeni

func _try_token() -> void:
	if _attackers < MAX_ATTACKERS:
		_attackers += 1
		_has_token = true


func _release_token() -> void:
	if _has_token:
		_has_token = false
		_attackers = maxi(_attackers - 1, 0)


func _exit_tree() -> void:
	_release_token()


# ---------------------------------------------------------------- Hujum bosqichlari

func _begin_attack() -> void:
	state = State.WINDUP
	_timer = 0.0
	_struck = false
	_lock_facing = false


func _windup(dir: Vector3, delta: float) -> void:
	var windup: float = _stats.windup
	_timer += delta
	var t := clampf(_timer / windup, 0.0, 1.0)
	_stop(delta)
	# Oxirgi 30% da yo'nalish qotadi, o'yinchi yon tomonga qochishi mumkin
	if t < 0.7:
		_face(dir, delta, 8.0)
	_weapon.rotation_degrees.x = lerpf(0.0, 70.0, t)
	# Ogohlantirish: tanasi to'q sariq charaqlaydi
	_mat.emission_energy_multiplier = t * 1.8
	if _timer >= windup:
		state = State.STRIKE
		_timer = 0.0


func _strike(dir: Vector3, delta: float) -> void:
	var strike: float = _stats.strike
	if _timer == 0.0:
		_weapon.rotation_degrees.x = -50.0
		_mat.emission_energy_multiplier = 0.0
		if kind == Kind.ARCHER:
			_fire_arrow()
			_struck = true
	_timer += delta
	var forward := -global_basis.z
	var lunge: float = _stats.lunge
	velocity.x = forward.x * lunge
	velocity.z = forward.z * lunge
	if not _struck:
		_melee_hit()
	if _timer >= strike:
		state = State.RECOVER
		_timer = _stats.recover
		_release_token()


func _melee_hit() -> void:
	var to := _player.global_position - global_position
	to.y = 0.0
	var reach: float = _stats.reach
	if to.length() > reach + 0.4:
		return
	var forward := -global_basis.z
	if forward.angle_to(to) > deg_to_rad(60.0):
		return
	_struck = true
	_player.take_damage(_stats.damage * GameSettings.get_mult("enemy_dmg"), global_position, 6.0)


func _fire_arrow() -> void:
	var origin := global_position + Vector3.UP * 1.4 + (-global_basis.z) * 0.6
	var target := _player.global_position + Vector3.UP * 1.0
	var arrow := Arrow.new()
	arrow.shooter = self
	arrow.damage = _stats.damage * GameSettings.get_mult("enemy_dmg")
	arrow.gravity = 2.0
	arrow.hit_mask = 1 | (1 << 1)
	arrow.velocity = (target - origin).normalized() * 24.0
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = origin


# ---------------------------------------------------------------- Zarar va o'lim

func take_damage(amount: float, from_pos := Vector3.ZERO, knockback := 4.0) -> void:
	if state == State.DEAD:
		return
	health = maxf(health - amount, 0.0)
	_update_label()
	FX.popup(global_position + Vector3.UP * 2.0, amount)
	_mat.emission_energy_multiplier = 2.5
	create_tween().tween_property(_mat, "emission_energy_multiplier", 0.0, 0.2)
	_release_token()
	if health <= 0.0:
		_die()
		return
	if state == State.IDLE:
		_alert()
	var away := global_position - from_pos
	away.y = 0.0
	if away.length() > 0.01:
		away = away.normalized()
		velocity.x = away.x * knockback
		velocity.z = away.z * knockback
	_weapon.rotation_degrees.x = 0.0
	state = State.STAGGER
	_timer = 0.7 if knockback >= 8.0 else 0.4


## Parry: dushman muvozanatini yo'qotadi va uzoqroq larzaga tushadi
func get_parried(from_pos: Vector3) -> void:
	if state == State.DEAD:
		return
	_release_token()
	_weapon.rotation_degrees.x = 0.0
	_mat.emission_energy_multiplier = 0.0
	var away := global_position - from_pos
	away.y = 0.0
	if away.length() > 0.01:
		away = away.normalized()
		velocity.x = away.x * 4.0
		velocity.z = away.z * 4.0
	FX.popup(global_position + Vector3.UP * 2.3, 0.0, Color(0.5, 0.9, 1.0))
	state = State.STAGGER
	_timer = 1.3


func _die() -> void:
	state = State.DEAD
	_release_token()
	collision_layer = 0
	remove_from_group("enemies")
	remove_from_group("hurtable")
	_label.visible = false
	_mat.emission_energy_multiplier = 0.0
	var t := create_tween()
	t.tween_property(_body, "rotation:x", -PI / 2.0, 0.35)
	t.parallel().tween_property(_body, "position:y", 0.4, 0.35)
	died.emit(self)
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.has_method("add_xp"):
		prog.add_xp(30)
	await get_tree().create_timer(3.0).timeout
	queue_free()


func reset_to_spawn(spawn_pos: Vector3) -> void:
	if state == State.DEAD:
		return
	global_position = spawn_pos
	velocity = Vector3.ZERO
	health = max_health
	state = State.IDLE
	_release_token()
	_update_label()

