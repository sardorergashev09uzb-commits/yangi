extends Node3D
## Test poligoni, Surxayil Boss arenasi va Boysun Dashti (Boychibor bilan).

const HorseScript = preload("res://scripts/world/horse.gd")
const SteppeGiantScript = preload("res://scripts/enemies/steppe_giant.gd")
const BossSurxayilScript = preload("res://scripts/enemies/boss_surxayil.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const DummyScript = preload("res://scripts/world/dummy.gd")
const TrapScript = preload("res://scripts/world/trap.gd")

var _boss: CharacterBody3D
var _arena_gate: StaticBody3D
var _fight_started := false
var _boss_spawn := Vector3(0, 0, -90)
var _enemy_spawns: Array[Dictionary] = []

var _horse: CharacterBody3D
var _giant: CharacterBody3D
var _giant_spawn := Vector3(38, 0, 48)


func _ready() -> void:
	_build_environment()

	# Yagona yaxlit ulkan Boysun dashti zamini (Z-fighting mutlaqo yo'q)
	_box(Vector3(20, -1.0, 10), Vector3(320, 2.0, 320), Color(0.42, 0.45, 0.28))

	# Mashg'ulot tosh maydoni (Alpomish boshlang'ich mashq o'rni, Y = 0.01 da tosh to'shama)
	_box(Vector3(0, 0.01, -2), Vector3(28, 0.02, 28), Color(0.46, 0.43, 0.38))

	# Arena sari olib boruvchi qadimiy tosh yo'lak
	_box(Vector3(0, 0.01, -38), Vector3(6, 0.02, 44), Color(0.38, 0.36, 0.34))

	# Mashg'ulot to'siqlari va rampasi
	_box(Vector3(6, 0.5, -4), Vector3(3, 1, 3), Color(0.5, 0.45, 0.4))
	_box(Vector3(9, 1.0, -4), Vector3(3, 2, 3), Color(0.5, 0.45, 0.4))
	_box(Vector3(-8, 0.75, -6), Vector3(6, 1.5, 1), Color(0.55, 0.4, 0.35))
	var ramp := _box(Vector3(-6, 0.9, 6), Vector3(5, 0.5, 8), Color(0.5, 0.5, 0.45))
	ramp.rotation_degrees.x = 15

	# Mashg'ulot yog'ochi
	var dummy = DummyScript.new()
	dummy.position = Vector3(8, 0, -2)
	add_child(dummy)

	# Qalmoq soqchilari (yo'l bo'yida)
	_spawn_enemy(EnemyScript.Kind.SWORD, Vector3(-4, 0, -22))
	_spawn_enemy(EnemyScript.Kind.SWORD, Vector3(4, 0, -24))
	_spawn_enemy(EnemyScript.Kind.SPEAR, Vector3(-3, 0, -32))
	_spawn_enemy(EnemyScript.Kind.ARCHER, Vector3(5, 0, -38))

	# Sinov tuzog'i
	var trap = TrapScript.new()
	trap.position = Vector3(5, 0.15, 8)
	add_child(trap)

	# Boychibor tulpori (o'yinchi yonida o'tlab turadi)
	_horse = HorseScript.new()
	_horse.position = Vector3(4.5, 0.1, 3.5)
	add_child(_horse)

	# Katta Boysun Dashti (Janub va Sharq tomonda)
	_build_steppe()

	# Surxayil Boss Arenasi (Shimolda, Z = -60 dan -105 gacha)
	_build_boss_arena()

	# O'yinchi qayta tirilganda arenani tiklash ulanishi
	_connect_player_respawn.call_deferred()


func _build_steppe() -> void:
	# Dashtdagi tabiiy qoyalar va tepaliklar
	_hill(Vector3(20, 1.2, 30), Vector3(14, 2.5, 12))
	_hill(Vector3(60, 2.2, 55), Vector3(24, 4.4, 20))
	_hill(Vector3(35, 1.5, 75), Vector3(18, 3.0, 16))
	_hill(Vector3(-25, 1.4, 45), Vector3(16, 2.8, 14))
	_hill(Vector3(80, 2.5, 20), Vector3(22, 5.0, 18))

	# Qadimiy tosh balballar (qadimgi obidalar)
	for bp in [Vector3(15, 0, 45), Vector3(55, 0, 35), Vector3(40, 0, 75), Vector3(70, 0, 80)]:
		_balbal(bp)

	# Dasht daraxtlari (yulg'un / saksovul)
	for tp in [Vector3(10, 0, 25), Vector3(30, 0, 50), Vector3(50, 0, 20), Vector3(65, 0, 65), Vector3(25, 0, 85)]:
		_tree(tp)

	# Dasht Devi (Qoyali Dev)
	_giant = SteppeGiantScript.new()
	_giant.position = _giant_spawn
	add_child(_giant)


func _hill(pos: Vector3, size: Vector3) -> StaticBody3D:
	var h := _box(pos, size, Color(0.46, 0.44, 0.32))
	h.rotation_degrees.y = randf_range(0, 45)
	return h


func _balbal(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.5
	cyl.height = 3.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.48, 0.44)
	cyl.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.position.y = 1.75
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.55
	shape.height = 3.5
	col.shape = shape
	col.position.y = 1.75
	body.add_child(col)
	add_child(body)


func _connect_player_respawn() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("respawned"):
		player.connect("respawned", _on_player_respawned)


func _on_player_respawned() -> void:
	_fight_started = false

	# Arenadagi darvoza ochiladi
	if _arena_gate:
		var t := create_tween()
		t.tween_property(_arena_gate, "position:y", -6.0, 0.5)

	# Boss tirik bo'lsa, asl joyiga qaytarilib, uxlash holatiga o'tkaziladi
	if _boss and is_instance_valid(_boss) and _boss.has_method("reset_boss"):
		_boss.reset_boss(_boss_spawn)

	# Dasht devi tirik bo'lsa, joyiga qaytadi
	if _giant and is_instance_valid(_giant) and _giant.has_method("reset_to_spawn"):
		_giant.reset_to_spawn(_giant_spawn)

	# Boychibor otdan tushgan bo'lsa, o'yinchi yoniga qaytadi
	if _horse and is_instance_valid(_horse) and not _horse.get("is_mounted"):
		_horse.global_position = Vector3(4.5, 0.1, 3.5)
		_horse.velocity = Vector3.ZERO

	# Tirik qolgan dushmanlar o'z joylariga qaytadi (o'lganlari qayta tug'ilmaydi!)
	for item in _enemy_spawns:
		var raw_node: Variant = item.get("node")
		if is_instance_valid(raw_node):
			var e: Variant = raw_node
			if e != null and not e.is_queued_for_deletion() and e.has_method("reset_to_spawn"):
				e.reset_to_spawn(item.pos)

	# Maydondagi eski to'lqin yoki otilgan o'qlarni tozalash
	for s in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(s):
			s.queue_free()
	for child in get_children():
		if is_instance_valid(child) and child.is_in_group("shockwaves"):
			child.queue_free()


func _spawn_enemy(kind_val: int, pos: Vector3) -> void:
	var e = EnemyScript.new()
	e.kind = kind_val
	e.position = pos
	add_child(e)
	var dict := {"node": e, "pos": pos}
	_enemy_spawns.append(dict)
	e.tree_exited.connect(func(): _enemy_spawns.erase(dict))


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
	_boss = BossSurxayilScript.new()
	_boss.position = _boss_spawn
	add_child(_boss)
	if _boss.has_signal("boss_defeated"):
		_boss.connect("boss_defeated", _on_boss_defeated)

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
	if _fight_started or not body.is_in_group("player") or (_boss and _boss.get("state") == 6): # State.DEAD = 6
		return
	_fight_started = true
	if _boss and _boss.has_method("activate"):
		_boss.activate()

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
	env.fog_density = 0.003
	env.ssao_enabled = true
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)


func _box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
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


func _tree(pos: Vector3, h := 4.0) -> void:
	var trunk := StaticBody3D.new()
	trunk.position = pos
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.35
	cyl.height = h
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.38, 0.25, 0.15)
	tmat.roughness = 0.9
	cyl.material = tmat
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.position.y = h * 0.5
	trunk.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = h
	col.shape = shape
	col.position.y = h * 0.5
	trunk.add_child(col)

	var crown := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 1.4
	sph.height = 2.4
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.24, 0.35, 0.20)
	cmat.roughness = 0.85
	sph.material = cmat
	crown.mesh = sph
	crown.position.y = h + 0.6
	trunk.add_child(crown)
	add_child(trunk)
