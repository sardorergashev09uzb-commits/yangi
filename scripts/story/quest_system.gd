class_name QuestSystem
extends Node
## Alpomish dostoni: Erkin (non-linear) kvest tizimi va vazifalar jurnali.

signal quest_state_changed(id: String, completed: bool)
signal banner_requested(title: String, subtitle: String)
signal all_quests_completed()

var rescued_sheep: Array[String] = []
var communed_balbals: Array[String] = []

var quests: Dictionary = {
	"qultoy": {
		"id": "qultoy",
		"category": "main",
		"title": "Qultoy Cho'pon sadosi",
		"desc": "Boysun o'toviga borib Qultoy oqsoqol bilan suhbatlashish [ E ]",
		"hint": "O'tovda suhbatlashish [ E ]",
		"lore": "Boysun dashtida o'tov tiklagan el oqsoqoli Qultoy cho'pon Alpomishga amakisi Boysari va suyukli yori Barchinoyning Qalmoq yurtidagi musibati haqida so'zlaydi. Barchinoy shart qo'ygan: faqat Hakimbek kelib uni asoratdan qutqara oladi.",
		"completed": false,
		"xp": 50,
		"gold": 25,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Qultoy cho'pon bilan suhbatlashish [ E ]"]
	},
	"boss": {
		"id": "boss",
		"category": "main",
		"title": "Surxayil Alp arenasi",
		"desc": "Shimoliy arenaga kirib, Qalmoq pahlavoni Surxayilni mag'lub etish",
		"hint": "Shimoliy arenadagi botirni yengish",
		"lore": "Qalmoq hukmdorining eng qudratli bahodirlaridan biri — Surxayil Alp shimoliy qasr arenasida pahlavonlar bilan bellashmoqda. Uni yengmasdan turib Qalmoq zindoniga kirishning iloji yo'q.",
		"completed": false,
		"xp": 150,
		"gold": 70,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Surxayil Alp arenasiga kirish", "Surxayil Alpni mag'lub etish"]
	},
	"karajon_oath": {
		"id": "karajon_oath",
		"category": "main",
		"title": "Karajon bilan qardoshlik",
		"desc": "Qalmoq Zindoniga kirib, Karajon Botir bilan do'stlik ahdini bog'lash [ E ]",
		"hint": "Zindonda Karajon bilan suhbatlashish",
		"lore": "Karajon Alp Qalmoq elining mard va adolatparvar botiri bo'lib, haqiqat Alpomish tomonidaligini anglab yetadi. Ular o'rtasida qadimgi turkiy botirlik qasamiyodi va qardoshlik rishtasi bog'lanadi.",
		"completed": false,
		"xp": 120,
		"gold": 50,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Qalmoq zindoniga kirish", "Karajon Botir bilan qardoshlik ahdini bog'lash [ E ]"]
	},
	"rescue_barchin": {
		"id": "rescue_barchin",
		"category": "main",
		"title": "Barchinoyni ozod etish",
		"desc": "Zindon ichida bandi bo'lgan go'zal Barchinoyni qutqarish [ E ]",
		"hint": "Barchinoyni zindondan ozod qilish",
		"lore": "Barchinoy Qo'ng'irot elining iftixori, Alpomishning va'dalashgan yori. Zindon panjarasini ochib, uni qutqarish — dostonning oliy cho'qqisi va g'alaba tantanasidir.",
		"completed": false,
		"xp": 200,
		"gold": 100,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Zindon tutqunligidagi Barchinoy yoniga borish", "Barchinoyni ozod etish va Boysunga qaytish [ E ]"]
	},
	"boychibor": {
		"id": "boychibor",
		"category": "side",
		"title": "Boychibor tulpori",
		"desc": "Boychiborga minib [ F ], dasht bo'ylab chopish va sakrash",
		"hint": "Otga minish va chopish [ F ]",
		"lore": "Boychibor — oddiy ot emas, u qanotli samoviy tulpor naslidan bo'lib, Alpomishga sadoqatli yo'ldoshdir. Tulpor ustida dasht bo'ylab shamoldek chopish va to'siqlardan sakrash botirning shon-shavkatidir.",
		"completed": false,
		"xp": 60,
		"gold": 25,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Boychibor tulporiga minish [ F ]", "Dasht bo'ylab chopish va sakrash"]
	},
	"giant": {
		"id": "giant",
		"category": "side",
		"title": "Qoyali Dasht Devi",
		"desc": "Sharqdagi bahaybat Dasht Devini yengish",
		"hint": "Sharqdagi bahaybat devni yengish",
		"lore": "Sharqiy qoyalar etagida yashovchi ulkan tosh tanali Dasht Devi yo'lovchilarga xavf solmoqda. Botir uni yengib, dasht yo'llarini xavf-xatardan tozalaydi.",
		"completed": false,
		"xp": 100,
		"gold": 40,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Sharqiy qoyalarga borish", "Dasht Devini mag'lub etish"]
	},
	"caravan": {
		"id": "caravan",
		"category": "side",
		"title": "Tuyalar Karvoni Himoyasi",
		"desc": "Buyuk Ipak Yo'li tuyalar karvonini sahro qaroqchilari pistirmasidan qutqarish",
		"hint": "Karvonni pistirmadan himoya qiling",
		"lore": "Ipak, xushbo'y ziravorlar va ne'matlar ortilgan Buyuk Ipak Yo'li tuyalar karvoni sahro qaroqchilari qamalida qoldi. Karvonboshi va karvonni qutqarish el obodligi uchun zarur.",
		"completed": false,
		"xp": 150,
		"gold": 60,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Karvon yo'lida qaroqchilar hujumini qaytarish", "Karvonboshidan minnatdorchilik olish"]
	},
	"bandit_outpost": {
		"id": "bandit_outpost",
		"category": "side",
		"title": "Qaroqchilar Qarorgohi",
		"desc": "Sharqiy tog' etagidagi Qaroqchilar istehkomini tor-mor qilish va Sardorni yengish",
		"hint": "Qaroqchilar Sardorini yengish",
		"lore": "Dashtdagi talon-torojlarning uyasi — yog'och to'siqlar bilan o'ralgan maxfiy qaroqchilar qarorgohi. Sardor va uning kamonchilarini tor-mor qilib, xazinani qaytarish lozim.",
		"completed": false,
		"xp": 160,
		"gold": 65,
		"progress": 0,
		"max_progress": 1,
		"objectives": ["Qaroqchilar istehkomiga bostirib kirish", "Qaroqchilar Sardorini yengish", "O'g'irlangan xazina sandig'ini ochish"]
	},
	"lost_flock": {
		"id": "lost_flock",
		"category": "side",
		"title": "Qultoyning yo'qolgan podasi",
		"desc": "Dasht bo'ylab adashib qolgan 3 ta qo'yni topish va bo'rilardan qutqarish [ E ]",
		"hint": "Dashtdan 3 ta qo'yni topish [ E ]",
		"lore": "Qultoy cho'ponning suruvidan qattiq shamolda 3 ta qo'zi-qo'y adashib ketgan. Bo'rilar ularni g'ajib ketmasdan oldin Alpomish ularni topib xalos qilishi kerak.",
		"completed": false,
		"xp": 100,
		"gold": 40,
		"progress": 0,
		"max_progress": 3,
		"objectives": ["1-qo'yni topish [ E ]", "2-qo'yni topish [ E ]", "3-qo'yni topish [ E ]"]
	},
	"ancient_balbals": {
		"id": "ancient_balbals",
		"category": "side",
		"title": "Qadimiy Balbal tilsimi",
		"desc": "Dashtning to'rt tomonida qad ko'targan 4 ta qadimiy tosh Balbalni ziyorat qilish [ E ]",
		"hint": "4 ta tosh Balbalni ziyorat qilish [ E ]",
		"lore": "Turkiy ajdodlar xotirasiga atab toshdan yo'nilgan qadimiy Balballar dashtning muqaddas qo'riqchilaridir. Ularning har birini ziyorat qilib, toshiga qo'l qo'ygan mard botirga ajdodlar ruhi kuch va omonlik ato etadi.",
		"completed": false,
		"xp": 120,
		"gold": 50,
		"progress": 0,
		"max_progress": 4,
		"objectives": ["Shimoliy Balbalni ziyorat qilish", "Sharqiy Balbalni ziyorat qilish", "Janubiy Balbalni ziyorat qilish", "G'arbiy Balbalni ziyorat qilish"]
	}
}


