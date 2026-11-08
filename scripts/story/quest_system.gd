class_name QuestSystem
extends Node
## Alpomish dostoni: Erkin (non-linear) kvest tizimi va vazifalar jurnali.

signal quest_state_changed(id: String, completed: bool)
signal banner_requested(title: String, subtitle: String)
signal all_quests_completed()

var quests: Dictionary = {
	"qultoy": {
		"id": "qultoy",
		"title": "Qultoy Cho'pon sadosi",
		"desc": "Boysun o'toviga borib Qultoy oqsoqol bilan suhbatlashish [ E ]",
		"hint": "O'tovda suhbatlashish [ E ]",
		"completed": false,
		"xp": 50
	},
	"boychibor": {
		"id": "boychibor",
		"title": "Boychibor tulpori",
		"desc": "Boychiborga minib [ F ], dasht bo'ylab chopish va sakrash",
		"hint": "Otga minish va chopish [ F ]",
		"completed": false,
		"xp": 60
	},
	"giant": {
		"id": "giant",
		"title": "Qoyali Dasht Devi",
		"desc": "Sharqdagi bahaybat Dasht Devini yengish",
		"hint": "Sharqdagi bahaybat devni yengish",
		"completed": false,
		"xp": 100
	},
	"boss": {
		"id": "boss",
		"title": "Surxayil Alp arenasi",
		"desc": "Shimoliy arenaga kirib, Qalmoq pahlavoni Surxayilni mag'lub etish",
		"hint": "Shimoliy arenadagi botirni yengish",
		"completed": false,
		"xp": 150
	}
}


func _ready() -> void:
	add_to_group("quest_system")


func get_all_quests() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for qid in ["qultoy", "boychibor", "giant", "boss"]:
		if quests.has(qid):
			list.append(quests[qid])
	return list


func get_active_quest() -> Dictionary:
	# Bajarilmagan birinchi vazifa (eski interfeyslar mosligi uchun)
	for qid in ["qultoy", "boychibor", "giant", "boss"]:
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


func complete_quest(id: String) -> void:
	if not quests.has(id):
		return
	var q: Dictionary = quests[id]
	if q.completed:
		return # Allaqachon bajarilgan

	q.completed = true
	quest_state_changed.emit(id, true)
	banner_requested.emit("VAZIFA BAJARILDI!", "%s (+%d XP)" % [q.title, q.get("xp", 50)])

	# XP berish
	var prog = get_tree().get_first_node_in_group("progression")
	if prog and prog.has_method("add_xp"):
		prog.add_xp(q.get("xp", 50))

	# Barcha vazifalar bajarilganini tekshirish
	_check_all_completed()


func _check_all_completed() -> void:
	for qid in quests.keys():
		if not quests[qid].completed:
			return # Hali bajarilmagan vazifa bor

	# Barcha 4 ta vazifa bajarildi!
	all_quests_completed.emit()
	banner_requested.emit(
		"DOSTON QAHRAMONI!",
		"Barcha shartlar bajarildi! Barchinoy ozod, Qo'ng'irot eli faxri!"
	)
