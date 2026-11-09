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
const DungeonGateScript = preload("res://scripts/world/dungeon_gate.gd")
const DungeonAreaScript = preload("res://scripts/world/dungeon_area.gd")
const DayNightCycleScript = preload("res://scripts/world/day_night_cycle.gd")
const MainMenuScript = preload("res://scripts/ui/main_menu.gd")
const TreasureChestScript = preload("res://scripts/world/treasure_chest.gd")
const ShopMenuScript = preload("res://scripts/ui/shop_menu.gd")
const CraftingMenuScript = preload("res://scripts/ui/crafting_menu.gd")
const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")
const CamelCaravanScript = preload("res://scripts/world/camel_caravan.gd")
const BanditChiefScript = preload("res://scripts/enemies/bandit_chief.gd")

var _boss: CharacterBody3D
var _dungeon_gate: StaticBody3D
var _dungeon_area: Node3D
var _arena_gate: StaticBody3D
var _fight_started := false
var _boss_defeated_flag := false
var _lever_label: Label3D
var _boss_spawn := Vector3(0, 0, -90)
var _enemy_spawns: Array[Dictionary] = []

var _horse: CharacterBody3D
var _giant: CharacterBody3D
var _giant_spawn := Vector3(38, 0, 48)
var _caravan: Node3D
var _bandit_chief: CharacterBody3D


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

	# Savdo va Do'kon tizimi
	var shop_menu := ShopMenuScript.new()
	shop_menu.add_to_group("shop_menu")
	add_child(shop_menu)

	# Hunarmandchilik Menyusi [ V ]
	var craft_menu := CraftingMenuScript.new()
	craft_menu.add_to_group("crafting_menu")
	add_child(craft_menu)

	# Yagona yaxlit ulkan Boysun dashti zamini: Shimoldagi Zindon va Qal'agacha to'liq cho'zilgan
	_box(Vector3(0, -1.0, -50), Vector3(500, 2.0, 500), Color(0.42, 0.45, 0.28))

	# Mutlaq xavfsizlik to'shagi (Safety Net Floor) - xarita ostida hech narsa cheksizlikka qulab ketmasligi uchun
	_box(Vector3(0, -2.5, -50), Vector3(600, 1.0, 600), Color(0.2, 0.2, 0.2))

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

	# Chorsu Bozori (Usta Temirchi va Savdogar Karvonboshi)
	_build_chorsu_market()

	# Boychibor tulpori (o'yinchi va o'tov yonida o'tlab turadi)
	_horse = HorseScript.new()
	_horse.position = Vector3(6.0, 0.1, 4.0)
	add_child(_horse)

	# Katta Boysun Dashti (Janub va Sharq tomonda)
	_build_steppe()

	# Surxayil Boss Arenasi (Shimolda, Z = -60 dan -105 gacha)
	_build_boss_arena()

	# Qadimiy xazina sandiqlari (Loot & Economy)
	_build_treasure_chests()

	# Tabiiy resurslar (Temir rudasi, Qora saksovul, Shifobaxsh giyohlar)
	_build_resource_nodes()

	# Buyuk Ipak Yo'li tuyalar karvoni
	_build_camel_caravan()

	# Sahro Qaroqchilari Istehkomi (Bandit Outpost)
	_build_bandit_outpost()

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


