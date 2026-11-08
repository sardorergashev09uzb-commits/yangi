class_name DungeonGate
extends StaticBody3D
## Zindon darvozasi / Qalmoq qal'asi portali (Qora Arena Eshigi).
## Surxayil mag'lub etilgach ochiladi va Karajon hamda Barchinoy zindoniga olib boradi.

signal portal_entered

var _left_pivot: Node3D
var _right_pivot: Node3D
var _door: MeshInstance3D # Orqaga moslik uchun
var _door_col: CollisionShape3D
var _right_door: MeshInstance3D
var _right_door_col: CollisionShape3D
var _prompt: Label3D
var _area: Area3D
var is_open := false


func _ready() -> void:
	add_to_group("dungeon_gates")
	_build_structure()


func _build_structure() -> void:
	# Qadimiy qora tosh ustunlar va peshtoq
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.18, 0.16, 0.18)
	pmat.roughness = 0.9

	# Chap va o'ng tosh ustunlar (Kengligi 10 metrlik darvoza uchun)
	for x_off in [-5.3, 5.3]:
		var col := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(1.6, 6.0, 1.8)
		col.shape = box_shape
		col.position = Vector3(x_off, 3.0, 0)
		add_child(col)

		var mi := MeshInstance3D.new()
		var bmesh := BoxMesh.new()
		bmesh.size = box_shape.size
		mi.mesh = bmesh
		mi.material_override = pmat
		mi.position = col.position
		add_child(mi)

		# Ustunlardagi mash'allar
		_add_torch(Vector3(x_off * 0.85, 3.2, 0.9))

	# Yuqori peshtoq (lintel)
	var top_mi := MeshInstance3D.new()
	var tmesh := BoxMesh.new()
	tmesh.size = Vector3(12.4, 1.2, 2.0)
	top_mi.mesh = tmesh
	top_mi.material_override = pmat
	top_mi.position = Vector3(0, 5.6, 0)
	add_child(top_mi)

	var top_col := CollisionShape3D.new()
	var top_shape := BoxShape3D.new()
	top_shape.size = tmesh.size
	top_col.shape = top_shape
	top_col.position = top_mi.position
	add_child(top_col)

	# Temir panjarali qora darvoza (qo'sh tavaqali - ochilganda ikki yonga ochiladi!)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.12, 0.12, 0.14)
	dmat.metallic = 0.85
	dmat.roughness = 0.4

	# Chap tavaqa pivot
	_left_pivot = Node3D.new()
	_left_pivot.position = Vector3(-4.5, 2.5, 0)
	add_child(_left_pivot)

	_door = MeshInstance3D.new()
	var dmesh_leaf := BoxMesh.new()
	dmesh_leaf.size = Vector3(4.5, 5.0, 0.25)
	_door.mesh = dmesh_leaf
	_door.material_override = dmat
	_door.position = Vector3(2.25, 0, 0)
	_left_pivot.add_child(_door)

	_door_col = CollisionShape3D.new()
	var leaf_shape := BoxShape3D.new()
	leaf_shape.size = dmesh_leaf.size
	_door_col.shape = leaf_shape
	_door_col.position = _door.position
	_left_pivot.add_child(_door_col)

	# O'ng tavaqa pivot
	_right_pivot = Node3D.new()
	_right_pivot.position = Vector3(4.5, 2.5, 0)
	add_child(_right_pivot)

	_right_door = MeshInstance3D.new()
	_right_door.mesh = dmesh_leaf
	_right_door.material_override = dmat
	_right_door.position = Vector3(-2.25, 0, 0)
	_right_pivot.add_child(_right_door)

	_right_door_col = CollisionShape3D.new()
	_right_door_col.shape = leaf_shape
	_right_door_col.position = _right_door.position
	_right_pivot.add_child(_right_door_col)

	# Interaktiv o'tish hududi (trigger) - otda ham, piyoda ham kirish mumkin
	_area = Area3D.new()
	var a_shape := BoxShape3D.new()
	a_shape.size = Vector3(9.5, 5.0, 5.0)
	var acol := CollisionShape3D.new()
	acol.shape = a_shape
	acol.position = Vector3(0, 2.5, 0)
	_area.add_child(acol)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)

	# Yozuv / Nishon (ko'z darajasida, HUD to'sib qo'ymaydi)
	_prompt = Label3D.new()
	_prompt.position = Vector3(0, 4.2, 0.6)
	_prompt.font_size = 32
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.text = "QALMOQ ZINDONI (QULFLANGAN)"
	_prompt.modulate = Color(0.95, 0.35, 0.35)
	add_child(_prompt)


func _add_torch(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 2.2
	light.omni_range = 9.0
	light.shadow_enabled = true
	add_child(light)

	var torch_m := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.16
	sph.height = 0.32
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.15)
	mat.emission_energy_multiplier = 3.0
	torch_m.mesh = sph
	torch_m.material_override = mat
	torch_m.position = pos
	add_child(torch_m)


func unlock() -> void:
	if is_open:
		return
	is_open = true
	_prompt.text = "QALMOQ ZINDONI (OCHILDI)\n[ E ] yoki to'g'ridan-to'g'ri kiring"
	_prompt.modulate = Color(0.3, 1.0, 0.6)

	# Qo'sh tavaqali qora temir darvoza ikki yonga silliq ochiladi va ochiq holatda ko'rinib turadi!
	var t := create_tween().set_parallel(true)
	t.tween_property(_left_pivot, "rotation:y", -deg_to_rad(85.0), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_right_pivot, "rotation:y", deg_to_rad(85.0), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_door_col.disabled = true
	_right_door_col.disabled = true
	Audio.play_heavy_hit()


func _on_body_entered(body: Node3D) -> void:
	if is_open and (body.is_in_group("player") or body.is_in_group("horses")):
		portal_entered.emit()
