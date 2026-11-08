extends Node
## Headless sinov: godot --headless --path . res://tests/difficulty_test.tscn
## Qiyinlik darajasi (Oson, Oddiy, Alp) va uning zararlarga ta'sirini tekshiradi.

var main: Node
var player: Player


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player

	# 1. Standart qiyinlik NORMAL
	GameSettings.difficulty = GameSettings.Difficulty.NORMAL
	_check(GameSettings.get_mult("player_dmg") == 1.0, "normal player_dmg != 1.0")
	_check(GameSettings.get_mult("enemy_dmg") == 1.0, "normal enemy_dmg != 1.0")

	# 2. EASY ga o'tkazish
	GameSettings.difficulty = GameSettings.Difficulty.EASY
	_check(GameSettings.get_mult("player_dmg") > 1.0, "easy player_dmg oshmadi")
	_check(GameSettings.get_mult("enemy_dmg") < 1.0, "easy enemy_dmg kamaymadi")

	# 3. HARD ga o'tkazish
	GameSettings.difficulty = GameSettings.Difficulty.HARD
	_check(GameSettings.get_mult("player_dmg") < 1.0, "hard player_dmg kamaymadi")
	_check(GameSettings.get_mult("enemy_dmg") > 1.0, "hard enemy_dmg oshmadi")

	# 4. Save/Load da qiyinlik saqlanadimi?
	DirAccess.remove_absolute(SaveGame.SAVE_PATH)
	GameSettings.difficulty = GameSettings.Difficulty.HARD
	_check(SaveGame.save_game(), "saqlab bo'lmadi")

	GameSettings.difficulty = GameSettings.Difficulty.EASY
	_check(SaveGame.load_game(), "yuklab bo'lmadi")
	_check(GameSettings.difficulty == GameSettings.Difficulty.HARD, "qiyinlik tiklanmadi")

	DirAccess.remove_absolute(SaveGame.SAVE_PATH)
	# Standartga qaytaramiz
	GameSettings.difficulty = GameSettings.Difficulty.NORMAL

	print("QIYINLIK DARAJALARI VA BALANS TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
