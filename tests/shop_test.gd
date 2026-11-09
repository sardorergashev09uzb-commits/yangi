extends Node
## 2-Bosqich Sinovi: Chorsu Bozori va Savdo Tizimi (Shop & Marketplace Test)

const ShopMenuScript = preload("res://scripts/ui/shop_menu.gd")
const NPCScript = preload("res://scripts/world/npc.gd")

var player: Player
var shop: CanvasLayer

func _ready() -> void:
	print("=== 2-BOSQICH: CHORSU BOZORI VA SAVDO TIZIMI SINOVI BOSHLANDI ===")

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

	# 3. Do'kon UI
	shop = ShopMenuScript.new()
	add_child(shop)

	await _frames(5)

	# --- SINOV 1: Usta Temirchi va Qilich yangilanishi ---
	player.add_gold(200) # 200 tilla
	assert(player.gold == 200, "O'yinchi tillasi 200 bo'lishi kerak")
	assert(player.is_steel_sword_equipped == false, "Dastlab po'lat qilich bo'lmasligi kerak")
	assert(player.sword_damage_bonus == 0.0, "Dastlab qilich bonusi 0 bo'lishi kerak")

	shop.open_shop("blacksmith")
	assert(shop.is_shop_open == true, "Do'kon ochilishi kerak")
	assert(shop.current_shop_type == "blacksmith", "Temirchi ochilishi kerak")

	# Temirchidan O'tkir Po'lat Qilich sotib olish (Narxi: 120 tilla)
	var sword_item: Dictionary = shop.BLACKSMITH_ITEMS[0]
	shop._buy_item(sword_item)

	assert(player.gold == 80, "200 - 120 = 80 tilla qolishi kerak, amalda: %d" % player.gold)
	assert(player.is_steel_sword_equipped == true, "Po'lat qilich jihozlangan bo'lishi kerak")
	assert(player.sword_damage_bonus == 25.0, "Qilich bonusi 25 bo'lishi kerak")
	print("✓ SINOV 1 MUVAFFAQIYATLI: Usta Temirchidan Po'lat qilich sotib olindi (+25 zarar, Qoldiq: 80 tilla)")

	# --- SINOV 2: Olovli o'qlar xaridi va Mablag' yetmaslik tekshiruvi ---
	var fire_arrows_item: Dictionary = shop.BLACKSMITH_ITEMS[2] # 50 tilla
	shop._buy_item(fire_arrows_item)
	assert(player.gold == 30, "80 - 50 = 30 tilla qolishi kerak, amalda: %d" % player.gold)
	assert(player.fire_arrows_count == 10, "10 ta olovli o'q berilishi kerak")

	# Mablag' yetmaslik: Alp Po'lat Sovuti 200 tilla turadi, ammo bizda faqat 30 tilla bor
	var armor_item: Dictionary = shop.BLACKSMITH_ITEMS[1]
	shop._buy_item(armor_item)
	assert(player.gold == 30, "Mablag' yetmaganda tilla yechilmasligi kerak")
	assert(player.is_plate_armor_equipped == false, "Sovut olinmasligi kerak")
	print("✓ SINOV 2 MUVAFFAQIYATLI: Olovli o'qlar xarid qilindi, mablag' yetmaganda xarid rad etildi")

	# --- SINOV 3: Savdogar Karvonboshi, Malham va Qimiz ---
	shop.open_shop("merchant")
	assert(shop.current_shop_type == "merchant", "Savdogar do'koni ochilishi kerak")

	# O'yinchi jarohat oladi
	player.health = 40.0
	player.health_changed.emit(player.health, player.max_health)

	# Malham sotib olish (25 tilla, +50 HP davolash)
	var salve_item: Dictionary = shop.MERCHANT_ITEMS[1]
	shop._buy_item(salve_item)
	assert(player.gold == 5, "30 - 25 = 5 tilla qolishi kerak, amalda: %d" % player.gold)
	assert(player.health == 90.0, "HP 40 + 50 = 90 bo'lishi kerak, amalda: %f" % player.health)

	# Tilla qo'shib Qimiz va Oltin Taqa sotib olamiz
	player.add_gold(210) # Balans: 215 tilla
	var qimiz_item: Dictionary = shop.MERCHANT_ITEMS[0] # 30 tilla
	shop._buy_item(qimiz_item)
	assert(player.gold == 185, "Balans 185 bo'lishi kerak")
	assert(player.qimiz_buff_timer > 0.0, "Qimiz quvvati faollashishi kerak")

	var horseshoe_item: Dictionary = shop.MERCHANT_ITEMS[2] # 180 tilla
	shop._buy_item(horseshoe_item)
	assert(player.gold == 5, "Balans 5 bo'lishi kerak")
	assert(player.has_golden_horseshoes == true, "Oltin taqa faollashishi kerak")
	print("✓ SINOV 3 MUVAFFAQIYATLI: Savdogardan malham, qimiz va oltin taqa xarid qilindi")

	# --- SINOV 4: Save & Load tizimida barcha xaridlar saqlanishi ---
	var save_data := SaveGame.collect_state()
	assert(save_data.has("player"), "Save ma'lumotlarida player bo'lishi kerak")
	var pdata: Dictionary = save_data["player"]
	assert(pdata.get("steel_sword") == true, "Po'lat qilich saqlanishi kerak")
	assert(pdata.get("horseshoes") == true, "Oltin taqa saqlanishi kerak")
	assert(pdata.get("fire_arrows") == 10, "10 ta olovli o'q saqlanishi kerak")
	assert(pdata.get("gold") == 5, "5 tilla saqlanishi kerak")

	# O'yinchi holatini nollaymiz
	player.is_steel_sword_equipped = false
	player.sword_damage_bonus = 0.0
	player.has_golden_horseshoes = false
	player.fire_arrows_count = 0
	player.gold = 0

	# Saqlangan holatni yuklaymiz
	SaveGame.apply_state(save_data)
	assert(player.is_steel_sword_equipped == true, "Qayta yuklanganda qilich tiklanishi kerak")
	assert(player.sword_damage_bonus == 25.0, "Qilich bonusi tiklanishi kerak")
	assert(player.has_golden_horseshoes == true, "Oltin taqa tiklanishi kerak")
	assert(player.fire_arrows_count == 10, "Olovli o'qlar tiklanishi kerak")
	assert(player.gold == 5, "Tilla balansi tiklanishi kerak")
	print("✓ SINOV 4 MUVAFFAQIYATLI: Do'kon xaridlari Save/Load tizimida 100% to'liq saqlanib tiklandi!")

	# --- SINOV 5: NPC interaksiyasi orqali do'kon ochilishi ---
	var smith_npc = NPCScript.new()
	smith_npc.character_type = NPCScript.CharacterType.BLACKSMITH
	add_child(smith_npc)
	smith_npc.interact()
	assert(shop.is_shop_open == true and shop.current_shop_type == "blacksmith", "NPC Temirchi orqali do'kon ochilishi kerak")
	shop.close_shop()
	assert(shop.is_shop_open == false, "Do'kon yopilishi kerak")
	print("✓ SINOV 5 MUVAFFAQIYATLI: NPC interaksiyasi do'kon oynasini to'g'ri ochdi va yopdi")

	print("=== BARCHA BOZOR VA SAVDO TIZIMI SINOVLARI A'LO DARAJADA O'TDI! ===")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
