extends Node3D
## 0/1-bosqich test poligoni: yer, to'siqlar, rampa, manekenlar, yoritish.

func _ready() -> void:
	_build_environment()
	_box(Vector3(0, -0.5, 0), Vector3(120, 1, 120), Color(0.45, 0.38, 0.28))
	# sakrash va to'siqlar
	_box(Vector3(6, 0.5, -4), Vector3(3, 1, 3), Color(0.5, 0.45, 0.4))
	_box(Vector3(9, 1.0, -4), Vector3(3, 2, 3), Color(0.5, 0.45, 0.4))
	_box(Vector3(-8, 0.75, -6), Vector3(6, 1.5, 1), Color(0.55, 0.4, 0.35))
	var ramp := _box(Vector3(-6, 0.9, 6), Vector3(5, 0.5, 8), Color(0.5, 0.5, 0.45))
	ramp.rotation_degrees.x = 15
	# lock-on uchun manekenlar
	for p in [Vector3(0, 0, -10), Vector3(7, 0, -12), Vector3(-7, 0, -14)]:
		_dummy(p)


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.4, 0.65)
	sky_mat.sky_horizon_color = Color(0.85, 0.7, 0.5)
	sky_mat.ground_horizon_color = Color(0.85, 0.7, 0.5)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.72, 0.55)
	env.fog_density = 0.005
	env.ssao_enabled = true
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


func _box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	mesh_inst.mesh = mesh
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(mesh_inst)
	body.add_child(col)
	add_child(body)
	return body


func _dummy(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.add_to_group("targetable")
	var mesh_inst := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.4
	mesh.height = 1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.15, 0.15)
	mesh.material = mat
	mesh_inst.mesh = mesh
	mesh_inst.position.y = 0.9
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	var label := Label3D.new()
	label.text = "Maneken"
	label.position.y = 2.3
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	body.add_child(mesh_inst)
	body.add_child(col)
	body.add_child(label)
	add_child(body)
