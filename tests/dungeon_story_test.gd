extends Node
## Headless sinov: godot --headless --path . res://tests/dungeon_story_test.tscn
## 11-bosqich: Surxayil mag'lubiyati -> Zindon Darvozasi ochilishi -> Karajon va Barchinoy bilan dialoglar va kvestlar.

var main: Node
var player: Player
var arena: Node3D
var qsys: QuestSystem


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	arena = main as Node3D
	player = main.get_node("Player") as Player
	qsys = get_tree().get_first_node_in_group("quest_system") as QuestSystem
	_check(qsys != null, "quest system topilmadi")

	var dgate = arena.get("_dungeon_gate")
	var darea = arena.get("_dungeon_area")
	_check(dgate != null and darea != null, "zindon darvozasi yoki hududi topilmadi")
	_check(not dgate.is_open, "zindon darvozasi dastlab qulflangan bo'lishi kerak")

	# 1. Bossni yengish orqali darvoza ochilishini tekshirish
	arena._on_boss_defeated()
	await _frames(5)
	_check(dgate.is_open, "boss yengilgach darvoza ochilmadi")

	# 2. Portal orqali zindonga o'tish
	arena._on_dungeon_portal_entered()
	await _frames(5)
	_check(player.global_position.distance_to(Vector3(0, 0.2, -135)) < 1.0, "zindonga teleport bo'lmadi")

	# 3. Karajon bilan do'stlashish (ahd)
	_check(darea.karajon != null, "karajon topilmadi")
	darea.karajon.interact()
	await _frames(5)
	var dbox = get_tree().get_first_node_in_group("dialog_box")
	if dbox and dbox.visible:
		dbox._close_dialog(0)
	await _frames(5)
	_check(qsys.is_quest_completed("karajon_oath"), "karajon bilan qardoshlik kvesti bajarilmadi")

	# 4. Barchinoyni ozod qilish (suhbat)
	_check(darea.barchin != null, "barchinoy topilmadi")
	darea.barchin.interact()
	await _frames(5)
	if dbox and dbox.visible:
		dbox._close_dialog(0)
	await _frames(5)
	_check(qsys.is_quest_completed("rescue_barchin"), "barchinoyni qutqarish kvesti bajarilmadi")

	print("11-BOSQICH: ZINDON VA DOSTON SYUJETI TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
