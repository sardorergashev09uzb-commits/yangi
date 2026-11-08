extends Node
## Alpomish dostoni: Kvestlar va vazifalar boshqaruvchisi.

signal quest_updated(id: String, title: String, text: String, completed: bool)
signal banner_requested(title: String, subtitle: String)

enum QuestStatus { NOT_STARTED, ACTIVE, COMPLETED }

var quests: Dictionary = {
	"qultoy": {
		"title": "1. Qultoy Cho'pon sadosi",
		"desc": "Boysun o'toviga boring va Qultoy oqsoqol bilan gaplashing [ E ]",
		"status": QuestStatus.ACTIVE
	},
	"boychibor": {
		"title": "2. Boychibor tulpori",
		"desc": "Afsonaviy Boychiborga mining [ F ] va dasht bo'ylab tezlashing",
		"status": QuestStatus.NOT_STARTED
	},
	"giant": {
		"title": "3. Qoyali Dasht Devi",
		"desc": "Sharqdagi Qoyali Dasht Devini mag'lub eting",
		"status": QuestStatus.NOT_STARTED
	},
	"boss": {
		"title": "4. Surxayil Alp arenasi",
		"desc": "Shimoliy darvozadan o'tib, Qalmoq pahlavoni Surxayilni tiz cho'ktiring",
		"status": QuestStatus.NOT_STARTED
	}
}

var current_quest_id := "qultoy"


func _ready() -> void:
	add_to_group("quest_system")


func get_active_quest() -> Dictionary:
	if quests.has(current_quest_id):
		return quests[current_quest_id]
	return {}


func complete_quest(id: String) -> void:
	if not quests.has(id):
		return
	var q: Dictionary = quests[id]
	if q.status == QuestStatus.COMPLETED:
		return
	q.status = QuestStatus.COMPLETED
	quest_updated.emit(id, q.title, q.desc, true)
	banner_requested.emit("VAZIFA BAJARILDI!", q.title)

	# Keyingi kvestni faollashtirish
	match id:
		"qultoy":
			_activate_quest("boychibor")
		"boychibor":
			_activate_quest("giant")
		"giant":
			_activate_quest("boss")
		"boss":
			banner_requested.emit("DOSTON QAHRAMONI!", "Barchinoy sari yo'l ochildi. Boysun eli ozod!")


func _activate_quest(id: String) -> void:
	if quests.has(id):
		quests[id].status = QuestStatus.ACTIVE
		current_quest_id = id
		quest_updated.emit(id, quests[id].title, quests[id].desc, false)
		banner_requested.emit("YANGI VAZIFA!", quests[id].title)
