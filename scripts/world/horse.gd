class_name Horse
extends CharacterBody3D
## Boychibor - Alpamishning afsonaviy tulpori.
## Xususiyatlari:
## - O'tlab turish (Idle)
## - Hushtak chalinganda (H) o'yinchi yoniga yugurib kelish (Whistle Call)
## - Minish (F): tezkor yugurish (16 m/s galop), baland sakrash va ot ustida kamon otish.

signal mounted_state_changed(is_mounted: bool)

@export var walk_speed := 7.5
@export var gallop_speed := 16.0
@export var jump_velocity := 8.5
@export var turn_speed := 8.0
@export var gravity := 20.0

var is_mounted := false
var rider: CharacterBody3D = null
var is_called := false

var _follow_target: Node3D = null
var _saddle: Node3D
var _prompt_label: Label3D
var _body_mesh: Node3D
var _legs: Array[Node3D] = []
var _anim_time := 0.0
var _mount_cooldown := 0.0
var _trample_cooldown := 0.0
var _gallop_dust_timer := 0.0
var _spawn_pos := Vector3(6.0, 0.5, 4.0)


func _ready() -> void:
	_spawn_pos = global_position
	add_to_group("horses")
	collision_layer = 1 # Dunyo bilan to'qnashadi
	collision_mask = 1

	# Pog'onalar, tosh yo'laklar va qiyaliklardan erkin oshib o'tish (Step & Slope handling)
	floor_snap_length = 0.55
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_stop_on_slope = false
	max_slides = 6

	_build_visuals()


func _build_visuals() -> void:
	_body_mesh = Node3D.new()
	add_child(_body_mesh)

	var horse_mat := StandardMaterial3D.new()
	horse_mat.albedo_color = Color(0.48, 0.24, 0.12) # To'riq / to'q jigar
	horse_mat.roughness = 0.7

	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.12, 0.1, 0.08) # Yol va oyoq uchlari

	var saddle_mat := StandardMaterial3D.new()
	saddle_mat.albedo_color = Color(0.7, 0.15, 0.15) # Qizil baxmal egar

	# 1. Tana (Torso)
	var torso := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.9, 2.2)
	torso.mesh = box
	torso.material_override = horse_mat
	torso.position = Vector3(0, 1.4, 0)
	_body_mesh.add_child(torso)

	# 2. Bo'yin va Bosh
	var neck := MeshInstance3D.new()
	var neck_box := BoxMesh.new()
	neck_box.size = Vector3(0.45, 0.9, 0.6)
	neck.mesh = neck_box
	neck.material_override = horse_mat
	neck.position = Vector3(0, 2.0, -1.0)
	neck.rotation_degrees.x = -25.0
	_body_mesh.add_child(neck)

	var head := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.4, 0.45, 0.8)
	head.mesh = head_box
	head.material_override = horse_mat
	head.position = Vector3(0, 2.3, -1.4)
	_body_mesh.add_child(head)

	# 3. Egar (Saddle)
	_saddle = Node3D.new()
	_saddle.position = Vector3(0, 1.95, -0.1)
	add_child(_saddle)

	var saddle_mesh := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(0.7, 0.2, 0.7)
	saddle_mesh.mesh = sbox
	saddle_mesh.material_override = saddle_mat
	_saddle.add_child(saddle_mesh)

	# 4. Oyoqlar (4 ta ustun)
	var leg_positions := [
		Vector3(-0.35, 0.65, -0.7), # Old chap
		Vector3(0.35, 0.65, -0.7),  # Old o'ng
		Vector3(-0.35, 0.65, 0.7),  # Orqa chap
		Vector3(0.35, 0.65, 0.7),   # Orqa o'ng
	]
	for pos in leg_positions:
		var leg_pivot := Node3D.new()
		leg_pivot.position = pos + Vector3(0, 0.5, 0)
		_body_mesh.add_child(leg_pivot)

		var leg_mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.09
		cyl.height = 1.1
		leg_mi.mesh = cyl
		leg_mi.material_override = horse_mat
		leg_mi.position.y = -0.5
		leg_pivot.add_child(leg_mi)
		_legs.append(leg_pivot)

	# 5. Dum
	var tail := MeshInstance3D.new()
	var tail_cyl := CylinderMesh.new()
	tail_cyl.top_radius = 0.08
	tail_cyl.bottom_radius = 0.03
	tail_cyl.height = 1.0
	tail.mesh = tail_cyl
	tail.material_override = dark_mat
	tail.position = Vector3(0, 1.4, 1.2)
	tail.rotation_degrees.x = 20.0
	_body_mesh.add_child(tail)

	# Kolliziya
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	# Oyoqlarning pastki qismida 0.35m bo'shliq qoldiriladi - bu yo'laklar, tosh pog'onalar va rampalarga tiqilib qolishni 100% yo'qotadi
	cbox.size = Vector3(1.0, 1.6, 2.2)
	col.shape = cbox
	col.position.y = 1.15
	add_child(col)

	# Interaction Label
	_prompt_label = Label3D.new()
	_prompt_label.text = "BOYCHIBOR\n[ F ] - Minish"
	_prompt_label.font_size = 40
	_prompt_label.position = Vector3(0, 2.8, 0)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.modulate = Color(1.0, 0.9, 0.4)
	add_child(_prompt_label)


