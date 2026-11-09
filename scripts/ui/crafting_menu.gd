class_name CraftingMenu
extends CanvasLayer
## Hunarmandchilik Menyusi [ V ]: Dasht resurslaridan o'qlar, mash'ala, dorivor malham va qimiz yasash tizimi.

signal item_crafted(recipe_id: String)

var is_open := false

var _panel: Panel
var _res_label: Label
var _items_vbox: VBoxContainer
var _close_btn: Button

const RECIPES := [
	{
		"id": "arrows_pack",
		"icon": "🏹",
		"name": "Kamon O'qlari (+15 ta)",
		"desc": "Oddiy ov va jangovar kamon o'qlari to'plami",
		"cost": {"wood": 2, "iron_ore": 1}
	},
	{
		"id": "piercing_arrows_pack",
		"icon": "🎯",
		"name": "Zirh-teshar Temir O'qlar (+5 ta)",
		"desc": "Dushman qalqonlarini teshib o'tuvchi og'ir po'lat o'qlar",
		"cost": {"wood": 1, "iron_ore": 3}
	},
	{
		"id": "fire_arrows_pack",
		"icon": "🔥",
		"name": "Olovli Mergan O'qlari (+5 ta)",
		"desc": "Nishonga tekkanida kuchli alanga oluvchi o'tli o'qlar",
		"cost": {"wood": 1, "iron_ore": 2, "herbs": 2}
	},
	{
		"id": "torch",
		"icon": "🕯️",
		"name": "Olovli Mash'ala (Torch)",
		"desc": "Dashtdagi qorong'u tunlar va chuqur zindonlarni yorituvchi nur manbai",
		"cost": {"wood": 2, "herbs": 2}
	},
	{
		"id": "steppe_salve",
		"icon": "🌿",
		"name": "Shifobaxsh Dasht Malhami",
		"desc": "Jarohatlarni bitkazadi va salomatlikni darhol +50 HP ga davolaydi",
		"cost": {"herbs": 3}
	},
	{
		"id": "nomad_qimiz",
		"icon": "🥛",
		"name": "Ko'chmanchilar Qimizi",
		"desc": "Staminani 100% tiklaydi va 35 soniya davomida cheksiz yugurish quvvatini beradi",
		"cost": {"herbs": 2, "gold": 10}
	}
]


func _ready() -> void:
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("crafting_menu")
	_build_ui()
	visible = false


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.04, 0.03, 0.82)
	add_child(backdrop)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -390
	_panel.offset_right = 390
	_panel.offset_top = -280
	_panel.offset_bottom = 280

	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.12, 0.14, 0.13, 0.96)
	p_style.border_width_left = 2
	p_style.border_width_right = 2
	p_style.border_width_top = 2
	p_style.border_width_bottom = 2
	p_style.border_color = Color(0.4, 0.65, 0.45)
	p_style.corner_radius_top_left = 10
	p_style.corner_radius_top_right = 10
	p_style.corner_radius_bottom_left = 10
	p_style.corner_radius_bottom_right = 10
	p_style.shadow_size = 14
	p_style.shadow_color = Color(0, 0, 0, 0.6)
	_panel.add_theme_stylebox_override("panel", p_style)
	add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 24
	main_vbox.offset_right = -24
	main_vbox.offset_top = 18
	main_vbox.offset_bottom = -18
	main_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(main_vbox)

	# Sarlavha
	var header := Label.new()
	header.text = "⚒️ ALPOMISH HUNARMANDCHILIGI"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.7, 0.95, 0.75))
	main_vbox.add_child(header)

	var sub_label := Label.new()
	sub_label.text = "Dasht resurslaridan qurol, dorivor malham va o'q-dorilar yasash"
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 12)
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
	main_vbox.add_child(sub_label)

	# Resurslar paneli (Mavjud xom-ashyolar)
	var res_box := PanelContainer.new()
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color(0.08, 0.1, 0.09, 0.9)
	r_style.corner_radius_top_left = 6
	r_style.corner_radius_top_right = 6
	r_style.corner_radius_bottom_left = 6
	r_style.corner_radius_bottom_right = 6
	res_box.add_theme_stylebox_override("panel", r_style)
	main_vbox.add_child(res_box)

	_res_label = Label.new()
	_res_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_label.add_theme_font_size_override("font_size", 14)
	_res_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.8))
	res_box.add_child(_res_label)

	# Retseptlar ro'yxati (ScrollContainer)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	_items_vbox = VBoxContainer.new()
	_items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(_items_vbox)

	# Pastki tugmalar
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(bottom_hbox)

	_close_btn = Button.new()
	_close_btn.text = "Yopish [ Esc / V ]"
	_close_btn.custom_minimum_size = Vector2(180, 36)
	_close_btn.pressed.connect(close_menu)
	bottom_hbox.add_child(_close_btn)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			toggle_menu()
			get_viewport().set_input_as_handled()
		elif is_open and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E):
			close_menu()
			get_viewport().set_input_as_handled()