func _ready() -> void:
	add_to_group("quest_system")


func get_all_quests() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var order := [
		"qultoy", "boss", "karajon_oath", "rescue_barchin",
		"boychibor", "giant", "caravan", "bandit_outpost",
		"lost_flock", "ancient_balbals"
	]
	for qid in order:
		if quests.has(qid):
			list.append(quests[qid])
	return list


func get_quests_by_category(category: String) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for q in get_all_quests():
		if q.get("category", "main") == category:
			list.append(q)
	return list


func get_quest(id: String) -> Dictionary:
	if quests.has(id):
		return quests[id]
	return {}


func get_active_quest() -> Dictionary:
	# Birinchi bajarilmagan asosiy kvest
	for qid in ["qultoy", "boss", "karajon_oath", "rescue_barchin"]:
		if quests.has(qid) and not quests[qid].completed:
			return quests[qid]
	# Agar barcha asosiy bajarilgan bo'lsa, bajarilmagan birinchi qo'shimcha kvest
	for qid in ["boychibor", "giant", "caravan", "bandit_outpost", "lost_flock", "ancient_balbals"]:
		if quests.has(qid) and not quests[qid].completed:
			return quests[qid]
	return {}


func get_completed_count() -> int:
	var count := 0
	for q in quests.values():
		if q.get("completed", false):
			count += 1
	return count


func get_total_count() -> int:
	return quests.size()


func is_quest_completed(id: String) -> bool:
	if quests.has(id):
		return quests[id].completed
	return false


