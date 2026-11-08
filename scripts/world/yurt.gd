class_name Yurt
extends StaticBody3D
## Boysun milliy o'tovi (yurt) va kechki gulxan manzilgohi.

var _fire_light: OmniLight3D
var _fire_time := 0.0


func _ready() -> void:
	_build_yurt()
	_build_campfire()


func _build_yurt() -> void:
	# 1. O'tovning oq kigiz devori (Cylinder)
	var wall := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 3.6
	cyl.bottom_radius = 3.8
	cyl.height = 1.9
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.92, 0.88, 0.82) # Oq kigiz / namat
	wall_mat.roughness = 0.95
	wall.mesh = cyl
	wall.material_override = wall_mat
	wall.position.y = 0.95
	add_child(wall)

	# Qizil baxmal belbog' (namat bezagi)
	var belt := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 3.72
	bcyl.bottom_radius = 3.75
	bcyl.height = 0.35
	var belt_mat := StandardMaterial3D.new()
	belt_mat.albedo_color = Color(0.72, 0.16, 0.15) # Qizil belbog'
	belt.mesh = bcyl
	belt.material_override = belt_mat
	belt.position.y = 1.2
	add_child(belt)

	# 2. Gumbaz (Tom / Chang'aroq)
	var roof := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.6 # Chang'aroq teshigi
	cone.bottom_radius = 3.85
	cone.height = 1.6
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.88, 0.84, 0.78)
	roof_mat.roughness = 0.95
	roof.mesh = cone
	roof.material_override = roof_mat
	roof.position.y = 2.7
	add_child(roof)

	# 3. Yog'och o'ymakor eshik
	var door := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(1.2, 1.6, 0.2)
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.36, 0.22, 0.12)
	door.mesh = dbox
	door.material_override = door_mat
	door.position = Vector3(0, 0.8, 3.65)
	add_child(door)

	# Kolliziya
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.radius = 3.8
	cshape.height = 2.4
	col.shape = cshape
	col.position.y = 1.2
	add_child(col)


func _build_campfire() -> void:
	# O'tov oldidagi gulxan (Z = 5.8)
	var fire_pos := Vector3(0, 0, 5.8)

	# Toshlar doirasi
	for i in 8:
		var angle := i * (TAU / 8.0)
		var stone := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.35, 0.25, 0.35)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.4, 0.38, 0.35)
		stone.mesh = sbox
		stone.material_override = smat
		stone.position = fire_pos + Vector3(cos(angle) * 0.7, 0.12, sin(angle) * 0.7)
		stone.rotation_degrees.y = randf_range(0, 90)
		add_child(stone)

	# Cho'g' va o'tinlar
	var log_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = 0.9
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.25, 0.15, 0.08)
	log_mesh.mesh = cyl
	log_mesh.material_override = log_mat
	log_mesh.position = fire_pos + Vector3(0, 0.15, 0)
	log_mesh.rotation_degrees.z = 70.0
	add_child(log_mesh)

	# Olov nuri (OmniLight3D)
	_fire_light = OmniLight3D.new()
	_fire_light.position = fire_pos + Vector3(0, 0.6, 0)
	_fire_light.light_color = Color(1.0, 0.68, 0.25)
	_fire_light.light_energy = 2.2
	_fire_light.omni_range = 14.0
	_fire_light.shadow_enabled = true
	add_child(_fire_light)


func _process(delta: float) -> void:
	if _fire_light:
		_fire_time += delta * 12.0
		# Olov nuri tebranishi (Flicker effect)
		_fire_light.light_energy = 2.0 + sin(_fire_time) * 0.3 + sin(_fire_time * 2.3) * 0.15
