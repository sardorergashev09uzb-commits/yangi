class_name Player
extends CharacterBody3D
## Alpamish: harakat, qochish, yaqin jang kombosi, kamon, salomatlik va kuch (stamina).

signal stamina_changed(current: float, maximum: float)
signal health_changed(current: float, maximum: float)
signal gold_changed(new_gold: int, delta_amount: int)
signal resources_changed(iron: int, wood: int, herbs: int)
signal died
signal respawned

enum State { NORMAL, DODGE, ATTACK, HURT, DEAD, BLOCK, SPECIAL }

# Jang ma'lumotlari: vaqtlar soniyada. swing: 0 - chapga, 1 - o'ngga, 2 - tepadan pastga
const LIGHT_COMBO := [
	{"damage": 18.0, "windup": 0.10, "active": 0.14, "recover": 0.22, "lunge": 3.5, "swing": 0, "cost": 10.0},
	{"damage": 20.0, "windup": 0.08, "active": 0.14, "recover": 0.24, "lunge": 3.5, "swing": 1, "cost": 10.0},
	{"damage": 32.0, "windup": 0.16, "active": 0.16, "recover": 0.42, "lunge": 5.0, "swing": 2, "cost": 12.0},
]
const HEAVY := {"damage": 50.0, "windup": 0.38, "active": 0.16, "recover": 0.48, "lunge": 5.0, "swing": 2, "cost": 25.0}
const BOW_DRAW_TIME := 0.8
const BOW_COST := 8.0
const SPECIAL_STAMINA_COST := 35.0
const SPECIAL_COOLDOWN := 4.5
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
var gold: int = 0

# 2-Bosqich: Savdo va qurol-yarog' anjomlari
var sword_damage_bonus: float = 0.0
var damage_reduction: float = 0.0
var fire_arrows_count: int = 0
var piercing_arrows_count: int = 0
var has_golden_horseshoes: bool = false
var qimiz_buff_timer: float = 0.0
var is_steel_sword_equipped: bool = false
var is_plate_armor_equipped: bool = false

# 4 & 5-Bosqich: Qahramon ko'rinishi va afsonaviy mahoratlar (Dubulg'a, Qalqon, Yopinchiq, Simurg' Qanotlari)
var is_gliding: bool = false
var _battle_cry_cooldown: float = 0.0
var _battle_cry_buff_timer: float = 0.0
const BATTLE_CRY_COOLDOWN := 10.0
const BATTLE_CRY_COST := 25.0

var _helmet: Node3D
var _cape_pivot: Node3D
var _shield: Node3D
var _pauldrons: Node3D
var _simurgh_wings: Node3D

# 3-Bosqich: Resurslar va Hunarmandchilik
var iron_ore: int = 0
var wood: int = 0
var herbs: int = 0
var torch_active: bool = false
var torch_node: OmniLight3D = null

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
var _special_cooldown_timer := 0.0
var _special_windup_timer := 0.0
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

	# Pog'onalar, tosh yo'laklar va qiyaliklardan sakramasdan silliq oshib o'tish
	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(55.0)
	floor_stop_on_slope = false
	max_slides = 6

	_build_bow_visuals()
	_build_hero_visuals()


