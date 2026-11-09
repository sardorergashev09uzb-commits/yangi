class_name CoinDrop
extends CharacterBody3D
## Yerga tushadigan tilla tanga (Loot drop). O'yinchi yaqinlashganda magnit kabi tortiladi va olinadi.

@export var value: int = 5

var _player: Node3D = null
var _mesh: MeshInstance3D
var _age: float = 0.0
var _is_collected := false
var _magnet_speed := 4.0

const GRAVITY := 18.0


func _ready() -> void:
	add_to_group("coins")
	collision_layer = 0
	collision_mask = 1 # faqat dunyo zaminiga tushadi

	# 3D Tilla Tanga vizuali
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.16
	cyl.height = 0.04

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.12)
	mat.metallic = 0.92
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.7, 0.1)
	mat.emission_energy_multiplier = 0.6
	cyl.material = mat

	_mesh = MeshInstance3D.new()
	_mesh.mesh = cyl
	_mesh.rotation_degrees.x = 45.0
	add_child(_mesh)

	# Yengil kolliziya shakli (yerga tegib to'xtashi uchun)
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.2
	col.shape = sph
	add_child(col)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > 90.0:
		queue_free()
		return

	if _mesh:
		_mesh.rotate_y(delta * 4.5)

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return

	var p_pos := _player.global_position + Vector3.UP * 0.9
	var dist := global_position.distance_to(p_pos)

	# 1. O'yinchi yaqinlashganda (3.8 metr) magnit tortish kuchi
	if dist < 3.8 and not _is_collected:
		var dir := (p_pos - global_position).normalized()
		_magnet_speed = minf(_magnet_speed + delta * 24.0, 18.0)
		global_position += dir * _magnet_speed * delta

		# 2. O'yinchiga yetib borganda yig'ib olish
		if dist < 0.65:
			_collect()
		return

	# Zaminga tushish harakati
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)

	move_and_slide()


func _collect() -> void:
	if _is_collected:
		return
	_is_collected = true

	if _player and is_instance_valid(_player) and _player.has_method("add_gold"):
		_player.add_gold(value)

	FX.sparks(global_position, Vector3.UP, Color(1.0, 0.85, 0.2), 6)
	queue_free()


## Bir nechta tangalarni qulay sochib chiqarish yordamchisi
static func spawn_coins(tree: SceneTree, pos: Vector3, total_value: int, coin_count := 3) -> void:
	if tree == null or tree.current_scene == null or total_value <= 0:
		return

	var count := clampi(coin_count, 1, 10)
	var base_val := total_value / count
	var rem := total_value % count

	var coin_script = load("res://scripts/world/coin_drop.gd") as GDScript
	for i in range(count):
		var c = coin_script.new()
		c.value = base_val + (1 if i < rem else 0)
		if c.value <= 0:
			continue

		var spread := Vector3(randf_range(-1.8, 1.8), randf_range(2.8, 4.5), randf_range(-1.8, 1.8))
		c.velocity = spread
		tree.current_scene.add_child(c)
		c.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0.2, randf_range(-0.3, 0.3))