func _build_chorsu_market() -> void:
	# Chorsu bozori maydonchasi (Stone plaza base & red carpet)
	_box(Vector3(28.0, 0.015, 8.0), Vector3(18.0, 0.02, 12.0), Color(0.48, 0.44, 0.38))
	_box(Vector3(28.0, 0.025, 8.0), Vector3(16.0, 0.01, 3.0), Color(0.65, 0.22, 0.18))

	# 1. Usta Temirchi ustaxonasi (Blacksmith forge & anvil)
	# Tosh pech (Forge furnace)
	_box(Vector3(21.0, 0.9, 5.5), Vector3(2.4, 1.8, 2.0), Color(0.28, 0.26, 0.25))
	# Qizigan ko'mir (Glowing embers)
	_box(Vector3(21.0, 0.7, 6.2), Vector3(1.4, 0.4, 0.8), Color(0.95, 0.35, 0.1))
	# Mo'ri (Chimney)
	_box(Vector3(21.0, 2.4, 5.5), Vector3(1.0, 1.4, 1.0), Color(0.22, 0.20, 0.20))
	# Olov nuri (Forge fire light)
	var forge_light := OmniLight3D.new()
	forge_light.position = Vector3(21.0, 1.2, 6.5)
	forge_light.light_color = Color(1.0, 0.45, 0.15)
	forge_light.light_energy = 2.2
	forge_light.omni_range = 7.0
	add_child(forge_light)

	# Sanddon (Anvil on tree stump)
	_box(Vector3(22.8, 0.35, 7.2), Vector3(0.65, 0.7, 0.65), Color(0.42, 0.28, 0.18))
	_box(Vector3(22.8, 0.75, 7.2), Vector3(0.45, 0.2, 0.85), Color(0.18, 0.20, 0.22))
	_box(Vector3(22.8, 0.8, 6.6), Vector3(0.2, 0.1, 0.4), Color(0.22, 0.24, 0.26))

	# Qurol rastasi (Weapon rack with props)
	_box(Vector3(24.5, 0.8, 5.5), Vector3(0.2, 1.6, 1.8), Color(0.38, 0.25, 0.15))
	_box(Vector3(24.4, 0.8, 5.5), Vector3(0.05, 1.2, 0.3), Color(0.7, 0.75, 0.8))

	# Usta Temirchi NPC
	var blacksmith = NPCScript.new()
	blacksmith.character_type = NPCScript.CharacterType.BLACKSMITH
	blacksmith.character_name = "Usta Temirchi"
	blacksmith.position = Vector3(22.8, 0.0, 8.6)
	blacksmith.rotation_degrees.y = 180.0
	add_child(blacksmith)

	# 2. Savdogar Karvonboshi rastasi (Merchant stall & canopy)
	# Yog'och peshtaxta (Wooden stall counter)
	_box(Vector3(33.0, 0.45, 6.5), Vector3(3.2, 0.9, 1.2), Color(0.45, 0.30, 0.16))

	# Soya-bon ustunlari (Canopy posts)
	_box(Vector3(31.5, 1.3, 5.8), Vector3(0.12, 2.6, 0.12), Color(0.35, 0.22, 0.12))
	_box(Vector3(34.5, 1.3, 5.8), Vector3(0.12, 2.6, 0.12), Color(0.35, 0.22, 0.12))
	_box(Vector3(31.5, 1.15, 7.2), Vector3(0.12, 2.3, 0.12), Color(0.35, 0.22, 0.12))
	_box(Vector3(34.5, 1.15, 7.2), Vector3(0.12, 2.3, 0.12), Color(0.35, 0.22, 0.12))

	# Shohi chodir soyaboni (Canopy silk roof)
	var canopy := _box(Vector3(33.0, 2.45, 6.5), Vector3(3.6, 0.08, 2.0), Color(0.8, 0.18, 0.18))
	canopy.rotation_degrees.x = 10.0

	# Peshtaxtadagi mollar (Qimiz ko'zasi, malham idishi, taqa)
	_box(Vector3(32.2, 1.05, 6.5), Vector3(0.3, 0.4, 0.3), Color(0.75, 0.55, 0.35))
	_box(Vector3(33.0, 0.98, 6.5), Vector3(0.35, 0.15, 0.35), Color(0.3, 0.6, 0.35))
	_box(Vector3(33.8, 0.95, 6.5), Vector3(0.25, 0.08, 0.25), Color(0.95, 0.8, 0.2))

	# Savdo qutilari va bochkalar (Crates & barrels)
	_box(Vector3(31.6, 0.45, 5.0), Vector3(0.9, 0.9, 0.9), Color(0.5, 0.36, 0.22))
	_box(Vector3(34.0, 0.4, 5.0), Vector3(1.1, 0.8, 1.0), Color(0.48, 0.34, 0.20))
	_box(Vector3(31.6, 1.15, 5.0), Vector3(0.7, 0.6, 0.7), Color(0.52, 0.38, 0.24))

	# Savdogar Karvonboshi NPC
	var merchant = NPCScript.new()
	merchant.character_type = NPCScript.CharacterType.MERCHANT
	merchant.character_name = "Savdogar Karvonboshi"
	merchant.position = Vector3(33.0, 0.0, 8.5)
	merchant.rotation_degrees.y = 180.0
	add_child(merchant)


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
	# Kirish va chiqishdagi silliq pandus / nishabliklar (Ot va aravada to'siqsiz kirish uchun)
	var ramp_south := _box(arena_center + Vector3(0, 0.07, 24.2), Vector3(14, 0.15, 2.8), Color(0.35, 0.33, 0.38))
	ramp_south.rotation_degrees.x = -3.5
	var ramp_north := _box(arena_center + Vector3(0, 0.12, -23.5), Vector3(14, 0.15, 2.5), Color(0.30, 0.28, 0.32))
	ramp_north.rotation_degrees.x = 3.5

	# Atrof tosh devorlari
	# Shimoliy devor: Zindon Darvozasiga o'tish yo'li (12 metr kenglikdagi mustahkam arkada)
	_box(arena_center + Vector3(-17, 3, -23), Vector3(12, 6, 2), Color(0.25, 0.24, 0.28))
	_box(arena_center + Vector3(17, 3, -23), Vector3(12, 6, 2), Color(0.25, 0.24, 0.28))
	_box(arena_center + Vector3(0, 6.5, -23), Vector3(14, 1, 2), Color(0.25, 0.24, 0.28))
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

	# Arena ortidagi mustahkam tosh ko'prik yo'lak (Zindon darvozasiga va zindonga to'g'ridan-to'g'ri olib boruvchi yo'l)
	_box(Vector3(0, 0.05, -127), Vector3(16, 0.4, 46), Color(0.26, 0.24, 0.27))
	# Yon devorlar (parapetlar - ot yoki o'yinchi hech qachon chetga tushib ketmaydi)
	_box(Vector3(-8.2, 0.8, -127), Vector3(0.6, 1.5, 46), Color(0.32, 0.3, 0.33))
	_box(Vector3(8.2, 0.8, -127), Vector3(0.6, 1.5, 46), Color(0.32, 0.3, 0.33))

	# 11-bosqich: Shimoliy devordagi Qalmoq Zindoni Darvozasi (Qora Temir Eshik)
	_dungeon_gate = DungeonGateScript.new()
	_dungeon_gate.position = arena_center + Vector3(0, 0, -23)
	add_child(_dungeon_gate)
	_dungeon_gate.portal_entered.connect(_on_dungeon_portal_entered)

	# Zindon ichki maydoni (Shimolda, Z = -150 da alohida qal'a)
	_dungeon_area = DungeonAreaScript.new()
	_dungeon_area.position = Vector3(0, 0, -150)
	add_child(_dungeon_area)


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

	# Global xavfsizlik nazorati: o'yinchi yoki ot xaritadan pastga tushib ketsa
	_check_void_safety()


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
	# Boss qayerda o'lishidan qat'iy nazar ikkala darvoza to'liq ochiladi
	if _arena_gate:
		var t := create_tween()
		t.tween_property(_arena_gate, "position:y", -6.0, 0.8)
	if _dungeon_gate and is_instance_valid(_dungeon_gate):
		_dungeon_gate.unlock()
	var qsys = get_tree().get_first_node_in_group("quest_system")
	if qsys and qsys.has_method("emit_signal"):
		qsys.banner_requested.emit("ZINDON DARVOZASI OCHILDI!", "Shimoldagi portal orqali Barchinoy va Karajon huzuriga o'ting!")


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
	sky_mat.sky_top_color = Color(0.2, 0.45, 0.75)
	sky_mat.sky_horizon_color = Color(0.85, 0.75, 0.6)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	sky_mat.sun_angle_max = 30.0

	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05

	# Realistik tuman (Volumetric-like atmosferik fog)
	env.fog_enabled = true
	env.fog_light_color = Color(0.82, 0.76, 0.68)
	env.fog_density = 0.0025
	env.fog_aerial_perspective = 0.5

	# Zamonaviy post-processing: SSAO, Glow va rang jozibadorligi
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.15

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color(1.0, 0.94, 0.84)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	sun.directional_shadow_blend_splits = true
	add_child(sun)

	# 12-bosqich: Dinamik Kun/Tun aylanishini boshlash
	var cycle := DayNightCycleScript.new()
	add_child(cycle)
	cycle.setup(sun, env, sky_mat)


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

