class_name Player
extends CharacterBody3D
## Alpamish: harakat, qochish, yaqin jang kombosi, kamon, salomatlik va kuch (stamina).

signal stamina_changed(current: float, maximum: float)
signal health_changed(current: float, maximum: float)
signal died
signal respawned

enum State { NORMAL, DODGE, ATTACK, HURT, DEAD, BLOCK }

# Jang ma'lumotlari: vaqtlar soniyada. swing: 0 - chapga, 1 - o'ngga, 2 - tepadan pastga
const LIGHT_COMBO := [
	{"damage": 18.0, "windup": 0.10, "active": 0.14, "recover": 0.22, "lunge": 3.5, "swing": 0, "cost": 10.0},
	{"damage": 20.0, "windup": 0.08, "active": 0.14, "recover": 0.24, "lunge": 3.5, "swing": 1, "cost": 10.0},
	{"damage": 32.0, "windup": 0.16, "active": 0.16, "recover": 0.42, "lunge": 5.0, "swing": 2, "cost": 12.0},
]
const HEAVY := {"damage": 50.0, "windup": 0.38, "active": 0.16, "recover": 0.48, "lunge": 5.0, "swing": 2, "cost": 25.0}
const BOW_DRAW_TIME := 0.8
const BOW_COST := 8.0
const PARRY_WINDOW := 0.2      # Blok boshlanishidan keyingi "parry" oynasi (soniya)
const BLOCK_REDUCTION := 0.25  # Blokda o'tadigan zarar ulushi
const BLOCK_STAMINA_MULT := 0.9
const BLOCK_ARC_DEG := 110.0   # Old tomondan himoya burchagi

@export_group("Harakat")
@export var run_speed := 5.5
@export var sprint_speed := 8.5
@export var aim_speed := 3.0
@export var ground_accel := 45.0
@export var air_accel := 12.0
@export var jump_velocity := 6.5
@export var turn_speed := 14.0
@export var gravity := 20.0

@export_group("Qochish")
@export var dodge_speed := 11.0
@export var dodge_time := 0.45
@export var dodge_iframes := 0.28
@export var dodge_cost := 20.0

@export_group("Kuch va salomatlik")
@export var max_health := 100.0
@export var max_stamina := 100.0
@export var sprint_cost_per_sec := 14.0
@export var stamina_regen := 28.0
@export var regen_delay := 0.8
@export var hurt_iframes := 0.7

var state := State.NORMAL
var health := 100.0
var stamina := 100.0
var aiming := false
var bow_charge := 0.0
var is_mounted := false
var mounted_horse: Node3D = null

var invulnerable: bool:
	get:
		return _dodge_invuln or _hit_invuln > 0.0

var _dodge_invuln := false
var _hit_invuln := 0.0
var _dodge_dir := Vector3.ZERO
var _dodge_timer := 0.0
var _regen_timer := 0.0
var _hurt_timer := 0.0
var _spawn := Vector3.ZERO

var _attack: Dictionary = {}
var _attack_heavy := false
var _attack_time := 0.0
var _attack_dir := Vector3.FORWARD
var _combo_index := 0
var _hit_list: Array[Node] = []
var _buffer_light := 0.0
var _buffer_heavy := 0.0
var _drawing := false
var _block_time := 0.0
var is_blocking: bool:
	get:
		return state == State.BLOCK

var _bow_back: Node3D
var _bow_hand: Node3D
var _bow_arrow_mesh: MeshInstance3D

@onready var model: Node3D = $Model
@onready var rig: CameraRig = $CameraRig
@onready var weapon: Node3D = $Model/WeaponPivot
@onready var hitbox: Area3D = $Model/Hitbox


func _ready() -> void:
	health = max_health
	stamina = max_stamina
	_spawn = global_position
	collision_layer = 1 << 1
	collision_mask = 1 | (1 << 2)
	hitbox.collision_layer = 1 << 3
	hitbox.collision_mask = 1 << 2
	_build_bow_visuals()


