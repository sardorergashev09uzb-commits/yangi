class_name DragonFireball
extends Area3D
## Yetti Boshli Qora Ajdahoning otadigan olovli snaryadi (Explosive Fireball).
## Tegishi bilan portlaydi, yerga olov sachratadi va zarba to'lqini hosil qiladi.

var velocity := Vector3.ZERO
var damage := 24.0
var max_lifetime := 5.0
var _timer := 0.0
var _trail_timer := 0.0


func _ready() -> void:
	collision_layer = 1 << 4 # enemy hitbox
	collision_mask = 1 | (1 << 1) # world and player
	add_to_group("projectiles")

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	col.shape = shape
	add_child(col)

	# Nurlanuvchi olov shari (Emissive glowing sphere)
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.45
	sph.height = 0.9
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.45, 0.1)
	mi.mesh = sph
	mi.material_override = mat
	add_child(mi)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_timer += delta

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.08
		FX.sparks(global_position, -velocity.normalized(), Color(1.0, 0.6, 0.15), 3)

	if _timer >= max_lifetime:
		_explode()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("bosses") or body.is_in_group("enemies"):
		return
	_explode()


func _explode() -> void:
	FX.impact_burst(global_position, Color(1.0, 0.4, 0.05), 24)
	FX.shockwave_ring(global_position, 4.0, Color(1.0, 0.55, 0.15, 0.85), 0.35)
	Audio.play_heavy_hit()
	FX.camera_shake(0.35)

	# Splash damage: 4 metr radiusdagi o'yinchiga zarar berish
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player.has_method("take_damage"):
		var d := global_position.distance_to(player.global_position)
		if d <= 4.0:
			player.take_damage(damage, global_position, 8.0)

	queue_free()