func _on_dungeon_portal_entered() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var target_pos := Vector3(0, 0.2, -135)
		if player.get("is_mounted") and player.get("mounted_horse"):
			var horse: CharacterBody3D = player.get("mounted_horse")
			if is_instance_valid(horse):
				horse.global_position = target_pos
				horse.velocity = Vector3.ZERO
			player.global_position = target_pos + Vector3.UP * 1.5
			player.velocity = Vector3.ZERO
		else:
			player.global_position = target_pos
			player.velocity = Vector3.ZERO
		Audio.play_level_up()
		FX.popup(target_pos + Vector3.UP * 2.5, 0.0, Color(0.9, 0.2, 0.5))


func _check_void_safety() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player.global_position.y < -3.0:
		var safe_p := Vector3(0, 0.5, 0)
		player.global_position = safe_p
		player.velocity = Vector3.ZERO
		if player.get("is_mounted") and player.get("mounted_horse"):
			var h = player.get("mounted_horse")
			if is_instance_valid(h):
				h.global_position = safe_p
				h.velocity = Vector3.ZERO
	if _horse and is_instance_valid(_horse) and _horse.global_position.y < -3.0:
		_horse.global_position = Vector3(6.0, 0.5, 4.0)
		_horse.velocity = Vector3.ZERO


