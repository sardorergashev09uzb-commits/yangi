class_name QuestJournal
extends CanvasLayer
## Alpomish Dostoni va Vazifalar Jurnali [ J ]: Asosiy syujet va el-yurt qo'shimcha vazifalari kitobi.

signal journal_opened()
signal journal_closed()

var is_open := false
var current_tab: String = "main" # "main" yoki "side"
var selected_quest_id: String = "qultoy"

var _backdrop: ColorRect
var _main_panel: Panel
var _tab_main_btn: Button
var _tab_side_btn: Button
var _stats_label: Label

var _quest_list_vbox: VBoxContainer
var _detail_title: Label
var _detail_category_badge: Label
var _detail_status_badge: Label
var _detail_lore: Label
var _detail_objectives_vbox: VBoxContainer
var _detail_rewards_label: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("quest_journal")
	_build_ui()
	visible = false

	# Kvest signallari ulanganda avtomatik yangilash
	call_deferred("_connect_signals")


func _connect_signals() -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs and qs.has_signal("quest_state_changed"):
		qs.connect("quest_state_changed", func(_id: String, _comp: bool):
			if is_open:
				refresh_journal())


func _build_ui() -> void:
	# 1. To'liq ekranli qorong'i parda (Backdrop)
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.04, 0.03, 0.02, 0.85)
	add_child(_backdrop)

	# 2. Qadimiy charm / pergament uslubidagi asosiy kitob paneli
	_main_panel = Panel.new()
	_main_panel.set_anchors_preset(Control.PRESET_CENTER)
	_main_panel.offset_left = -460
	_main_panel.offset_right = 460
	_main_panel.offset_top = -290
	_main_panel.offset_bottom = 290

	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.11, 0.09, 0.07, 0.97)
	pstyle.border_width_left = 3
	pstyle.border_width_right = 3
	pstyle.border_width_top = 3
	pstyle.border_width_bottom = 3
	pstyle.border_color = Color(0.82, 0.68, 0.32, 0.95)
	pstyle.corner_radius_top_left = 12
	pstyle.corner_radius_top_right = 12
	pstyle.corner_radius_bottom_left = 12
	pstyle.corner_radius_bottom_right = 12
	pstyle.content_margin_left = 20
	pstyle.content_margin_right = 20
	pstyle.content_margin_top = 16
	pstyle.content_margin_bottom = 16
	_main_panel.add_theme_stylebox_override("panel", pstyle)
	add_child(_main_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 12)
	_main_panel.add_child(root_vbox)

	# 3. Yuqori sarlavha qatori
	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 2)
	root_vbox.add_child(header_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "📜 ALPOMISH DOSTONI VA VAZIFALAR JURNALI"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	header_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "El-yurt or-nomusi, Boysun sha'ni va Barchinoy sevgisi yo'lidagi muqaddas qadamlar"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	header_vbox.add_child(sub_lbl)

	_stats_label = Label.new()
	_stats_label.text = "Jami: 0/10 ta vazifa bajarildi (0%)"
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 12)
	_stats_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	header_vbox.add_child(_stats_label)

	# 4. Kategoriya Tab tugmalari
	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 16)
	root_vbox.add_child(tab_hbox)

	_tab_main_btn = Button.new()
	_tab_main_btn.text = "⚔️ ASOSIY DOSTON VAZIFALARI"
	_tab_main_btn.custom_minimum_size = Vector2(260, 36)
	_tab_main_btn.pressed.connect(func(): _switch_tab("main"))
	tab_hbox.add_child(_tab_main_btn)

	_tab_side_btn = Button.new()
	_tab_side_btn.text = "🏕️ EL-YURT QO'SHIMCHA VAZIFALARI"
	_tab_side_btn.custom_minimum_size = Vector2(280, 36)
	_tab_side_btn.pressed.connect(func(): _switch_tab("side"))
	tab_hbox.add_child(_tab_side_btn)

	# 5. Asosiy bo'linma (Ikki ustunli daftar: Chapda ro'yxat, O'ngda batafsil doston sahifasi)
	var content_hbox := HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 16)
	root_vbox.add_child(content_hbox)

	# Chap Ustun: Vazifalar ro'yxati
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(350, 0)
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(left_scroll)

	_quest_list_vbox = VBoxContainer.new()
	_quest_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list_vbox.add_theme_constant_override("separation", 6)
	left_scroll.add_child(_quest_list_vbox)

	# O'ng Ustun: Tanlangan Vazifa Sahifasi (Parchment detail page)
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var dstyle := StyleBoxFlat.new()
	dstyle.bg_color = Color(0.08, 0.07, 0.05, 0.92)
	dstyle.border_width_left = 1
	dstyle.border_width_right = 1
	dstyle.border_width_top = 1
	dstyle.border_width_bottom = 1
	dstyle.border_color = Color(0.65, 0.52, 0.25, 0.7)
	dstyle.corner_radius_top_left = 8
	dstyle.corner_radius_top_right = 8
	dstyle.corner_radius_bottom_left = 8
	dstyle.corner_radius_bottom_right = 8
	dstyle.content_margin_left = 16
	dstyle.content_margin_right = 16
	dstyle.content_margin_top = 14
	dstyle.content_margin_bottom = 14
	right_panel.add_theme_stylebox_override("panel", dstyle)
	content_hbox.add_child(right_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 10)
	right_panel.add_child(detail_vbox)

	# Sahifa sarlavhasi va holat nishonlari
	var dtitle_hbox := HBoxContainer.new()
	detail_vbox.add_child(dtitle_hbox)

	_detail_title = Label.new()
	_detail_title.text = "Vazifa Sarlavhasi"
	_detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_title.add_theme_font_size_override("font_size", 17)
	_detail_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	dtitle_hbox.add_child(_detail_title)

	_detail_category_badge = Label.new()
	_detail_category_badge.text = "[ ASOSIY ]"
	_detail_category_badge.add_theme_font_size_override("font_size", 11)
	_detail_category_badge.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	dtitle_hbox.add_child(_detail_category_badge)

	_detail_status_badge = Label.new()
	_detail_status_badge.text = "[ BAJARILMOQDA ]"
	_detail_status_badge.add_theme_font_size_override("font_size", 12)
	_detail_status_badge.add_theme_color_override("font_color", Color(1.0, 0.8, 0.25))
	dtitle_hbox.add_child(_detail_status_badge)

	# Ajratuvchi chiziq
	var sep := HSeparator.new()
	detail_vbox.add_child(sep)

	# Doston Tarixi va Qissasi
	var lore_header := Label.new()
	lore_header.text = "📖 DOSTON QISSASI:"
	lore_header.add_theme_font_size_override("font_size", 12)
	lore_header.add_theme_color_override("font_color", Color(0.85, 0.72, 0.35))
	detail_vbox.add_child(lore_header)

	_detail_lore = Label.new()
	_detail_lore.text = "Doston qissasi matni..."
	_detail_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_lore.add_theme_font_size_override("font_size", 13)
	_detail_lore.add_theme_color_override("font_color", Color(0.92, 0.89, 0.82))
	detail_vbox.add_child(_detail_lore)

	# Maqsadlar ro'yxati (Objectives checklist)
	var obj_header := Label.new()
	obj_header.text = "🎯 MAQSADLAR:"
	obj_header.add_theme_font_size_override("font_size", 12)
	obj_header.add_theme_color_override("font_color", Color(0.85, 0.72, 0.35))
	detail_vbox.add_child(obj_header)

	_detail_objectives_vbox = VBoxContainer.new()
	_detail_objectives_vbox.add_theme_constant_override("separation", 4)
	detail_vbox.add_child(_detail_objectives_vbox)

	# Mukofotlar paneli
	var rew_spacer := Control.new()
	rew_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_child(rew_spacer)

	var rew_panel := PanelContainer.new()
	var rstyle := StyleBoxFlat.new()
	rstyle.bg_color = Color(0.06, 0.05, 0.04, 0.8)
	rstyle.border_width_left = 1
	rstyle.border_width_right = 1
	rstyle.border_width_top = 1
	rstyle.border_width_bottom = 1
	rstyle.border_color = Color(0.55, 0.45, 0.2, 0.5)
	rstyle.corner_radius_top_left = 6
	rstyle.corner_radius_top_right = 6
	rstyle.corner_radius_bottom_left = 6
	rstyle.corner_radius_bottom_right = 6
	rstyle.content_margin_left = 12
	rstyle.content_margin_right = 12
	rstyle.content_margin_top = 8
	rstyle.content_margin_bottom = 8
	rew_panel.add_theme_stylebox_override("panel", rstyle)
	detail_vbox.add_child(rew_panel)

	_detail_rewards_label = Label.new()
	_detail_rewards_label.text = "🏆 MUKOFOT: +100 XP | 🪙 50 Tilla"
	_detail_rewards_label.add_theme_font_size_override("font_size", 13)
	_detail_rewards_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	rew_panel.add_child(_detail_rewards_label)

	# 6. Pastki navigatsiya qatori
	var footer_hbox := HBoxContainer.new()
	root_vbox.add_child(footer_hbox)

	var hint_lbl := Label.new()
	hint_lbl.text = "Maslahat: Vazifalarni bajarish orqali yangi ko'nikmalar, tilla va qurollarga ega bo'lasiz"
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55))
	footer_hbox.add_child(hint_lbl)

	var close_btn := Button.new()
	close_btn.text = "Jurnalni yopish [ Esc / J ]"
	close_btn.custom_minimum_size = Vector2(200, 34)
	close_btn.pressed.connect(close_journal)
	footer_hbox.add_child(close_btn)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			toggle_journal()
			get_viewport().set_input_as_handled()
		elif is_open and (event.keycode == KEY_ESCAPE):
			close_journal()
			get_viewport().set_input_as_handled()


