class_name Player
extends CharacterBody3D
## Alpamish: harakat, qochish (i-frame bilan), kuch (stamina) va nishonga qulflash.

signal stamina_changed(current: float, maximum: float)

enum State { NORMAL, DODGE }

@export_group("Harakat")
@export var run_speed := 5.5
@export var sprint_speed := 8.5
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

@export_group("Kuch")
@export var max_stamina := 100.0
@export var sprint_cost_per_sec := 14.0
@export var stamina_regen := 28.0
@export var regen_delay := 0.8

@export_group("Lock-on")
@export var lock_range := 25.0

var state := State.NORMAL
var stamina := 100.0
var invulnerable := false
var lock_target: Node3D = null

var _dodge_dir := Vector3.ZERO
var _dodge_timer := 0.0
var _regen_timer := 0.0

@onready var model: Node3D = $Model
@onready var rig: CameraRig = $CameraRig


func _ready() -> void:
	stamina = max_stamina
	collision_layer = 1 << 1
	collision_mask = 1


func _physics_process(delta: float) -> void:
	_update_lock_on()
	match state:
		State.NORMAL:
			_normal(delta)
		State.DODGE:
			_dodge(delta)
	move_and_slide()
	_regen(delta)


func _normal(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, rig.yaw)
	var moving := dir.length() > 0.1

	var sprinting := moving and Input.is_action_pressed("sprint") and stamina > 1.0 and is_on_floor()
	if sprinting:
		_use_stamina(sprint_cost_per_sec * delta)

	var speed := sprint_speed if sprinting else run_speed
	var accel := ground_accel if is_on_floor() else air_accel
	var target_vel := dir * speed
	velocity.x = move_toward(velocity.x, target_vel.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, accel * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= gravity * delta

	# Yuzlanish: qulflanganda nishonga, aks holda harakat tomoniga
	if lock_target != null and not sprinting:
		var to_t := lock_target.global_position - global_position
		_face(Vector3(to_t.x, 0.0, to_t.z), delta)
	elif moving:
		_face(dir, delta)

	if Input.is_action_just_pressed("dodge") and is_on_floor() and stamina >= dodge_cost:
		_start_dodge(dir if moving else -model.global_basis.z)


func _start_dodge(dir: Vector3) -> void:
	_use_stamina(dodge_cost)
	_dodge_dir = Vector3(dir.x, 0.0, dir.z).normalized()
	_dodge_timer = 0.0
	state = State.DODGE
	invulnerable = true
	_face(_dodge_dir, 1.0 / 60.0, true)


func _dodge(delta: float) -> void:
	_dodge_timer += delta
	var t := clampf(_dodge_timer / dodge_time, 0.0, 1.0)
	var curve := 1.0 - t * t  # tez boshlanadi, sekinlashadi
	velocity.x = _dodge_dir.x * dodge_speed * curve
	velocity.z = _dodge_dir.z * dodge_speed * curve
	velocity.y -= gravity * delta
	invulnerable = _dodge_timer < dodge_iframes
	model.scale.y = lerpf(0.65, 1.0, t)  # vaqtincha vizual signal
	if _dodge_timer >= dodge_time:
		state = State.NORMAL
		invulnerable = false
		model.scale.y = 1.0


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


func _update_lock_on() -> void:
	if lock_target != null:
		if not is_instance_valid(lock_target) \
				or lock_target.global_position.distance_to(global_position) > lock_range * 1.3:
			_set_lock(null)
	if Input.is_action_just_pressed("lock_on"):
		if lock_target != null:
			_set_lock(null)
		else:
			_set_lock(_find_target())


func _find_target() -> Node3D:
	var best: Node3D = null
	var best_score := INF
	var cam_forward := -rig.camera.global_basis.z
	for n in get_tree().get_nodes_in_group("targetable"):
		var node := n as Node3D
		if node == null:
			continue
		var to_n := node.global_position - global_position
		var dist := to_n.length()
		if dist > lock_range:
			continue
		var angle := cam_forward.angle_to(to_n)
		var score := dist + angle * 8.0  # kamera yo'nalishiga yaqinlarni afzal ko'radi
		if score < best_score:
			best_score = score
			best = node
	return best


func _set_lock(target: Node3D) -> void:
	lock_target = target
	rig.lock_target = target
