class_name PauseMenu
extends CanvasLayer
## Alpomish dostoni: Pauza, Doston Vazifalari Jurnali, Ko'nikmalar daraxti (Skills) va Sozlamalar menyusi.

var _panel: Panel
var _tab_container: TabContainer

# 1-tab: Doston Vazifalari
var _quests_list: VBoxContainer
var _quests_summary_lbl: Label

# 2-tab: Ko'nikmalar
var _sp_label: Label
var _skills_list: VBoxContainer
var _skill_buttons: Dictionary = {}

# 3-tab: Sozlamalar
var _sens_slider: HSlider
var _sens_val_label: Label
var _fov_slider: HSlider
var _fov_val_label: Label

# Holat
var is_menu_open := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_panel.offset_left = -390
	_panel.offset_right = 390
	_panel.offset_top = -270
	_panel.offset_bottom = 270

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.07, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.9, 0.75, 0.25) # Oltin naqsh
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var main_vbox := VBoxContainer.new()
	margin.add_child(main_vbox)

	# Yuqori sarlavha
	var title := Label.new()
	title.text = "ALPOMISH: DOSTON VA KO'NIKMALAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	main_vbox.add_child(title)

	# Tab container
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_tab_container)

	_build_quests_tab()
	_build_skills_tab()
	_build_settings_tab()

	# Pastki tugmalar
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 24)
	main_vbox.add_child(btn_box)

	var resume_btn := Button.new()
	resume_btn.text = "O'yinni davom ettirish (ESC)"
	resume_btn.custom_minimum_size = Vector2(220, 38)
	resume_btn.pressed.connect(toggle_menu)
	btn_box.add_child(resume_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Qayta boshlash"
	restart_btn.custom_minimum_size = Vector2(160, 38)
	restart_btn.pressed.connect(_on_restart_pressed)
	btn_box.add_child(restart_btn)


func _build_quests_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "Doston Vazifalari"
	tab.add_theme_constant_override("separation", 10)
	_tab_container.add_child(tab)

	_quests_summary_lbl = Label.new()
	_quests_summary_lbl.text = "Bajarilgan vazifalar: 0 / 4"
	_quests_summary_lbl.add_theme_font_size_override("font_size", 16)
	_quests_summary_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	tab.add_child(_quests_summary_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(scroll)

	_quests_list = VBoxContainer.new()
	_quests_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quests_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_quests_list)


func _build_skills_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "Alp Ko'nikmalari"
	tab.add_theme_constant_override("separation", 10)
	_tab_container.add_child(tab)

	_sp_label = Label.new()
	_sp_label.text = "Ko'nikma ochkolari (Skill Points): 0"
	_sp_label.add_theme_font_size_override("font_size", 16)
	_sp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	tab.add_child(_sp_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(scroll)

	_skills_list = VBoxContainer.new()
	_skills_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skills_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_skills_list)


func _build_settings_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "Sozlamalar"
	tab.add_theme_constant_override("separation", 16)
	_tab_container.add_child(tab)

	var space := Control.new()
	space.custom_minimum_size = Vector2(0, 8)
	tab.add_child(space)

	# Sichqoncha sezgirligi
	var sens_row := HBoxContainer.new()
	tab.add_child(sens_row)
	var slabel := Label.new()
	slabel.text = "Sichqoncha sezgirligi:"
	slabel.custom_minimum_size = Vector2(200, 0)
	sens_row.add_child(slabel)

	_sens_slider = HSlider.new()
	_sens_slider.min_value = 0.5
	_sens_slider.max_value = 3.0
	_sens_slider.step = 0.1
	_sens_slider.value = 1.0
	_sens_slider.custom_minimum_size = Vector2(220, 0)
	_sens_slider.value_changed.connect(_on_sens_changed)
	sens_row.add_child(_sens_slider)

	_sens_val_label = Label.new()
	_sens_val_label.text = "1.0x"
	sens_row.add_child(_sens_val_label)

	# Kamera FOV
	var fov_row := HBoxContainer.new()
	tab.add_child(fov_row)
	var flabel := Label.new()
	flabel.text = "Kamera ko'rish burchagi (FOV):"
	flabel.custom_minimum_size = Vector2(200, 0)
	fov_row.add_child(flabel)

	_fov_slider = HSlider.new()
	_fov_slider.min_value = 55.0
	_fov_slider.max_value = 95.0
	_fov_slider.step = 1.0
	_fov_slider.value = 70.0
	_fov_slider.custom_minimum_size = Vector2(220, 0)
	_fov_slider.value_changed.connect(_on_fov_changed)
	fov_row.add_child(_fov_slider)

	_fov_val_label = Label.new()
	_fov_val_label.text = "70°"
	fov_row.add_child(_fov_val_label)

	# Ovoz effektlari (SFX)
	var sfx_row := HBoxContainer.new()
	tab.add_child(sfx_row)
	var sfx_label := Label.new()
	sfx_label.text = "Ovoz effektlari (SFX):"
	sfx_label.custom_minimum_size = Vector2(200, 0)
	sfx_row.add_child(sfx_label)

	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = db_to_linear(Audio.sfx_volume_db)
	sfx_slider.custom_minimum_size = Vector2(220, 0)
	sfx_row.add_child(sfx_slider)

	var sfx_val := Label.new()
	sfx_val.text = "%d%%" % int(sfx_slider.value * 100)
	sfx_row.add_child(sfx_val)

	sfx_slider.value_changed.connect(func(v: float):
		sfx_val.text = "%d%%" % int(v * 100)
		Audio.sfx_volume_db = linear_to_db(v) if v > 0.01 else -80.0
		Audio.play_hit())

	# Jangovar Musiqa (Doyra)
	var music_row := HBoxContainer.new()
	tab.add_child(music_row)
	var m_label := Label.new()
	m_label.text = "Jang musiqasi (Doyra):"
	m_label.custom_minimum_size = Vector2(200, 0)
	music_row.add_child(m_label)

	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = db_to_linear(Audio.music_volume_db)
	music_slider.custom_minimum_size = Vector2(220, 0)
	music_row.add_child(music_slider)

	var m_val := Label.new()
	m_val.text = "%d%%" % int(music_slider.value * 100)
	music_row.add_child(m_val)

	music_slider.value_changed.connect(func(v: float):
		m_val.text = "%d%%" % int(v * 100)
		Audio.music_volume_db = linear_to_db(v) if v > 0.01 else -80.0
		Audio.is_music_enabled = v > 0.01)

	var info := Label.new()
	info.text = "Qisqa tugmalar:\n[ TAB / K ] – Doston jurnali va Ko'nikmalar\n[ E ] – Suhbatlashish | [ F ] – Boychiborga minish\n[ T ] – Joyida tezkor qayta boshlash"
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.65))
	tab.add_child(info)


