class_name ShopMenu
extends CanvasLayer
## Chorsu Bozori: Usta Temirchi va Karvonboshi savdo do'koni oynasi.
## Qurollar, sovutlar, o'qlar va shifobaxsh ichimliklarni sotib olish tizimi.

signal item_purchased(item_id: String, cost: int)

var is_shop_open := false
var current_shop_type: String = "blacksmith"

var _panel: Panel
var _title_label: Label
var _sub_label: Label
var _gold_label: Label
var _items_vbox: VBoxContainer
var _close_btn: Button

# Do'kon tovarlari bazasi
const BLACKSMITH_ITEMS := [
	{
		"id": "steel_sword",
		"icon": "⚔️",
		"name": "O'tkir Po'lat Qilich",
		"desc": "Yaqin jangdagi qilich zarbalariga +25 qo'shimcha zarar beradi",
		"price": 120,
		"type": "permanent"
	},
	{
		"id": "plate_armor",
		"icon": "🛡️",
		"name": "Alp Po'lat Sovuti",
		"desc": "Dushmanlarning barcha zararlarini 30% ga kamaytiradi (Mudofaa)",
		"price": 200,
		"type": "permanent"
	},
	{
		"id": "fire_arrows",
		"icon": "🔥",
		"name": "Olovli Mergan O'qlari (+10 ta)",
		"desc": "Kamon o'qlariga alanga bag'ishlaydi va dushmanni yondirib kuydiradi",
		"price": 50,
		"type": "stack"
	},
	{
		"id": "piercing_arrows",
		"icon": "🏹",
		"name": "Zirh-teshar Temir O'qlar (+10 ta)",
		"desc": "Kamon zararini +40% ga oshiradi va dushman qalqonlarini teshib o'tadi",
		"price": 70,
		"type": "stack"
	}
]

const MERCHANT_ITEMS := [
	{
		"id": "nomad_qimiz",
		"icon": "🥛",
		"name": "Ko'chmanchilar Qimizi",
		"desc": "Staminani 100% tiklaydi va 30 soniya davomida cheksiz chopish quvvatini beradi",
		"price": 30,
		"type": "instant"
	},
	{
		"id": "steppe_salve",
		"icon": "🌿",
		"name": "Shifobaxsh Dasht Malhami",
		"desc": "Salomatlikni darhol +50 HP ga davolaydi va jarohatlarni bitkazadi",
		"price": 25,
		"type": "instant"
	},
	{
		"id": "golden_horseshoes",
		"icon": "🐎",
		"name": "Boychibor uchun Oltin Taqa",
		"desc": "Tulporning chopish va yelish tezligini +20% ga oshiradi",
		"price": 180,
		"type": "permanent"
	}
]


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("shop_menu")
	_build_ui()
	visible = false


func _build_ui() -> void:
	# Qoraytirilgan orqa fon
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.03, 0.03, 0.85)
	add_child(backdrop)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -380
	_panel.offset_right = 380
	_panel.offset_top = -280
	_panel.offset_bottom = 280

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.08, 0.07, 0.96)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.9, 0.75, 0.25) # Oltin naqsh hoshiya
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 24
	main_vbox.offset_right = -24
	main_vbox.offset_top = 18
	main_vbox.offset_bottom = -18
	_panel.add_child(main_vbox)

	# Yuqori sarlavha va oltin balansi
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_vbox)

	_title_label = Label.new()
	_title_label.text = "⚔️ USTA TEMIRCHI O'CHOG'I"
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	title_vbox.add_child(_title_label)

	_sub_label = Label.new()
	_sub_label.text = "Po'lat qurollar, alp sovuti va mergan o'qlari"
	_sub_label.add_theme_font_size_override("font_size", 13)
	_sub_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	title_vbox.add_child(_sub_label)

	_gold_label = Label.new()
	_gold_label.text = "🪙 0 Tilla"
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	header_hbox.add_child(_gold_label)

	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# Tovarlar ro'yxati (Scrollable)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	_items_vbox = VBoxContainer.new()
	_items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(_items_vbox)

	var sep2 := HSeparator.new()
	main_vbox.add_child(sep2)

	# Pastki Chiqish tugmasi
	var footer_hbox := HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_END
	main_vbox.add_child(footer_hbox)

	_close_btn = Button.new()
	_close_btn.text = "Chiqish [ ESC ]"
	_close_btn.custom_minimum_size = Vector2(160, 36)
	_close_btn.pressed.connect(close_shop)
	footer_hbox.add_child(_close_btn)


