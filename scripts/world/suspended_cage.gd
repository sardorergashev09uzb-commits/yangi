class_name SuspendedCage
extends Node3D
## 8-bosqich: Zindon Muallaq Temir Qafasi va Tushiruvchi Richag (Suspended Iron Cage & Winch).
## Barchinoy zindon tepasida osilgan temir qafasda asirlikda saqlanadi.
## O'yinchi richag mexanizmini ishga tushirib qafasni yerga tushiradi va eshigini ochadi.

signal cage_lowered()

@export var is_lowered := false

var _cage_node: Node3D
var _chain_mesh: MeshInstance3D
var _lever_handle: MeshInstance3D
var _lever_area: Area3D
var _target_y := 0.0
var _current_y := 5.2
var _prompt_label: Label3D


func _ready() -> void:
	add_to_group("suspended_cages")
	_build_cage()
	_build_lever()


func _build_cage() -> void:
	_cage_node = Node3D.new()
	_cage_node.position.y = _current_y
	add_child(_cage_node)

	# Zanjir (Shiftga ulanuvchi temir zanjir)
	_chain_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 7.0
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.18, 0.18, 0.2)
	cmat.metallic = 0.9
	cyl.material = cmat
	_chain_mesh.mesh = cyl
	_chain_mesh.position.y = 3.5
	_cage_node.add_child(_chain_mesh)

	# Qafas tomi va zamini (Iron plates)
	for y in [0.0, 3.2]:
		var plate := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(3.2, 0.12, 3.2)
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.2, 0.2, 0.22)
		pmat.metallic = 0.8
		pbox.material = pmat
		plate.mesh = pbox
		plate.position.y = y
		_cage_node.add_child(plate)

	# Panjaralar (Vertical iron bars)
	for x in [-1.5, -0.75, 0.0, 0.75, 1.5]:
		for z in [-1.5, 1.5]:
			_add_bar(Vector3(x, 1.6, z))
	for z in [-0.75, 0.0, 0.75]:
		for x in [-1.5, 1.5]:
			_add_bar(Vector3(x, 1.6, z))


func _add_bar(pos: Vector3) -> void:
	var bar := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.04
	bcyl.bottom_radius = 0.04
	bcyl.height = 3.1
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.15, 0.15, 0.18)
	bmat.metallic = 0.85
	bcyl.material = bmat
	bar.mesh = bcyl
	bar.position = pos
	_cage_node.add_child(bar)


func _build_lever() -> void:
	# Richag poydevori (devor oldidagi temir podstavka)
	var base := StaticBody3D.new()
	base.position = Vector3(5.5, 0, 0)
	var bmesh := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(0.6, 0.8, 0.6)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.3, 0.25, 0.2)
	bbox.material = bmat
	bmesh.mesh = bbox
	bmesh.position.y = 0.4
	base.add_child(bmesh)

	# Buriluvchi richag tutqichi
	_lever_handle = MeshInstance3D.new()
	var hcyl := CylinderMesh.new()
	hcyl.top_radius = 0.04
	hcyl.bottom_radius = 0.04
	hcyl.height = 1.0
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.8, 0.2, 0.15) # Qizil tutqich
	hcyl.material = hmat
	_lever_handle.mesh = hcyl
	_lever_handle.position = Vector3(0, 0.8, 0)
	_lever_handle.rotation_degrees.z = -30.0
	base.add_child(_lever_handle)

	# Interaksiya maydoni
	_lever_area = Area3D.new()
	_lever_area.collision_layer = 1 << 0
	_lever_area.collision_mask = 1 << 1
	var acol := CollisionShape3D.new()
	var ashape := SphereShape3D.new()
	ashape.radius = 2.2
	acol.shape = ashape
	acol.position.y = 0.6
	_lever_area.add_child(acol)

	# E tugmasi matni
	_prompt_label = Label3D.new()
	_prompt_label.text = "[E] Qafasni Tushirish"
	_prompt_label.font_size = 28
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.modulate = Color(1.0, 0.85, 0.2)
	_prompt_label.position = Vector3(0, 1.6, 0)
	_prompt_label.visible = false
	_lever_area.add_child(_prompt_label)

	base.add_child(_lever_area)
	add_child(base)

	_lever_area.body_entered.connect(func(_b): if not is_lowered: _prompt_label.visible = true)
	_lever_area.body_exited.connect(func(_b): _prompt_label.visible = false)


func interact() -> void:
	if is_lowered:
		return
	lower_cage()


func lower_cage() -> void:
	if is_lowered:
		return
	is_lowered = true
	if _prompt_label:
		_prompt_label.visible = false
	if _lever_handle:
		_lever_handle.rotation_degrees.z = 35.0

	Audio.play_heavy_hit()
	FX.shockwave_ring(global_position + Vector3(5.5, 0.1, 0), 3.0, Color(1.0, 0.6, 0.1), 0.3)


func _physics_process(delta: float) -> void:
	if is_lowered and _current_y > _target_y:
		_current_y = move_toward(_current_y, _target_y, 4.5 * delta)
		if _cage_node:
			_cage_node.position.y = _current_y
		if _current_y <= _target_y:
			Audio.play_level_up()
			FX.impact_burst(global_position + Vector3.UP * 0.2, Color(0.9, 0.8, 0.2), 24)
			cage_lowered.emit()
