extends Node
## Headless sinov: godot --headless --path . res://tests/menu_test.tscn
## Bosh menyu: ochilganda o'yin to'xtaydi, "Yangi o'yin" va "Davom etish" ishlaydi.

var main: Node
var player: Player


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player
	DirAccess.remove_absolute(SaveGame.SAVE_PATH)

	var menu := MainMenu.new()
	main.add_child(menu)
	await _frames(2)
	_check(menu.is_open() and get_tree().paused, "menyu ochilganda o'yin to'xtamadi")
	_check(menu._continue_btn.disabled, "saqlash yo'q, lekin 'Davom etish' faol")

	menu.start_new()
	await _frames(2)
	_check(not menu.is_open() and not get_tree().paused, "'Yangi o'yin' menyuni yopmadi")

	# Saqlab, qayta ochilganda 'Davom etish' faol bo'lishi va holatni tiklashi kerak
	var prog = get_tree().get_first_node_in_group("progression")
	prog.add_xp(100)
	var lvl: int = prog.level
	player.global_position = Vector3(7, 0.1, 7)
	_check(SaveGame.save_game(), "saqlab bo'lmadi")
	prog.level = 1
	player.global_position = Vector3(-9, 0.1, -9)
	menu.open()
	await _frames(2)
	_check(not menu._continue_btn.disabled, "saqlash bor, lekin 'Davom etish' o'chiq")
	menu.continue_game()
	await _frames(2)
	_check(prog.level == lvl, "Davom etish progressni tiklamadi")
	_check(player.global_position.distance_to(Vector3(7, 0.3, 7)) < 1.0, "Davom etish joylashuvni tiklamadi")
	_check(not get_tree().paused, "Davom etishdan keyin o'yin to'xtab qoldi")

	DirAccess.remove_absolute(SaveGame.SAVE_PATH)
	print("BOSH MENYU TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
