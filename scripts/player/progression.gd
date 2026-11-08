class_name Progression
extends Node
## Alpomish dostoni: XP, Level, Ko'nikmalar daraxti (Skills) va parametrlar.

signal xp_gained(current_xp: int, next_xp: int)
signal level_up(new_level: int, skill_points: int)
signal skill_unlocked(skill_id: String)

var level := 1
var xp := 0
var next_level_xp := 100
var skill_points := 0

# Olingan ko'nikmalar ro'yxati
var unlocked_skills: Dictionary = {
	"health_boost": false,    # Alp Qurbati: Salomatlik +30
	"stamina_flow": false,    # Qo'ng'irot Shiddati: Stamina +30 va tez tiklanish
	"sword_mastery": false,   # Po'lat Qilich: Qilich zarari +35%
	"bow_mastery": false,     # Merganlik: Kamon tezroq tortiladi va +40% zarar
	"horse_trample": false    # Tulpor Shiddati: Boychibor dushmanlarni bosib o'tadi
}

var skill_info: Dictionary = {
	"health_boost": {
		"name": "Alp Qurbati",
		"desc": "Maksimal salomatlik +30 HP va jarohatlarga chidamlilik",
		"cost": 1
	},
	"stamina_flow": {
		"name": "Qo'ng'irot Shiddati",
		"desc": "Stamina +30 va regeneratsiya 40% ga tezlashadi",
		"cost": 1
	},
	"sword_mastery": {
		"name": "Po'lat Qilich",
		"desc": "Yaqin jangdagi qilich zarbalari kuchi +35% ga oshadi",
		"cost": 1
	},
	"bow_mastery": {
		"name": "Merganlik Hikmati",
		"desc": "Kamon tortilishi 2 baravar tezlashadi va o'q zarari +40%",
		"cost": 1
	},
	"horse_trample": {
		"name": "Boychibor Shiddati",
		"desc": "Boychibor chopganda dushmanlarni urib yiqitadi va ezadi",
		"cost": 1
	}
}


func _ready() -> void:
	add_to_group("progression")


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= next_level_xp:
		xp -= next_level_xp
		level += 1
		skill_points += 1
		next_level_xp = int(next_level_xp * 1.5)
		level_up.emit(level, skill_points)
		_notify_level_up()

	xp_gained.emit(xp, next_level_xp)


func can_unlock(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id) and not unlocked_skills[skill_id] and skill_points >= 1


func unlock_skill(skill_id: String) -> bool:
	if not can_unlock(skill_id):
		return false
	skill_points -= 1
	unlocked_skills[skill_id] = true
	skill_unlocked.emit(skill_id)
	_apply_skill_to_player(skill_id)
	return true


func _apply_skill_to_player(skill_id: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return

	match skill_id:
		"health_boost":
			var cur_max: float = float(player.get("max_health"))
			player.set("max_health", cur_max + 30.0)
			var cur_hp: float = float(player.get("health"))
			player.set("health", cur_hp + 30.0)
			if player.has_signal("health_changed"):
				player.health_changed.emit(player.get("health"), player.get("max_health"))
		"stamina_flow":
			var cur_max_s: float = float(player.get("max_stamina"))
			player.set("max_stamina", cur_max_s + 30.0)
			var cur_regen: float = float(player.get("stamina_regen"))
			player.set("stamina_regen", cur_regen * 1.4)
			if player.has_signal("stamina_changed"):
				player.stamina_changed.emit(player.get("stamina"), player.get("max_stamina"))


func _notify_level_up() -> void:
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem and qsystem.has_method("emit_signal"):
		qsystem.banner_requested.emit("DARAJA OSHDI! (LEVEL %d)" % level, "Yangi ko'nikma ochkosi olindi! [ TAB ]")

	# O'yinchining to'liq tiklanishi
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		player.set("health", player.get("max_health"))
		player.set("stamina", player.get("max_stamina"))
		if player.has_signal("health_changed"):
			player.health_changed.emit(player.get("health"), player.get("max_health"))
		if player.has_signal("stamina_changed"):
			player.stamina_changed.emit(player.get("stamina"), player.get("max_stamina"))
		FX.popup(player.global_position + Vector3.UP * 2.5, 0.0, Color(0.2, 1.0, 0.5))