func _physics_process(delta: float) -> void:
	if _hit_invuln > 0.0:
		_hit_invuln -= delta
		model.visible = int(_hit_invuln * 20.0) % 2 == 0 or _hit_invuln <= 0.0

	_update_bow_visuals()

	if is_mounted:
		# Ot ustida: harakatni ot bajaradi, o'yinchi yuzlanish va kamon bilan jang qiladi
		velocity = Vector3.ZERO
		_face(_cam_forward(), delta)
		aiming = Input.is_action_pressed("aim")
		rig.aiming = aiming
		if aiming:
			_bow(delta)
		else:
			_cancel_bow()
		return

	match state:
		State.NORMAL:
			_normal(delta)
		State.DODGE:
			_dodge(delta)
		State.ATTACK:
			_attack_tick(delta)
		State.HURT:
			_hurt(delta)
		State.BLOCK:
			_block(delta)
		State.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0
			velocity.y -= gravity * delta
	move_and_slide()
	_regen(delta)


# ---------------------------------------------------------------- Oddiy holat

func _cam_forward() -> Vector3:
	return Vector3(-sin(rig.yaw), 0.0, -cos(rig.yaw))


func _normal(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, rig.yaw)
	var moving := dir.length() > 0.1

	aiming = Input.is_action_pressed("aim")
	rig.aiming = aiming

	var sprinting := moving and not aiming and Input.is_action_pressed("sprint") \
			and stamina > 1.0 and is_on_floor()
	if sprinting:
		_use_stamina(sprint_cost_per_sec * delta)

	var speed := run_speed
	if sprinting:
		speed = sprint_speed
	elif aiming:
		speed = aim_speed
	var accel := ground_accel if is_on_floor() else air_accel
	var target_vel := dir * speed
	velocity.x = move_toward(velocity.x, target_vel.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, accel * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not aiming:
			velocity.y = jump_velocity
			Audio.play_jump()
	else:
		velocity.y -= gravity * delta

	# Yuzlanish faqat sichqoncha (kamera) bilan boshqariladi; WASD faqat harakat.
	_face(_cam_forward(), delta, aiming)

	if Input.is_action_just_pressed("dodge") and is_on_floor() and stamina >= dodge_cost:
		_cancel_bow()
		_start_dodge(dir if moving else -_cam_forward())
		return

	# Otdan foydalanish: Minish (F) yoki Hushtak chalish (H)
	if Input.is_action_just_pressed("interact"):
		_try_mount_horse()
	elif Input.is_action_just_pressed("whistle"):
		_whistle_horse()

	if Input.is_action_pressed("block") and not aiming and is_on_floor() and stamina >= 1.0:
		_cancel_bow()
		_start_block()
		return

	if aiming:
		_bow(delta)
	else:
		_cancel_bow()
		if is_on_floor():
			if Input.is_action_just_pressed("attack_light"):
				_start_attack(false, 0)
			elif Input.is_action_just_pressed("attack_heavy"):
				_start_attack(true, 0)


# ---------------------------------------------------------------- Kamon

func _bow(delta: float) -> void:
	if not _drawing:
		if Input.is_action_just_pressed("attack_light") and stamina >= BOW_COST:
			_drawing = true
			bow_charge = 0.0
			Audio.play_bow_draw()
		return

	var draw_spd := BOW_DRAW_TIME
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.get("unlocked_skills") and prog.unlocked_skills.get("bow_mastery", false):
		draw_spd *= 0.55

	bow_charge = minf(bow_charge + delta / draw_spd, 1.0)

	# Agar qo'yib yuborilsa - darhol o'q otiladi! (har qanday click ishlaydi)
	if Input.is_action_just_released("attack_light"):
		_fire_bow(maxf(bow_charge, 0.2))
		_cancel_bow()


func _cancel_bow() -> void:
	_drawing = false
	bow_charge = 0.0


func _fire_bow(charge: float) -> void:
	_use_stamina(BOW_COST)
	Audio.play_bow_shoot()
	var excludes: Array[RID] = [get_rid()]
	if is_mounted and mounted_horse and is_instance_valid(mounted_horse):
		excludes.append(mounted_horse.get_rid())

	var aim_info: Dictionary = rig.get_aim_target(140.0, excludes)
	var target: Vector3 = aim_info.get("target", global_position - rig.global_basis.z * 140.0)
	var ray_dir: Vector3 = aim_info.get("dir", -rig.global_basis.z)

	# O'q kamon qo'li yaqinidan, lekin qahramon va ot to'sig'idan oldinda chiqadi
	var spawn := global_position + Vector3.UP * 1.45 + ray_dir * 1.0
	if _bow_hand and is_instance_valid(_bow_hand) and _bow_hand.is_inside_tree():
		spawn = _bow_hand.global_position + ray_dir * 0.75

	var arrow := Arrow.new()
	arrow.shooter = self
	if is_mounted and mounted_horse and is_instance_valid(mounted_horse):
		arrow.extra_exclude = [mounted_horse.get_rid()]

	var base_dmg := lerpf(18.0, 48.0, charge) * GameSettings.get_mult("player_dmg")
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.get("unlocked_skills") and prog.unlocked_skills.get("bow_mastery", false):
		base_dmg *= 1.4
	arrow.damage = base_dmg
	arrow.velocity = (target - spawn).normalized() * lerpf(36.0, 66.0, charge)

	get_tree().current_scene.add_child(arrow)
	arrow.global_position = spawn
	rig.shake(0.04)
	FX.popup(spawn, 0.0, Color(1.0, 0.8, 0.3))


func _build_bow_visuals() -> void:
	# 1. Orqadagi kamon (Yelkada osilgan)
	_bow_back = _create_bow_mesh()
	_bow_back.position = Vector3(-0.15, 1.35, 0.38)
	_bow_back.rotation_degrees = Vector3(15.0, -20.0, 45.0)
	model.add_child(_bow_back)

	# 2. Qo'ldagi kamon (Nishonlaganda chap qo'lga o'tadi)
	_bow_hand = _create_bow_mesh()
	_bow_hand.position = Vector3(-0.35, 1.25, -0.6)
	_bow_hand.rotation_degrees = Vector3(0.0, 0.0, 10.0)
	_bow_hand.visible = false
	model.add_child(_bow_hand)

	# Qo'ldagi o'q (faqat tortilganda ko'rinadi)
	_bow_arrow_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = 0.95
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.85, 0.7, 0.4)
	_bow_arrow_mesh.mesh = cyl
	_bow_arrow_mesh.material_override = amat
	_bow_arrow_mesh.rotation_degrees.x = 90.0
	_bow_arrow_mesh.position = Vector3(0.12, 0, 0)
	_bow_arrow_mesh.visible = false
	_bow_hand.add_child(_bow_arrow_mesh)


