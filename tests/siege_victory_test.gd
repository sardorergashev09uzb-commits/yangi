extends Node
## Headless sinov: godot --headless --path . res://tests/siege_victory_test.tscn
## 9-Bosqich: Qalmoq Qal'asi Katta Qamali, Do'st Botirlar va G'alaba Tantanasi Sinovi.

const SiegeBattleScript = preload("res://scripts/world/siege_battle.gd")
const AlliedWarriorScript = preload("res://scripts/enemies/allied_warrior.gd")
const CatapultRockScript = preload("res://scripts/world/siege_catapult_rock.gd")
const VictoryCelebrationScript = preload("res://scripts/ui/victory_celebration.gd")

var main: Node
var player: Player
var arena: Node3D
var siege: Node3D
var qsys: QuestSystem


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)

	arena = main as Node3D
	player = main.get_node("Player") as Player
	qsys = get_tree().get_first_node_in_group("quest_system") as QuestSystem
	_check(player != null, "Player topilmadi")
	_check(qsys != null, "QuestSystem topilmadi")

	siege = arena.get("_siege_battle")
	_check(siege != null, "SiegeBattle topilmadi")
	_check(not siege.is_active, "Qamal dastlab faol bo'lmasligi kerak")
	_check(not siege.is_completed, "Qamal dastlab tugallanmagan bo'lishi kerak")

	# 1. Qamalni boshlash (start_siege)
	siege.start_siege()
	await _frames(5)
	_check(siege.is_active, "Qamal jangi boshlanmadi")
	_check(siege.allies.size() == 3, "3 ta do'st botir maydonga tushmadi")
	_check(siege.enemies.size() == 3, "3 ta qal'a qo'riqchisi maydonga tushmadi")

	# 2. Do'st botirlar (Allied Warrior) tekshiruvi
	var ally: CharacterBody3D = siege.allies[0]
	_check(ally.health > 150.0, "Do'st botir salomatligi yetarli emas")
	_check(ally.is_in_group("allies"), "Do'st botir 'allies' guruhiga kiritilmagan")

	# 3. Katapulta toshini sinash (launch & explode)
	var rock := CatapultRockScript.new()
	siege.add_child(rock)
	rock.launch(player.global_position)
	await _frames(5)
	_check(rock.is_inside_tree(), "Katapulta toshi sahnaga qo'shilmadi")
	# Portlatish
	rock._explode()
	await _frames(2)

	# 4. Qamal jangini muvaffaqiyatli yakunlash (complete_siege)
	var gold_before: int = player.gold
	siege.complete_siege()
	await _frames(5)

	_check(siege.is_completed, "Qamal tugallanmadi")
	_check(not siege.is_active, "Qamal yakunlangach faol holatda qoldi")
	_check(ally.state == AlliedWarriorScript.State.CHEER, "Botirlar g'alaba quvonchi (CHEER) holatiga o'tmadi")
	_check(qsys.is_quest_completed("rescue_barchin"), "Qamal yakunida Barchinoy kvesti yopilmadi")
	_check(player.gold >= gold_before + 500, "Yakuniy g'alaba sarpo oltinlari (+500) berilmadi")

	# 5. G'alaba ekrani (VictoryCelebration) tekshiruvi
	var victory_ui: CanvasLayer = siege.get("_victory_ui")
	_check(victory_ui != null, "VictoryCelebration ekrani topilmadi")
	_check(victory_ui.visible, "G'alaba oynasi ko'rsatilmadi")

	print("9-BOSQICH: KATTA QAMAL VA G'ALABA TANTANASI TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
