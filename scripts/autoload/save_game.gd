extends Node
## Saqlash tizimi: F5 - tezkor saqlash, F9 - yuklash. Vazifa bajarilganda va level oshganda avtomatik saqlanadi.
## Saqlanadi: level/XP/ko'nikmalar, vazifalar, o'yinchi joyi va salomatligi.

const SAVE_PATH := "user://alpomish_save.json"
const VERSION := 1

var _connected := false
var _poll := 0.0


func _process(delta: float) -> void:
	if _connected:
		return
	_poll += delta
	if _poll < 0.5:
		return
	_poll = 0.0
	var q := get_tree().get_first_node_in_group("quest_system")
	var p := get_tree().get_first_node_in_group("progression")
	if q == null or p == null:
		return
	q.quest_state_changed.connect(func(_id: String, _done: bool) -> void: _autosave.call_deferred())
	p.level_up.connect(func(_l: int, _s: int) -> void: _autosave.call_deferred())
	_connected = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			if save_game():
				_banner("O'YIN SAQLANDI", "Tezkor saqlash [ F5 ] | Yuklash [ F9 ]")
		elif event.keycode == KEY_F9:
			if load_game():
				_banner("O'YIN YUKLANDI", "Saqlangan holatdan davom etmoqdasiz")
			else:
				_banner("SAQLASH TOPILMADI", "Avval [ F5 ] bilan saqlang")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func collect_state() -> Dictionary:
	var data := {"version": VERSION, "difficulty": GameSettings.difficulty}
	var prog = get_tree().get_first_node_in_group("progression")
	if prog:
		data["progression"] = {
			"level": prog.level, "xp": prog.xp, "next_level_xp": prog.next_level_xp,
			"skill_points": prog.skill_points, "unlocked_skills": prog.unlocked_skills.duplicate(),
		}
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs:
		var done := {}
		for id in qs.quests.keys():
			done[id] = qs.quests[id].completed
		data["quests"] = done
		data["rescued_sheep"] = qs.rescued_sheep.duplicate()
		data["communed_balbals"] = qs.communed_balbals.duplicate()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var pos: Vector3 = player.global_position
		data["player"] = {
			"pos": [pos.x, pos.y, pos.z],
			"health": player.health,
			"gold": int(player.get("gold")) if player.get("gold") != null else 0,
			"steel_sword": bool(player.get("is_steel_sword_equipped")),
			"plate_armor": bool(player.get("is_plate_armor_equipped")),
			"horseshoes": bool(player.get("has_golden_horseshoes")),
			"fire_arrows": int(player.get("fire_arrows_count")),
			"piercing_arrows": int(player.get("piercing_arrows_count")),
			"iron_ore": int(player.get("iron_ore")),
			"wood": int(player.get("wood")),
			"herbs": int(player.get("herbs")),
			"torch": bool(player.get("torch_active"))
		}
	var opened_chests: Array[String] = []
	for chest in get_tree().get_nodes_in_group("treasure_chests"):
		if chest and chest.get("is_opened") and chest.get("chest_id") != "":
			opened_chests.append(String(chest.get("chest_id")))
	data["chests"] = opened_chests

	var harvested_nodes: Array[String] = []
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if node and node.get("is_depleted") and node.get("resource_node_id") != "":
			harvested_nodes.append(String(node.get("resource_node_id")))
	data["harvested_nodes"] = harvested_nodes
	return data


func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Saqlab bo'lmadi: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(collect_state()))
	return true


func read_save() -> Dictionary:
	if not has_save():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


func load_game() -> bool:
	var data := read_save()
	if data.is_empty():
		return false
	apply_state(data)
	return true


