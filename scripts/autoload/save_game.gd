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
	var data := {"version": VERSION}
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
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var pos: Vector3 = player.global_position
		data["player"] = {"pos": [pos.x, pos.y, pos.z], "health": player.health}
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
		_sync_world(qs)

	if player and data.has("player"):
		var pd: Dictionary = data["player"]
		var p: Array = pd.get("pos", [0, 0.1, 0])
		player.global_position = Vector3(p[0], p[1] + 0.2, p[2])
		player.velocity = Vector3.ZERO
		player.health = clampf(float(pd.get("health", player.max_health)), 1.0, player.max_health)
		player.stamina = player.max_stamina
		player.health_changed.emit(player.health, player.max_health)
		player.stamina_changed.emit(player.stamina, player.max_stamina)
		if player.rig:
			player.rig.global_position = player.global_position + Vector3.UP * player.rig.height


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
	if qs.is_quest_completed("giant"):
		var giant = arena.get("_giant")
		if giant and is_instance_valid(giant):
			giant.queue_free()


func _autosave() -> void:
	save_game()


func _banner(title: String, sub: String) -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs:
		qs.banner_requested.emit(title, sub)
