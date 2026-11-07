class_name CameraRig
extends Node3D
## Uchinchi shaxs kamerasi: sichqoncha/o'ng stik bilan aylanish, silliq kuzatuv,
## SpringArm bilan devordan o'tmaslik va nishonga qulflash (lock-on).

@export var mouse_sensitivity := 0.0025
@export var stick_sensitivity := 2.8
@export var follow_speed := 14.0
@export var height := 1.5
@export var min_pitch := deg_to_rad(-60.0)
@export var max_pitch := deg_to_rad(35.0)
@export var lock_pitch := deg_to_rad(-18.0)

var yaw := 0.0
var pitch := deg_to_rad(-15.0)
var lock_target: Node3D = null

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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and lock_target == null:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
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

	if lock_target != null and not is_instance_valid(lock_target):
		lock_target = null

	if lock_target != null:
		var to_target := lock_target.global_position - global_position
		var goal_yaw := atan2(-to_target.x, -to_target.z)
		yaw = lerp_angle(yaw, goal_yaw, 1.0 - exp(-8.0 * delta))
		pitch = lerpf(pitch, lock_pitch, 1.0 - exp(-4.0 * delta))
	else:
		var look := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
		yaw -= look.x * stick_sensitivity * delta
		pitch = clampf(pitch - look.y * stick_sensitivity * delta, min_pitch, max_pitch)

	rotation = Vector3(pitch, yaw, 0.0)