func _physics_process(delta: float) -> void:
	if _hit_invuln > 0.0:
		_hit_invuln -= delta
		model.visible = int(_hit_invuln * 20.0) % 2 == 0 or _hit_invuln <= 0.0

	_update_bow_visuals()
	_update_hero_visuals(delta)

	# Cheksizlikka qulashdan qat'iy himoya (Void Fall Protection - otda bo'lsa ham ishlaydi)
	if global_position.y < -3.0 and state != State.DEAD:
		global_position = _spawn + Vector3.UP * 0.5
		velocity = Vector3.ZERO
		if is_mounted and mounted_horse != null and is_instance_valid(mounted_horse):
			mounted_horse.global_position = _spawn + Vector3.UP * 0.5
			mounted_horse.velocity = Vector3.ZERO

	if is_mounted:
		# Ot ustida: harakatni ot bajaradi, o'yinchi yuzlanish, kamon VA ot ustida qilich zarbasini bera oladi!
		velocity = Vector3.ZERO
		_face(_cam_forward(), delta)
		aiming = Input.is_action_pressed("aim")
		rig.aiming = aiming
		if aiming:
			_bow(delta)
		else:
			_cancel_bow()
			if state == State.ATTACK:
				_attack_tick(delta)
			elif Input.is_action_just_pressed("attack_light"):
				_start_attack(false, 0)
			elif Input.is_action_just_pressed("attack_heavy"):
				_start_attack(true, 0)
		_regen(delta)
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
		State.SPECIAL:
			_special_tick(delta)
		State.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0
			velocity.y -= gravity * delta

	# Pog'ona va notekis tosh yo'laklardan sakramasdan chiqish (Step-up assist)
	_apply_step_up(delta)

	move_and_slide()
	_regen(delta)

	# Cheksizlikka qulashdan himoya (Void Fall Protection):
	# Agar o'yinchi kutilmaganda xaritadan pastga qulab ketsa (Y < -15.0), uni xavfsiz oxirgi joyga qaytaramiz
	if global_position.y < -3.0 and state != State.DEAD:
		global_position = _spawn + Vector3.UP * 0.5
		velocity = Vector3.ZERO


## Pog'onalar, tosh yo'laklar va qiyaliklardan sakramasdan silliq oshib o'tish (Step-up assist)
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
		if wall_norm.y < 0.5: # Tik devor yoki pog'ona yuzi
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
		is_gliding = false
		if Input.is_action_just_pressed("jump") and not aiming:
			velocity.y = jump_velocity
			Audio.play_jump()
	else:
		# Simurg' Qanotlari (Gliding): Havoda jump bosib turilsa sekin sho'ng'iydi
		if Input.is_action_pressed("jump") and velocity.y < 0.5:
			is_gliding = true
			velocity.y = maxf(velocity.y - (gravity * 0.25) * delta, -2.0)
			var glide_vel := dir * (sprint_speed * 1.05)
			velocity.x = move_toward(velocity.x, glide_vel.x, ground_accel * delta)
			velocity.z = move_toward(velocity.z, glide_vel.z, ground_accel * delta)
		else:
			is_gliding = false
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

	_special_cooldown_timer = maxf(_special_cooldown_timer - delta, 0.0)

	# 13-bosqich: Maxsus qobiliyat - Alp Gumburi [ C ]
	if Input.is_action_just_pressed("skill_special") and not aiming and is_on_floor() \
			and stamina >= SPECIAL_STAMINA_COST and _special_cooldown_timer <= 0.0:
		_start_special_earthquake()
		return

	# 5-bosqich: Afsonaviy Jangovar Hayqiriq [ V ] (Bo'ron Hayqirig'i)
	if Input.is_action_just_pressed("battle_cry") and not aiming and is_on_floor() \
			and stamina >= BATTLE_CRY_COST and _battle_cry_cooldown <= 0.0:
		_execute_battle_cry()
		return

	if aiming:
		# Merganlik fokusi (Slo-mo focus)
		if stamina > 6.0 and not FX._stopping:
			Engine.time_scale = 0.4
			_use_stamina(6.0 * delta)
		_bow(delta)
	else:
		if Engine.time_scale != 1.0 and not FX._stopping:
			Engine.time_scale = 1.0
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

	# O'q krossxayr nuri (kamera markazi) chizig'i bo'ylab to'g'ridan-to'g'ri chiqadi (aynan krossxayrga uradi)
	var spawn := global_position + Vector3.UP * 1.4 + ray_dir * 1.1

	var arrow := Arrow.new()
	arrow.shooter = self
	if is_mounted and mounted_horse and is_instance_valid(mounted_horse):
		arrow.extra_exclude = [mounted_horse.get_rid()]

	var base_dmg := lerpf(18.0, 48.0, charge) * GameSettings.get_mult("player_dmg")
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.get("unlocked_skills") and prog.unlocked_skills.get("bow_mastery", false):
		base_dmg *= 1.4

	# 2-Bosqich: Maxsus o'qlar sarfi va kuchi
	if fire_arrows_count > 0:
		fire_arrows_count -= 1
		base_dmg += 18.0
		FX.sparks(spawn, ray_dir, Color(1.0, 0.45, 0.1), 12)
	elif piercing_arrows_count > 0:
		piercing_arrows_count -= 1
		base_dmg *= 1.4
		FX.sparks(spawn, ray_dir, Color(0.9, 0.9, 1.0), 12)

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


