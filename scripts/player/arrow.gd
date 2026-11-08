class_name Arrow
extends Node3D
## O'q: har kadrda nur (raycast) bilan to'qnashuvni tekshiradi, shuning uchun tez uchsa ham devordan o'tmaydi.

var velocity := Vector3.ZERO
var damage := 20.0
var shooter: CollisionObject3D
var extra_exclude: Array[RID] = []
var gravity := 7.0
var hit_mask := 1 | (1 << 2)  # dunyo + dushman; dushman o'qlari uchun dunyo + o'yinchi

var _life := 6.0
var _stuck := false


func _ready() -> void:
	# O'q sopi (Yog'och)
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.012
	mesh.bottom_radius = 0.012
	mesh.height = 0.95
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.45, 0.25)
	mesh.material = mat
	mesh_inst.mesh = mesh
	mesh_inst.rotation_degrees.x = 90.0
	add_child(mesh_inst)

	# Temir paykon (Uch)
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.001
	cone.bottom_radius = 0.025
	cone.height = 0.14
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.2, 0.22, 0.25)
	tmat.metallic = 0.9
	tip.mesh = cone
	tip.material_override = tmat
	tip.position.z = -0.52
	tip.rotation_degrees.x = -90.0
	add_child(tip)

	# Patlar (Feather)
	var feather := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(0.005, 0.08, 0.15)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.9, 0.2, 0.2) # Qizil burgut pati
	feather.mesh = fbox
	feather.material_override = fmat
	feather.position.z = 0.4
	add_child(feather)


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
	var excludes: Array[RID] = []
	if shooter:
		excludes.append(shooter.get_rid())
	excludes.append_array(extra_exclude)
	query.exclude = excludes
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
