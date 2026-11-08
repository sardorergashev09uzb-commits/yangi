extends Node
## Headless sinov: godot --headless --path . res://tests/mounted_combat_test.tscn
## Ot ustidagi jang: minish, ot ustida qilich zarbasi va galop bonusini tekshiradi.

var main: Node
var player: Player
var horse: Node3D
var dummy: Dummy


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player
	dummy = main.get_children().filter(func(n): return n is Dummy)[0]
	horse = get_tree().get_first_node_in_group("horses")
	_check(horse != null, "ot topilmadi")

	# Otga minish
	horse.global_position = Vector3(8, 0.1, -1.2)
	player.global_position = horse.global_position
	await _frames(2)
	horse.mount(player)
	await _frames(5)
	_check(player.is_mounted and horse.is_mounted, "otga minib bo'lmadi")

	# Ot ustida qilich zarbasi (dummy ga urish)
	dummy.reset_dummy()
	var hp0 := dummy.health
	player.rig.yaw = 0.0
	Input.action_press("attack_light")
	await _frames(2)
	Input.action_release("attack_light")
	await _frames(25)
	print("ot ustida qilich zarari: ", hp0 - dummy.health)
	_check(dummy.health < hp0, "ot ustida qilich zarar bermadi")

	# Otdan tushish
	horse.dismount()
	await _frames(5)
	_check(not player.is_mounted and not horse.is_mounted, "otdan tushib bo'lmadi")

	print("OT USTIDAGI JANG TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