# ---------------------------------------------------------------- Qahramon ko'rinishi va mahoratlari

func _build_hero_visuals() -> void:
	# 1. Dubulg'a (Turkiy jangchi konussimon po'lat dubulg'asi)
	_helmet = Node3D.new()
	_helmet.name = "AlpomishHelmet"
	_helmet.position = Vector3(0, 1.80, 0)
	model.add_child(_helmet)

	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.24, 0.27, 0.32)
	steel_mat.metallic = 0.9
	steel_mat.roughness = 0.25

	var gold_trim_mat := StandardMaterial3D.new()
	gold_trim_mat.albedo_color = Color(0.88, 0.72, 0.22)
	gold_trim_mat.metallic = 0.92
	gold_trim_mat.roughness = 0.3

	var plume_mat := StandardMaterial3D.new()
	plume_mat.albedo_color = Color(0.85, 0.12, 0.18)
	plume_mat.roughness = 0.8

	# Konussimon gumbaz
	var dome := MeshInstance3D.new()
	var dome_cyl := CylinderMesh.new()
	dome_cyl.top_radius = 0.02
	dome_cyl.bottom_radius = 0.37
	dome_cyl.height = 0.38
	dome.mesh = dome_cyl
	dome.material_override = steel_mat
	dome.position = Vector3(0, 0.05, 0)
	_helmet.add_child(dome)

	# Peshona tilla halqasi
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.385
	ring.mesh = torus
	ring.material_override = gold_trim_mat
	ring.position = Vector3(0, -0.12, 0)
	_helmet.add_child(ring)

	# Dubulg'a uchi nayzasi va qizil popuk (sarvigul/tug')
	var spike := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.005
	scyl.bottom_radius = 0.02
	scyl.height = 0.18
	spike.mesh = scyl
	spike.material_override = gold_trim_mat
	spike.position = Vector3(0, 0.28, 0)
	_helmet.add_child(spike)

	var plume := MeshInstance3D.new()
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.08
	pmesh.height = 0.24
	plume.mesh = pmesh
	plume.material_override = plume_mat
	plume.position = Vector3(0, 0.36, -0.05)
	_helmet.add_child(plume)

	# Burunlik (Nose guard)
	var nose_guard := MeshInstance3D.new()
	var ng_box := BoxMesh.new()
	ng_box.size = Vector3(0.04, 0.22, 0.08)
	nose_guard.mesh = ng_box
	nose_guard.material_override = steel_mat
	nose_guard.position = Vector3(0, -0.12, -0.38)
	_helmet.add_child(nose_guard)

	# 2. Yelkadoshlar (Pauldrons)
	_pauldrons = Node3D.new()
	_pauldrons.name = "AlpomishPauldrons"
	model.add_child(_pauldrons)

	for side in [-1.0, 1.0]:
		var pauldron := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.24, 0.14, 0.36)
		pauldron.mesh = pbox
		pauldron.material_override = steel_mat
		pauldron.position = Vector3(side * 0.44, 1.54, 0.0)
		pauldron.rotation_degrees.z = side * 18.0
		_pauldrons.add_child(pauldron)

	# 3. Yopinchiq (Flowing Crimson Cape)
	_cape_pivot = Node3D.new()
	_cape_pivot.name = "AlpomishCapePivot"
	_cape_pivot.position = Vector3(0, 1.48, 0.32)
	model.add_child(_cape_pivot)

	var cape_mesh_inst := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(0.74, 1.25, 0.03)
	cape_mesh_inst.mesh = cbox
	var cape_mat := StandardMaterial3D.new()
	cape_mat.albedo_color = Color(0.72, 0.12, 0.18)
	cape_mat.roughness = 0.85
	cape_mesh_inst.material_override = cape_mat
	cape_mesh_inst.position = Vector3(0, -0.6, 0)
	_cape_pivot.add_child(cape_mesh_inst)

	# 4. Sayyor Qalqon (Nomad Round Shield - Chap qo'lda)
	_shield = Node3D.new()
	_shield.name = "AlpomishShield"
	_shield.position = Vector3(-0.44, 1.1, -0.05)
	_shield.rotation_degrees.y = 80.0
	model.add_child(_shield)

	var shield_body := MeshInstance3D.new()
	var scyl_mesh := CylinderMesh.new()
	scyl_mesh.top_radius = 0.36
	scyl_mesh.bottom_radius = 0.36
	scyl_mesh.height = 0.05
	shield_body.mesh = scyl_mesh
	var shield_mat := StandardMaterial3D.new()
	shield_mat.albedo_color = Color(0.26, 0.18, 0.12)
	shield_body.material_override = shield_mat
	shield_body.rotation_degrees.x = 90.0
	_shield.add_child(shield_body)

	var shield_rim := MeshInstance3D.new()
	var s_torus := TorusMesh.new()
	s_torus.inner_radius = 0.34
	s_torus.outer_radius = 0.375
	shield_rim.mesh = s_torus
	shield_rim.material_override = gold_trim_mat
	shield_rim.rotation_degrees.x = 90.0
	_shield.add_child(shield_rim)

	var umbo := MeshInstance3D.new()
	var umbo_mesh := SphereMesh.new()
	umbo_mesh.radius = 0.11
	umbo_mesh.height = 0.12
	umbo.mesh = umbo_mesh
	umbo.material_override = gold_trim_mat
	umbo.position = Vector3(0, 0, -0.04)
	_shield.add_child(umbo)

	# 5. Afsonaviy Simurg' Qanotlari (Parvoz vaqtida nurlanadi)
	_simurgh_wings = Node3D.new()
	_simurgh_wings.name = "SimurghWings"
	_simurgh_wings.position = Vector3(0, 1.45, 0.30)
	model.add_child(_simurgh_wings)

	var wing_mat := StandardMaterial3D.new()
	wing_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wing_mat.albedo_color = Color(1.0, 0.75, 0.18, 0.82)

	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var pmesh_w := BoxMesh.new()
		pmesh_w.size = Vector3(1.3, 0.38, 0.04)
		wing.mesh = pmesh_w
		wing.material_override = wing_mat
		wing.position = Vector3(side * 0.75, 0.32, 0.0)
		wing.rotation_degrees = Vector3(0.0, side * 22.0, side * 32.0)
		_simurgh_wings.add_child(wing)

	_simurgh_wings.visible = false