func _build_treasure_chests() -> void:
	# 1. Mashg'ulot tosh maydoni sandig'i
	_spawn_chest("chest_training", Vector3(11.0, 0.0, -5.0), 35, 15.0)

	# 2. Qultoy o'tovi orqasidagi sandiq
	_spawn_chest("chest_yurt", Vector3(22.0, 0.0, 12.0), 45, -45.0)

	# 3. Dasht qoyalari xazinasi
	_spawn_chest("chest_steppe", Vector3(36.0, 0.0, 34.0), 60, 30.0)

	# 4. Surxayil Arenasi darvozasi oldi
	_spawn_chest("chest_arena", Vector3(-11.0, 0.0, -56.0), 75, -90.0)

	# 5. Zindon ko'prigi boshidagi qo'riqchilar sandig'i
	_spawn_chest("chest_bridge", Vector3(6.5, 0.25, -110.0), 90, 180.0)


func _spawn_chest(id: String, pos: Vector3, gold: int, rot_y_deg := 0.0) -> Node3D:
	var chest = TreasureChestScript.new()
	chest.chest_id = id
	chest.gold_amount = gold
	chest.position = pos
	chest.rotation_degrees.y = rot_y_deg
	add_child(chest)
	return chest


func _build_resource_nodes() -> void:
	# 1. Tog' Temir Rudalari (Mining Ores)
	_spawn_resource_node("ore_cliffs_01", ResourceNodeScript.Type.IRON_ORE, Vector3(25.0, 0.0, 32.0), 3)
	_spawn_resource_node("ore_cliffs_02", ResourceNodeScript.Type.IRON_ORE, Vector3(45.0, 0.0, 52.0), 3)
	_spawn_resource_node("ore_north_01", ResourceNodeScript.Type.IRON_ORE, Vector3(-18.0, 0.0, -35.0), 4)

	# 2. Qora Saksovul va Archa Yog'ochlari (Steppe Wood)
	_spawn_resource_node("wood_steppe_01", ResourceNodeScript.Type.WOOD, Vector3(12.0, 0.0, 28.0), 3)
	_spawn_resource_node("wood_steppe_02", ResourceNodeScript.Type.WOOD, Vector3(38.0, 0.0, 22.0), 3)
	_spawn_resource_node("wood_steppe_03", ResourceNodeScript.Type.WOOD, Vector3(-14.0, 0.0, 15.0), 2)

	# 3. Dasht Shifobaxsh Giyohlari (Isiriq va Kiyiko't)
	_spawn_resource_node("herbs_meadow_01", ResourceNodeScript.Type.HERBS, Vector3(14.0, 0.0, 8.0), 3)
	_spawn_resource_node("herbs_meadow_02", ResourceNodeScript.Type.HERBS, Vector3(24.0, 0.0, 16.0), 3)
	_spawn_resource_node("herbs_meadow_03", ResourceNodeScript.Type.HERBS, Vector3(36.0, 0.0, 30.0), 4)
	_spawn_resource_node("herbs_meadow_04", ResourceNodeScript.Type.HERBS, Vector3(-6.0, 0.0, -12.0), 2)


