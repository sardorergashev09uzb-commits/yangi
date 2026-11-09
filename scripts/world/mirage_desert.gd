class_name MirageDesert
extends Node3D
## Qoraqum Sarobi Sahrosi (The Mirage Desert) & Qadimiy Kohna Qo'rg'on Harobalari
## Boysun dashtining janubi-g'arbida joylashgan oltin qumli sahro,
## qum bo'roni, saksovulzorlar va qadimiy maqbara xarobalari.

const DesertShader = preload("res://shaders/terrain_desert.gdshader")
const TreasureChestScript = preload("res://scripts/world/treasure_chest.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")

var _sand_mat: ShaderMaterial
var _stone_mat: StandardMaterial3D
var _sandstorm: CPUParticles3D


func _ready() -> void:
	name = "MirageDesert"
	_init_materials()
	_build_desert_terrain()
	_build_sandstorm()
	_build_ancient_ruins()
	_build_desert_flora()
	_spawn_desert_guardians()


func _init_materials() -> void:
	_sand_mat = ShaderMaterial.new()
	_sand_mat.shader = DesertShader

	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.78, 0.68, 0.52) # Sariq qadimgi qumtosh
	_stone_mat.roughness = 0.88
	_stone_mat.metallic = 0.05


func _build_desert_terrain() -> void:
	# Asosiy sahro zamini (Desert Base Ground - G'arb tomon: X = -75, Z = 75, O'lchami: 140 x 140)
	var desert_base := _box(Vector3(-75, 0.02, 70), Vector3(120, 0.05, 110), _sand_mat)

	# Qum barxanlari (Rolling Sand Dunes)
	_dune(Vector3(-45, 1.4, 45), Vector3(26, 3.2, 18), 25.0)
	_dune(Vector3(-70, 2.0, 35), Vector3(32, 4.5, 22), -15.0)
	_dune(Vector3(-95, 1.8, 60), Vector3(36, 4.0, 25), 35.0)
	_dune(Vector3(-60, 2.6, 95), Vector3(40, 5.5, 28), 10.0)
	_dune(Vector3(-105, 2.8, 105), Vector3(42, 6.0, 30), -20.0)
	_dune(Vector3(-40, 1.2, 85), Vector3(24, 2.8, 16), 40.0)


func _dune(pos: Vector3, size: Vector3, rot_y: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = rot_y
	body.collision_layer = 1
	body.collision_mask = 0

	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = size.x * 0.1
	cyl.bottom_radius = size.x * 0.5
	cyl.height = size.y
	mi.mesh = cyl
	mi.scale.z = size.z / maxf(size.x, 1.0)
	mi.material_override = _sand_mat
	mi.position.y = size.y * 0.45
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position.y = size.y * 0.45
	body.add_child(col)

	add_child(body)
	return body


func _build_sandstorm() -> void:
	# Chisong'i qum bo'roni effekti (Chisongi Sandstorm CPU Particles)
	_sandstorm = CPUParticles3D.new()
	_sandstorm.name = "DesertSandstorm"
	_sandstorm.position = Vector3(-70, 2.5, 70)
	_sandstorm.amount = 180
	_sandstorm.lifetime = 2.4
	_sandstorm.explosiveness = 0.05
	_sandstorm.randomness = 0.3

	var pmesh := SphereMesh.new()
	pmesh.radius = 0.12
	pmesh.height = 0.24
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.albedo_color = Color(0.88, 0.74, 0.45, 0.35) # Qum zarralari
	pmesh.material = pmat
	_sandstorm.mesh = pmesh

	_sandstorm.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_sandstorm.emission_box_extents = Vector3(50, 4.0, 45)
	_sandstorm.direction = Vector3(-1.0, -0.05, 0.35).normalized()
	_sandstorm.spread = 25.0
	_sandstorm.initial_velocity_min = 10.0
	_sandstorm.initial_velocity_max = 16.0
	_sandstorm.gravity = Vector3(0, -0.8, 0)
	_sandstorm.scale_amount_min = 0.8
	_sandstorm.scale_amount_max = 2.4
	add_child(_sandstorm)


func _build_ancient_ruins() -> void:
	# Qadimiy Kohna Qo'rg'on Harobalari (Markaziy koordinata: X = -75, Z = 65)
	var ruins_center := Vector3(-75, 0, 65)

	# 1. Poydevor tosh supasi (Temple foundation platform)
	_box(ruins_center + Vector3(0, 0.25, 0), Vector3(22, 0.5, 22), _stone_mat)
	_box(ruins_center + Vector3(0, 0.65, 0), Vector3(16, 0.4, 16), _stone_mat)

	# Pog'onali zinalar (Stairs leading up)
	for i in range(4):
		_box(ruins_center + Vector3(0, 0.12 * (i + 1), 9.0 + i * 0.9), Vector3(8.0, 0.25, 1.2), _stone_mat)

	# 2. Qadimiy ustunlar (Sandstone Pillars)
	var pillar_offsets := [
		Vector3(-6, 0, -6), Vector3(-6, 0, 0), Vector3(-6, 0, 6),
		Vector3(6, 0, -6), Vector3(6, 0, 0), Vector3(6, 0, 6),
		Vector3(-2, 0, -6), Vector3(2, 0, -6)
	]
	for idx in pillar_offsets.size():
		var po: Vector3 = pillar_offsets[idx]
		var p_height := 4.8 if idx % 2 == 0 else 3.4 # Ayrimlari vaqt o'tishi bilan siniq/nuragan
		_pillar(ruins_center + po, p_height)

	# 3. Katta tosh ark / darvoza to'sini (Architrave beam)
	_box(ruins_center + Vector3(-6, 5.0, 0), Vector3(1.4, 0.6, 7.5), _stone_mat)
	_box(ruins_center + Vector3(6, 5.0, 0), Vector3(1.4, 0.6, 7.5), _stone_mat)

	# 4. Qadimiy Maqbara Mehrobi va Oltin Qo'chqor Obidasi (Ancient Altar)
	var altar_pos := ruins_center + Vector3(0, 0.85, -2.5)
	_box(altar_pos + Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 1.8), _stone_mat)

	# Oltin Qo'chqor Haykalchasi (Golden Ram Relic)
	var relic := MeshInstance3D.new()
	var r_box := BoxMesh.new()
	r_box.size = Vector3(0.5, 0.6, 0.8)
	relic.mesh = r_box
	var r_mat := StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.95, 0.82, 0.25) # Oltin
	r_mat.metallic = 0.95
	r_mat.roughness = 0.2
	r_mat.emission_enabled = true
	r_mat.emission = Color(0.95, 0.82, 0.25)
	r_mat.emission_energy_multiplier = 0.6
	relic.material_override = r_mat
	relic.position = altar_pos + Vector3(0, 1.25, 0)
	add_child(relic)

	# Mehrob ustidagi xazina sandig'i
	var chest = TreasureChestScript.new()
	chest.gold_amount = 120
	chest.name = "DesertRuinsChest"
	chest.position = altar_pos + Vector3(0, 0.9, 1.6)
	add_child(chest)

	# Qadimiy Bitiktosh (Ancient Stele)
	_stele(ruins_center + Vector3(-4.5, 0.85, 3.5))