func _update_hero_visuals(delta: float) -> void:
	# Yopinchiq tebranishi (Cape dynamic flutter & wind)
	if _cape_pivot:
		var horiz_vel := Vector2(velocity.x, velocity.z).length()
		var flutter := sin(Time.get_ticks_msec() * 0.012) * 0.05
		var target_rot_x := -clampf(horiz_vel * 0.055, 0.0, 0.72) + flutter
		if is_gliding:
			target_rot_x = -0.55 + flutter
		_cape_pivot.rotation.x = lerpf(_cape_pivot.rotation.x, target_rot_x, 10.0 * delta)

	# Qalqon holati (Shield active block position)
	if _shield:
		var target_rot_y := deg_to_rad(15.0) if is_blocking else deg_to_rad(80.0)
		var target_pos := Vector3(-0.25, 1.15, -0.45) if is_blocking else Vector3(-0.44, 1.1, -0.05)
		_shield.rotation.y = lerp_angle(_shield.rotation.y, target_rot_y, 14.0 * delta)
		_shield.position = _shield.position.lerp(target_pos, 14.0 * delta)

	# Simurg' qanotlari parvozi va nurlanishi
	if _simurgh_wings:
		_simurgh_wings.visible = is_gliding
		if is_gliding:
			var flap := sin(Time.get_ticks_msec() * 0.015) * 0.18
			_simurgh_wings.scale = Vector3(1.0 + flap * 0.5, 1.0 + flap, 1.0)
			if randf() < 0.2:
				FX.sparks(global_position + Vector3(0, 1.2, 0.3), Vector3.UP, Color(1.0, 0.8, 0.2), 3)

	# Bo'ron Hayqirig'i cooldown va buff vaqtlari
	if _battle_cry_cooldown > 0.0:
		_battle_cry_cooldown = maxf(_battle_cry_cooldown - delta, 0.0)
	if _battle_cry_buff_timer > 0.0:
		_battle_cry_buff_timer = maxf(_battle_cry_buff_timer - delta, 0.0)
		if randf() < 0.15:
			FX.sparks(global_position + Vector3(randf_range(-0.4, 0.4), 1.0, randf_range(-0.4, 0.4)), Vector3.UP, Color(1.0, 0.7, 0.1), 2)