func _unhandled_input(event: InputEvent) -> void:
	var mm := get_tree().get_first_node_in_group("main_menu")
	if mm and mm.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_K:
			get_viewport().set_input_as_handled()
			toggle_menu()
		elif event.keycode == KEY_ESCAPE and is_menu_open:
			get_viewport().set_input_as_handled()
			toggle_menu()


func toggle_menu() -> void:
	is_menu_open = not is_menu_open
	visible = is_menu_open
	get_tree().paused = is_menu_open

	if is_menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_quests()
		_refresh_skills()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh_quests() -> void:
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem == null or _quests_list == null:
		return

	for child in _quests_list.get_children():
		child.queue_free()

	var quests: Array[Dictionary] = qsystem.get_all_quests()
	var completed_count: int = qsystem.get_completed_count()
	var total_count: int = qsystem.get_total_count()

	_quests_summary_lbl.text = "Doston Shartlari: %d / %d bajarildi (Ixtiyoriy ketma-ketlikda bajarish mumkin)" % [completed_count, total_count]
	if completed_count == total_count:
		_quests_summary_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.4))
	else:
		_quests_summary_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	for q in quests:
		var is_comp: bool = q.get("completed", false)
		var item_panel := PanelContainer.new()
		var pstyle := StyleBoxFlat.new()
		pstyle.bg_color = Color(0.12, 0.18, 0.12) if is_comp else Color(0.14, 0.12, 0.10)
		pstyle.border_width_left = 3
		pstyle.border_color = Color(0.3, 0.9, 0.4) if is_comp else Color(0.8, 0.65, 0.25)
		pstyle.content_margin_left = 12
		pstyle.content_margin_right = 12
		pstyle.content_margin_top = 8
		pstyle.content_margin_bottom = 8
		item_panel.add_theme_stylebox_override("panel", pstyle)
		_quests_list.add_child(item_panel)

		var row := HBoxContainer.new()
		item_panel.add_child(row)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_vbox)

		var name_lbl := Label.new()
		name_lbl.text = q.get("title", "")
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if is_comp else Color(1.0, 0.9, 0.5))
		text_vbox.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = q.get("desc", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
		text_vbox.add_child(desc_lbl)

		var status_badge := Label.new()
		status_badge.text = "[ BAJARILDI ]\n+%d XP" % q.get("xp", 50) if is_comp else "[ KUTILMOQDA ]\n+%d XP" % q.get("xp", 50)
		status_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_badge.add_theme_font_size_override("font_size", 13)
		status_badge.add_theme_color_override("font_color", Color(0.3, 0.95, 0.4) if is_comp else Color(1.0, 0.78, 0.25))
		row.add_child(status_badge)


func _refresh_skills() -> void:
	var prog: Progression = get_tree().get_first_node_in_group("progression") as Progression
	if prog == null or _skills_list == null:
		return

	_sp_label.text = "Daraja (Level): %d | Mavjud ko'nikma ochkolari: %d" % [prog.level, prog.skill_points]

	for child in _skills_list.get_children():
		child.queue_free()

	for skill_id in prog.skill_info.keys():
		var sdata: Dictionary = prog.skill_info[skill_id]
		var is_unlocked: bool = prog.unlocked_skills.get(skill_id, false)

		var item_panel := PanelContainer.new()
		var pstyle := StyleBoxFlat.new()
		pstyle.bg_color = Color(0.14, 0.12, 0.10) if not is_unlocked else Color(0.12, 0.20, 0.12)
		pstyle.border_width_left = 3
		pstyle.border_color = Color(0.4, 0.8, 0.3) if is_unlocked else Color(0.6, 0.5, 0.3)
		pstyle.content_margin_left = 12
		pstyle.content_margin_right = 12
		pstyle.content_margin_top = 8
		pstyle.content_margin_bottom = 8
		item_panel.add_theme_stylebox_override("panel", pstyle)
		_skills_list.add_child(item_panel)

		var row := HBoxContainer.new()
		item_panel.add_child(row)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_vbox)

		var name_lbl := Label.new()
		name_lbl.text = sdata.name + (" (O'RGANILGAN)" if is_unlocked else "")
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if is_unlocked else Color(1.0, 0.9, 0.5))
		text_vbox.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = sdata.desc
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
		text_vbox.add_child(desc_lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 36)
		if is_unlocked:
			btn.text = "FAOL"
			btn.disabled = true
		else:
			btn.text = "Ochish (1 ball)"
			btn.disabled = prog.skill_points < 1
			btn.pressed.connect(func(): _unlock_and_refresh(skill_id))
		row.add_child(btn)


func _unlock_and_refresh(skill_id: String) -> void:
	var prog: Progression = get_tree().get_first_node_in_group("progression") as Progression
	if prog and prog.unlock_skill(skill_id):
		_refresh_skills()


func _on_sens_changed(val: float) -> void:
	_sens_val_label.text = "%.1fx" % val
	var player = get_tree().get_first_node_in_group("player")
	if player and "rig" in player and player.rig:
		player.rig.mouse_sensitivity = 0.0025 * val


func _on_fov_changed(val: float) -> void:
	_fov_val_label.text = "%d°" % int(val)
	var player = get_tree().get_first_node_in_group("player")
	if player and "rig" in player and player.rig:
		player.rig.normal_fov = val
		if player.rig.camera:
			player.rig.camera.fov = val


func _on_restart_pressed() -> void:
	get_tree().paused = false
	FX.reset()
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()
