class_name Dummy
extends StaticBody3D
## Mashq yog'ochi: zarbani sinash uchun yog'och nishon.
## Dushmandan farqlanadi: jonsiz yog'och rangida, o'ldirilsa qayta jonlanmaydi.

@export var max_health := 120.0

var health := 120.0

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _label: Label3D


func _ready() -> void:
	health = max_health
	collision_layer = 1 << 2
	collision_mask = 0
	add_to_group("hurtable")

	# Yog'och ko'rinishi (dushmanga o'xshamaydi)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.52, 0.36, 0.22)
	_mat.roughness = 0.8
	_mat.emission_enabled = true
	_mat.emission = Color.WHITE
	_mat.emission_energy_multiplier = 0.0

	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.35
	cyl.height = 1.8
	cyl.material = _mat

	_mesh = MeshInstance3D.new()
	_mesh.mesh = cyl
	_mesh.position.y = 0.9
	add_child(_mesh)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)

	_label = Label3D.new()
	_label.position.y = 2.2
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 36
	add_child(_label)
	_update_label()


func take_damage(amount: float, _from_pos := Vector3.ZERO, _knockback := 0.0) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	_update_label()
	_popup(amount)
	_mat.emission_energy_multiplier = 2.0
	create_tween().tween_property(_mat, "emission_energy_multiplier", 0.0, 0.15)
	_mesh.scale = Vector3(1.15, 0.9, 1.15)
	create_tween().tween_property(_mesh, "scale", Vector3.ONE, 0.15)
	if health <= 0.0:
		_die()


func _die() -> void:
	collision_layer = 0
	remove_from_group("hurtable")
	_label.visible = false
	var t := create_tween()
	t.tween_property(_mesh, "rotation:x", -PI / 2.0, 0.3)
	t.parallel().tween_property(_mesh, "position:y", 0.2, 0.3)


func reset_dummy() -> void:
	health = max_health
	collision_layer = 1 << 2
	add_to_group("hurtable")
	_mesh.rotation = Vector3.ZERO
	_mesh.position.y = 0.9
	_label.visible = true
	_update_label()


func _update_label() -> void:
	_label.text = "Mashq yog'ochi\n%d/%d" % [int(health), int(max_health)]


func _popup(amount: float) -> void:
	var l := Label3D.new()
	l.text = str(int(amount))
	l.font_size = 72
	l.modulate = Color(1.0, 0.9, 0.3)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.top_level = true
	add_child(l)
	l.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 2.0, 0.0)
	var t := l.create_tween()
	t.tween_property(l, "global_position:y", l.global_position.y + 0.9, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)