func _physics_process(delta: float) -> void:
	if _mount_cooldown > 0.0:
		_mount_cooldown -= delta

	if is_mounted and rider != null:
		_process_mounted(delta)
	elif is_called and _follow_target != null:
		_process_calling(delta)
	else:
		_process_idle(delta)

	# Pog'onalar va tosh yo'laklardan sakramasdan silliq oshib o'tish (Step-up assist)
	_apply_step_up(delta)

	move_and_slide()
	_animate_legs(delta)

	# Cheksizlikka qulashdan himoya (Void Fall Protection)
	if global_position.y < -3.0:
		global_position = _spawn_pos + Vector3.UP * 0.5
		velocity = Vector3.ZERO
		if is_mounted and rider != null and is_instance_valid(rider):
			rider.global_position = global_position + Vector3.UP * 1.5
			rider.velocity = Vector3.ZERO

	# Chavandozni silkinishsiz aynan egar ustida ushlab turish
	if is_mounted and rider != null:
		rider.global_position = _saddle.global_position
	else:
		_update_prompt()


func _process_mounted(delta: float) -> void:
	_prompt_label.visible = false

	# Tushish (Dismount) - cooldown bilan bir freymda qayta tushib ketishning oldi olinadi
	if _mount_cooldown <= 0.0 and Input.is_action_just_pressed("interact"):
		dismount()
		return

	# Harakat yo'nalishi (kamera burchagiga mos)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_yaw: float = 0.0
	if rider != null:
		var rig_node: Variant = rider.get("rig")
		if rig_node != null and "yaw" in rig_node:
			cam_yaw = float(rig_node.yaw)
	var move_dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, cam_yaw)
	var moving := move_dir.length() > 0.1

	var galloping := moving and Input.is_action_pressed("sprint")
	var current_speed := gallop_speed if galloping else walk_speed

	if moving:
		var target_yaw := atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))
		var fwd := -global_basis.z
		velocity.x = fwd.x * current_speed
		velocity.z = fwd.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)

	# Sakrash: Oddiy sakrash yoki Boychiborning Afsonaviy Pegas Sakrashi (Pegasus Leap)
	if is_on_floor() and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("dodge")):
		if galloping or (rider != null and rider.get("has_golden_horseshoes")):
			velocity.y = 11.5
			FX.impact_burst(global_position, Color(0.3, 0.8, 1.0), 20)
			FX.shockwave_ring(global_position, 4.2, Color(0.3, 0.85, 1.0, 0.8), 0.4)
			Audio.play_boss_slam()
			if rider != null and "rig" in rider and rider.rig:
				rider.rig.shake(0.3)
		else:
			velocity.y = jump_velocity
		apply_floor_snap()

	if not is_on_floor():
		velocity.y -= gravity * delta
		# Agar yerdan uzilsa ham (kichik pog'ona yoki nishablikda) oldinga harakat tezligi o'chmaydi
		if moving:
			var fwd := -global_basis.z
			velocity.x = fwd.x * current_speed
			velocity.z = fwd.z * current_speed

	# Ot chopganda dushmanlarni urib yiqitish (Trample) va chang chiqarish
	if _trample_cooldown > 0.0:
		_trample_cooldown -= delta
	elif galloping:
		_check_trample()

	if galloping and moving and is_on_floor():
		_gallop_dust_timer -= delta
		if _gallop_dust_timer <= 0.0:
			_gallop_dust_timer = 0.16
			FX.dust(global_position - global_basis.z * 0.9, 4, 0.75)
			Audio.play_horse_step()


