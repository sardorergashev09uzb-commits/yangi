extends Node3D
## Test poligoni, Surxayil Boss arenasi va Boysun Dashti (Boychibor bilan).

const HorseScript = preload("res://scripts/world/horse.gd")
const SteppeGiantScript = preload("res://scripts/enemies/steppe_giant.gd")
const BossSurxayilScript = preload("res://scripts/enemies/boss_surxayil.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const DummyScript = preload("res://scripts/world/dummy.gd")
const TrapScript = preload("res://scripts/world/trap.gd")
const YurtScript = preload("res://scripts/world/yurt.gd")
const NPCScript = preload("res://scripts/world/npc.gd")
const DialogBoxScript = preload("res://scripts/story/dialog_box.gd")
const QuestSystemScript = preload("res://scripts/story/quest_system.gd")
const ProgressionScript = preload("res://scripts/player/progression.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const MainMenuScript = preload("res://scripts/ui/main_menu.gd")

var _boss: CharacterBody3D
var _arena_gate: StaticBody3D
var _fight_started := false
var _boss_defeated_flag := false
var _lever_label: Label3D
var _boss_spawn := Vector3(0, 0, -90)
var _enemy_spawns: Array[Dictionary] = []

var _horse: CharacterBody3D
var _giant: CharacterBody3D
var _giant_spawn := Vector3(38, 0, 48)


func _ready() -> void:
	_build_environment()

	# RPG Rivojlanish va Pauza / Ko'nikmalar menyusi
	var prog = ProgressionScript.new()
	add_child(prog)

	var pause_menu = PauseMenuScript.new()
	add_child(pause_menu)

	# Kvest va Dialog tizimi
	var qsystem = QuestSystemScript.new()
	add_child(qsystem)

	var dbox = DialogBoxScript.new()
	dbox.add_to_group("dialog_box")
	add_child(dbox)

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

	# Boysun elining o'tovlari va Qultoy Cho'pon manzilgohi
	_build_yurt_village()

	# Boychibor tulpori (o'yinchi va o'tov yonida o'tlab turadi)
	_horse = HorseScript.new()
	_horse.position = Vector3(6.0, 0.1, 4.0)
	add_child(_horse)

	# Katta Boysun Dashti (Janub va Sharq tomonda)
	_build_steppe()

	# Surxayil Boss Arenasi (Shimolda, Z = -60 dan -105 gacha)
	_build_boss_arena()

	# O'yinchi qayta tirilganda arenani tiklash ulanishi
	_connect_player_respawn.call_deferred()

	# Bosh menyu (headless sinovlarda o'tkazib yuboriladi)
	if DisplayServer.get_name() != "headless":
		add_child(MainMenuScript.new())


func _build_yurt_village() -> void:
	# 1. Asosiy katta o'tov
	var main_yurt = YurtScript.new()
	main_yurt.position = Vector3(18, 0, 16)
	add_child(main_yurt)

	# Qultoy Cho'pon (Alpomishning sodiq do'sti va oqsoqol)
	var qultoy = NPCScript.new()
	qultoy.character_type = NPCScript.CharacterType.QULTOY
	qultoy.character_name = "Qultoy Cho'pon"
	qultoy.position = Vector3(18, 0, 21.2)
	qultoy.rotation_degrees.y = 180.0
	add_child(qultoy)

	# 2. Qo'shni o'tov
	var side_yurt = YurtScript.new()
	side_yurt.position = Vector3(32, 0, 18)
	side_yurt.scale = Vector3(0.85, 0.85, 0.85)
	add_child(side_yurt)

	# 3. Qo'ng'irot tug'i (Ko'k bayroq)
	var pole := StaticBody3D.new()
	pole.position = Vector3(13, 0, 14)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.06
	cyl.height = 4.5
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.3, 0.2, 0.1)
	cyl.material = pmat
	var pmi := MeshInstance3D.new()
	pmi.mesh = cyl
	pmi.position.y = 2.25
	pole.add_child(pmi)

	var flag := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(0.04, 0.8, 1.3)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.15, 0.35, 0.75) # Ko'k bayroq
	flag.mesh = fbox
	flag.material_override = fmat
	flag.position = Vector3(0, 3.8, 0.65)
	pole.add_child(flag)
	add_child(pole)


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

	# Darvozani tushirish uchun ichki tosh richag (qamalib qolmaslik uchun)
	_build_gate_lever(arena_center + Vector3(7.5, 0.0, 21.0))


func _build_gate_lever(pos: Vector3) -> void:
	var pillar := _box(pos, Vector3(0.6, 1.1, 0.6), Color(0.42, 0.38, 0.32))
	_lever_label = Label3D.new()
	_lever_label.text = "[ E ] - Darvozani tushirish"
	_lever_label.font_size = 32
	_lever_label.modulate = Color(1.0, 0.85, 0.25)
	_lever_label.position = Vector3(0, 1.4, 0)
	_lever_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lever_label.no_depth_test = true
	_lever_label.visible = false
	pillar.add_child(_lever_label)


func _process(_delta: float) -> void:
	# Agar boss o'lgan bo'lsa, darvoza doimo ochiq qoladi
	if _boss_defeated_flag and _arena_gate and _arena_gate.position.y > -5.0:
		_arena_gate.position.y = -6.0

	# Darvoza oldidagi richag bilan o'zaro ta'sir (E)
	var player = get_tree().get_first_node_in_group("player")
	if player and _lever_label and is_instance_valid(_lever_label):
		var d: float = player.global_position.distance_to(_lever_label.global_position)
		_lever_label.visible = d < 4.0 and _arena_gate and _arena_gate.position.y > -4.0
		if d < 4.0 and Input.is_action_just_pressed("interact"):
			_open_gate()


func _open_gate() -> void:
	if _arena_gate:
		var t := create_tween()
		t.tween_property(_arena_gate, "position:y", -6.0, 0.8)
		if _lever_label:
			_lever_label.visible = false


func _on_player_entered_arena(body: Node3D) -> void:
	# Agar boss tashqaridan otib o'ldirilgan bo'lsa, yoki allqachon o'lgan bo'lsa (State.DEAD = 7), darvoza yopilmaydi!
	if _boss_defeated_flag or _fight_started or not body.is_in_group("player"):
		return
	if _boss == null or not is_instance_valid(_boss) or _boss.get("state") == 7: # State.DEAD = 7
		return
	_fight_started = true
	if _boss and _boss.has_method("activate"):
		_boss.activate()

	var t := create_tween()
	t.tween_property(_arena_gate, "position:y", 3.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_boss_defeated() -> void:
	_boss_defeated_flag = true
	_fight_started = false
	if _arena_gate:
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
