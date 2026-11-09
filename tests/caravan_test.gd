extends Node
## 4-Bosqich Sinovi: Harakatlanuvchi Karvon va Qaroqchilar Istehkomi (Caravan & Bandits Test)

const CamelCaravanScript = preload("res://scripts/world/camel_caravan.gd")
const BanditChiefScript = preload("res://scripts/enemies/bandit_chief.gd")
const QuestSystemScript = preload("res://scripts/story/quest_system.gd")

var player: Player
var qsystem: QuestSystem
var caravan: Node3D
var chief: CharacterBody3D

func _ready() -> void:
	print("=== 4-BOSQICH: HARAKATLANUVCHI KARVON VA QAROQCHILAR SINOVI BOSHLANDI ===")

	# 1. Zamin
	var ground := StaticBody3D.new()
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(100, 2, 100)
	gcol.shape = gbox
	gcol.position.y = -1.0
	ground.add_child(gcol)
	add_child(ground)

	# 2. Kvest tizimi
	qsystem = QuestSystemScript.new()
	add_child(qsystem)

	# 3. O'yinchi
	var player_scn = load("res://scenes/player.tscn")
	player = player_scn.instantiate() as Player
	player.position = Vector3(0, 0.1, 0)
	add_child(player)

	# 4. Tuyalar karvoni
	caravan = CamelCaravanScript.new()
	add_child(caravan)

	await _frames(5)

	# --- SINOV 1: Karvon tuzilishi va boshlang'ich holati ---
	assert(caravan.is_ambush_active == false, "Dastlab pistirma faol bo'lmasligi kerak")
	assert(caravan.ambush_completed == false, "Dastlab pistirma tugallanmagan bo'lishi kerak")
	assert(caravan.waypoints.size() == 4, "Karvonda 4 ta yo'l nuqtasi bo'lishi kerak")
	print("✓ SINOV 1 MUVAFFAQIYATLI: Tuyalar karvoni va yo'l xaritasi to'g'ri yaratildi")

	# --- SINOV 2: Pistirma (Ambush Event) faollashishi va Qaroqchilar hujumi ---
	var ambush_started_flag := [false]
	caravan.ambush_started.connect(func(): ambush_started_flag[0] = true)

	caravan._trigger_ambush()
	assert(ambush_started_flag[0] == true, "ambush_started signali tarqalishi kerak")
	assert(caravan.is_ambush_active == true, "Pistirma holati faollashishi kerak")
	assert(caravan._ambush_enemies.size() == 3, "3 ta sahro qaroqchisi paydo bo'lishi kerak")
	print("✓ SINOV 2 MUVAFFAQIYATLI: Qaroqchilar pistirmasi faollashdi va 3 ta dushman chaqirildi")

	# --- SINOV 3: Qaroqchilarni yengish va Karvonni qutqarish mukofoti ---
	var initial_gold := player.gold
	# Qaroqchilarni yengamiz
	for enemy in caravan._ambush_enemies:
		if is_instance_valid(enemy):
			enemy.state = enemy.State.DEAD

	caravan._check_ambush_progress()
	assert(caravan.ambush_completed == true, "Pistirma muvaffaqiyatli yakunlanishi kerak")
	assert(caravan.is_ambush_active == false, "Pistirma tugashi kerak")
	assert(player.gold >= initial_gold + 80, "Karvonni qutqargani uchun o'yinchiga 80 tilla berilishi kerak")
	assert(qsystem.is_quest_completed("caravan") == true, "'caravan' kvesti bajarilgan bo'lishi kerak")
	print("✓ SINOV 3 MUVAFFAQIYATLI: Qaroqchilar yengildi, 'caravan' kvesti yakunlandi va 80 tilla berildi")

	# --- SINOV 4: Qaroqchilar Sardori (Bandit Chief Mini-Boss) jangi ---
	chief = BanditChiefScript.new()
	chief.position = Vector3(10, 0, 0)
	add_child(chief)

	assert(chief.health == 150.0, "Sardor HP si 150 bo'lishi kerak")
	chief.take_damage(60.0)
	assert(chief.health == 90.0, "60 zarar tekkanida 90 HP qolishi kerak")

	var chief_died_flag := [false]
	chief.died.connect(func(_c): chief_died_flag[0] = true)

	# Yakuniy zarba
	chief.take_damage(100.0)
	assert(chief.health <= 0.0, "Sardor sog'lig'i 0 ga tushishi kerak")
	assert(chief.state == BanditChiefScript.State.DEAD, "Sardor DEAD holatiga o'tishi kerak")
	assert(chief_died_flag[0] == true, "Sardor o'lim signali berilishi kerak")
	assert(qsystem.is_quest_completed("bandit_outpost") == true, "'bandit_outpost' kvesti bajarilishi kerak")
	print("✓ SINOV 4 MUVAFFAQIYATLI: Qaroqchilar Sardori (Bandit Chief) mag'lub etildi va kvest yopildi")

	# --- SINOV 5: Save/Load integratsiyasi ---
	var save_data := SaveGame.collect_state()
	assert(save_data.has("quests"), "Kvestlar saqlanishi kerak")
	var qdata: Dictionary = save_data["quests"]
	assert(qdata.get("caravan") == true, "Karvon kvesti saqlanishi kerak")
	assert(qdata.get("bandit_outpost") == true, "Qaroqchilar istehkomi kvesti saqlanishi kerak")

	# Qayta tiklash
	qsystem.quests["caravan"].completed = false
	qsystem.quests["bandit_outpost"].completed = false
	caravan.ambush_completed = false

	SaveGame.apply_state(save_data)
	assert(qsystem.is_quest_completed("caravan") == true, "Karvon kvesti tiklanishi kerak")
	assert(qsystem.is_quest_completed("bandit_outpost") == true, "Istehkom kvesti tiklanishi kerak")
	print("✓ SINOV 5 MUVAFFAQIYATLI: 4-Bosqich kvestlari va voqealari Save/Load tizimida 100% tiklandi")

	print("=== BARCHA 4-BOSQICH SINOVLARI A'LO DARAJADA O'TDI! ===")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
