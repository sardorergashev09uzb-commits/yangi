extends Node3D

const QuestJournalScript = preload("res://scripts/ui/quest_journal.gd")
const LostSheepScript = preload("res://scripts/world/lost_sheep.gd")
const AncientBalbalScript = preload("res://scripts/world/ancient_balbal.gd")
const QuestSystemScript = preload("res://scripts/story/quest_system.gd")

var tests_passed := 0
var total_tests := 5


func _ready() -> void:
	print("\n=== 5-BOSQICH: DOSTON VA VAZIFALAR JURNALI [ J ] SINOVI BOSHLANDI ===")

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
	var qsystem = QuestSystemScript.new()
	add_child(qsystem)

	# 3. O'yinchi
	var player_scn = load("res://scenes/player.tscn")
	var player = player_scn.instantiate() as Player
	player.position = Vector3(0, 0.1, 0)
	add_child(player)

	# 4. QuestJournal
	var journal = QuestJournalScript.new()
	add_child(journal)

	await get_tree().process_frame
	await get_tree().process_frame

	_test_quest_system_structure()
	_test_quest_journal_ui()
	_test_lost_sheep_quest()
	_test_ancient_balbals_quest()
	_test_save_load_quests()

	print("\n=== SINOV NATIJASI: %d/%d MUVAFFAQIYATLI O'TDI ===" % [tests_passed, total_tests])
	if tests_passed == total_tests:
		print("=== BARCHA 5-BOSQICH SINOVLARI A'LO DARAJADA O'TDI! ===\n")
		get_tree().quit(0)
	else:
		push_error("BA'ZI SINOVLAR MUVAFFAQIYATSIZ YAKUNLANDI!")
		get_tree().quit(1)


func _test_quest_system_structure() -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	assert(qs != null, "QuestSystem mavjud bo'lishi kerak")

	var all_q: Array[Dictionary] = qs.get_all_quests()
	assert(all_q.size() >= 10, "Kamida 10 ta kvest bo'lishi kerak, topildi: %d" % all_q.size())

	var main_q: Array[Dictionary] = qs.get_quests_by_category("main")
	assert(main_q.size() == 4, "4 ta asosiy kvest bo'lishi kerak, topildi: %d" % main_q.size())

	var side_q: Array[Dictionary] = qs.get_quests_by_category("side")
	assert(side_q.size() == 6, "6 ta qo'shimcha kvest bo'lishi kerak, topildi: %d" % side_q.size())

	for q in all_q:
		assert(q.has("id") and q.has("title"), "Har bir kvestda id va sarlavha bo'lishi kerak")
		assert(q.has("lore") and q["lore"] != "", "Kvestda doston qissasi (lore) bo'lishi kerak: %s" % q.id)
		assert(q.has("objectives") and q["objectives"].size() > 0, "Kvestda maqsadlar bo'lishi kerak: %s" % q.id)
		assert(q.has("xp") and q["xp"] > 0, "Kvestda XP mukofoti bo'lishi kerak: %s" % q.id)
		assert(q.has("gold") and q["gold"] > 0, "Kvestda Tilla mukofoti bo'lishi kerak: %s" % q.id)

	tests_passed += 1
	print("✓ SINOV 1 MUVAFFAQIYATLI: Kvest tizimi (10 ta kvest, lore, mukofotlar va toifalar) to'liq tasdiqlandi")


func _test_quest_journal_ui() -> void:
	var journal = get_tree().get_first_node_in_group("quest_journal")
	assert(journal != null, "QuestJournal guruhi topilmadi")

	assert(not journal.is_open, "Boshida jurnal yopiq bo'lishi kerak")
	journal.open_journal()
	assert(journal.is_open, "open_journal chaqirilgach, is_open true bo'lishi kerak")
	assert(journal.visible, "Jurnal ko'rinadigan bo'lishi kerak")

	# Tab almashtirish
	journal._switch_tab("side")
	assert(journal.current_tab == "side", "Qo'shimcha vazifalar tabiga o'tishi kerak")

	# Kvest tanlash
	journal.selected_quest_id = "lost_flock"
	journal.refresh_journal()
	assert(journal._detail_title.text == "Qultoyning yo'qolgan podasi", "Tanlangan kvest sarlavhasi to'g'ri chiqishi kerak")
	assert(journal._detail_objectives_vbox.get_child_count() == 3, "3 ta maqsad qatori chizilishi kerak")

	journal.close_journal()
	assert(not journal.is_open, "close_journal chaqirilgach, is_open false bo'lishi kerak")

	tests_passed += 1
	print("✓ SINOV 2 MUVAFFAQIYATLI: Vazifalar Jurnali [ J ] interfeysi va tablar mukammal ishladi")


