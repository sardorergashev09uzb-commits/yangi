class_name SiegeCatapultRock
extends Area3D
## 9-bosqich: Qamal Katapultasining Olovli Tosh Snaryadi (Siege Catapult Rock).
## Qal'a qo'rg'onidan o'yinchilar va botirlar ustiga tushuvchi portlovchi qoya bo'lagi.

@export var damage := 35.0
@export var blast_radius := 4.5

var _target_pos: Vector3
var _timer := 0.0
var _land_time := 1.4
var _mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = (1 << 1) | (1 << 2) # Player va dushmanlar
	add_to_group("catapult_rocks")

	# Olovli tosh modeli
	_mesh = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.65
	sph.height = 1.3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.15, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.05)
	mat.emission_energy_multiplier = 3.5
	sph.material = mat
	_mesh.mesh = sph
	add_child(_mesh)


func launch(target: Vector3) -> void:
	_target_pos = target
	global_position = target + Vector3(randf_range(-4, 4), 22.0, randf_range(-4, 4))
	# Yerda ogohlantiruvchi qizil halqa
	FX.shockwave_ring(_target_pos + Vector3.UP * 0.05, blast_radius, Color(1.0, 0.2, 0.1, 0.8), _land_time)


func _physics_process(delta: float) -> void:
	_timer += delta
	var progress := clampf(_timer / _land_time, 0.0, 1.0)

	global_position = global_position.lerp(_target_pos, progress)
	if _mesh:
		_mesh.rotate_x(5.0 * delta)
		_mesh.rotate_y(3.0 * delta)

	if progress >= 1.0:
		_explode()


func _explode() -> void:
	Audio.play_heavy_hit()
	FX.impact_burst(global_position + Vector3.UP * 0.3, Color(1.0, 0.4, 0.05), 26)
	FX.shockwave_ring(global_position + Vector3.UP * 0.1, blast_radius, Color(1.0, 0.5, 0.1, 0.9), 0.45)
	FX.camera_shake(0.4)

	# Blast radius zarari
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			var d := global_position.distance_to(body.global_position)
			if d <= blast_radius:
				var falloff := 1.0 - (d / blast_radius)
				body.take_damage(damage * falloff, global_position)

	queue_free()
