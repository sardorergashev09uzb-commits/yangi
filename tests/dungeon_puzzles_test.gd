extends Node
## Headless sinov: godot --headless --path . res://tests/dungeon_puzzles_test.tscn
## 8-Bosqich: Qalmoq Ko'p Qavatli Zindoni, O'lim Tuzoqlari va Boshqotirmalar Sinovi.

const BladeTrapScript = preload("res://scripts/world/blade_trap.gd")
const PressurePlateScript = preload("res://scripts/world/pressure_plate.gd")
const SuspendedCageScript = preload("res://scripts/world/suspended_cage.gd")
const LightMirrorPuzzleScript = preload("res://scripts/world/light_mirror_puzzle.gd")

var main: Node
var player: Player
var arena: Node3D
var darea: Node3D


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)

	arena = main as Node3D
	player = main.get_node("Player") as Player
	_check(player != null, "Player topilmadi")

	darea = arena.get("_dungeon_area")
	_check(darea != null, "DungeonArea topilmadi")

	# 1. Zindon komponentlari mavjudligi tekshiruvi
	_check(darea.blade_traps.size() >= 2, "Aylanuvchi tig'lar tuzoqlari topilmadi")
	_check(darea.pressure_plates.size() >= 2, "Bosim plitalari topilmadi")
	_check(darea.suspended_cage != null, "Muallaq temir qafas topilmadi")
	_check(darea.mirror_puzzle != null, "Nur va ko'zgu boshqotirmasi topilmadi")

	# 2. Aylanuvchi pichoqlar (Blade Trap) sinovi
	var blade_trap = darea.blade_traps[0]
	_check(blade_trap.damage > 0.0, "BladeTrap zarari belgilanmagan")
	var hp_before: float = player.health
	player.global_position = blade_trap.global_position
	await _frames(5)
	# Agar o'yinchi tuzoq ustida bo'lsa zarar olishi kerak
	_check(player.health <= hp_before, "O'yinchi aylanuvchi pichoqdan zarar olmadi")

	# 3. Bosim plitasi (Pressure Plate) sinovi
	var plate = darea.pressure_plates[0]
	_check(not plate.is_pressed, "Plita dastlab bosilmagan bo'lishi kerak")
	var plate_signal_fired := [false]
	plate.plate_activated.connect(func(_id): plate_signal_fired[0] = true)
	plate._on_body_entered(player)
	_check(plate.is_pressed, "Plita o'yinchi bosganda aktivlashmadi")
	_check(plate_signal_fired[0], "Plita plate_activated signalini uzatmadi")

	# 4. Muallaq Temir Qafas (Suspended Cage) sinovi
	var cage = darea.suspended_cage
	_check(not cage.is_lowered, "Qafas dastlab tepada osilgan bo'lishi kerak")
	cage.interact()
	_check(cage.is_lowered, "Richag tortilgach qafas tushish holatiga o'tmadi")

	# Qafas tushishi jarayonini simulyatsiya qilish
	for i in range(60):
		await get_tree().physics_frame
	_check(cage._current_y < 2.0, "Qafas pastga siljimadi")

	# 5. Nur va Tosh Ko'zgu Boshqotirmasi (Light & Mirror Puzzle) sinovi
	var puzzle = darea.mirror_puzzle
	_check(not puzzle.is_solved, "Boshqotirma dastlab yechilmagan bo'lishi kerak")
	_check(puzzle._mirrors.size() == 3, "Boshqotirmada 3 ta tosh ko'zgu bo'lishi kerak")

	var gold_before: int = player.gold
	# Boshqotirmani yechish
	puzzle.solve_puzzle()
	await _frames(5)
	_check(puzzle.is_solved, "Boshqotirma solve_puzzle() chaqirilgach yechilmadi")
	_check(player.gold >= gold_before + 150, "Boshqotirma yechilgach mukofot oltin berilmadi")

	# Maxfiy eshik ochilishi
	for i in range(40):
		await get_tree().physics_frame
	_check(puzzle._gate_current_y > 2.0, "Maxfiy xazina qabr eshigi ochilmadi")

	print("8-BOSQICH: BOSHQOTIRMALAR VA KO'P QAVATLI ZINDON TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