func _create_bow_mesh() -> Node3D:
	var root := Node3D.new()
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.42, 0.22, 0.1) # Qizg'ish-to'q eman yog'ochi
	wood_mat.roughness = 0.6

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.85, 0.7, 0.2) # Oltin/suyak qoplama

	var string_mat := StandardMaterial3D.new()
	string_mat.albedo_color = Color(0.95, 0.95, 0.92) # Oq pay kamon ipi

	# Tutqich
	var grip := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(0.04, 0.25, 0.04)
	grip.mesh = gbox
	grip.material_override = gold_mat
	root.add_child(grip)

	# Yuqori yelka (Yuqoriga egilgan)
	var upper := MeshInstance3D.new()
	var ubox := BoxMesh.new()
	ubox.size = Vector3(0.035, 0.55, 0.035)
	upper.mesh = ubox
	upper.material_override = wood_mat
	upper.position = Vector3(0, 0.35, -0.06)
	upper.rotation_degrees.x = -22.0
	root.add_child(upper)

	# Pastki yelka (Pastga egilgan)
	var lower := MeshInstance3D.new()
	var lbox := BoxMesh.new()
	lbox.size = Vector3(0.035, 0.55, 0.035)
	lower.mesh = lbox
	lower.material_override = wood_mat
	lower.position = Vector3(0, -0.35, -0.06)
	lower.rotation_degrees.x = 22.0
	root.add_child(lower)

	# Kamon ipi (String)
	var string_node := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.005
	scyl.bottom_radius = 0.005
	scyl.height = 1.15
	string_node.mesh = scyl
	string_node.material_override = string_mat
	string_node.position = Vector3(0, 0, 0.04)
	root.add_child(string_node)

	return root


