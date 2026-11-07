extends Node3D
## Test poligoni va Surxayil Boss arenasi.

var _boss: BossSurxayil
var _arena_gate: StaticBody3D
var _fight_started := false
var _boss_spawn := Vector3(0, 0, -90)
var _enemy_spawns: Array[Dictionary] = []


func _ready() -> void:
	_build_environment()
	# Asosiy maydon yeri
	_box(Vector3(0, -0.5, -35), Vector3(100, 1, 150), Color(0.45, 0.38, 0.28))

	# Mashg'ulot to'siqlari va rampasi
	_box(Vector3(6, 0.5, -4), Vector3(3, 1, 3), Color(0.5, 0.45, 0.4))
	_box(Vector3(9, 1.0, -4), Vector3(3, 2, 3), Color(0.5, 0.45, 0.4))
	_box(Vector3(-8, 0.75, -6), Vector3(6, 1.5, 1), Color(0.55, 0.4, 0.35))
	var ramp := _box(Vector3(-6, 0.9, 6), Vector3(5, 0.5, 8), Color(0.5, 0.5, 0.45))
	ramp.rotation_degrees.x = 15

	# Mashg'ulot yog'ochi (burchakda, dushmanga xalaqit bermaydi)
	var dummy := Dummy.new()
	dummy.position = Vector3(8, 0, -2)
	add_child(dummy)

	# Qalmoq soqchilari (yo'l bo'yida)
	_spawn_enemy(Enemy.Kind.SWORD, Vector3(-4, 0, -22))
	_spawn_enemy(Enemy.Kind.SWORD, Vector3(4, 0, -24))
	_spawn_enemy(Enemy.Kind.SPEAR, Vector3(-3, 0, -32))
	_spawn_enemy(Enemy.Kind.ARCHER, Vector3(5, 0, -38))

	# Sinov tuzog'i
	var trap := Trap.new()
	trap.position = Vector3(5, 0.15, 8)
	add_child(trap)

	# Surxayil Boss Arenasi (Shimolda, Z = -60 dan -105 gacha)
	_build_boss_arena()

	# O'yinchi qayta tirilganda arenani tiklash ulanishi
	_connect_player_respawn.call_deferred()


func _connect_player_respawn() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.respawned.connect(_on_player_respawned)


func _on_player_respawned() -> void:
	_fight_started = false

	# Arenadagi darvoza ochiladi
	if _arena_gate:
		var t := create_tween()
		t.tween_property(_arena_gate, "position:y", -6.0, 0.5)

	# Boss tirik bo'lsa, asl joyiga qaytarilib, uxlash holatiga o'tkaziladi
	if _boss and is_instance_valid(_boss):
		_boss.reset_boss(_boss_spawn)

	# Tirik qolgan dushmanlar o'z joylariga qaytadi (o'lganlari qayta tug'ilmaydi!)
	for item in _enemy_spawns:
		var e: Enemy = item.node
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			e.reset_to_spawn(item.pos)

	# Maydondagi eski to'lqin yoki otilgan o'qlarni tozalash
	for s in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(s):
			s.queue_free()
	for child in get_children():
		if child is Shockwave:
			child.queue_free()


func _spawn_enemy(kind: Enemy.Kind, pos: Vector3) -> void:
	var e := Enemy.new()
	e.kind = kind
	e.position = pos
	add_child(e)
	_enemy_spawns.append({"node": e, "pos": pos})


func _build_boss_arena() -> void:
	var arena_center := Vector3(0, 0, -82)
	# Arena tosh poydevori
	_box(arena_center + Vector3(0, 0.05, 0), Vector3(46, 0.3, 46), Color(0.32, 0.3, 0.35))

	# Atrof tosh devorlari
	_box(arena_center + Vector3(0, 3, -23), Vector3(46, 6, 2), Color(0.25, 0.24, 0.28))
	_box(arena_center + Vector3(-23, 3, 0), Vector3(2, 6, 46), Color(0.25, 0.24, 0.28))
	_box(arena_center + Vector3(23, 3, 0), Vector3(2, 6, 46), Color(0.25, 0.24, 0.28))

	# Janubiy kirish devori
	_box(arena_center + Vector3(-15, 3, 23), Vector3(16, 6, 2), Color(0.25, 0.24, 0.28))
	_box(arena_center + Vector3(15, 3, 23), Vector3(16, 6, 2), Color(0.25, 0.24, 0.28))

	# Arena ustunlari
	for ox in [-14.0, 14.0]:
		for oz in [-14.0, 14.0]:
			_pillar(arena_center + Vector3(ox, 0, oz))

	# Darvoza
	_arena_gate = _box(arena_center + Vector3(0, -6, 23), Vector3(14, 6, 1.5), Color(0.18, 0.12, 0.1))

	# Surxayil Alp bossi
	_boss_spawn = arena_center + Vector3(0, 0, -8)
	_boss = BossSurxayil.new()
	_boss.position = _boss_spawn
	add_child(_boss)
	_boss.boss_defeated.connect(_on_boss_defeated)

	# Kirish triggeri
	var trigger := Area3D.new()
	trigger.position = arena_center + Vector3(0, 1.5, 18)
	trigger.collision_layer = 0
	trigger.collision_mask = 1 << 1
	var shape := BoxShape3D.new()
	shape.size = Vector3(18, 4, 6)
	var col := CollisionShape3D.new()
	col.shape = shape
	trigger.add_child(col)
	trigger.body_entered.connect(_on_player_entered_arena)
	add_child(trigger)


func _on_player_entered_arena(body: Node3D) -> void:
	if _fight_started or not body is Player or (_boss and _boss.state == BossSurxayil.State.DEAD):
		return
	_fight_started = true
	_boss.activate()

	# Darvoza ko'tarilib yo'lni to'sadi
	var t := create_tween()
	t.tween_property(_arena_gate, "position:y", 3.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_boss_defeated() -> void:
	var t := create_tween()
	t.tween_property(_arena_gate, "position:y", -6.0, 1.2)


func _pillar(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.1
	cyl.height = 6.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.35, 0.33)
	cyl.material = mat

	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.position.y = 3.0
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.05
	shape.height = 6.0
	col.shape = shape
	col.position.y = 3.0
	body.add_child(col)
	add_child(body)


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.4, 0.65)
	sky_mat.sky_horizon_color = Color(0.85, 0.7, 0.5)
	sky_mat.ground_horizon_color = Color(0.85, 0.7, 0.5)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.72, 0.55)
	env.fog_density = 0.004
	env.ssao_enabled = true
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)


func _box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	mesh_inst.mesh = mesh
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(mesh_inst)
	body.add_child(col)
	add_child(body)
	return body
