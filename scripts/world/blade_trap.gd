class_name BladeTrap
extends Area3D
## 8-bosqich: Aylanuvchi o'tkir po'lat tig'lar tuzog'i (Rotating Blade Trap).
## O'yinchi labirintdan o'tayotganda aylanuvchi pichoqlarga tegmasdan vaqtni poylab o'tishi kerak.

@export var damage := 20.0
@export var rotation_speed := 3.5 # rad/sec
@export var blade_length := 3.2

var _blades_node: Node3D
var _hit_cooldown := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1 # Faqat o'yinchi
	add_to_group("traps")

	# Markaziy tosh poydevor
	var base_mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.45
	cyl.height = 1.6
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.25, 0.22, 0.2)
	bmat.roughness = 0.9
	cyl.material = bmat
	base_mi.mesh = cyl
	base_mi.position.y = 0.8
	add_child(base_mi)

	# Aylanuvchi tig'lar guruhi
	_blades_node = Node3D.new()
	_blades_node.position.y = 0.9
	add_child(_blades_node)

	# 2 ta qarama-qarshi po'lat pichoq (Double-edged rotating scythes)
	for rot in [0.0, PI]:
		var blade_arm := MeshInstance3D.new()
		var bmesh := BoxMesh.new()
		bmesh.size = Vector3(0.06, 0.22, blade_length)
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.85, 0.88, 0.92) # Yarqiroq po'lat
		pmat.metallic = 0.95
		pmat.roughness = 0.15
		blade_arm.mesh = bmesh
		blade_arm.material_override = pmat
		blade_arm.position = Vector3(0, 0, blade_length * 0.5)
		blade_arm.rotation.y = rot
		_blades_node.add_child(blade_arm)

	# Collision shape (aylanish radiusi bo'yicha silindr)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = blade_length * 0.95
	shape.height = 0.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)


func _process(delta: float) -> void:
	if _blades_node:
		_blades_node.rotate_y(rotation_speed * delta)

	_hit_cooldown -= delta
	if _hit_cooldown <= 0.0:
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position, 5.0)
				_hit_cooldown = 0.8
				FX.parry_burst(global_position + Vector3.UP * 0.9)
				Audio.play_heavy_hit()
				break
