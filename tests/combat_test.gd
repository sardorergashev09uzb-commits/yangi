extends Node
## Headless sinov: godot --headless --path . res://tests/combat_test.tscn
## Qilich kombosi, kamon va tuzoqdan zarar olishni tekshiradi.

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
	player.global_position = Vector3(0, 0.1, -4.3)
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
	var hp1 := dummy.health
	player.global_position = Vector3(0, 0.1, 0)
	player.rig.pitch = 0.0
	Input.action_press("aim")
	await _frames(6)
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
	print("TESTLAR O'TDI")
	get_tree().quit(0)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