func _execute_battle_cry() -> void:
	if _battle_cry_cooldown > 0.0 or stamina < BATTLE_CRY_COST:
		return
	_use_stamina(BATTLE_CRY_COST)
	_battle_cry_cooldown = BATTLE_CRY_COOLDOWN
	_battle_cry_buff_timer = 10.0

	Audio.play_boss_slam()
	rig.shake(0.35)
	FX.hit_stop(0.06)
	FX.shockwave_ring(global_position + Vector3.UP * 0.15, 9.5, Color(1.0, 0.75, 0.15, 0.9), 0.5)
	FX.sparks(global_position + Vector3.UP * 1.2, Vector3.UP, Color(1.0, 0.85, 0.3), 32)
	FX.popup(global_position + Vector3.UP * 2.3, 0.0, Color(1.0, 0.85, 0.2))

	for e in get_tree().get_nodes_in_group("hurtable"):
		if e != self and is_instance_valid(e) and e.has_method("take_damage"):
			var dist := global_position.distance_to(e.global_position)
			if dist <= 9.5:
				e.take_damage(28.0 * GameSettings.get_mult("player_dmg"), global_position, 10.0)
				if e.has_method("get_parried"):
					e.get_parried(global_position)


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
	if _attack.is_empty():
		_end_attack()
		return
	_attack_time += delta
	_buffer_light = maxf(_buffer_light - delta, 0.0)
	_buffer_heavy = maxf(_buffer_heavy - delta, 0.0)
	if Input.is_action_just_pressed("attack_light"):
		_buffer_light = 0.4
	if Input.is_action_just_pressed("attack_heavy"):
		_buffer_heavy = 0.4

	var windup: float = _attack.get("windup", 0.15)
	var active: float = _attack.get("active", 0.15)
	var recover: float = _attack.get("recover", 0.25)
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
	var lunge: float = _attack.get("lunge", 0.0)
	if _attack_time >= windup and _attack_time < strike_end:
		if not is_mounted:
			velocity.x = _attack_dir.x * lunge
			velocity.z = _attack_dir.z * lunge
		_check_hits()
	else:
		if not is_mounted:
			velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
	velocity.y -= gravity * delta

	_update_swing(windup, active, recover, delta)

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
	var dmg: float = (_attack.damage + sword_damage_bonus) * GameSettings.get_mult("player_dmg")
	if _battle_cry_buff_timer > 0.0:
		dmg *= 1.4  # Alp G'ayrati buffi: +40% kuch
	if is_mounted and mounted_horse and mounted_horse.get("galloping"):
		dmg *= 1.3  # Ot shiddatli chopganda qilich kuchi +30%
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.get("unlocked_skills") and prog.unlocked_skills.get("sword_mastery", false):
		dmg *= 1.35

	# Ot ustida hitbox balandroq bo'lishi mumkinligi uchun, agar hitbox orqali topilmasa
	# atrofidagi dushmanlarni (2.5m radiusda) ham qamrab olamiz:
	var targets: Array = hitbox.get_overlapping_bodies()
	if is_mounted:
		for hurtable in get_tree().get_nodes_in_group("hurtable"):
			if hurtable != self and not hurtable in targets:
				var d: float = global_position.distance_to(hurtable.global_position)
				if d < 3.2:
					targets.append(hurtable)

	for b in targets:
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


