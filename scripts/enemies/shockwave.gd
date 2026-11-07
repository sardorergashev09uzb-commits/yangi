class_name Shockwave
extends Area3D
## Surxayilning yerga urishidan hosil bo'ladigan kengayuvchi to'lqin.
## O'yinchi sakrab yoki qochib qutulishi kerak.

var speed := 9.0
var max_radius := 9.0
var damage := 20.0
var current_radius := 0.5

var _col: CollisionShape3D
var _shape: CylinderShape3D
var _ring: MeshInstance3D
var _torus: TorusMesh
var _mat: StandardMaterial3D
var _hit_player := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1 # Faqat o'yinchi

	_shape = CylinderShape3D.new()
	_shape.radius = current_radius
	_shape.height = 0.5

	_col = CollisionShape3D.new()
	_col.name = "CollisionShape3D"
	_col.shape = _shape
	add_child(_col)

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(1.0, 0.4, 0.1, 0.9)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.5, 0.1)
	_mat.emission_energy_multiplier = 3.0
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_torus = TorusMesh.new()
	_torus.inner_radius = 0.1
	_torus.outer_radius = 0.5
	_torus.material = _mat

	_ring = MeshInstance3D.new()
	_ring.mesh = _torus
	add_child(_ring)


func _physics_process(delta: float) -> void:
	current_radius += speed * delta
	if _shape:
		_shape.radius = current_radius

	if _torus:
		_torus.outer_radius = maxf(current_radius, 0.3)
		_torus.inner_radius = maxf(current_radius - 0.4, 0.05)
		if _torus.inner_radius >= _torus.outer_radius:
			_torus.inner_radius = _torus.outer_radius - 0.1

	if _mat:
		var alpha := clampf(1.0 - (current_radius / max_radius), 0.0, 1.0)
		_mat.albedo_color.a = alpha

	if not _hit_player:
		for b in get_overlapping_bodies():
			if b is Player and b.is_on_floor() and not b.invulnerable:
				_hit_player = true
				b.take_damage(damage, global_position, 8.0)
				break

	if current_radius >= max_radius:
		queue_free()