func _apply_step_up(delta: float, max_step_height := 0.65) -> void:
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


func _check_trample() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e and is_instance_valid(e) and e.has_method("take_damage"):
			if global_position.distance_to(e.global_position) < 2.5:
				e.take_damage(22.0, global_position, 8.0)
				FX.hit_stop(0.04)
				FX.camera_shake(0.35)
				FX.sparks(e.global_position + Vector3(0, 1.0, 0), Vector3.UP, Color(1.0, 0.75, 0.2), 12)
				FX.dust(global_position, 8, 1.1)
				Audio.play_heavy_hit()
				_trample_cooldown = 0.35
				return


func _process_calling(delta: float) -> void:
	var to_target := _follow_target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()

	if dist > 3.0:
		var dir := to_target.normalized()
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))
		var fwd := -global_basis.z
		velocity.x = fwd.x * 12.0
		velocity.z = fwd.z * 12.0
	else:
		is_called = false
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity.y -= gravity * delta


func _process_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta


func _animate_legs(delta: float) -> void:
	var horiz_vel := Vector2(velocity.x, velocity.z).length()
	if horiz_vel > 0.5:
		_anim_time += delta * (horiz_vel * 1.5)
		var s := sin(_anim_time)
		_legs[0].rotation_degrees.x = s * 30.0
		_legs[1].rotation_degrees.x = -s * 30.0
		_legs[2].rotation_degrees.x = -s * 30.0
		_legs[3].rotation_degrees.x = s * 30.0
		_body_mesh.position.y = abs(sin(_anim_time * 2.0)) * 0.08
	else:
		for leg in _legs:
			leg.rotation_degrees.x = lerpf(leg.rotation_degrees.x, 0.0, 10.0 * delta)
		_body_mesh.position.y = move_toward(_body_mesh.position.y, 0.0, delta)


func _update_prompt() -> void:
	if is_mounted:
		return
	var p := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if p == null:
		_prompt_label.visible = false
		return
	var dist := global_position.distance_to(p.global_position)
	_prompt_label.visible = dist < 4.5


func mount(p: CharacterBody3D) -> void:
	if is_mounted or p == null:
		return
	is_mounted = true
	rider = p
	_mount_cooldown = 0.4
	# O'yinchi kolliziyasini vaqtincha to'xtatish (ot tanasi bilan qisilib qolmasligi uchun)
	rider.collision_layer = 0
	rider.collision_mask = 0
	rider.velocity = Vector3.ZERO
	rider.set("is_mounted", true)
	rider.set("mounted_horse", self)
	is_called = false
	_prompt_label.visible = false
	mounted_state_changed.emit(true)
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem and qsystem.has_method("complete_quest"):
		qsystem.complete_quest("boychibor")


func dismount() -> void:
	if not is_mounted or rider == null:
		return
	var drop_pos := global_position + global_basis.x * 1.8
	rider.global_position = drop_pos
	rider.collision_layer = 1 << 1 # layer 2 (player)
	rider.collision_mask = 1 | (1 << 2) # layer 1 (world) + layer 3 (enemy)
	rider.velocity = Vector3.ZERO
	rider.set("is_mounted", false)
	rider.set("mounted_horse", null)
	is_mounted = false
	rider = null
	_mount_cooldown = 0.4
	mounted_state_changed.emit(false)


func call_horse(target: Node3D) -> void:
	if is_mounted:
		return
	_follow_target = target
	is_called = true