func apply_state(data: Dictionary) -> void:
	if data.has("difficulty"):
		GameSettings.difficulty = int(data["difficulty"])
	var player = get_tree().get_first_node_in_group("player")
	var prog = get_tree().get_first_node_in_group("progression")
	var qs = get_tree().get_first_node_in_group("quest_system")

	if prog and data.has("progression"):
		var d: Dictionary = data["progression"]
		prog.level = int(d.get("level", 1))
		prog.xp = int(d.get("xp", 0))
		prog.next_level_xp = int(d.get("next_level_xp", 100))
		prog.skill_points = int(d.get("skill_points", 0))
		# Ko'nikmalarni noldan qayta qo'llash (statlar ikki marta oshib ketmasligi uchun)
		if player:
			player.max_health = 100.0
			player.max_stamina = 100.0
			player.stamina_regen = 28.0
		var saved: Dictionary = d.get("unlocked_skills", {})
		for sid in prog.unlocked_skills.keys():
			prog.unlocked_skills[sid] = bool(saved.get(sid, false))
			if prog.unlocked_skills[sid]:
				prog._apply_skill_to_player(sid)
		prog.xp_gained.emit(prog.xp, prog.next_level_xp)

	if qs and data.has("quests"):
		var done: Dictionary = data["quests"]
		for id in qs.quests.keys():
			var c := bool(done.get(id, false))
			qs.quests[id].completed = c
			qs.quest_state_changed.emit(id, c)
		if data.has("rescued_sheep"):
			qs.rescued_sheep.clear()
			for s_id in data["rescued_sheep"]:
				qs.rescued_sheep.append(String(s_id))
			for s in get_tree().get_nodes_in_group("lost_sheep"):
				if qs.rescued_sheep.has(s.get("sheep_id")):
					s.set("is_rescued", true)
					if s.get("_prompt"):
						s.get("_prompt").text = "🐑 Qutqarildi ✓"
						s.get("_prompt").modulate = Color(0.35, 1.0, 0.45)
		if data.has("communed_balbals"):
			qs.communed_balbals.clear()
			for b_id in data["communed_balbals"]:
				qs.communed_balbals.append(String(b_id))
			for b in get_tree().get_nodes_in_group("ancient_balbals"):
				if qs.communed_balbals.has(b.get("balbal_id")):
					b.set("is_communed", true)
					if b.get("_prompt"):
						b.get("_prompt").text = "🗿 %s ✓" % b.balbal_name
						b.get("_prompt").modulate = Color(1.0, 0.85, 0.25)
		_sync_world(qs)

	if player and data.has("player"):
		var pd: Dictionary = data["player"]
		var p: Array = pd.get("pos", [0, 0.1, 0])
		player.global_position = Vector3(p[0], p[1] + 0.2, p[2])
		player.velocity = Vector3.ZERO
		player.health = clampf(float(pd.get("health", player.max_health)), 1.0, player.max_health)
		player.stamina = player.max_stamina
		if pd.has("gold"):
			var g := int(pd["gold"])
			player.set("gold", g)
			if player.has_signal("gold_changed"):
				player.emit_signal("gold_changed", g, 0)
		if pd.get("steel_sword", false) and player.has_method("upgrade_sword"):
			player.upgrade_sword()
		if pd.get("plate_armor", false) and player.has_method("upgrade_armor"):
			player.upgrade_armor()
		if pd.get("horseshoes", false):
			player.set("has_golden_horseshoes", true)
		if pd.has("fire_arrows"):
			player.set("fire_arrows_count", int(pd["fire_arrows"]))
		if pd.has("piercing_arrows"):
			player.set("piercing_arrows_count", int(pd["piercing_arrows"]))
		if pd.has("iron_ore"):
			player.set("iron_ore", int(pd["iron_ore"]))
		if pd.has("wood"):
			player.set("wood", int(pd["wood"]))
		if pd.has("herbs"):
			player.set("herbs", int(pd["herbs"]))
		if pd.get("torch", false) and player.has_method("enable_torch"):
			player.enable_torch(true)
		if player.has_signal("resources_changed"):
			player.emit_signal("resources_changed", player.get("iron_ore"), player.get("wood"), player.get("herbs"))
		player.health_changed.emit(player.health, player.max_health)
		player.stamina_changed.emit(player.stamina, player.max_stamina)
		if player.rig:
			player.rig.global_position = player.global_position + Vector3.UP * player.rig.height

	if data.has("chests"):
		var opened: Array = data["chests"]
		for chest in get_tree().get_nodes_in_group("treasure_chests"):
			if chest and chest.get("chest_id") in opened:
				if chest.has_method("set_opened_silent"):
					chest.set_opened_silent()

	if data.has("harvested_nodes"):
		var harvested: Array = data["harvested_nodes"]
		for node in get_tree().get_nodes_in_group("resource_nodes"):
			if node and node.get("resource_node_id") in harvested:
				if node.has_method("set_depleted_silent"):
					node.set_depleted_silent()


## Yengilgan dushmanlar dunyoda qayta paydo bo'lmasligi uchun
func _sync_world(qs: Node) -> void:
	var arena := get_tree().current_scene
	if arena == null:
		return
	if qs.is_quest_completed("boss"):
		var boss = arena.get("_boss")
		if boss and is_instance_valid(boss):
			boss.queue_free()
		if arena.has_method("_on_boss_defeated"):
			arena._on_boss_defeated()
		var dgate = arena.get("_dungeon_gate")
		if dgate and is_instance_valid(dgate) and dgate.has_method("unlock"):
			dgate.unlock()
	if qs.is_quest_completed("giant"):
		var giant = arena.get("_giant")
		if giant and is_instance_valid(giant):
			giant.queue_free()
	if qs.is_quest_completed("caravan"):
		var caravan = arena.get("_caravan")
		if caravan and is_instance_valid(caravan) and caravan.has_method("set_ambush_completed_silent"):
			caravan.set_ambush_completed_silent()
	if qs.is_quest_completed("bandit_outpost"):
		var chief = arena.get("_bandit_chief")
		if chief and is_instance_valid(chief):
			chief.queue_free()


func _autosave() -> void:
	save_game()


func _banner(title: String, sub: String) -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs:
		qs.banner_requested.emit(title, sub)
