extends Node
## Step-Up sinovi: O'yinchi, Ot va Dushman kichik pog'ona va yo'laklardan sakramasdan silliq oshib o'tishini tekshiradi.

const HorseScript = preload("res://scripts/world/horse.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")

var player: Player
var horse: CharacterBody3D
var enemy: CharacterBody3D
var step_body: StaticBody3D

func _ready() -> void:
	# 1. Zamin (Y = 0)
	var ground := StaticBody3D.new()
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(60, 2, 60)
	gcol.shape = gbox
	gcol.position.y = -1.0
	ground.add_child(gcol)
	add_child(ground)

	# 2. 0.25 metrli tik tosh yo'lak / pog'ona (X = 1.0 dan 10.0 gacha, balandligi 0.25m)
	step_body = StaticBody3D.new()
	var scol := CollisionShape3D.new()
	var sbox := BoxShape3D.new()
	sbox.size = Vector3(8.0, 0.25, 20.0)
	scol.shape = sbox
	scol.position = Vector3(5.0, 0.125, 0.0) # Pog'ona X: 1.0 dan 9.0 gacha, ustki yuzasi Y = 0.25
	step_body.add_child(scol)
	add_child(step_body)

	# --- SINTOV 1: O'yinchi (Alpomish) ---
	var player_scn = load("res://scenes/player.tscn")
	player = player_scn.instantiate() as Player
	player.position = Vector3(0.0, 0.1, 0.0)
	add_child(player)

	await _frames(5)

	for f in range(50):
		player.velocity = Vector3(4.0, 0, 0)
		await get_tree().physics_frame

	print("Sinov 1 (Player): X = ", player.global_position.x, " Y = ", player.global_position.y)
	if player.global_position.x < 2.0 or player.global_position.y < 0.20:
		printerr("XATO: O'yinchi 0.25m pog'onada to'xtab qoldi!")
		get_tree().quit(1)
		return

	# --- SINOV 2: Tulpor (Boychibor) ---
	horse = HorseScript.new()
	horse.position = Vector3(0.0, 0.1, 4.0)
	add_child(horse)
	await _frames(5)

	for f in range(50):
		horse.velocity = Vector3(5.0, 0, 0)
		await get_tree().physics_frame

	var horse_foot_y := horse.global_position.y + 0.35
	print("Sinov 2 (Horse): X = ", horse.global_position.x, " Foot Y = ", horse_foot_y)
	if horse.global_position.x < 2.0 or horse_foot_y < 0.20:
		printerr("XATO: Ot 0.25m pog'onada to'xtab qoldi!")
		get_tree().quit(1)
		return

	# --- SINOV 3: Dushman (Askarlar) ---
	enemy = EnemyScript.new()
	enemy.kind = EnemyScript.Kind.SWORD
	enemy.position = Vector3(0.0, 0.1, -4.0)
	add_child(enemy)
	await _frames(5)

	for f in range(70):
		enemy.velocity = Vector3(3.5, 0, 0)
		await get_tree().physics_frame

	print("Sinov 3 (Enemy): X = ", enemy.global_position.x, " Y = ", enemy.global_position.y)
	if enemy.global_position.x < 1.5 or enemy.global_position.y < 0.20:
		printerr("XATO: Dushman 0.25m pog'onada to'xtab qoldi!")
		get_tree().quit(1)
		return

	print("BARCHA SINOVLAR MUVAFFAQIYATLI: O'yinchi, Ot va Dushman sakramasdan pog'onaga chiqdi!")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
