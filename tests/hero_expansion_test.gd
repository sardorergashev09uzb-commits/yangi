extends Node
## Headless sinov: godot --headless --path . res://tests/hero_expansion_test.tscn
## Alpomish yangi grafikasi (Dubulg'a, Qalqon, Yopinchiq), Bo'ron Hayqirig'i, Simurg' parvozi va Boychibor Pegas sakrashi.

const MirageDesertScript = preload("res://scripts/world/mirage_desert.gd")

var main: Node
var player: Player
var dummy: Dummy
var horse: Horse


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)

	player = main.get_node("Player") as Player
	dummy = main.get_children().filter(func(n): return n is Dummy)[0]
	horse = main.get_children().filter(func(n): return n is Horse)[0]

	_check(player != null, "player topilmadi")
	_check(dummy != null, "dummy topilmadi")
	_check(horse != null, "horse topilmadi")

	# 1. Vizual qismlar mavjudligi tekshiruvi (Dubulg'a, Qalqon, Yopinchiq, Simurg' qanotlari)
	_check(player._helmet != null, "Alpomish dubulg'asi mavjud emas")
	_check(player._shield != null, "Alpomish qalqoni mavjud emas")
	_check(player._cape_pivot != null, "Alpomish yopinchiq pivot mavjud emas")
	_check(player._pauldrons != null, "Alpomish yelkadoshlari mavjud emas")
	_check(player._simurgh_wings != null, "Simurg' qanotlari mavjud emas")

	# 2. Qalqon bilan blok qilish va parry
	player.state = Player.State.BLOCK
	player._block_time = 0.05 # Parry oynasi ichida
	var reduced := player._try_block(30.0, player.global_position + Vector3.FORWARD * 2.0)
	_check(reduced == 0.0, "Parry zararni to'liq qaytarmadi")

	# 3. Bo'ron Hayqirig'i (Battle Cry) tekshiruvi
	dummy.reset_dummy()
	dummy.global_position = player.global_position + Vector3(3.0, 0, 0)
	player.stamina = player.max_stamina
	player._battle_cry_cooldown = 0.0
	var hp0 := dummy.health
	var st0 := player.stamina

	player._execute_battle_cry()
	await _frames(5)

	_check(dummy.health < hp0, "Bo'ron Hayqirig'i dummyga zarar bermadi")
	_check(player.stamina < st0, "Bo'ron Hayqirig'i stamina sarflamadi")
	_check(player._battle_cry_cooldown > 0.0, "Bo'ron Hayqirig'i cooldown boshlanmadi")
	_check(player._battle_cry_buff_timer > 0.0, "Bo'ron Hayqirig'i Alp G'ayrati buffi berilmadi")

	# 4. Simurg' Parvozi (Gliding) tekshiruvi
	player.global_position = Vector3(0, 10.0, 0)
	player.velocity = Vector3(0, -3.0, 0)
	player.move_and_slide()
	await _frames(2)
	Input.action_press("jump")
	player._normal(0.016)
	_check(player.is_gliding, "Simurg' parvozi faollashmadi")
	_check(player.velocity.y >= -2.1, "Simurg' parvozi tushish tezligini ushlab qolmadi")
	Input.action_release("jump")

	# 5. Boychibor Pegas Sakrashi (Pegasus Leap)
	horse.global_position = Vector3(0, 0.2, 0)
	horse.velocity = Vector3.ZERO
	player.global_position = horse.global_position
	# Boychiborga minish
	horse.mount(player)
	_check(horse.is_mounted, "Boychiborga minilmadi")

	# Chopganda sakrash (Gallop leap)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	Input.action_press("jump")
	await _frames(2)
	_check(horse.velocity.y > 9.0, "Boychibor Pegas sakrashi baland sakramadi")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	Input.action_release("jump")

	# 6. Qoraqum Sarobi Sahrosi (Mirage Desert biome & Ruins)
	var desert: Node3D = null
	for c in main.get_children():
		if c.name == "MirageDesert" or c.get_script() == MirageDesertScript:
			desert = c
			break
	_check(desert != null, "MirageDesert sahnada topilmadi")
	_check(desert._sandstorm != null, "Sahro qum bo'roni topilmadi")

	print("HERO & DESERT EXPANSION: BARCHA GRAFIK, MAHORAT VA SAHRO BIOMI TESTI MUVAFFAQIYATLI O'TDI!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		printerr("XATO: ", msg)
		get_tree().quit(1)
