extends Node
## Umumiy effektlar: hit-stop, sonlar qalqishi, uchqunlar va chang zarralari.

var _stopping := false


func hit_stop(duration: float, slow := 0.05) -> void:
	if _stopping:
		return
	_stopping = true
	Engine.time_scale = slow
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


func reset() -> void:
	_stopping = false
	Engine.time_scale = 1.0


func camera_shake(amount: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and "rig" in player and player.rig and player.rig.has_method("shake"):
		player.rig.shake(amount)


func popup(world_pos: Vector3, amount: float, color := Color(1.0, 0.9, 0.3)) -> void:
	var l := Label3D.new()
	l.text = str(int(amount))
	l.font_size = 72
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	var scene := get_tree().current_scene
	if scene == null:
		l.queue_free()
		return
	scene.add_child(l)
	l.global_position = world_pos + Vector3(randf_range(-0.3, 0.3), 0.0, 0.0)
	var t := l.create_tween()
	t.tween_property(l, "global_position:y", l.global_position.y + 0.9, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)


func sparks(world_pos: Vector3, normal := Vector3.UP, color := Color(1.0, 0.85, 0.25), count := 14) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.4
	p.amount = count

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.04, 0.04, 0.14)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mesh.material = mat
	p.mesh = mesh

	var dir := normal if normal.length_squared() > 0.01 else Vector3.UP
	p.direction = dir
	p.spread = 70.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 8.0
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3

	scene.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	get_tree().create_timer(0.6, false).timeout.connect(p.queue_free)


func dust(world_pos: Vector3, count := 8, p_scale := 1.0, color := Color(0.72, 0.65, 0.52, 0.6)) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 0.6
	p.amount = count

	var mesh := SphereMesh.new()
	mesh.radius = 0.16 * p_scale
	mesh.height = 0.32 * p_scale
	mesh.radial_segments = 6
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.roughness = 1.0
	mesh.material = mat
	p.mesh = mesh

	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 1.2 * p_scale
	p.initial_velocity_max = 2.6 * p_scale
	p.gravity = Vector3(0, 0.3, 0)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.8

	scene.add_child(p)
	p.global_position = world_pos + Vector3(0, 0.1, 0)
	p.emitting = true
	get_tree().create_timer(0.8, false).timeout.connect(p.queue_free)


func impact_burst(world_pos: Vector3, color := Color(1.0, 0.35, 0.1), count := 14) -> void:
	sparks(world_pos, Vector3.UP, color, count)
	dust(world_pos, 6, 0.8, Color(0.4, 0.3, 0.25, 0.5))


## Kengayuvchi shaffof to'lqin halqasi (Shockwave ring)
func shockwave_ring(world_pos: Vector3, radius_max := 3.5, color := Color(1.0, 0.85, 0.4, 0.8), duration := 0.35) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var mesh_inst := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 6
	mesh_inst.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mesh_inst.material_override = mat

	mesh_inst.global_position = world_pos + Vector3(0, 0.08, 0)
	mesh_inst.scale = Vector3(0.2, 0.1, 0.2)
	scene.add_child(mesh_inst)

	var t := mesh_inst.create_tween()
	t.tween_property(mesh_inst, "scale", Vector3(radius_max, 0.1, radius_max), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	t.tween_callback(mesh_inst.queue_free)


## Qilich zarbasi nuri (Crescent slash arc)
func slash_arc(world_pos: Vector3, facing_rot: Vector3, color := Color(0.8, 0.95, 1.0, 0.85), scale_size := 1.2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var mesh_inst := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.7 * scale_size
	torus.outer_radius = 1.15 * scale_size
	torus.rings = 16
	torus.ring_segments = 4
	mesh_inst.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mesh_inst.material_override = mat

	mesh_inst.global_position = world_pos
	mesh_inst.rotation = facing_rot
	mesh_inst.scale = Vector3(0.5, 0.5, 0.5)
	scene.add_child(mesh_inst)

	var t := mesh_inst.create_tween()
	t.tween_property(mesh_inst, "scale", Vector3(scale_size, 0.1, scale_size * 1.3), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.14)
	t.tween_callback(mesh_inst.queue_free)


## Mukammal qaytarish effekti (Parry burst)
func parry_burst(world_pos: Vector3) -> void:
	sparks(world_pos, Vector3.UP, Color(0.4, 0.85, 1.0), 24)
	sparks(world_pos, Vector3.UP, Color(1.0, 0.95, 0.7), 16)
	shockwave_ring(world_pos, 2.8, Color(0.4, 0.9, 1.0, 0.9), 0.3)
	camera_shake(0.25)