func _update_swing(windup: float, active: float, recover: float, delta: float = 0.016) -> void:
	var poses := [
		[Vector3(0, 80, 0), Vector3(0, -80, 0)],
		[Vector3(0, -80, 0), Vector3(0, 80, 0)],
		[Vector3(110, 0, 0), Vector3(-40, 0, 0)],
	]
	var swing_idx: int = clampi(int(_attack.get("swing", 0)), 0, poses.size() - 1)
	var pose: Array = poses[swing_idx]
	var start: Vector3 = pose[0]
	var end: Vector3 = pose[1]

	# Zarbani kesuvchi nur effekti (Slash Arc VFX)
	if _attack_time >= windup and (_attack_time - delta) < windup:
		var slash_pos := global_position + Vector3(0, 1.15, 0) - model.global_basis.z * 0.95
		var slash_rot := model.rotation
		if swing_idx == 2:
			slash_rot.x = deg_to_rad(65.0)
		FX.slash_arc(slash_pos, slash_rot, Color(0.9, 0.95, 1.0, 0.85) if not _attack_heavy else Color(1.0, 0.65, 0.2, 0.95), 1.45 if _attack_heavy else 1.15)

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
		# Mukammal parry: zarar yo'q, dushman larzaga tushadi va ko'k chaqnash
		FX.hit_stop(0.12)
		FX.parry_burst(spark_pos)
		FX.popup(global_position + Vector3.UP * 2.3, 0.0, Color(0.4, 0.9, 1.0))
		Audio.play_heavy_hit()
		rig.shake(0.25)
		stamina = minf(stamina + 20.0, max_stamina)
		stamina_changed.emit(stamina, max_stamina)
		_stagger_attacker(from_pos)
		return 0.0
	var cost := amount * BLOCK_STAMINA_MULT
	FX.hit_stop(0.05)
	FX.sparks(spark_pos, Vector3.UP, Color(1.0, 0.9, 0.6), 10)
	FX.shockwave_ring(spark_pos, 1.6, Color(1.0, 0.85, 0.4, 0.6), 0.2)
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
	if damage_reduction > 0.0:
		amount *= (1.0 - damage_reduction)
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
	if is_mounted:
		_hit_invuln = hurt_iframes
		return
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


func respawn() -> void:
	if is_mounted and mounted_horse != null:
		mounted_horse.dismount()
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
	if state == State.DEAD:
		respawn()


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
	if qimiz_buff_timer > 0.0:
		return
	stamina = maxf(stamina - amount, 0.0)
	_regen_timer = regen_delay
	stamina_changed.emit(stamina, max_stamina)


func _regen(delta: float) -> void:
	if qimiz_buff_timer > 0.0:
		qimiz_buff_timer -= delta
		stamina = max_stamina
		stamina_changed.emit(stamina, max_stamina)
		return
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	if stamina < max_stamina:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)
		stamina_changed.emit(stamina, max_stamina)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold, amount)
	Audio.play_coin()


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold, -amount)
		return true
	return false


func upgrade_sword() -> void:
	is_steel_sword_equipped = true
	sword_damage_bonus = 25.0
	_upgrade_sword_visuals()


func upgrade_armor() -> void:
	is_plate_armor_equipped = true
	damage_reduction = 0.30
	_upgrade_armor_visuals()


func apply_qimiz_buff(duration := 35.0) -> void:
	stamina = max_stamina
	qimiz_buff_timer = duration
	stamina_changed.emit(stamina, max_stamina)
	Audio.play_level_up()
	FX.popup(global_position + Vector3.UP * 2.2, 0.0, Color(0.3, 0.9, 1.0))


func heal_hp(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)
	FX.popup(global_position + Vector3.UP * 2.2, amount, Color(0.2, 1.0, 0.4))


func _upgrade_sword_visuals() -> void:
	if weapon:
		for child in weapon.get_children():
			if child is MeshInstance3D:
				var m := StandardMaterial3D.new()
				m.albedo_color = Color(0.9, 0.95, 1.0)
				m.metallic = 0.95
				m.roughness = 0.15
				m.emission_enabled = true
				m.emission = Color(0.4, 0.7, 1.0)
				m.emission_energy_multiplier = 0.35
				child.material_override = m
	FX.sparks(global_position + Vector3.UP * 1.2, Vector3.UP, Color(0.5, 0.85, 1.0), 16)


func _upgrade_armor_visuals() -> void:
	var armor_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.42
	cyl.bottom_radius = 0.38
	cyl.height = 0.75
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.72, 0.75, 0.82)
	amat.metallic = 0.92
	amat.roughness = 0.25
	armor_mesh.mesh = cyl
	armor_mesh.material_override = amat
	armor_mesh.position = Vector3(0, 1.15, 0)
	model.add_child(armor_mesh)
	FX.sparks(global_position + Vector3.UP * 1.0, Vector3.UP, Color(0.9, 0.8, 0.3), 16)


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