func _update_bow_visuals() -> void:
	if _bow_hand == null or _bow_back == null:
		return
	if aiming:
		weapon.visible = false
		_bow_back.visible = false
		_bow_hand.visible = true
		if rig:
			_bow_hand.rotation_degrees.x = rad_to_deg(rig.pitch)
		_bow_arrow_mesh.visible = _drawing
		if _drawing:
			_bow_arrow_mesh.position.z = lerpf(0.0, 0.35, bow_charge)
	else:
		weapon.visible = true
		_bow_back.visible = true
		_bow_hand.visible = false
		_bow_arrow_mesh.visible = false


# ---------------------------------------------------------------- Yaqin jang

func _start_attack(heavy: bool, index: int) -> void:
	if stamina < 1.0:
		return
	_attack = HEAVY if heavy else LIGHT_COMBO[index]
	_attack_heavy = heavy
	_combo_index = index
	_attack_time = 0.0
	_hit_list.clear()
	_buffer_light = 0.0
	_buffer_heavy = 0.0
	_use_stamina(_attack.cost)
	Audio.play_sword_swing()

	_attack_dir = _cam_forward()
	_face(_attack_dir, 1.0 / 60.0, true)
	state = State.ATTACK


func _attack_tick(delta: float) -> void:
	_attack_time += delta
	_buffer_light = maxf(_buffer_light - delta, 0.0)
	_buffer_heavy = maxf(_buffer_heavy - delta, 0.0)
	if Input.is_action_just_pressed("attack_light"):
		_buffer_light = 0.4
	if Input.is_action_just_pressed("attack_heavy"):
		_buffer_heavy = 0.4

	var windup: float = _attack.windup
	var active: float = _attack.active
	var recover: float = _attack.recover
	var strike_end := windup + active
	var total := strike_end + recover

	# Qochish bilan jangni bekor qilish (zarbadan keyin)
	if _attack_time >= windup and Input.is_action_just_pressed("dodge") \
			and stamina >= dodge_cost and is_on_floor():
		_end_attack()
		var di := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var dd := Vector3(di.x, 0.0, di.y).rotated(Vector3.UP, rig.yaw)
		_start_dodge(dd if dd.length() > 0.1 else -_cam_forward())
		return

	# Vaqt oynasiga qarab harakat: tayyorlanish (to'xtash), zarba (oldinga siljish), tiklanish
	var lunge: float = _attack.lunge
	if _attack_time >= windup and _attack_time < strike_end:
		velocity.x = _attack_dir.x * lunge
		velocity.z = _attack_dir.z * lunge
		_check_hits()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
	velocity.y -= gravity * delta

	_update_swing(windup, active, recover)

	# Kombo yoki og'ir zarbaga o'tish (tiklanishning boshlanishidan keyin)
	if _attack_time >= strike_end + recover * 0.3:
		if _buffer_heavy > 0.0 and stamina >= 1.0:
			_start_attack(true, 0)
			return
		if _buffer_light > 0.0 and not _attack_heavy and stamina >= 1.0 \
				and _combo_index < LIGHT_COMBO.size() - 1:
			_start_attack(false, _combo_index + 1)
			return

	if _attack_time >= total:
		_end_attack()


func _check_hits() -> void:
	var dmg: float = _attack.damage * GameSettings.get_mult("player_dmg")
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.get("unlocked_skills") and prog.unlocked_skills.get("sword_mastery", false):
		dmg *= 1.35
	for b in hitbox.get_overlapping_bodies():
		if b == self or b in _hit_list or not b.has_method("take_damage"):
			continue
		_hit_list.append(b)
		var knock := 9.0 if _attack_heavy else 5.0
		b.take_damage(dmg, global_position, knock)
		FX.hit_stop(0.12 if _attack_heavy else 0.07)
		FX.sparks(b.global_position + Vector3(0, 1.0, 0), Vector3.UP, Color(1.0, 0.85, 0.25))
		if _attack_heavy:
			Audio.play_heavy_hit()
		else:
			Audio.play_hit()
		rig.shake(0.3 if _attack_heavy else 0.15)


func _end_attack() -> void:
	state = State.NORMAL
	_combo_index = 0
	weapon.rotation_degrees = Vector3.ZERO


