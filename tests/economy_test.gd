extends Node
## 1-Bosqich Sinovi: Iqtisodiyot, Tilla tangalar va Xazina sandiqlari (Economy & Loot Test)

const TreasureChestScript = preload("res://scripts/world/treasure_chest.gd")
const CoinDropScript = preload("res://scripts/world/coin_drop.gd")

var player: Player
var chest: Node3D

func _ready() -> void:
	print("=== 1-BOSQICH: IQTISODIYOT VA TILLA TIZIMI SINOVI BOSHLANDI ===")

	# 1. Zamin
	var ground := StaticBody3D.new()
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(50, 2, 50)
	gcol.shape = gbox
	gcol.position.y = -1.0
	ground.add_child(gcol)
	add_child(ground)

	# 2. O'yinchi
	var player_scn = load("res://scenes/player.tscn")
	player = player_scn.instantiate() as Player
	player.position = Vector3(0, 0.1, 0)
	add_child(player)

	await _frames(5)

	# --- SINOV 1: O'yinchining tilla hisob-kitob funksiyalari ---
	assert(player.gold == 0, "Dastlabki tilla 0 bo'lishi kerak")
	player.add_gold(50)
	assert(player.gold == 50, "50 tilla qo'shilgandan so'ng 50 bo'lishi kerak")
	var spent := player.spend_gold(20)
	assert(spent == true and player.gold == 30, "20 tilla sarflanganda 30 qolishi kerak")
	var overspent := player.spend_gold(100)
	assert(overspent == false and player.gold == 30, "Yetarli tilla bo'lmaganda sarflanmasligi kerak")
	print("✓ SINOV 1 MUVAFFAQIYATLI: O'yinchi hamyoni to'g'ri ishladi (Balans: 30)")

	# --- SINOV 2: Tilla tanga tushishi va magnit bilan yig'ib olinishi ---
	var coin := CoinDropScript.new()
	coin.value = 25
	coin.position = Vector3(1.5, 0.5, 0.0)
	add_child(coin)

	# Bir necha kadr kutamiz, tanga o'yinchiga tortilib yig'iladi
	for i in range(30):
		await get_tree().physics_frame

	print("Player gold coin yig'ilgach: ", player.gold)
	assert(player.gold == 55, "Tanga yig'ilgandan so'ng tilla 55 bo'lishi kerak (30 + 25)")
	print("✓ SINOV 2 MUVAFFAQIYATLI: Tilla tanga o'yinchiga magnitdek tortilib yig'ildi (Balans: 55)")

	# --- SINOV 3: Qadimiy Xazina Sandig'i (Treasure Chest) ---
	chest = TreasureChestScript.new()
	chest.chest_id = "test_chest_01"
	chest.gold_amount = 40
	chest.position = Vector3(2.0, 0.0, 0.0)
	add_child(chest)

	await _frames(2)
	assert(chest.is_opened == false, "Sandiq dastlab yopiq bo'lishi kerak")

	# Sandiqni ochish
	chest.open_chest(player)
	assert(chest.is_opened == true, "Sandiq ochilishi kerak")

	# Sandiqdan tushgan tangalar o'yinchiga yetib kelishi uchun kutamiz
	for i in range(40):
		await get_tree().physics_frame

	print("Player gold sandiq ochilgach: ", player.gold)
	assert(player.gold >= 95, "Sandiq ochilgach tilla 95 bo'lishi kerak (55 + 40)")
	print("✓ SINOV 3 MUVAFFAQIYATLI: Xazina sandig'i ochildi va oltinlar muvaffaqiyatli o'zlashtirildi!")

	# --- SINOV 4: Saqlash va Yuklash (Save/Load) integratsiyasi ---
	var save_ok = SaveGame.save_game()
	assert(save_ok == true, "O'yin holati saqlanishi kerak")

	# O'yinchi balansini va sandiq holatini vaqtincha buzamiz
	player.gold = 0
	chest.is_opened = false

	# Saqlangan holatni yuklaymiz
	var load_ok = SaveGame.load_game()
	assert(load_ok == true, "O'yin holati yuklanishi kerak")
	assert(player.gold >= 95, "Yuklanganda o'yinchi tillasi qayta tiklanishi kerak")
	assert(chest.is_opened == true, "Yuklanganda ochilgan sandiq ochiq holda qolishi kerak")
	print("✓ SINOV 4 MUVAFFAQIYATLI: Tilla va xazina sandiqlari Save/Load tizimida to'liq tiklandi!")

	print("=== BARCHA IQTISODIYOT SINOVLARI A'LO DARAJADA O'TDI! ===")
	get_tree().quit(0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
