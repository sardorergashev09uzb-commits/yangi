class_name AlpEarthquake
extends Area3D
## Alpomishning 13-bosqich maxsus mahorati: "Alp Gumburi" (Yer tebranishi).
## C tugmasi bilan yerga sakrab zarba beradi: tevarakdagi dushmanlarga zarba beradi,
## ularni parokanda qilib uchiradi va 1.5 soniyaga karaxt (stagger) qiladi.

var speed := 14.0
var max_radius := 8.5
var damage := 45.0
var current_radius := 0.6

var _hit_enemies: Array[Node] = []
var _col: CollisionShape3D
var _shape: CylinderShape3D
var _ring: MeshInstance3D
var _torus: TorusMesh
var _mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("player_skills")
	collision_layer = 0
	collision_mask = 1 << 2 # Dushmanlar va devlar (layer 3)

	_shape = CylinderShape3D.new()
	_shape.radius = current_radius
	_shape.height = 1.0

	_col = CollisionShape3D.new()
	_col.shape = _shape
	add_child(_col)

	_mat = StandardMaterial3D.new()
	# Oltin va zangori alp nuri
	_mat.albedo_color = Color(1.0, 0.82, 0.25, 0.95)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.75, 0.2)
	_mat.emission_energy_multiplier = 4.0
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_torus = TorusMesh.new()
	_torus.inner_radius = 0.2
	_torus.outer_radius = 0.6
	_torus.material = _mat

	_ring = MeshInstance3D.new()
	_ring.mesh = _torus
	add_child(_ring)


func _physics_process(delta: float) -> void:
	current_radius += speed * delta
	if _shape:
		_shape.radius = current_radius

	if _torus:
		_torus.outer_radius = maxf(current_radius, 0.4)
		_torus.inner_radius = maxf(current_radius - 0.5, 0.1)

	if _mat:
		var alpha := clampf(1.0 - (current_radius / max_radius), 0.0, 1.0)
		_mat.albedo_color.a = alpha

	# Dushmanlarga zarar berish va ularni parokanda qilish
	for b in get_overlapping_bodies():
		if b in _hit_enemies:
			continue
		if b.has_method("take_damage"):
			_hit_enemies.append(b)
			b.take_damage(damage, global_position, 12.0)
			FX.sparks(b.global_position + Vector3(0, 1.0, 0), Vector3.UP, Color(1.0, 0.85, 0.25), 18)
			FX.popup(b.global_position + Vector3.UP * 2.2, damage, Color(1.0, 0.8, 0.2))

	if current_radius >= max_radius:
		queue_free()