func _unhandled_input(event: InputEvent) -> void:
	if not is_shop_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			close_shop()
			get_viewport().set_input_as_handled()


func open_shop(shop_type: String) -> void:
	current_shop_type = shop_type
	is_shop_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if shop_type == "blacksmith":
		_title_label.text = "⚔️ USTA TEMIRCHI O'CHOG'I"
		_sub_label.text = "Po'lat qurollar, pishiq sovutlar va jangovar o'q-dorilar"
	else:
		_title_label.text = "🐫 KARVONBOSHI BOZORI"
		_sub_label.text = "Buyuk Ipak Yo'li tuhfalari, qimiz va shifobaxsh malhamlar"

	refresh_items()


func close_shop() -> void:
	is_shop_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func refresh_items() -> void:
	for child in _items_vbox.get_children():
		child.queue_free()

	var player = get_tree().get_first_node_in_group("player")
	var current_gold := 0
	if player and player.get("gold") != null:
		current_gold = int(player.get("gold"))
	_gold_label.text = "🪙 %d Tilla" % current_gold

	var items: Array = BLACKSMITH_ITEMS if current_shop_type == "blacksmith" else MERCHANT_ITEMS

	for item in items:
		var row := _build_item_row(item, player, current_gold)
		_items_vbox.add_child(row)


func _build_item_row(item: Dictionary, player: Node, current_gold: int) -> PanelContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.12, 0.9)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.45, 0.38, 0.25)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	pc.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	pc.add_child(hbox)

	# Rasm/Belgi
	var icon_lbl := Label.new()
	icon_lbl.text = item.icon
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.custom_minimum_size = Vector2(40, 40)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	# Nomi va tavsifi
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	text_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item.desc
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_vbox.add_child(desc_lbl)

	# Narxi
	var price_lbl := Label.new()
	price_lbl.text = "🪙 %d" % item.price
	price_lbl.add_theme_font_size_override("font_size", 16)
	price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	price_lbl.custom_minimum_size = Vector2(90, 0)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(price_lbl)

	# Sotib olish tugmasi
	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(130, 36)

	# Holat tekshiruvi (allaqachon olinganmi yoki tilla yetadimi)
	var already_owned := false
	if player:
		if item.id == "steel_sword" and player.get("is_steel_sword_equipped"):
			already_owned = true
		elif item.id == "plate_armor" and player.get("is_plate_armor_equipped"):
			already_owned = true
		elif item.id == "golden_horseshoes" and player.get("has_golden_horseshoes"):
			already_owned = true

	if already_owned:
		buy_btn.text = "OLINGAN ✓"
		buy_btn.disabled = true
	elif current_gold < item.price:
		buy_btn.text = "Tilla kam"
		buy_btn.disabled = true
	else:
		buy_btn.text = "Sotib olish"
		buy_btn.pressed.connect(func(): _buy_item(item))

	hbox.add_child(buy_btn)
	return pc


func _buy_item(item: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return

	if not player.has_method("spend_gold") or not player.spend_gold(item.price):
		return

	# Buyumni qo'llash
	match item.id:
		"steel_sword":
			if player.has_method("upgrade_sword"):
				player.upgrade_sword()
		"plate_armor":
			if player.has_method("upgrade_armor"):
				player.upgrade_armor()
		"fire_arrows":
			var cur: int = int(player.get("fire_arrows_count"))
			player.set("fire_arrows_count", cur + 10)
		"piercing_arrows":
			var cur: int = int(player.get("piercing_arrows_count"))
			player.set("piercing_arrows_count", cur + 10)
		"nomad_qimiz":
			if player.has_method("apply_qimiz_buff"):
				player.apply_qimiz_buff(35.0)
		"steppe_salve":
			if player.has_method("heal_hp"):
				player.heal_hp(50.0)
		"golden_horseshoes":
			player.set("has_golden_horseshoes", true)
			for h in get_tree().get_nodes_in_group("horses"):
				if h and is_instance_valid(h):
					h.set("sprint_speed", 19.2) # 16.0 * 1.2

	item_purchased.emit(item.id, item.price)
	refresh_items()