func _test_lost_sheep_quest() -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	var player = get_tree().get_first_node_in_group("player")
	var initial_gold: int = int(player.get("gold"))

	var sheep1 = LostSheepScript.new()
	sheep1.sheep_id = "test_sheep_1"
	add_child(sheep1)

	var sheep2 = LostSheepScript.new()
	sheep2.sheep_id = "test_sheep_2"
	add_child(sheep2)

	var sheep3 = LostSheepScript.new()
	sheep3.sheep_id = "test_sheep_3"
	add_child(sheep3)

	sheep1.rescue()
	assert(sheep1.is_rescued, "1-qo'y qutqarilgan deb belgilanishi kerak")
	assert(qs.rescued_sheep.size() == 1, "1 ta qo'y yozilishi kerak")
	assert(not qs.is_quest_completed("lost_flock"), "Hali kvest tugallanmasligi kerak")

	sheep2.rescue()
	assert(qs.rescued_sheep.size() == 2, "2 ta qo'y yozilishi kerak")

	sheep3.rescue()
	assert(qs.rescued_sheep.size() == 3, "3 ta qo'y yozilishi kerak")
	assert(qs.is_quest_completed("lost_flock"), "3 ta qo'y qutqarilgach 'lost_flock' kvesti bajarilishi kerak")

	# Mukofot berilganini tekshirish (+40 tilla)
	assert(int(player.get("gold")) == initial_gold + 40, "Qo'ylarni qutqargani uchun +40 tilla berilishi kerak")

	tests_passed += 1
	print("✓ SINOV 3 MUVAFFAQIYATLI: Adashgan qo'ylar qutqarildi va 'lost_flock' kvesti mukofotlandi")


func _test_ancient_balbals_quest() -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	var player = get_tree().get_first_node_in_group("player")
	var initial_gold: int = int(player.get("gold"))

	# O'yinchi salomatligini 50 ga tushiramiz
	player.health = 50.0

	var b1 = AncientBalbalScript.new()
	b1.balbal_id = "test_balbal_1"
	b1.balbal_name = "Shimoliy Balbal"
	add_child(b1)

	var b2 = AncientBalbalScript.new()
	b2.balbal_id = "test_balbal_2"
	b2.balbal_name = "Sharqiy Balbal"
	add_child(b2)

	var b3 = AncientBalbalScript.new()
	b3.balbal_id = "test_balbal_3"
	b3.balbal_name = "Janubiy Balbal"
	add_child(b3)

	var b4 = AncientBalbalScript.new()
	b4.balbal_id = "test_balbal_4"
	b4.balbal_name = "G'arbiy Balbal"
	add_child(b4)

	# 1-balbal bilan muloqot
	b1.commune()
	assert(b1.is_communed, "1-balbal duo olingan deb belgilanadi")
	assert(player.health == 85.0, "Balbal o'yinchini +35 HP ga shifolashi kerak (50 + 35 = 85)")
	assert(qs.communed_balbals.size() == 1, "1 ta balbal yozilishi kerak")
	assert(not qs.is_quest_completed("ancient_balbals"), "Hali kvest tugallanmasligi kerak")

	b2.commune()
	b3.commune()
	b4.commune()

	assert(qs.communed_balbals.size() == 4, "4 ta balbal yozilishi kerak")
	assert(qs.is_quest_completed("ancient_balbals"), "4 ta balbal ziyorat qilingach kvest yakunlanishi kerak")
	assert(int(player.get("gold")) == initial_gold + 50, "Balbal tilsimi uchun +50 tilla mukofot berilishi kerak")

	tests_passed += 1
	print("✓ SINOV 4 MUVAFFAQIYATLI: 4 ta tosh Balbal ziyorat qilindi, shifo va +50 tilla olindi")


func _test_save_load_quests() -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")

	# Saqlash
	var saved := SaveGame.save_game()
	assert(saved, "O'yin holati saqlanishi kerak")

	# Vaqtincha holatlarni tozalash
	qs.quests["lost_flock"].completed = false
	qs.quests["ancient_balbals"].completed = false
	qs.rescued_sheep.clear()
	qs.communed_balbals.clear()

	# Yuklash
	var loaded := SaveGame.load_game()
	assert(loaded, "O'yin holati yuklanishi kerak")

	assert(qs.is_quest_completed("lost_flock"), "Yuklangach 'lost_flock' bajarilgan holatda bo'lishi kerak")
	assert(qs.is_quest_completed("ancient_balbals"), "Yuklangach 'ancient_balbals' bajarilgan bo'lishi kerak")
	assert(qs.rescued_sheep.size() == 3, "Yuklangach qutqarilgan qo'ylar ro'yxati tiklanishi kerak")
	assert(qs.communed_balbals.size() == 4, "Yuklangach ziyorat qilingan balballar tiklanishi kerak")

	tests_passed += 1
	print("✓ SINOV 5 MUVAFFAQIYATLI: Kvestlar va doston holati Save/Load tizimida 100% tiklandi")