func _pillar(pos: Vector3, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.45
	cyl.bottom_radius = 0.52
	cyl.height = height
	mi.mesh = cyl
	mi.material_override = _stone_mat
	mi.position.y = height * 0.5
	body.add_child(mi)

	# Ustun boshpoyasi (Capital)
	var cap := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(1.2, 0.35, 1.2)
	cap.mesh = cbox
	cap.material_override = _stone_mat
	cap.position.y = height - 0.15
	body.add_child(cap)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.55
	shape.height = height
	col.shape = shape
	col.position.y = height * 0.5
	body.add_child(col)

	add_child(body)
	return body


func _stele(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 2.2, 0.3)
	mi.mesh = box
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.65, 0.58, 0.48)
	mi.material_override = smat
	mi.position.y = 1.1
	body.add_child(mi)

	var label := Label3D.new()
	label.text = "QORAQUM BITIGI\n[ Qadimiy Sarob Maqbarasi ]"
	label.font_size = 28
	label.modulate = Color(0.95, 0.85, 0.5)
	label.outline_modulate = Color(0.1, 0.1, 0.1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.4
	body.add_child(label)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 2.2, 0.3)
	col.shape = shape
	col.position.y = 1.1
	body.add_child(col)

	add_child(body)


func _build_desert_flora() -> void:
	# Saksovul va cho'l butalari (Saxaul bushes)
	var saxaul_positions := [
		Vector3(-35, 0, 30), Vector3(-50, 0, 55), Vector3(-65, 0, 25),
		Vector3(-85, 0, 40), Vector3(-95, 0, 85), Vector3(-55, 0, 80),
		Vector3(-40, 0, 105), Vector3(-80, 0, 110), Vector3(-110, 0, 65)
	]
	for sp in saxaul_positions:
		_saxaul(sp)


func _saxaul(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.48, 0.35, 0.22) # Quruq saksovul tanasi
	wood_mat.roughness = 0.9

	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.45, 0.52, 0.28) # Quruq och-yashil ignalar
	leaf_mat.roughness = 0.9

	# Egri tana
	var trunk := MeshInstance3D.new()
	var tcyl := CylinderMesh.new()
	tcyl.top_radius = 0.12
	tcyl.bottom_radius = 0.25
	tcyl.height = 1.8
	trunk.mesh = tcyl
	trunk.material_override = wood_mat
	trunk.position.y = 0.9
	trunk.rotation_degrees.z = randf_range(-15, 15)
	root.add_child(trunk)

	# Butalar
	for i in range(3):
		var clump := MeshInstance3D.new()
		var csph := SphereMesh.new()
		csph.radius = randf_range(0.45, 0.75)
		csph.height = csph.radius * 1.5
		clump.mesh = csph
		clump.material_override = leaf_mat
		clump.position = Vector3(randf_range(-0.4, 0.4), 1.5 + i * 0.3, randf_range(-0.4, 0.4))
		root.add_child(clump)

	add_child(root)


func _spawn_desert_guardians() -> void:
	# Sahro qaroqchilari (Desert Nomads / Sand Raiders)
	var spawns := [
		{"kind": EnemyScript.Kind.SWORD, "pos": Vector3(-70, 0.5, 55)},
		{"kind": EnemyScript.Kind.ARCHER, "pos": Vector3(-82, 0.5, 60)},
		{"kind": EnemyScript.Kind.SPEAR, "pos": Vector3(-76, 0.5, 75)}
	]
	for sp in spawns:
		var e: CharacterBody3D = EnemyScript.new()
		e.kind = sp.kind
		e.position = sp.pos
		add_child(e)


func _box(pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	add_child(body)
	return body
