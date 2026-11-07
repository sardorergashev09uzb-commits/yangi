class_name Shockwave
extends Area3D
## Surxayilning yerga urishidan hosil bo'ladigan kengayuvchi to'lqin.
## O'yinchi sakrab yoki qochib qutulishi kerak.

var speed := 9.0
var max_radius := 9.0
var damage := 20.0
var current_radius := 0.5
var _ring: MeshInstance3D
var _hit_player := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1 # Faqat o'yinchi
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = current_radius
	shape.height = 0.4
	col.shape = shape
	add_child(col)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.3
	torus.outer_radius = 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.1, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.1)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.mesh = torus
	_ring.material_override = mat
	add_child(_ring)

func _physics_process(delta: float) -> void:
	current_radius += speed * delta
	var col_shape := get_node("CollisionShape3D") as CollisionShape3D
	(col_shape.shape as CylinderShape3D).radius = current_radius
	
	var torus := _ring.mesh as TorusMesh
	torus.inner_radius = maxf(current_radius - 0.4, 0.1)
	torus.outer_radius = current_radius
	
	var alpha := 1.0 - (current_radius / max_radius)
	(_ring.material_override as StandardMaterial3D).albedo_color.a = alpha

	if not _hit_player:
		for b in get_overlapping_bodies():
			if b is Player and b.is_on_floor() and not b.invulnerable:
				_hit_player = true
				b.take_damage(damage, global_position, 8.0)
				break

	if current_radius >= max_radius:
		queue_free()
