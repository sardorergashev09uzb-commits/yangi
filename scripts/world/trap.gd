class_name Trap
extends Area3D
## Sinov tuzog'i: ustida turgan o'yinchiga har soniyada zarar beradi (salomatlik/o'lim sinovi).

@export var damage := 15.0
@export var size := Vector3(3, 0.3, 3)

var _cooldown := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.1, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.1, 0.05)
	mat.emission_energy_multiplier = 0.6
	mesh.material = mat
	mesh_inst.mesh = mesh
	add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size + Vector3(0, 1.0, 0)
	col.shape = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	for b in get_overlapping_bodies():
		if b.has_method("take_damage"):
			b.take_damage(damage, global_position, 6.0)
			_cooldown = 1.0
			return
