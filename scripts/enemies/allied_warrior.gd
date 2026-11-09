class_name AlliedWarrior
extends CharacterBody3D
## 9-bosqich: Do'stlashgan Qo'ng'irot va Karajon alp-botirlari (Allied Siege Warriors).
## Alpomish bilan birga Qalmoq qal'asi qamalida yelkama-yelka jang qiladi.

enum State { IDLE, CHASE, ATTACK, CHEER, DEAD }

@export var max_health := 180.0
var health: float
var attack_damage := 20.0
var move_speed := 5.2
var state: State = State.IDLE

var _target: Node3D
var _attack_timer := 0.0
var _anim_timer := 0.0
var _sword_mesh: MeshInstance3D
var _hp_bar: Sprite3D


func _ready() -> void:
	health = max_health
	add_to_group("allies")
	add_to_group("hurtable")
	_build_visuals()


func _build_visuals() -> void:
	# Gavda (Ko'k choponli botir)
	var body_mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.7
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.12, 0.35, 0.75) # Qo'ng'irot ko'k matosi
	cmat.roughness = 0.8
	cap.material = cmat
	body_mi.mesh = cap
	body_mi.position.y = 0.85
	add_child(body_mi)

	# Temir dubulg'a
	var helmet := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.3
	sph.height = 0.5
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.7, 0.72, 0.75)
	hmat.metallic = 0.85
	sph.material = hmat
	helmet.mesh = sph
	helmet.position.y = 1.65
	add_child(helmet)

	# Qalqon (Chap qo'lda ko'k tamg'ali qalqon)
	var shield := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.4
	scyl.bottom_radius = 0.4
	scyl.height = 0.08
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.15, 0.4, 0.8)
	scyl.material = smat
	shield.mesh = scyl
	shield.rotation_degrees.z = 90.0
	shield.position = Vector3(-0.55, 0.95, 0.1)
	add_child(shield)

	# Qilich (O'ng qo'lda po'lat qilich)
	_sword_mesh = MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(0.08, 0.9, 0.08)
	var swmat := StandardMaterial3D.new()
	swmat.albedo_color = Color(0.9, 0.92, 0.95)
	swmat.metallic = 0.9
	sbox.material = swmat
	_sword_mesh.mesh = sbox
	_sword_mesh.position = Vector3(0.55, 0.95, 0.2)
	add_child(_sword_mesh)

	# Kolliziya
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if state == State.CHEER:
		_anim_timer += delta * 6.0
		if _sword_mesh:
			_sword_mesh.position.y = 1.4 + sin(_anim_timer) * 0.25
			_sword_mesh.rotation_degrees.x = 45.0
		return

	_attack_timer -= delta

	# Dushmanni qidirish
	if _target == null or not is_instance_valid(_target) or (_target.has_method("is_dead") and _target.is_dead()):
		_find_nearest_enemy()

	if _target and is_instance_valid(_target):
		var diff := _target.global_position - global_position
		diff.y = 0.0
		var dist := diff.length()

		if dist > 2.2:
			state = State.CHASE
			var dir := diff.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			look_at(global_position + dir, Vector3.UP)
		else:
			state = State.ATTACK
			velocity.x = 0.0
			velocity.z = 0.0
			if _attack_timer <= 0.0:
				_execute_attack()
				_attack_timer = 1.2
	else:
		state = State.IDLE
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func _find_nearest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var min_d := 45.0

	for e in enemies:
		if e is Node3D and is_instance_valid(e):
			var d := global_position.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				nearest = e

	_target = nearest


func _execute_attack() -> void:
	if _target and is_instance_valid(_target):
		FX.slash_arc(global_position + Vector3.UP * 0.9, rotation, Color(0.3, 0.7, 1.0, 0.85), 1.1)
		Audio.play_sword_swing()
		if _target.has_method("take_damage"):
			_target.take_damage(attack_damage, global_position)


func take_damage(amount: float, from_pos: Vector3, _knockback := 3.0) -> void:
	if state == State.DEAD:
		return
	health -= amount
	FX.impact_burst(global_position + Vector3.UP * 0.9, Color(0.8, 0.1, 0.1), 10)
	FX.popup(global_position + Vector3.UP * 1.6, amount, Color(1.0, 0.3, 0.3))
	Audio.play_hit()

	if health <= 0.0:
		die()


func die() -> void:
	state = State.DEAD
	collision_layer = 0
	collision_mask = 0
	FX.dust(global_position, 12, 1.2)
	queue_free()


func cheer() -> void:
	state = State.CHEER
	velocity = Vector3.ZERO
