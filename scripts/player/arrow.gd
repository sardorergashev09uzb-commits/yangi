class_name Arrow
extends Node3D
## O'q: har kadrda nur (raycast) bilan to'qnashuvni tekshiradi, shuning uchun tez uchsa ham devordan o'tmaydi.

var velocity := Vector3.ZERO
var damage := 20.0
var shooter: CollisionObject3D
var gravity := 7.0
var hit_mask := 1 | (1 << 2)  # dunyo + dushman; dushman o'qlari uchun dunyo + o'yinchi

var _life := 6.0
var _stuck := false


func _ready() -> void:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.015
	mesh.bottom_radius = 0.015
	mesh.height = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.3, 0.15)
	mesh.material = mat
	mesh_inst.mesh = mesh
	mesh_inst.rotation_degrees.x = 90.0
	add_child(mesh_inst)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _stuck:
		return
	var from := global_position
	velocity.y -= gravity * delta
	var to := from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, hit_mask)
	if shooter:
		query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		if velocity.length() > 0.1:
			look_at(global_position + velocity, Vector3.UP)
		return
	global_position = hit.position
	var collider: Object = hit.collider
	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(damage, from, 3.0)
		FX.hit_stop(0.04)
		queue_free()
	else:
		_stuck = true
		_life = 3.0