func _update_swing(windup: float, active: float, recover: float) -> void:
	var poses := [
		[Vector3(0, 80, 0), Vector3(0, -80, 0)],
		[Vector3(0, -80, 0), Vector3(0, 80, 0)],
		[Vector3(110, 0, 0), Vector3(-40, 0, 0)],
	]
	var pose: Array = poses[_attack.swing]
	var start: Vector3 = pose[0]
	var end: Vector3 = pose[1]
	if _attack_time < windup:
		weapon.rotation_degrees = Vector3.ZERO.lerp(start, _attack_time / windup)
	elif _attack_time < windup + active:
		weapon.rotation_degrees = start.lerp(end, (_attack_time - windup) / active)
	else:
		var t := clampf((_attack_time - windup - active) / recover, 0.0, 1.0)
		weapon.rotation_degrees = end.lerp(Vector3.ZERO, t)


# ---------------------------------------------------------------- Blok va parry

func _start_block() -> void:
	state = State.BLOCK
	_block_time = 0.0
	_face(_cam_forward(), 1.0 / 60.0, true)


func _block(delta: float) -> void:
	_block_time += delta
	_face(_cam_forward(), delta, true)
	velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
	velocity.y -= gravity * delta
	model.scale = Vector3(1.0, 0.92, 1.0) if _block_time > PARRY_WINDOW else Vector3(1.05, 0.96, 1.05)
	# Blokdan qochish
	if Input.is_action_just_pressed("dodge") and stamina >= dodge_cost and is_on_floor():
		_end_block()
		var di := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var dd := Vector3(di.x, 0.0, di.y).rotated(Vector3.UP, rig.yaw)
		_start_dodge(dd if dd.length() > 0.1 else -_cam_forward())
		return
	if not Input.is_action_pressed("block") or stamina < 1.0 or not is_on_floor():
		_end_block()


func _end_block() -> void:
	if state == State.BLOCK:
		state = State.NORMAL
	model.scale = Vector3.ONE


## Zarba old tomondan kelganmi (himoya burchagi ichida)
func _covers(from_pos: Vector3) -> bool:
	var to := from_pos - global_position
	to.y = 0.0
	if to.length() < 0.05:
		return true
	var facing := Vector3(-sin(model.rotation.y), 0.0, -cos(model.rotation.y))
	return facing.angle_to(to) <= deg_to_rad(BLOCK_ARC_DEG * 0.5)


## Blok/parry hisobga olingandan keyin o'yinchiga o'tadigan zarar miqdori.
func _try_block(amount: float, from_pos: Vector3) -> float:
	if state != State.BLOCK or not _covers(from_pos):
		return amount
	var spark_pos := global_position + Vector3(0, 1.1, 0) + (from_pos - global_position).normalized() * 0.6
	if _block_time <= PARRY_WINDOW:
		# Mukammal parry: zarar yo'q, hujum qilgan dushman larzaga tushadi
		FX.hit_stop(0.12)
		FX.sparks(spark_pos, Vector3.UP, Color(0.5, 0.9, 1.0), 22)
		FX.popup(global_position + Vector3.UP * 2.3, 0.0, Color(0.5, 0.9, 1.0))
		Audio.play_heavy_hit()
		rig.shake(0.2)
		stamina = minf(stamina + 15.0, max_stamina)
		stamina_changed.emit(stamina, max_stamina)
		_stagger_attacker(from_pos)
		return 0.0
	var cost := amount * BLOCK_STAMINA_MULT
	FX.hit_stop(0.05)
	FX.sparks(spark_pos, Vector3.UP, Color(1.0, 0.9, 0.6), 10)
	Audio.play_hit()
	rig.shake(0.15)
	if stamina >= cost:
		_use_stamina(cost)
		return 0.0  # Kuch yetarli: zarar to'liq to'sildi
	# Himoya sinishi: kuch tugaydi, zarar qisman o'tadi
	var leftover := amount * (1.0 - stamina / maxf(cost, 0.01)) + amount * BLOCK_REDUCTION
	_use_stamina(stamina)
	_end_block()
	return minf(leftover, amount)


