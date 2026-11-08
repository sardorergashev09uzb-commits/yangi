extends Node
## Headless sinov: godot --headless --path . res://tests/ai_nav_test.tscn
## Dushman AI to'siqni (rampa, o'tov) aylanib o'tib, o'yinchiga yetib borishini tekshiradi.

var main: Node
var player: Player


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	await _frames(3)

	# Rampa (-6, 6) o'yinchi bilan dushman o'rtasida turadi
	await _reach("rampa", Vector3(-6, 0.1, 14), Vector3(-6, 0, -1))
	# O'tov qishlog'i yaqinida
	await _reach("o'tov", Vector3(20, 0.1, 20), Vector3(20, 0, 8))
	print("AI NAVIGATSIYA TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _reach(label: String, player_pos: Vector3, foe_pos: Vector3) -> void:
	player.health = player.max_health
	player.global_position = player_pos
	player.velocity = Vector3.ZERO
	await _frames(5)
	var foe := Enemy.new()
	foe.kind = Enemy.Kind.SWORD
	foe.position = foe_pos
	main.add_child(foe)
	await _frames(2)
	foe._alert()  # ko'rinish to'silgan bo'lsa ham chaqirilgan holatda sinaymiz
	var hp := player.health
	var t := 0
	while player.health >= hp and t < 1500:
		await _frames(1)
		t += 1
	print(label, ": dushman yetib keldi, kadrlar=", t, " hp=", player.health)
	_check(player.health < hp, label + ": dushman to'siqdan o'ta olmadi")
	foe.queue_free()
	await _frames(10)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