# ---------------------------------------------------------------- Maxsus mahorat (Alp Gumburi)

func _start_special_earthquake() -> void:
	state = State.SPECIAL
	_special_windup_timer = 0.35
	_special_cooldown_timer = SPECIAL_COOLDOWN
	_use_stamina(SPECIAL_STAMINA_COST)
	velocity.y = 5.0 # Havoga sakraydi
	Audio.play_jump()


func _special_tick(delta: float) -> void:
	_special_windup_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)
	velocity.y -= gravity * delta

	# Sakrab yerga tushganda yoki windup tugaganda portlash
	if _special_windup_timer <= 0.0:
		_execute_earthquake()
		state = State.NORMAL


func _execute_earthquake() -> void:
	velocity = Vector3.ZERO
	Audio.play_boss_slam()
	FX.camera_shake(0.45)
	FX.hit_stop(0.08)
	FX.dust(global_position, 16, 1.4)
	FX.impact_burst(global_position + Vector3.UP * 0.2, Color(1.0, 0.8, 0.2), 24)

	var quake := AlpEarthquake.new()
	var dmg := 45.0 * GameSettings.get_mult("player_dmg")
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.get("unlocked_skills") and prog.unlocked_skills.get("alp_earthquake", false):
		dmg *= 1.5 # Agar ko'nikma ochilgan bo'lsa +50% zarar va kengroq to'lqin
		quake.max_radius = 12.0
	quake.damage = dmg
	quake.global_position = global_position
	get_tree().current_scene.add_child(quake)


# ---------------------------------------------------------------- Resurslar va Hunarmandchilik

func add_resource(res_type: String, amount: int) -> void:
	match res_type:
		"iron_ore":
			iron_ore += amount
		"wood":
			wood += amount
		"herbs":
			herbs += amount
	resources_changed.emit(iron_ore, wood, herbs)


func spend_resource(res_type: String, amount: int) -> bool:
	match res_type:
		"iron_ore":
			if iron_ore >= amount:
				iron_ore -= amount
				resources_changed.emit(iron_ore, wood, herbs)
				return true
		"wood":
			if wood >= amount:
				wood -= amount
				resources_changed.emit(iron_ore, wood, herbs)
				return true
		"herbs":
			if herbs >= amount:
				herbs -= amount
				resources_changed.emit(iron_ore, wood, herbs)
				return true
	return false


func has_resources(recipe: Dictionary) -> bool:
	var req_iron: int = int(recipe.get("iron_ore", 0))
	var req_wood: int = int(recipe.get("wood", 0))
	var req_herbs: int = int(recipe.get("herbs", 0))
	var req_gold: int = int(recipe.get("gold", 0))
	return iron_ore >= req_iron and wood >= req_wood and herbs >= req_herbs and gold >= req_gold


func consume_resources(recipe: Dictionary) -> bool:
	if not has_resources(recipe):
		return false
	var req_iron: int = int(recipe.get("iron_ore", 0))
	var req_wood: int = int(recipe.get("wood", 0))
	var req_herbs: int = int(recipe.get("herbs", 0))
	var req_gold: int = int(recipe.get("gold", 0))

	iron_ore -= req_iron
	wood -= req_wood
	herbs -= req_herbs
	if req_gold > 0:
		spend_gold(req_gold)
	resources_changed.emit(iron_ore, wood, herbs)
	return true


func enable_torch(enable: bool) -> void:
	torch_active = enable
	if enable:
		if torch_node == null or not is_instance_valid(torch_node):
			torch_node = OmniLight3D.new()
			torch_node.light_color = Color(1.0, 0.65, 0.25) # Olov nuri
			torch_node.light_energy = 2.4
			torch_node.omni_range = 16.0
			torch_node.position = Vector3(0.4, 1.4, 0.3)
			add_child(torch_node)
		else:
			torch_node.visible = true
		FX.sparks(global_position + Vector3.UP * 1.5, Vector3.UP, Color(1.0, 0.5, 0.1), 12)
	else:
		if torch_node and is_instance_valid(torch_node):
			torch_node.visible = false