func record_sheep(sheep_id: String) -> int:
	if not rescued_sheep.has(sheep_id):
		rescued_sheep.append(sheep_id)
		if quests.has("lost_flock"):
			quests["lost_flock"]["progress"] = rescued_sheep.size()
			if rescued_sheep.size() >= 3:
				complete_quest("lost_flock")
			else:
				banner_requested.emit("QO'Y QUTQARILDI!", "Qultoy podasi: %d/3 ta qo'y topildi" % rescued_sheep.size())
				quest_state_changed.emit("lost_flock", false)
	return rescued_sheep.size()


func record_balbal(balbal_id: String) -> int:
	if not communed_balbals.has(balbal_id):
		communed_balbals.append(balbal_id)
		if quests.has("ancient_balbals"):
			quests["ancient_balbals"]["progress"] = communed_balbals.size()
			if communed_balbals.size() >= 4:
				complete_quest("ancient_balbals")
			else:
				banner_requested.emit("BALBAL ZIYORAT QILINDI!", "Ajdodlar ruhi: %d/4 ta balbal" % communed_balbals.size())
				quest_state_changed.emit("ancient_balbals", false)
	return communed_balbals.size()


func set_objective_completed(quest_id: String, obj_index: int, completed := true) -> void:
	if not quests.has(quest_id):
		return
	var q: Dictionary = quests[quest_id]
	if not q.has("completed_objectives"):
		q["completed_objectives"] = []
	var arr: Array = q["completed_objectives"]
	if completed and not arr.has(obj_index):
		arr.append(obj_index)
		quest_state_changed.emit(quest_id, q.get("completed", false))
	elif not completed and arr.has(obj_index):
		arr.erase(obj_index)
		quest_state_changed.emit(quest_id, q.get("completed", false))


func is_objective_completed(quest_id: String, obj_index: int) -> bool:
	if not quests.has(quest_id):
		return false
	var q: Dictionary = quests[quest_id]
	if q.get("completed", false):
		return true

	match quest_id:
		"ancient_balbals":
			var balbal_keys := ["balbal_north", "balbal_east", "balbal_south", "balbal_west"]
			if obj_index >= 0 and obj_index < balbal_keys.size():
				var key: String = balbal_keys[obj_index]
				if communed_balbals.has(key):
					return true
				var tag := key.substr(7)
				for b_id in communed_balbals:
					if tag in b_id.to_lower():
						return true
			var alt_id := "balbal_%d" % (obj_index + 1)
			var test_id := "test_balbal_%d" % (obj_index + 1)
			if communed_balbals.has(alt_id) or communed_balbals.has(test_id):
				return true
			return false

		"lost_flock":
			var sheep_keys := ["sheep_1", "sheep_2", "sheep_3"]
			if obj_index >= 0 and obj_index < sheep_keys.size():
				var key: String = sheep_keys[obj_index]
				if rescued_sheep.has(key):
					return true
			var test_id := "test_sheep_%d" % (obj_index + 1)
			if rescued_sheep.has(test_id):
				return true
			return false

		_:
			var done_objs: Array = q.get("completed_objectives", [])
			if done_objs.has(obj_index):
				return true
			var prog: int = int(q.get("progress", 0))
			var max_p: int = int(q.get("max_progress", 1))
			if max_p > 1:
				return obj_index < prog
			return false


func get_objectives_save_data() -> Dictionary:
	var result := {}
	for qid in quests.keys():
		var q = quests[qid]
		if q.has("completed_objectives"):
			result[qid] = q["completed_objectives"].duplicate()
	return result


func restore_objectives_save_data(data: Dictionary) -> void:
	for qid in data.keys():
		if quests.has(qid):
			quests[qid]["completed_objectives"] = Array(data[qid])


func complete_quest(id: String) -> void:
	if not quests.has(id):
		return
	var q: Dictionary = quests[id]
	if q.completed:
		return

	q.completed = true
	q.progress = q.get("max_progress", 1)
	if q.has("objectives"):
		var total_objs: int = q["objectives"].size()
		if not q.has("completed_objectives"):
			q["completed_objectives"] = []
		for i in range(total_objs):
			if not q["completed_objectives"].has(i):
				q["completed_objectives"].append(i)
	quest_state_changed.emit(id, true)

	var xp_reward: int = int(q.get("xp", 50))
	var gold_reward: int = int(q.get("gold", 0))

	if gold_reward > 0:
		banner_requested.emit("VAZIFA BAJARILDI!", "%s (+%d XP, +%d Tilla)" % [q.title, xp_reward, gold_reward])
	else:
		banner_requested.emit("VAZIFA BAJARILDI!", "%s (+%d XP)" % [q.title, xp_reward])

	Audio.play_level_up()

	# XP berish
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.has_method("add_xp"):
		prog.add_xp(xp_reward)

	# Tilla berish
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold") and gold_reward > 0:
		player.add_gold(gold_reward)

	# Barcha vazifalar bajarilganini tekshirish
	_check_all_completed()


func _check_all_completed() -> void:
	for qid in quests.keys():
		if not quests[qid].completed:
			return

	all_quests_completed.emit()
	Audio.play_victory()
	banner_requested.emit(
		"DOSTON QAHRAMONI!",
		"Barcha shartlar va el-yurt vazifalari to'liq bajarildi! Qo'ng'irot eli faxri!"
	)
