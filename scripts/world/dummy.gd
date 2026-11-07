class_name Dummy
extends StaticBody3D
## Maneken: zarbani qabul qiladi, zarar raqamini ko'rsatadi, yiqiladi va qayta tiklanadi.

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

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.6, 0.15, 0.15)
	_mat.emission = Color.WHITE
	_mat.emission_energy_multiplier = 0.0
	_mat.emission_enabled = true
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	capsule.material = _mat
	_mesh = MeshInstance3D.new()
	_mesh.mesh = capsule
	_mesh.position.y = 0.9
	add_child(_mesh)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)

	_label = Label3D.new()
	_label.position.y = 2.3
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	_update_label()


func take_damage(amount: float, _from_pos := Vector3.ZERO, _knockback := 0.0) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	_update_label()
	_popup(amount)
	_mat.emission_energy_multiplier = 2.5
	create_tween().tween_property(_mat, "emission_energy_multiplier", 0.0, 0.2)
	_mesh.scale = Vector3(1.2, 0.85, 1.2)
	create_tween().tween_property(_mesh, "scale", Vector3.ONE, 0.18)
	if health <= 0.0:
		_die()


func _die() -> void:
	collision_layer = 0
	var t := create_tween()
	t.tween_property(_mesh, "rotation:x", -PI / 2.0, 0.3)
	t.parallel().tween_property(_mesh, "position:y", 0.4, 0.3)
	await get_tree().create_timer(3.0).timeout
	_mesh.rotation.x = 0.0
	_mesh.position.y = 0.9
	health = max_health
	collision_layer = 1 << 2
	_update_label()


func _update_label() -> void:
	_label.text = "Maneken  %d/%d" % [int(health), int(max_health)]


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