func toggle_journal() -> void:
	if is_open:
		close_journal()
	else:
		open_journal()


func open_journal() -> void:
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play_coin()
	refresh_journal()
	journal_opened.emit()


func close_journal() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	journal_closed.emit()


func _switch_tab(tab: String) -> void:
	current_tab = tab
	Audio.play_coin()
	refresh_journal()


func refresh_journal() -> void:
	var qs = get_tree().get_first_node_in_group("quest_system")
	if qs == null:
		return

	var comp_count: int = qs.get_completed_count()
	var total_count: int = qs.get_total_count()
	var pct: int = int((float(comp_count) / float(max(1, total_count))) * 100.0)
	_stats_label.text = "Jami: %d/%d ta vazifa bajarildi (%d%%)" % [comp_count, total_count, pct]

	var main_quests: Array[Dictionary] = qs.get_quests_by_category("main")
	var side_quests: Array[Dictionary] = qs.get_quests_by_category("side")

	var main_done := 0
	for q in main_quests:
		if q.get("completed", false):
			main_done += 1
	var side_done := 0
	for q in side_quests:
		if q.get("completed", false):
			side_done += 1

	_tab_main_btn.text = "⚔️ ASOSIY DOSTON (%d/%d)" % [main_done, main_quests.size()]
	_tab_side_btn.text = "🏕️ EL-YURT VAZIFALARI (%d/%d)" % [side_done, side_quests.size()]

	if current_tab == "main":
		_tab_main_btn.modulate = Color(1.0, 1.0, 1.0)
		_tab_side_btn.modulate = Color(0.7, 0.7, 0.7)
	else:
		_tab_main_btn.modulate = Color(0.7, 0.7, 0.7)
		_tab_side_btn.modulate = Color(1.0, 1.0, 1.0)

	# Kvestlar ro'yxatini tozalash va to'ldirish
	for ch in _quest_list_vbox.get_children():
		_quest_list_vbox.remove_child(ch)
		ch.queue_free()

	var active_list := main_quests if current_tab == "main" else side_quests

	var found_selected := false
	for q in active_list:
		if q.id == selected_quest_id:
			found_selected = true
			break

	if not found_selected and active_list.size() > 0:
		selected_quest_id = active_list[0].id

	for q in active_list:
		var q_id: String = q.id
		var is_comp: bool = q.get("completed", false)
		var is_selected: bool = (q_id == selected_quest_id)

		var card_btn := Button.new()
		card_btn.custom_minimum_size = Vector2(0, 52)
		card_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var btn_style := StyleBoxFlat.new()
		if is_selected:
			btn_style.bg_color = Color(0.24, 0.18, 0.10, 0.95)
			btn_style.border_color = Color(1.0, 0.85, 0.3)
			btn_style.border_width_left = 3
			btn_style.border_width_right = 1
			btn_style.border_width_top = 1
			btn_style.border_width_bottom = 1
		else:
			btn_style.bg_color = Color(0.14, 0.12, 0.10, 0.85)
			btn_style.border_color = Color(0.4, 0.35, 0.25, 0.5)
			btn_style.border_width_left = 1
			btn_style.border_width_right = 1
			btn_style.border_width_top = 1
			btn_style.border_width_bottom = 1

		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn_style.corner_radius_bottom_right = 6
		btn_style.content_margin_left = 10
		btn_style.content_margin_right = 10
		card_btn.add_theme_stylebox_override("normal", btn_style)
		card_btn.add_theme_stylebox_override("hover", btn_style)
		card_btn.add_theme_stylebox_override("pressed", btn_style)

		var hbox := HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 10
		hbox.offset_right = -10
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_btn.add_child(hbox)

		var status_icon := Label.new()
		status_icon.text = "[✓]" if is_comp else "[▶]"
		status_icon.add_theme_font_size_override("font_size", 13)
		status_icon.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45) if is_comp else Color(1.0, 0.82, 0.25))
		hbox.add_child(status_icon)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(text_vbox)

		var qname := Label.new()
		qname.text = q.title
		qname.add_theme_font_size_override("font_size", 13)
		qname.add_theme_color_override("font_color", Color(1.0, 0.92, 0.8) if is_selected else Color(0.85, 0.82, 0.75))
		text_vbox.add_child(qname)

		var qhint := Label.new()
		qhint.text = "Bajarildi (+%d XP, +%d Tilla)" % [q.get("xp", 50), q.get("gold", 0)] if is_comp else q.get("hint", "")
		qhint.add_theme_font_size_override("font_size", 10)
		qhint.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5) if is_comp else Color(0.7, 0.65, 0.55))
		text_vbox.add_child(qhint)

		card_btn.pressed.connect(func():
			selected_quest_id = q_id
			refresh_journal())
		_quest_list_vbox.add_child(card_btn)

	# Tanlangan kvest tafsilotini yangilash
	_display_quest_details(qs.get_quest(selected_quest_id))


