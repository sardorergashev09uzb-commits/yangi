extends Node
## Headless sinov: godot --headless --path . res://tests/combat_test.tscn
## Qilich kombosi, kamon, dushman AI va Surxayil Boss jangini tekshiradi.

var main: Node
var player: Player
var dummy: Dummy

func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	player = main.get_node("Player") as Player
	dummy = main.get_children().filter(func(n): return n is Dummy)[0]
	print("dummy at ", dummy.position, " hp ", dummy.health)

	# 1) Qilich: kombo
	player.global_position = Vector3(8, 0.1, -0.4)
	await _frames(5)
	player.rig.yaw = 0.0
	var hp0 := dummy.health
	for i in 3:
		Input.action_press("attack_light")
		await _frames(2)
		Input.action_release("attack_light")
		await _frames(18)
	print("melee dmg: ", hp0 - dummy.health, " state ", player.state)
	_check(dummy.health < hp0, "qilich zarar bermadi")

	# 2) Kamon
	await _frames(60)
	dummy.reset_dummy()
	var hp1 := dummy.health
	player.global_position = Vector3(8, 0.1, 7.0)
	player.rig.pitch = 0.0
	Input.action_press("aim")
	await _frames(30)
	# Kamera yelka tomonga siljigan: crosshair dummyga tushishi uchun o'yinchini moslaymiz
	for i in 3:
		var aim: Dictionary = player.rig.get_aim_target(140.0, [player.get_rid()])
		player.global_position.x += dummy.global_position.x - aim.target.x
		await _frames(15)
	Input.action_press("attack_light")
	await _frames(60)
	Input.action_release("attack_light")
	await _frames(3)
	Input.action_release("aim")
	await _frames(40)
	print("bow dmg: ", hp1 - dummy.health)
	_check(dummy.health < hp1 or dummy.health <= 0.0, "kamon zarar bermadi")

	# 3) O'lim va qayta tirilish
	player.take_damage(1000.0, Vector3(0, 0, 5))
	_check(player.state == Player.State.DEAD, "o'lmadi")
	await get_tree().create_timer(3.0, true, false, true).timeout
	_check(player.state == Player.State.NORMAL and player.health > 0.0, "tirilmadi")

	# 4) Dushman AI: qilichchi
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e is BossSurxayil:
			e.queue_free()
	await _frames(3)
	player.global_position = Vector3(-22, 0.1, -4)
	player.velocity = Vector3.ZERO
	await _frames(5)
	var foe := Enemy.new()
	foe.kind = Enemy.Kind.SWORD
	foe.position = Vector3(-22, 0, -9)
	main.add_child(foe)
	var hp2 := player.health
	var t := 0
	while player.health >= hp2 and t < 600:
		await _frames(1)
		t += 1
	print("sword hit player after frames: ", t, " hp ", player.health)
	_check(player.health < hp2, "qilichchi zarar bermadi")

	# 5) Kamonchi
	foe.queue_free()
	await _frames(70)
	player.health = player.max_health
	player.global_position = Vector3(-22, 0.1, -4)
	await _frames(5)
	var archer := Enemy.new()
	archer.kind = Enemy.Kind.ARCHER
	archer.position = Vector3(-22, 0, -15)
	main.add_child(archer)
	hp2 = player.health
	t = 0
	while player.health >= hp2 and t < 600:
		await _frames(1)
		t += 1
	print("arrow hit player after frames: ", t, " hp ", player.health)
	_check(player.health < hp2, "kamonchi zarar bermadi")
	archer.take_damage(1000.0, player.global_position, 5.0)

	# 6) Surxayil Alp Boss jangi
	var boss := get_tree().get_first_node_in_group("bosses") as BossSurxayil
	_check(boss != null, "boss topilmadi")
	_check(boss.state == BossSurxayil.State.DORMANT, "boss dastlab dormant bo'lishi kerak")

	# Arenaga kirish
	player.global_position = Vector3(0, 0.1, -64)
	await _frames(10)
	_check(boss.state != BossSurxayil.State.DORMANT, "arenaga kirganda boss uyg'onmadi")
	print("Boss uyg'ondi: hp ", boss.health)

	# 1-bosqich zarari
	boss.take_damage(100.0, player.global_position)
	_check(boss.health == 180.0, "boss 1-bosqichda noto'g'ri zarar oldi")
	_check(boss.phase == 1, "boss hali 1-bosqichda bo'lishi kerak")

	# 2-bosqichga o'tish (HP <= 50% = 140)
	boss.take_damage(50.0, player.global_position)
	await _frames(2)
	_check(boss.phase == 2, "boss 2-bosqichga o'tmadi")
	_check(boss.state == BossSurxayil.State.ROAR, "2-bosqichda roar holati boshlanmadi")
	print("Boss 2-bosqichga o'tdi: phase ", boss.phase, " state ", boss.state)

	# Bossni yengish
	boss.take_damage(500.0, player.global_position)
	_check(boss.state == BossSurxayil.State.DEAD, "boss o'lmadi")
	print("Boss mag'lub etildi: state ", boss.state)

	print("BARCHA TESTLAR MUVAFFAQ QIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
