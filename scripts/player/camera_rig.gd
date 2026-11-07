class_name CameraRig
extends Node3D
## Uchinchi shaxs kamerasi: sichqoncha/o'ng stik bilan aylanish, silliq kuzatuv,
## SpringArm bilan devordan o'tmaslik, kamon nishonlash zoomi va zarba titrashi.

@export var mouse_sensitivity := 0.0025
@export var stick_sensitivity := 2.8
@export var follow_speed := 14.0
@export var height := 1.5
@export var min_pitch := deg_to_rad(-60.0)
@export var max_pitch := deg_to_rad(35.0)
@export var normal_distance := 4.5
@export var aim_distance := 2.2
@export var normal_fov := 70.0
@export var aim_fov := 55.0

var yaw := 0.0
var pitch := deg_to_rad(-15.0)
var aiming := false

var _aim_blend := 0.0
var _shake := 0.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	top_level = true
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	spring_arm.shape = sphere
	var body := get_parent() as CollisionObject3D
	if body:
		spring_arm.add_excluded_object(body.get_rid())
		global_position = body.global_position + Vector3.UP * height
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var k := mouse_sensitivity * (0.7 if aiming else 1.0)
		yaw -= event.relative.x * k
		pitch = clampf(pitch - event.relative.y * k, min_pitch, max_pitch)
	elif event is InputEventMouseButton and event.pressed:
		# Sichqoncha bosilganda avtomatik kursor o'yinga bog'lanadi (qotib qolmaslik uchun)
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var body := get_parent() as Node3D
	if body:
		var goal := body.global_position + Vector3.UP * height
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))

	var look := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	var k := stick_sensitivity * (0.6 if aiming else 1.0)
	yaw -= look.x * k * delta
	pitch = clampf(pitch - look.y * k * delta, min_pitch, max_pitch)
	rotation = Vector3(pitch, yaw, 0.0)

	# Nishonlashda kamera yaqinlashadi va yelka ustiga o'tadi
	_aim_blend = move_toward(_aim_blend, 1.0 if aiming else 0.0, delta * 6.0)
	var t := smoothstep(0.0, 1.0, _aim_blend)
	spring_arm.spring_length = lerpf(normal_distance, aim_distance, t)
	camera.fov = lerpf(normal_fov, aim_fov, t)

	var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * 0.15
	camera.h_offset = t * 0.7 + jitter.x
	camera.v_offset = jitter.y
	_shake = move_toward(_shake, 0.0, delta * 1.5)