func _display_quest_details(q: Dictionary) -> void:
	if q.is_empty():
		_detail_title.text = "Vazifa tanlanmagan"
		_detail_lore.text = ""
		return

	var is_comp: bool = q.get("completed", false)
	_detail_title.text = q.get("title", "")
	_detail_category_badge.text = "[ ASOSIY DOSTON ]" if q.get("category", "main") == "main" else "[ EL-YURT VAZIFASI ]"

	if is_comp:
		_detail_status_badge.text = "[✓ TUGALLANDI]"
		_detail_status_badge.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45))
	else:
		_detail_status_badge.text = "[⏳ BAJARILMOQDA]"
		_detail_status_badge.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))

	_detail_lore.text = q.get("lore", q.get("desc", ""))

	# Maqsadlar ro'yxatini qayta chizish
	for ch in _detail_objectives_vbox.get_children():
		_detail_objectives_vbox.remove_child(ch)
		ch.queue_free()

	var objs: Array = q.get("objectives", [q.get("desc", "")])
	var prog: int = int(q.get("progress", 0))
	var max_p: int = int(q.get("max_progress", objs.size()))

	for i in range(objs.size()):
		var obj_text: String = String(objs[i])
		var obj_done := false
		if is_comp:
			obj_done = true
		elif max_p > 1:
			obj_done = (i < prog)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_detail_objectives_vbox.add_child(row)

		var icon := Label.new()
		icon.text = "[✓]" if obj_done else "[ ]"
		icon.add_theme_font_size_override("font_size", 12)
		icon.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45) if obj_done else Color(0.7, 0.65, 0.55))
		row.add_child(icon)

		var lbl := Label.new()
		lbl.text = obj_text
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7) if obj_done else Color(0.85, 0.82, 0.75))
		row.add_child(lbl)

	# Mukofotlar
	var xp_val: int = int(q.get("xp", 50))
	var gold_val: int = int(q.get("gold", 0))
	_detail_rewards_label.text = "🏆 MUKOFOT: +%d XP  |  🪙 %d Tilla" % [xp_val, gold_val]
