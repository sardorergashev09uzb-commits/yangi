class_name DungeonGate
extends StaticBody3D
## Zindon darvozasi / Qalmoq qal'asi portali.
## Surxayil mag'lub etilgach ochiladi va Karajon hamda Barchinoy zindoniga olib boradi.

signal portal_entered

var _door: MeshInstance3D
var _door_col: CollisionShape3D
var _prompt: Label3D
var _area: Area3D
var is_open := false


func _ready() -> void:
	add_to_group("dungeon_gates")
	_build_structure()


func _build_structure() -> void:
	# Qadimiy qora tosh darvoza ustunlari
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.18, 0.16, 0.18)
	pmat.roughness = 0.9

	for x_off in [-2.4, 2.4]:
		var col := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(1.2, 5.0, 1.2)
		col.shape = box_shape
		col.position = Vector3(x_off, 2.5, 0)
		add_child(col)

		var mi := MeshInstance3D.new()
		var bmesh := BoxMesh.new()
		bmesh.size = box_shape.size
		mi.mesh = bmesh
		mi.material_override = pmat
		mi.position = col.position
		add_child(mi)

	# Yuqori peshtoq
	var top_mi := MeshInstance3D.new()
	var tmesh := BoxMesh.new()
	tmesh.size = Vector3(6.0, 1.0, 1.4)
	top_mi.mesh = tmesh
	top_mi.material_override = pmat
	top_mi.position = Vector3(0, 5.2, 0)
	add_child(top_mi)

	# Temir panjarali darvoza
	_door = MeshInstance3D.new()
	var dmesh := BoxMesh.new()
	dmesh.size = Vector3(3.6, 4.6, 0.2)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.12, 0.12, 0.14)
	dmat.metallic = 0.85
	dmat.roughness = 0.4
	_door.mesh = dmesh
	_door.material_override = dmat
	_door.position = Vector3(0, 2.3, 0)
	add_child(_door)

	_door_col = CollisionShape3D.new()
	var dc_shape := BoxShape3D.new()
	dc_shape.size = dmesh.size
	_door_col.shape = dc_shape
	_door_col.position = _door.position
	add_child(_door_col)

	# Interaktiv o'tish hududi (trigger)
	_area = Area3D.new()
	var a_shape := BoxShape3D.new()
	a_shape.size = Vector3(3.4, 4.0, 3.0)
	var acol := CollisionShape3D.new()
	acol.shape = a_shape
	acol.position = Vector3(0, 2.0, 0)
	_area.add_child(acol)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)

	# Yozuv / Nishon
	_prompt = Label3D.new()
	_prompt.position = Vector3(0, 5.8, 0)
	_prompt.font_size = 32
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.text = "QALMOQ ZINDONI (QULFLANGAN)"
	_prompt.modulate = Color(0.9, 0.4, 0.4)
	add_child(_prompt)


func unlock() -> void:
	if is_open:
		return
	is_open = true
	_prompt.text = "QALMOQ ZINDONI\n[ E ] - Zindonga kirish va Barchinoyni qutqarish"
	_prompt.modulate = Color(0.3, 1.0, 0.6)

	var t := create_tween()
	t.tween_property(_door, "position:y", -4.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_door_col.disabled = true
	Audio.play_heavy_hit()


func _on_body_entered(body: Node3D) -> void:
	if is_open and body.is_in_group("player"):
		portal_entered.emit()
