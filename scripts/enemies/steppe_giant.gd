class_name SteppeGiant
extends CharacterBody3D
## Dasht Devi (Cho'l / Qoya Devi) - O'zbek mifologiyasidagi ulkan jonzot.
## Xususiyatlari:
## - 4.5 metrli bahaybat tosh tanasi
## - Uzoqdan tosh uloqtirish (Rock Throw)
## - Yaqinda qadam larzasi (Stomp)

enum State { IDLE, CHASE, THROW, STOMP, STAGGER, DEAD }

@export var max_health := 180.0
@export var aggro_range := 30.0
@export var speed := 3.2
@export var gravity := 20.0

var state := State.IDLE
var health := 180.0

var _player: CharacterBody3D
var _timer := 0.0
var _cooldown := 1.5
var _body: MeshInstance3D
var _mat: StandardMaterial3D
var _label: Label3D


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	add_to_group("hurtable")
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1)

	# Dev uchun pog'onalar va toshlardan oshib o'tish
	floor_snap_length = 0.6
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(55.0)
	floor_stop_on_slope = false
	max_slides = 6

	_build_visuals()


func _build_visuals() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.35, 0.38, 0.32) # Tosh va mox rang
	_mat.roughness = 0.9
	_mat.emission_enabled = true
	_mat.emission = Color(0.8, 0.4, 0.1)
	_mat.emission_energy_multiplier = 0.0

	var torso := BoxMesh.new()
	torso.size = Vector3(2.2, 3.2, 1.8)
	torso.material = _mat

	_body = MeshInstance3D.new()
	_body.mesh = torso
	_body.position.y = 2.2
	add_child(_body)

	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(1.2, 1.1, 1.2)
	head_mesh.material = _mat
	head.mesh = head_mesh
	head.position = Vector3(0, 4.2, 0)
	add_child(head)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 4.5, 2.0)
	col.shape = shape
	col.position.y = 2.25
	add_child(col)

	_label = Label3D.new()
	_label.position.y = 5.2
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 44
	add_child(_label)
	_update_label()


func _update_label() -> void:
	if _label == null or not is_instance_valid(_label):
		return
	var pct := clampf(health / max_health, 0.0, 1.0)
	var total_bars := 16
	var filled := int(round(pct * total_bars))
	var empty := total_bars - filled
	var bar_str := "█".repeat(filled) + "░".repeat(empty)
	_label.text = "⚡ Qoyali Dasht Devi [ELITA]\n[%s] %d/%d HP" % [bar_str, int(ceil(health)), int(max_health)]
	if pct > 0.5:
		_label.modulate = Color(1.0, 0.85, 0.3)
	else:
		_label.modulate = Color(1.0, 0.35, 0.25)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	_cooldown -= delta

	if _label and is_instance_valid(_label):
		if state == State.DEAD:
			_label.visible = false
		elif _player and is_instance_valid(_player):
			_label.visible = global_position.distance_to(_player.global_position) < 35.0

	var player_alive: bool = _player != null and _player.get("state") != 4 # State.DEAD
	if state == State.DEAD or _player == null or not player_alive:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		velocity.y -= gravity * delta
		move_and_slide()
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var dir := to_player / dist if dist > 0.01 else Vector3.FORWARD

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
			if dist < aggro_range:
				state = State.CHASE
		State.CHASE:
			_face(dir, delta, 4.0)
			if dist > 6.0:
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
				if _cooldown <= 0.0 and dist < 25.0:
					_start_throw(dir)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
				if _cooldown <= 0.0:
					_start_stomp(dir)
		State.THROW:
			_tick_throw(dir, delta)
		State.STOMP:
			_tick_stomp(dir, delta)
		State.STAGGER:
			_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
			if _timer <= 0.0:
				state = State.CHASE

	velocity.y -= gravity * delta

	# Pog'onalar va qoyalardan sakramasdan chiqish (Step-up assist)
	_apply_step_up(delta, 0.85)

	move_and_slide()


