extends Node
## Headless sinov: godot --headless --path . res://tests/special_skill_test.tscn
## 13-bosqich: Alpomishning maxsus qobiliyati "Alp Gumburi" (C tugmasi) va tevarakdagi dushmanlarga zarar berishini tekshiradi.

var main: Node
var player: Player
var dummy: Dummy


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player
	dummy = main.get_children().filter(func(n): return n is Dummy)[0]

	dummy.reset_dummy()
	dummy.global_position = Vector3(4, 0, 0)
	player.global_position = Vector3(1, 0.1, 0)
	player.stamina = player.max_stamina
	player._special_cooldown_timer = 0.0
	await _frames(5)

	var hp0 := dummy.health
	var st0 := player.stamina

	# C tugmasi (skill_special) bosiladi
	Input.action_press("skill_special")
	await _frames(2)
	Input.action_release("skill_special")
	# 0.35s windup = ~21 frames, so'ng earthquake to'lqini 14m/s bilan kengayadi
	await _frames(45) # Havoga sakrab zarba berish va to'lqin tarqalishi

	print("Alp Gumburi zarari: ", hp0 - dummy.health, " stamina sarfi: ", st0 - player.stamina)
	_check(dummy.health < hp0, "Alp Gumburi dummyga zarar bermadi")
	_check(player.stamina < st0, "Alp Gumburi stamina sarflamadi")
	_check(player._special_cooldown_timer > 0.0, "Alp Gumburi cooldown ishlamadi")

	print("13-BOSQICH: MAXSUS QOBILIYAT TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