func _stagger_attacker(from_pos: Vector3) -> void:
	var best: Node = null
	var best_d := 3.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("get_parried"):
			continue
		var d: float = e.global_position.distance_to(from_pos)
		if d < best_d:
			best_d = d
			best = e
	if best:
		best.get_parried(global_position)


# ---------------------------------------------------------------- Qochish

func _start_dodge(dir: Vector3) -> void:
	_use_stamina(dodge_cost)
	_dodge_dir = Vector3(dir.x, 0.0, dir.z).normalized()
	_dodge_timer = 0.0
	state = State.DODGE
	_dodge_invuln = true
	FX.dust(global_position, 8, 0.9)
	Audio.play_dodge()


func _dodge(delta: float) -> void:
	_dodge_timer += delta
	var t := clampf(_dodge_timer / dodge_time, 0.0, 1.0)
	var curve := 1.0 - t * t
	velocity.x = _dodge_dir.x * dodge_speed * curve
	velocity.z = _dodge_dir.z * dodge_speed * curve
	velocity.y -= gravity * delta
	_dodge_invuln = _dodge_timer < dodge_iframes
	model.scale.y = lerpf(0.65, 1.0, t)  # vaqtincha vizual signal
	if _dodge_timer >= dodge_time:
		state = State.NORMAL
		_dodge_invuln = false
		model.scale.y = 1.0


# ---------------------------------------------------------------- Zarar va o'lim

func take_damage(amount: float, from_pos: Vector3, knockback := 5.0) -> void:
	if invulnerable or state == State.DEAD:
		return
	amount = _try_block(amount, from_pos)
	if amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	FX.hit_stop(0.05)
	rig.shake(0.35)
	_cancel_bow()
	_end_attack()
	_end_block()
	model.scale = Vector3.ONE
	_dodge_invuln = false
	if health <= 0.0:
		_die()
		return
	var away := global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -model.global_basis.z
	velocity = away * knockback
	state = State.HURT
	_hurt_timer = 0.3
	_hit_invuln = hurt_iframes


func _hurt(delta: float) -> void:
	_hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	velocity.y -= gravity * delta
	if _hurt_timer <= 0.0:
		state = State.NORMAL


func _die() -> void:
	if is_mounted and mounted_horse != null:
		mounted_horse.dismount()
	state = State.DEAD
	Engine.time_scale = 1.0
	FX.reset()
	aiming = false
	rig.aiming = false
	model.visible = true
	model.rotation.x = -PI / 2.0
	died.emit()
	# ignore_time_scale = true: sekinlashish yoki time_scale ta'sirida qotib qolmasligini ta'minlaydi
	await get_tree().create_timer(1.8, true, false, true).timeout
	global_position = _spawn
	velocity = Vector3.ZERO
	model.rotation = Vector3.ZERO
	if rig:
		rig.global_position = _spawn + Vector3.UP * rig.height
		rig.yaw = 0.0
		rig.pitch = deg_to_rad(-15.0)
	health = max_health
	stamina = max_stamina
	_hit_invuln = 1.0
	state = State.NORMAL
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	respawned.emit()


# ---------------------------------------------------------------- Yordamchi

func _face(dir: Vector3, delta: float, instant := false) -> void:
	if dir.length() < 0.01:
		return
	var goal := atan2(-dir.x, -dir.z)
	if instant:
		model.rotation.y = goal
	else:
		model.rotation.y = lerp_angle(model.rotation.y, goal, 1.0 - exp(-turn_speed * delta))


func _use_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	_regen_timer = regen_delay
	stamina_changed.emit(stamina, max_stamina)


func _regen(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	if stamina < max_stamina:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)
		stamina_changed.emit(stamina, max_stamina)


func _try_mount_horse() -> void:
	for h in get_tree().get_nodes_in_group("horses"):
		if h != null and h.has_method("mount") and not h.get("is_mounted") and global_position.distance_to(h.global_position) < 4.5:
			h.mount(self)
			return


func _whistle_horse() -> void:
	FX.popup(global_position + Vector3.UP * 2.2, 0.0, Color(0.4, 0.8, 1.0))
	for h in get_tree().get_nodes_in_group("horses"):
		if h != null and h.has_method("call_horse") and not h.get("is_mounted"):
			h.call_horse(self)
			return

