extends Node
## 3-Bosqich Sinovi: Dasht Resurslari va Hunarmandchilik (Gathering & Crafting Test)

const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")
const CraftingMenuScript = preload("res://scripts/ui/crafting_menu.gd")

var player: Player
var craft_menu: CanvasLayer

func _ready() -> void:
	print("=== 3-BOSQICH: DASHT RESURSLARI VA HUNARMANDCHILIK SINOVI BOSHLANDI ===")

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

	# 3. Hunarmandchilik menyusi
	craft_menu = CraftingMenuScript.new()
	add_child(craft_menu)

	await _frames(5)

	# --- SINOV 1: Resurs Node'laridan xom-ashyo yig'ish (Mining, Chopping, Gathering) ---
	assert(player.iron_ore == 0 and player.wood == 0 and player.herbs == 0, "Boshlang'ich resurslar 0 bo'lishi kerak")

	# 1.1 Temir rudasi
	var ore := ResourceNodeScript.new()
	ore.resource_node_id = "test_ore_01"
	ore.resource_type = ResourceNodeScript.Type.IRON_ORE
	ore.yield_amount = 3
	ore.hits_required = 2
	add_child(ore)

	# 1-zarba: hali tugamaydi
	ore.harvest(player)
	assert(ore.is_depleted == false, "1-zarbadan keyin ruda tugamasligi kerak")
	assert(player.iron_ore == 0, "Ruda to'liq qazib olinmaguncha resurs berilmasligi kerak")

	# 2-zarba: to'liq qazib olinadi
	ore.harvest(player)
	assert(ore.is_depleted == true, "2-zarbadan keyin ruda tugashi kerak")
	assert(player.iron_ore == 3, "O'yinchiga 3 ta temir rudasi berilishi kerak, amalda: %d" % player.iron_ore)

	# 1.2 Qora saksovul yog'ochi
	var wood_node := ResourceNodeScript.new()
	wood_node.resource_node_id = "test_wood_01"
	wood_node.resource_type = ResourceNodeScript.Type.WOOD
	wood_node.yield_amount = 4
	wood_node.hits_required = 2
	add_child(wood_node)

	wood_node.harvest(player)
	wood_node.harvest(player)
	assert(wood_node.is_depleted == true, "Yog'och tugashi kerak")
	assert(player.wood == 4, "O'yinchiga 4 ta yog'och berilishi kerak, amalda: %d" % player.wood)

	# 1.3 Dasht giyohlari
	var herb_node := ResourceNodeScript.new()
	herb_node.resource_node_id = "test_herb_01"
	herb_node.resource_type = ResourceNodeScript.Type.HERBS
	herb_node.yield_amount = 5
	herb_node.hits_required = 1
	add_child(herb_node)

	herb_node.harvest(player)
	assert(herb_node.is_depleted == true, "Giyoh 1 martada yig'ilishi kerak")
	assert(player.herbs == 5, "O'yinchiga 5 ta giyoh berilishi kerak, amalda: %d" % player.herbs)

	print("✓ SINOV 1 MUVAFFAQIYATLI: Resurs nodelaridan Temir (3), Yog'och (4) va Giyoh (5) yig'ildi")

	# --- SINOV 2: Hunarmandchilik Menyusi va Retseptlar (Crafting) ---
	craft_menu.open_menu()
	assert(craft_menu.is_open == true, "Menyu ochilishi kerak")

	# Retsept 1: Kamon O'qlari (2 Yog'och + 1 Temir) -> Muvaffaqiyatli
	var arrow_rec: Dictionary = craft_menu.RECIPES[0]
	var crafted_arrows: bool = craft_menu.craft_recipe(arrow_rec)
	assert(crafted_arrows == true, "Kamon o'qlari yasalishi kerak")
	assert(player.wood == 2, "Yog'och 4 - 2 = 2 qolishi kerak, amalda: %d" % player.wood)
	assert(player.iron_ore == 2, "Temir 3 - 1 = 2 qolishi kerak, amalda: %d" % player.iron_ore)

	# Retsept 2: Olovli Mash'ala (2 Yog'och + 2 Giyoh) -> Mash'ala yoqiladi
	var torch_rec: Dictionary = craft_menu.RECIPES[3]
	var crafted_torch: bool = craft_menu.craft_recipe(torch_rec)
	assert(crafted_torch == true, "Mash'ala yasalishi kerak")
	assert(player.wood == 0, "Yog'och 2 - 2 = 0 qolishi kerak, amalda: %d" % player.wood)
	assert(player.herbs == 3, "Giyoh 5 - 2 = 3 qolishi kerak, amalda: %d" % player.herbs)
	assert(player.torch_active == true, "Olovli mash'ala faollashishi kerak")
	assert(player.torch_node != null and player.torch_node.visible == true, "Mash'ala nuri ko'rinishi kerak")

	# Retsept 3: Shifobaxsh Dasht Malhami (3 Giyoh) -> +50 HP davolash
	player.health = 35.0
	var salve_rec: Dictionary = craft_menu.RECIPES[4]
	var crafted_salve: bool = craft_menu.craft_recipe(salve_rec)
	assert(crafted_salve == true, "Malham yasalishi kerak")
	assert(player.herbs == 0, "Giyoh 3 - 3 = 0 qolishi kerak, amalda: %d" % player.herbs)
	assert(player.health == 85.0, "Salomatlik 35 + 50 = 85 bo'lishi kerak, amalda: %f" % player.health)

	print("✓ SINOV 2 MUVAFFAQIYATLI: Kamon o'qlari, Olovli mash'ala va Malham yasash to'g'ri ishladi")

	# --- SINOV 3: Resurslar yetarli bo'lmaganda xatoliksiz rad etish ---
	# Zirh-teshar o'qlar uchun 1 Yog'och + 3 Temir kerak, bizda esa 0 Yog'och va 2 Temir bor
	var piercing_rec: Dictionary = craft_menu.RECIPES[1]
	var failed_craft: bool = craft_menu.craft_recipe(piercing_rec)
	assert(failed_craft == false, "Resurs yetmaganda yasash rad etilishi kerak")
	assert(player.wood == 0 and player.iron_ore == 2, "Resurslar sarflanmasdan qolishi kerak")
	print("✓ SINOV 3 MUVAFFAQIYATLI: Yetarli xom-ashyo bo'lmaganda yasash to'g'ri rad etildi")

	# --- SINOV 4: Save & Load tizimida resurslar va tugagan nodelar holati ---
	var save_data := SaveGame.collect_state()
	assert(save_data.has("player"), "Save ma'lumotlarida player bo'lishi kerak")
	var pdata: Dictionary = save_data["player"]
	assert(pdata.get("iron_ore") == 2, "2 ta temir saqlanishi kerak")
	assert(pdata.get("wood") == 0, "0 ta yog'och saqlanishi kerak")
	assert(pdata.get("herbs") == 0, "0 ta giyoh saqlanishi kerak")
	assert(pdata.get("torch") == true, "Mash'ala holati saqlanishi kerak")
	assert(save_data.has("harvested_nodes"), "Yig'ib olingan nodelar saqlanishi kerak")
	var hnodes: Array = save_data["harvested_nodes"]
	assert("test_ore_01" in hnodes and "test_wood_01" in hnodes and "test_herb_01" in hnodes, "Tugagan barcha nodelar saqlanishi kerak")

	# O'yinchi holatini nollaymiz
	player.iron_ore = 0
	player.wood = 0
	player.herbs = 0
	player.enable_torch(false)

	# Saqlangan holatni yuklaymiz
	SaveGame.apply_state(save_data)
	assert(player.iron_ore == 2, "Temir 2 ga tiklanishi kerak")
	assert(player.wood == 0, "Yog'och 0 ga tiklanishi kerak")
	assert(player.herbs == 0, "Giyoh 0 ga tiklanishi kerak")
	assert(player.torch_active == true, "Mash'ala faol holatda tiklanishi kerak")
	print("✓ SINOV 4 MUVAFFAQIYATLI: Resurslar, mash'ala va yig'ilgan konlar Save/Load da to'liq tiklandi")

	# --- SINOV 5: Menyu ochish va yopish ---
	craft_menu.close_menu()
	assert(craft_menu.is_open == false, "Menyu yopilishi kerak")
	craft_menu.toggle_menu()
	assert(craft_menu.is_open == true, "Toggle bilan menyu ochilishi kerak")
	craft_menu.toggle_menu()
	assert(craft_menu.is_open == false, "Toggle bilan menyu yopilishi kerak")
	print("✓ SINOV 5 MUVAFFAQIYATLI: Hunarmandchilik menyusi ochish/yopish to'liq ishladi")

	print("=== BARCHA DASHT RESURSLARI VA HUNARMANDCHILIK SINOVLARI A'LO DARAJADA O'TDI! ===")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