func _spawn_resource_node(id: String, type_val: int, pos: Vector3, yield_amt: int) -> Node3D:
	var node = ResourceNodeScript.new()
	node.resource_node_id = id
	node.resource_type = type_val
	node.yield_amount = yield_amt
	node.position = pos
	add_child(node)
	return node


func _build_camel_caravan() -> void:
	_caravan = CamelCaravanScript.new()
	add_child(_caravan)


func _build_bandit_outpost() -> void:
	var outpost_center := Vector3(75.0, 0.0, 55.0)

	# 1. Yog'och to'siqlar va devorlar (Palisades)
	_box(Vector3(75.0, 1.1, 47.0), Vector3(14.0, 2.2, 0.4), Color(0.35, 0.22, 0.12)) # Shimoliy devor
	_box(Vector3(68.0, 1.1, 55.0), Vector3(0.4, 2.2, 16.0), Color(0.35, 0.22, 0.12)) # G'arbiy devor
	_box(Vector3(82.0, 1.1, 55.0), Vector3(0.4, 2.2, 16.0), Color(0.35, 0.22, 0.12)) # Sharqiy devor
	# Janubiy darvoza
	_box(Vector3(71.0, 1.3, 63.0), Vector3(5.0, 2.6, 0.4), Color(0.35, 0.22, 0.12))
	_box(Vector3(79.0, 1.3, 63.0), Vector3(5.0, 2.6, 0.4), Color(0.35, 0.22, 0.12))

	# 2. Qorovul minorasi (Watchtower)
	_box(Vector3(79.0, 1.8, 51.0), Vector3(0.3, 3.6, 0.3), Color(0.32, 0.20, 0.10))
	_box(Vector3(81.5, 1.8, 51.0), Vector3(0.3, 3.6, 0.3), Color(0.32, 0.20, 0.10))
	_box(Vector3(79.0, 1.8, 53.5), Vector3(0.3, 3.6, 0.3), Color(0.32, 0.20, 0.10))
	_box(Vector3(81.5, 1.8, 53.5), Vector3(0.3, 3.6, 0.3), Color(0.32, 0.20, 0.10))
	# Minora maydonchasi
	_box(Vector3(80.25, 3.6, 52.25), Vector3(3.2, 0.2, 3.2), Color(0.4, 0.26, 0.15))
	# Minora qorovuli (Kamonchi)
	_spawn_enemy(EnemyScript.Kind.ARCHER, Vector3(80.25, 3.8, 52.25))

	# 3. Gulxan (Campfire with fire light)
	_box(outpost_center, Vector3(1.6, 0.2, 1.6), Color(0.2, 0.18, 0.16))
	_box(outpost_center + Vector3(0, 0.2, 0), Vector3(0.8, 0.3, 0.8), Color(0.9, 0.4, 0.1))
	var fire_light := OmniLight3D.new()
	fire_light.position = outpost_center + Vector3(0, 0.8, 0)
	fire_light.light_color = Color(1.0, 0.5, 0.15)
	fire_light.light_energy = 3.0
	fire_light.omni_range = 10.0
	add_child(fire_light)

	# 4. Qarorgoh qorovuli (Qilichchi)
	_spawn_enemy(EnemyScript.Kind.SWORD, Vector3(72.0, 0.0, 54.0))

	# 5. Qaroqchilar Sardori (Bandit Chief Mini-Boss)
	_bandit_chief = BanditChiefScript.new()
	_bandit_chief.position = Vector3(75.0, 0.0, 56.5)
	add_child(_bandit_chief)

	# 6. O'g'irlangan Xazina Sandig'i
	_spawn_chest("chest_bandit_outpost", Vector3(76.5, 0.0, 50.0), 85, -45.0)



