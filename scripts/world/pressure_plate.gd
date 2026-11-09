class_name PressurePlate
extends Area3D
## 8-bosqich: Qadimiy zindon tosh bosim plitasi (Pressure Plate).
## O'yinchi unga qadam bosganda pastga siljiydi, qulflarni ochadi yoki tuzoqlarni faollashtiradi.

signal plate_activated(plate_id: String)
signal plate_deactivated(plate_id: String)

@export var plate_id := "plate_1"
@export var is_one_shot := false

var is_pressed := false
var _plate_mesh: MeshInstance3D
var _plate_mat: StandardMaterial3D
var _rest_y := 0.08
var _pressed_y := 0.02


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1 # Faqat o'yinchi
	add_to_group("pressure_plates")

	# Tashqi tosh hoshiya (Oltin-bronza naqshli qadimiy plita ramkasi)
	var frame_mi := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(1.8, 0.08, 1.8)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.28, 0.25, 0.22)
	fbox.material = fmat
	frame_mi.mesh = fbox
	frame_mi.position.y = 0.04
	add_child(frame_mi)

	# Harakatlanuvchi markaziy tosh plita (Bosiladigan qism)
	_plate_mesh = MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(1.4, 0.08, 1.4)
	_plate_mat = StandardMaterial3D.new()
	_plate_mat.albedo_color = Color(0.65, 0.45, 0.2) # Runa naqshli oltin tusli tosh
	_plate_mat.roughness = 0.6
	_plate_mat.emission_enabled = true
	_plate_mat.emission = Color(0.4, 0.25, 0.05)
	_plate_mat.emission_energy_multiplier = 0.5
	_plate_mesh.mesh = pbox
	_plate_mesh.material_override = _plate_mat
	_plate_mesh.position.y = _rest_y
	add_child(_plate_mesh)

	# Collision
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 0.3, 1.5)
	col.shape = shape
	col.position.y = 0.15
	add_child(col)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(_body: Node3D) -> void:
	if is_pressed and is_one_shot:
		return
	is_pressed = true
	if _plate_mesh:
		_plate_mesh.position.y = _pressed_y
	if _plate_mat:
		_plate_mat.emission = Color(0.1, 0.8, 0.3)
		_plate_mat.emission_energy_multiplier = 1.5

	Audio.play_hit()
	FX.impact_burst(global_position + Vector3.UP * 0.1, Color(0.2, 0.9, 0.4), 12)
	plate_activated.emit(plate_id)


func _on_body_exited(_body: Node3D) -> void:
	if is_one_shot:
		return
	var overlapping := get_overlapping_bodies()
	if overlapping.is_empty():
		is_pressed = false
		if _plate_mesh:
			_plate_mesh.position.y = _rest_y
		if _plate_mat:
			_plate_mat.emission = Color(0.4, 0.25, 0.05)
			_plate_mat.emission_energy_multiplier = 0.5
		plate_deactivated.emit(plate_id)
