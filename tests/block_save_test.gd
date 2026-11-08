extends Node
## Headless sinov: godot --headless --path . res://tests/block_save_test.tscn
## Blok, parry va saqlash/yuklash tizimini tekshiradi.

var main: Node
var player: Player


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player
	player.global_position = Vector3(0, 0.1, 0)
	await _frames(5)

	# 1) Oddiy blok: kuch yetarli bo'lsa zarar yo'q (orqada emas, oldidan)
	Input.action_press("block")
	await _frames(20)  # parry oynasidan o'tish
	_check(player.is_blocking, "blok holatiga o'tmadi")
	var front := player.global_position + Vector3(-sin(player.model.rotation.y), 0, -cos(player.model.rotation.y)) * 2.0
	var hp := player.health
	var st := player.stamina
	player.take_damage(20.0, front, 5.0)
	_check(player.health == hp, "blok zararni to'smadi")
	_check(player.stamina < st, "blok kuch sarflamadi")

	# 2) Orqadan zarba blokni chetlab o'tadi
	var back := player.global_position - (front - player.global_position)
	player.take_damage(10.0, back, 5.0)
	_check(player.health < hp, "orqadan zarba o'tmadi")
	Input.action_release("block")
	await _frames(40)

	# 3) Parry: blok boshlanishidan zumda zarba
	player.health = player.max_health
	player.stamina = player.max_stamina
	player._hit_invuln = 0.0
	Input.action_press("block")
	await _frames(3)
	_check(player.is_blocking and player._block_time <= Player.PARRY_WINDOW, "parry oynasi yo'q")
	hp = player.health
	front = player.global_position + Vector3(-sin(player.model.rotation.y), 0, -cos(player.model.rotation.y)) * 2.0
	player.take_damage(30.0, front, 5.0)
	_check(player.health == hp, "parry zararni to'smadi")
	Input.action_release("block")
	await _frames(10)

	# 4) Saqlash / yuklash
	var prog = get_tree().get_first_node_in_group("progression")
	prog.add_xp(100)
	var lvl: int = prog.level
	var sp: int = prog.skill_points
	player.global_position = Vector3(5, 0.1, 5)
	_check(SaveGame.save_game(), "saqlab bo'lmadi")
	prog.level = 1
	prog.skill_points = 0
	player.global_position = Vector3(-9, 0.1, -9)
	_check(SaveGame.load_game(), "yuklab bo'lmadi")
	_check(prog.level == lvl and prog.skill_points == sp, "progress tiklanmadi")
	_check(player.global_position.distance_to(Vector3(5, 0.3, 5)) < 1.0, "joylashuv tiklanmadi")
	DirAccess.remove_absolute(SaveGame.SAVE_PATH)

	print("BLOK VA SAQLASH TESTLARI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