func _apply_step_up(delta: float, max_step_height := 0.85) -> void:
	if not is_on_floor():
		return
	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	if horiz.length_squared() < 0.01:
		return

	var move_step := horiz * delta
	var col_fwd := KinematicCollision3D.new()
	if test_move(global_transform, move_step, col_fwd):
		var wall_norm := col_fwd.get_normal()
		if wall_norm.y < 0.5:
			var up_vec := Vector3(0.0, max_step_height, 0.0)
			if not test_move(global_transform, up_vec):
				var up_xform := global_transform.translated(up_vec)
				if not test_move(up_xform, move_step):
					var col_down := KinematicCollision3D.new()
					if test_move(up_xform.translated(move_step), -up_vec, col_down):
						if col_down.get_normal().y >= 0.5:
							var step_up := max_step_height - col_down.get_travel().length()
							if step_up > 0.005 and step_up <= max_step_height:
								global_position.y += step_up
								apply_floor_snap()



func _start_throw(dir: Vector3) -> void:
	state = State.THROW
	_timer = 0.0
	velocity = Vector3.ZERO


func _tick_throw(dir: Vector3, delta: float) -> void:
	_timer += delta
	_face(dir, delta, 3.0)
	var windup := 0.9

	if _timer < windup:
		var t := _timer / windup
		_mat.emission_energy_multiplier = t * 2.0
	else:
		_mat.emission_energy_multiplier = 0.0
		_throw_rock(dir)
		_cooldown = 2.5
		state = State.CHASE


func _throw_rock(dir: Vector3) -> void:
	var rock := Arrow.new() # Arrow mexanikasidan foydalanib tosh uloqtiradi
	rock.shooter = self
	rock.damage = 18.0
	rock.gravity = 10.0
	rock.hit_mask = 1 | (1 << 1)
	var spawn := global_position + Vector3.UP * 4.0 + dir * 1.5
	var target := _player.global_position + Vector3.UP * 1.0
	rock.velocity = (target - spawn).normalized() * 26.0
	get_tree().current_scene.add_child(rock)
	rock.global_position = spawn


func _start_stomp(dir: Vector3) -> void:
	state = State.STOMP
	_timer = 0.0
	velocity = Vector3.ZERO


func _tick_stomp(dir: Vector3, delta: float) -> void:
	_timer += delta
	_face(dir, delta, 4.0)
	if _timer >= 0.7:
		# Yerga tepish
		var sw := Shockwave.new()
		sw.damage = 14.0
		sw.max_radius = 8.0
		sw.speed = 8.0
		get_tree().current_scene.add_child(sw)
		sw.global_position = global_position + Vector3.UP * 0.1
		FX.dust(global_position, 18, 2.0)
		FX.sparks(global_position + Vector3(0, 0.2, 0), Vector3.UP, Color(0.9, 0.8, 0.4), 16)
		FX.camera_shake(0.4)
		Audio.play_boss_slam()
		_cooldown = 2.0
		state = State.CHASE


func _face(dir: Vector3, delta: float, turn_spd := 4.0) -> void:
	if dir.length() < 0.01:
		return
	var goal := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, goal, 1.0 - exp(-turn_spd * delta))


func take_damage(amount: float, from_pos := Vector3.ZERO, knockback := 2.0) -> void:
	if state == State.DEAD:
		return
	health = maxf(health - amount, 0.0)
	_update_label()
	FX.popup(global_position + Vector3.UP * 4.5, amount)
	FX.sparks(global_position + Vector3.UP * 2.5, Vector3.UP, Color(1.0, 0.6, 0.2), 12)
	_mat.emission_energy_multiplier = 2.0
	create_tween().tween_property(_mat, "emission_energy_multiplier", 0.0, 0.2)
	if health <= 0.0:
		_die()
		return
	if state == State.IDLE:
		state = State.CHASE
	state = State.STAGGER
	_timer = 0.35


func _die() -> void:
	state = State.DEAD
	collision_layer = 0
	remove_from_group("enemies")
	remove_from_group("hurtable")
	_label.visible = false
	FX.dust(global_position, 22, 2.2)
	FX.sparks(global_position + Vector3.UP * 1.5, Vector3.UP, Color(0.8, 0.7, 0.3), 18)
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem and qsystem.has_method("complete_quest"):
		qsystem.complete_quest("giant")
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.has_method("add_xp"):
		prog.add_xp(90)
	var t := create_tween()
	t.tween_property(_body, "rotation:x", -PI / 2.0, 0.6)
	t.parallel().tween_property(_body, "position:y", 0.8, 0.6)
	await get_tree().create_timer(4.0).timeout
	queue_free()


func reset_to_spawn(spawn_pos: Vector3) -> void:
	if state == State.DEAD:
		return
	global_position = spawn_pos
	velocity = Vector3.ZERO
	health = max_health
	state = State.IDLE
	_update_label()