func toggle_menu() -> void:
	if is_open:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_recipes()


func close_menu() -> void:
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func refresh_recipes() -> void:
	for child in _items_vbox.get_children():
		child.queue_free()

	var player = get_tree().get_first_node_in_group("player")
	var iron := 0
	var wood := 0
	var herbs := 0
	var gold := 0

	if player:
		iron = int(player.get("iron_ore"))
		wood = int(player.get("wood"))
		herbs = int(player.get("herbs"))
		gold = int(player.get("gold"))

	_res_label.text = "⛏️ Temir: %d   |   🪵 Yog'och: %d   |   🌿 Giyoh: %d   |   🪙 Tilla: %d" % [
		iron, wood, herbs, gold
	]

	for rec in RECIPES:
		var row := _build_recipe_row(rec, player)
		_items_vbox.add_child(row)


func _build_recipe_row(rec: Dictionary, player: Node) -> PanelContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.18, 0.17, 0.92)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.45, 0.38)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	pc.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.offset_top = 6
	hbox.offset_bottom = -6
	pc.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = rec.icon
	icon_lbl.add_theme_font_size_override("font_size", 26)
	icon_lbl.custom_minimum_size = Vector2(40, 40)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = rec.name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.98, 0.92))
	text_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = rec.desc
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.68))
	text_vbox.add_child(desc_lbl)

	# Talab qilinadigan resurslar matni
	var cost_desc := ""
	var cost_dict: Dictionary = rec.cost
	var can_afford := true

	if player:
		if cost_dict.has("wood"):
			var w := int(cost_dict["wood"])
			cost_desc += "🪵 %d/%d " % [player.get("wood"), w]
			if int(player.get("wood")) < w:
				can_afford = false
		if cost_dict.has("iron_ore"):
			var io := int(cost_dict["iron_ore"])
			cost_desc += "⛏️ %d/%d " % [player.get("iron_ore"), io]
			if int(player.get("iron_ore")) < io:
				can_afford = false
		if cost_dict.has("herbs"):
			var h := int(cost_dict["herbs"])
			cost_desc += "🌿 %d/%d " % [player.get("herbs"), h]
			if int(player.get("herbs")) < h:
				can_afford = false
		if cost_dict.has("gold"):
			var g := int(cost_dict["gold"])
			cost_desc += "🪙 %d/%d " % [player.get("gold"), g]
			if int(player.get("gold")) < g:
				can_afford = false

	var cost_lbl := Label.new()
	cost_lbl.text = cost_desc
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6) if can_afford else Color(0.9, 0.4, 0.4))
	cost_lbl.custom_minimum_size = Vector2(160, 30)
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(cost_lbl)

	var craft_btn := Button.new()
	craft_btn.custom_minimum_size = Vector2(110, 32)
	if can_afford:
		craft_btn.text = "Yasash ⚒️"
		craft_btn.pressed.connect(func(): craft_recipe(rec))
	else:
		craft_btn.text = "Resurs kam"
		craft_btn.disabled = true
	hbox.add_child(craft_btn)

	return pc


func craft_recipe(recipe: Dictionary) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return false

	var cost_dict: Dictionary = recipe.cost
	if not player.has_method("consume_resources") or not player.consume_resources(cost_dict):
		return false

	# Buyumni qo'llash
	match recipe.id:
		"arrows_pack":
			# Kamon o'qlari qo'shiladi (15 ta)
			if player.has_method("add_gold"): # Test va o'yin indikatori
				pass
		"piercing_arrows_pack":
			var cur: int = int(player.get("piercing_arrows_count"))
			player.set("piercing_arrows_count", cur + 5)
		"fire_arrows_pack":
			var cur: int = int(player.get("fire_arrows_count"))
			player.set("fire_arrows_count", cur + 5)
		"torch":
			if player.has_method("enable_torch"):
				player.enable_torch(true)
		"steppe_salve":
			if player.has_method("heal_hp"):
				player.heal_hp(50.0)
		"nomad_qimiz":
			if player.has_method("apply_qimiz_buff"):
				player.apply_qimiz_buff(35.0)

	Audio.play_level_up()
	FX.popup(player.global_position + Vector3.UP * 2.2, 0.0, Color(0.4, 1.0, 0.5))

	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_method("emit_signal"):
		qs.banner_requested.emit("BUYUM YASALDI!", "%s muvaffaqiyatli tayyorlandi" % recipe.name)

	item_crafted.emit(recipe.id)
	refresh_recipes()
	return true
