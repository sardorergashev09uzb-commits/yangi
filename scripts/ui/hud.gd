extends CanvasLayer
## HUD: salomatlik, kuch, kamon zaryadi, dushmanlar soni, Boss paneli, Vazifalar jurnali (Checklist).

var _health_bar: ProgressBar
var _stamina_bar: ProgressBar
var _charge_bar: ProgressBar
var _crosshair: Label
var _enemy_label: Label
var _player: CharacterBody3D

# Boss UI elementlari
var _boss_container: VBoxContainer
var _boss_name_label: Label
var _boss_bar: ProgressBar
var _boss_phase_label: Label

# O'lim va G'alaba ekranlari
var _death_panel: Panel
var _victory_panel: Panel
var _victory_title: Label
var _victory_sub: Label

# Kvest Checklist UI
var _quest_panel: PanelContainer
var _quest_header: Label
var _quest_items: Dictionary = {} # id -> {check: Label, title: Label, hint: Label}
var _banner_panel: PanelContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_tween: Tween

# XP va Level UI
var _xp_bar: ProgressBar
var _lvl_label: Label
var _skill_hint: Label
var _gold_label: Label

# Kompas / Radar UI elementlari
var _compass_container: PanelContainer
var _compass_canvas: Control
var _compass_info_label: Label


func _ready() -> void:
	_setup_compass_ui()
	_health_bar = _make_bar(Vector2(30, 24), Vector2(320, 16), Color(0.85, 0.15, 0.15))
	_stamina_bar = _make_bar(Vector2(30, 44), Vector2(260, 10), Color(0.3, 0.75, 0.3))
	_xp_bar = _make_bar(Vector2(30, 58), Vector2(200, 8), Color(0.65, 0.35, 0.95))

	_lvl_label = Label.new()
	_lvl_label.text = "LVL 1 (0/100 XP)"
	_lvl_label.position = Vector2(238, 52)
	_lvl_label.add_theme_font_size_override("font_size", 12)
	_lvl_label.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	add_child(_lvl_label)

	_gold_label = Label.new()
	_gold_label.text = "🪙 0 Tilla"
	_gold_label.position = Vector2(30, 72)
	_gold_label.add_theme_font_size_override("font_size", 13)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	add_child(_gold_label)

	var _craft_hint := Label.new()
	_craft_hint.name = "CraftHint"
	_craft_hint.text = "[ V ] - Yasash"
	_craft_hint.position = Vector2(130, 72)
	_craft_hint.add_theme_font_size_override("font_size", 12)
	_craft_hint.add_theme_color_override("font_color", Color(0.7, 0.95, 0.75))
	add_child(_craft_hint)

	_skill_hint = Label.new()
	_skill_hint.text = "★ [ TAB ] - Yangi ko'nikma!"
	_skill_hint.position = Vector2(230, 72)
	_skill_hint.add_theme_font_size_override("font_size", 12)
	_skill_hint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_skill_hint.visible = false
	add_child(_skill_hint)

	_enemy_label = Label.new()
	_enemy_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_enemy_label.position = Vector2(-360, 24)
	add_child(_enemy_label)

	_crosshair = Label.new()
	_crosshair.text = "+"
	_crosshair.add_theme_font_size_override("font_size", 28)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.visible = false
	add_child(_crosshair)

	_charge_bar = _make_bar(Vector2(0, 0), Vector2(120, 8), Color(1.0, 0.8, 0.2))
	_charge_bar.set_anchors_preset(Control.PRESET_CENTER)
	_charge_bar.position += Vector2(-60, 30)
	_charge_bar.visible = false

	_setup_quest_ui()
	_setup_banner_ui()
	_setup_boss_ui()
	_setup_game_over_ui()
	_setup_victory_ui()

	var help := Label.new()
	help.position = Vector2(30, 92)
	help.text = "WASD - yurish | Sichqoncha - kamera | TAB - doston & ko'nikmalar | E - suhbatlashish | F - Boychibor | H - hushtak\n" \
			+ "Ot ustida Shift - shiddatli galop (16 m/s) va toptash | Space - qochish | X - sakrash | Q - blok | C - Alp Gumburi (Super zarba) | F5/F9 - saqlash/yuklash | O'ng tugma - kamon\n" \
			+ "Sharqda: O'tov, Qultoy Cho'pon va Dev | Shimolda: Surxayil Arenasi | T - qayta boshlash"
	add_child(help)

	_connect_player.call_deferred()
	_connect_boss.call_deferred()
	_connect_quests.call_deferred()
	_connect_progression.call_deferred()


func _setup_game_over_ui() -> void:
	_death_panel = Panel.new()
	_death_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.02, 0.02, 0.88)
	_death_panel.add_theme_stylebox_override("panel", style)
	_death_panel.visible = false
	add_child(_death_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -260
	vbox.offset_right = 260
	vbox.offset_top = -120
	vbox.offset_bottom = 120
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_death_panel.add_child(vbox)

	var title := Label.new()
	title.text = "MAG'LUB BO'LDINGIZ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Alp Alpomish o'z elini asrashi shart!\n[ SPACE ] yoki [ R ] – Qayta urinish"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75))
	vbox.add_child(sub)

	var space := Control.new()
	space.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(space)

	var btn := Button.new()
	btn.text = "Qayta urinish (Tiriklanish)"
	btn.custom_minimum_size = Vector2(260, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_respawn_player)
	vbox.add_child(btn)


func _respawn_player() -> void:
	_death_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _player and _player.has_method("respawn"):
		_player.respawn()


func _setup_victory_ui() -> void:
	_victory_panel = Panel.new()
	_victory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.02, 0.92)
	_victory_panel.add_theme_stylebox_override("panel", style)
	_victory_panel.visible = false
	add_child(_victory_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -320
	vbox.offset_right = 320
	vbox.offset_top = -140
	vbox.offset_bottom = 140
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	_victory_panel.add_child(vbox)

	_victory_title = Label.new()
	_victory_title.text = "DOSTON QAHRAMONI - ALPOMISH!"
	_victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_victory_title.add_theme_font_size_override("font_size", 38)
	_victory_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(_victory_title)

	_victory_sub = Label.new()
	_victory_sub.text = "Barcha shartlar ado etildi! Qo'ng'irot eli ozod, Barchinoy omon!"
	_victory_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_victory_sub.add_theme_font_size_override("font_size", 17)
	_victory_sub.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	vbox.add_child(_victory_sub)

	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_box)

	var continue_btn := Button.new()
	continue_btn.text = "Erkin sayrni davom ettirish"
	continue_btn.custom_minimum_size = Vector2(230, 44)
	continue_btn.pressed.connect(_on_continue_free_roam)
	btn_box.add_child(continue_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Dostonni qayta boshlash"
	restart_btn.custom_minimum_size = Vector2(210, 44)
	restart_btn.pressed.connect(_restart_scene)
	btn_box.add_child(restart_btn)


func _on_continue_free_roam() -> void:
	_victory_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			_restart_scene()
			return
		if _death_panel.visible:
			if event.keycode == KEY_SPACE or event.keycode == KEY_R or event.keycode == KEY_ENTER:
				_respawn_player()
				return
		if _victory_panel.visible:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_on_continue_free_roam()
				return


func _restart_scene() -> void:
	FX.reset()
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()


func _setup_boss_ui() -> void:
	_boss_container = VBoxContainer.new()
	_boss_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_boss_container.offset_top = -100
	_boss_container.offset_bottom = -30
	_boss_container.offset_left = 180
	_boss_container.offset_right = -180
	_boss_container.visible = false
	add_child(_boss_container)

	var title_box := HBoxContainer.new()
	_boss_container.add_child(title_box)

	_boss_name_label = Label.new()
	_boss_name_label.text = "SURXAYIL ALP - Qalmoq Botiri"
	_boss_name_label.add_theme_font_size_override("font_size", 20)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8))
	_boss_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_child(_boss_name_label)

	_boss_phase_label = Label.new()
	_boss_phase_label.text = "1-BOSQICH"
	_boss_phase_label.add_theme_font_size_override("font_size", 16)
	_boss_phase_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	title_box.add_child(_boss_phase_label)

	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(0, 18)
	_boss_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.1)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.12, 0.12, 0.14, 0.85)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_bar.add_theme_stylebox_override("background", back)
	_boss_container.add_child(_boss_bar)


func _make_bar(pos: Vector2, bar_size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = bar_size
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	add_child(bar)
	return bar


func _connect_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player == null:
		return
	_health_bar.max_value = _player.get("max_health")
	_health_bar.value = _player.get("health")
	_stamina_bar.max_value = _player.get("max_stamina")
	_player.connect("stamina_changed", func(c: float, m: float) -> void:
		_stamina_bar.max_value = m
		_stamina_bar.value = c)
	_player.connect("health_changed", func(c: float, m: float) -> void:
		_health_bar.max_value = m
		_health_bar.value = c)
	if _player.has_signal("gold_changed"):
		_player.connect("gold_changed", _on_gold_changed)
	if _player.get("gold") != null:
		_gold_label.text = "🪙 %d Tilla" % int(_player.get("gold"))
	_player.connect("died", func() -> void:
		_death_panel.visible = true
		_boss_container.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	_player.connect("respawned", func() -> void:
		_death_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)


func _on_gold_changed(new_gold: int, delta_amount: int) -> void:
	_gold_label.text = "🪙 %d Tilla" % new_gold
	if delta_amount > 0:
		_show_gold_popup("+%d Tilla" % delta_amount)
	elif delta_amount < 0:
		_show_gold_popup("%d Tilla" % delta_amount, Color(1.0, 0.4, 0.3))


func _show_gold_popup(text: String, col := Color(1.0, 0.88, 0.25)) -> void:
	var popup := Label.new()
	popup.text = text
	popup.position = _gold_label.position + Vector2(100, 0)
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", col)
	add_child(popup)
	var t := create_tween()
	t.tween_property(popup, "position:y", popup.position.y - 18.0, 0.8)
	t.parallel().tween_property(popup, "modulate:a", 0.0, 0.8)
	t.tween_callback(popup.queue_free)


func _connect_boss() -> void:
	var boss := get_tree().get_first_node_in_group("bosses")
	if boss == null:
		return
	boss.boss_activated.connect(_on_boss_activated)
	boss.boss_health_changed.connect(_on_boss_health)
	boss.boss_phase_transition.connect(_on_boss_phase)
	boss.boss_defeated.connect(_on_boss_defeated)


func _on_boss_activated(bname: String, cur: float, max_hp: float) -> void:
	_boss_name_label.text = bname + " - Qalmoq Botiri"
	_boss_bar.max_value = max_hp
	_boss_bar.value = cur
	_boss_phase_label.text = "1-BOSQICH"
	_boss_container.visible = true


func _on_boss_health(cur: float, max_hp: float, phase: int) -> void:
	_boss_bar.max_value = max_hp
	_boss_bar.value = cur
	_boss_phase_label.text = "2-BOSQICH: QUTURGAN!" if phase == 2 else "1-BOSQICH"


func _on_boss_phase(phase: int) -> void:
	if phase == 2:
		_boss_phase_label.text = "2-BOSQICH: QUTURGAN!"
		_boss_phase_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
		var fill := _boss_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill:
			fill.bg_color = Color(1.0, 0.25, 0.05)


func _on_boss_defeated() -> void:
	# Boss yengilganda o'yin majburan to'xtamaydi! O'yinchi bemalol dashtni kezishi mumkin.
	_boss_container.visible = false
	show_banner("SURXAYIL ALP YENGILDI!", "Qalmoq botiri tiz cho'kdi! Dasht sari yo'l ochiq!")


func _on_all_quests_completed() -> void:
	# Barcha 4 ta doston vazifasi to'liq bajarilganda ulug' g'alaba oynasi chiqadi
	_victory_title.text = "DOSTON QAHRAMONI - ALPOMISH!"
	_victory_sub.text = "Barcha 4 shart ado etildi: Qultoy oqsoqol duosi olindi, Boychibor jilovlandi,\n" \
			+ "Qoyali Dasht Devi yengildi va Surxayil Alp tiz cho'ktirildi!\n" \
			+ "Barchinoy ozod, Qo'ng'irot eli omon!"
	_victory_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	if _compass_canvas:
		_compass_canvas.queue_redraw()

	var enemies_count := get_tree().get_nodes_in_group("enemies").size()
	_enemy_label.text = "Dushmanlar: %d" % enemies_count
	if _player == null:
		return
	var is_aim: bool = bool(_player.get("aiming"))
	var charge: float = float(_player.get("bow_charge"))
	_crosshair.visible = is_aim
	_charge_bar.visible = is_aim and charge > 0.0
	_charge_bar.max_value = 1.0
	_charge_bar.value = charge


func _setup_compass_ui() -> void:
	_compass_container = PanelContainer.new()
	_compass_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_compass_container.offset_left = -210
	_compass_container.offset_right = 210
	_compass_container.offset_top = 8
	_compass_container.offset_bottom = 38

	var cstyle := StyleBoxFlat.new()
	cstyle.bg_color = Color(0.06, 0.05, 0.06, 0.82)
	cstyle.border_width_left = 1
	cstyle.border_width_right = 1
	cstyle.border_width_top = 1
	cstyle.border_width_bottom = 1
	cstyle.border_color = Color(0.75, 0.62, 0.28, 0.75)
	cstyle.corner_radius_top_left = 6
	cstyle.corner_radius_top_right = 6
	cstyle.corner_radius_bottom_left = 6
	cstyle.corner_radius_bottom_right = 6
	_compass_container.add_theme_stylebox_override("panel", cstyle)
	add_child(_compass_container)

	_compass_canvas = Control.new()
	_compass_canvas.custom_minimum_size = Vector2(400, 24)
	_compass_canvas.clip_contents = true
	_compass_canvas.draw.connect(_on_compass_draw)
	_compass_container.add_child(_compass_canvas)

	# Markaziy ko'rsatkich ignasi (Oltin uchburchak)
	var needle := Label.new()
	needle.text = "▼"
	needle.add_theme_font_size_override("font_size", 9)
	needle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	needle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	needle.offset_left = -4
	needle.offset_top = -2
	_compass_container.add_child(needle)

	# Kompas ostidagi nishon masofasi yozuvi
	_compass_info_label = Label.new()
	_compass_info_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_compass_info_label.offset_left = -180
	_compass_info_label.offset_right = 180
	_compass_info_label.offset_top = 40
	_compass_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compass_info_label.add_theme_font_size_override("font_size", 11)
	_compass_info_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	add_child(_compass_info_label)


func _on_compass_draw() -> void:
	if _compass_canvas == null:
		return
	var font := _compass_canvas.get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font

	var center_x := 200.0
	var px_per_rad := 400.0 / deg_to_rad(140.0) # 140 darajali ko'rish burchagi

	var cam := get_viewport().get_camera_3d()
	var cam_yaw: float = 0.0
	if cam:
		cam_yaw = cam.global_rotation.y
	elif _player and _player.get("rig"):
		cam_yaw = float(_player.get("rig").yaw)

	# 1. Gorizontal asos chizig'i
	_compass_canvas.draw_line(Vector2(0, 18), Vector2(400, 18), Color(0.45, 0.4, 0.3, 0.6), 1.0)

	# 2. Tomonlar (Kardinal yo'nalishlar)
	# Godot 3D koordinatalarda: -Z Shimol (0), +X Sharq (-PI/2), +Z Janub (PI), -X G'arb (PI/2)
	var cardinals := [
		[0.0, "SH", Color(1.0, 0.35, 0.35)],             # Shimol (North)
		[-PI * 0.25, "SH-SH", Color(0.75, 0.75, 0.75)],   # Shimoli-sharq
		[-PI * 0.5, "SH", Color(0.9, 0.85, 0.4)],         # Sharq (East)
		[-PI * 0.75, "J-SH", Color(0.75, 0.75, 0.75)],    # Janubi-sharq
		[PI, "J", Color(0.4, 0.8, 1.0)],                  # Janub (South)
		[PI * 0.75, "J-G'", Color(0.75, 0.75, 0.75)],     # Janubi-g'arb
		[PI * 0.5, "G'", Color(0.9, 0.85, 0.4)],          # G'arb (West)
		[PI * 0.25, "SH-G'", Color(0.75, 0.75, 0.75)],    # Shimoli-g'arb
	]

	for c in cardinals:
		var c_ang: float = c[0]
		var diff := wrapf(c_ang - cam_yaw, -PI, PI)
		var x := center_x + diff * px_per_rad
		if x >= 8.0 and x <= 392.0:
			_compass_canvas.draw_line(Vector2(x, 14), Vector2(x, 18), Color(0.7, 0.65, 0.5), 1.0)
			_compass_canvas.draw_string(font, Vector2(x - 12, 13), c[1], HORIZONTAL_ALIGNMENT_CENTER, 24, 10, c[2])

	# 3. Asosiy nishonlar (POIs)
	var p_pos := _player.global_position if _player and is_instance_valid(_player) else Vector3.ZERO
	var pois := [
		{"pos": Vector3(18, 0, 16), "name": "O'tov (Qultoy)", "icon": "⛺", "col": Color(1.0, 0.85, 0.3)},
		{"pos": Vector3(38, 0, 48), "name": "Qoyali Dev", "icon": "⚡", "col": Color(1.0, 0.5, 0.2)},
		{"pos": Vector3(0, 0, -82), "name": "Surxayil Arenasi", "icon": "⚔", "col": Color(0.95, 0.35, 0.35)},
		{"pos": Vector3(0, 0, -135), "name": "Qalmoq Zindoni", "icon": "☖", "col": Color(0.85, 0.45, 1.0)},
	]

	# Boychibor tulpori
	var horse = get_tree().get_first_node_in_group("horses")
	if horse and is_instance_valid(horse) and not horse.get("is_mounted"):
		pois.append({"pos": horse.global_position, "name": "Boychibor", "icon": "🐎", "col": Color(0.35, 1.0, 0.5)})

	var closest_name := ""
	var closest_dist := 99999.0

	for poi in pois:
		var pos: Vector3 = poi.pos
		var d := p_pos.distance_to(pos)
		if d < closest_dist:
			closest_dist = d
			closest_name = poi.name

		var to_poi := pos - p_pos
		var ang := atan2(to_poi.x, -to_poi.z) # North is -Z
		var diff := wrapf(ang - cam_yaw, -PI, PI)
		var x := center_x + diff * px_per_rad
		if x >= 12.0 and x <= 388.0:
			_compass_canvas.draw_string(font, Vector2(x - 8, 14), poi.icon, HORIZONTAL_ALIGNMENT_CENTER, 16, 11, poi.col)

	# 4. Yaqin dushmanlar (Qizil radar nuqtalari)
	for e in get_tree().get_nodes_in_group("enemies"):
		var e_node := e as Node3D
		if e_node and is_instance_valid(e_node) and not e_node.is_queued_for_deletion():
			var d := p_pos.distance_to(e_node.global_position)
			if d < 35.0:
				var to_e: Vector3 = e_node.global_position - p_pos
				var ang := atan2(to_e.x, -to_e.z)
				var diff := wrapf(ang - cam_yaw, -PI, PI)
				var x := center_x + diff * px_per_rad
				if x >= 10.0 and x <= 390.0:
					_compass_canvas.draw_circle(Vector2(x, 18), 2.5, Color(1.0, 0.2, 0.2, 0.9))

	if closest_name != "" and _compass_info_label:
		_compass_info_label.text = "[ %s: %dm ]" % [closest_name, int(round(closest_dist))]


func _setup_quest_ui() -> void:
	# Erkin va qulay Doston Vazifalari Jadvali (Checklist)
	_quest_panel = PanelContainer.new()
	_quest_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quest_panel.offset_left = -360
	_quest_panel.offset_right = -20
	_quest_panel.offset_top = 52
	_quest_panel.offset_bottom = 230

	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.08, 0.07, 0.06, 0.85)
	pstyle.border_width_left = 2
	pstyle.border_width_right = 2
	pstyle.border_width_top = 2
	pstyle.border_width_bottom = 2
	pstyle.border_color = Color(0.75, 0.62, 0.28, 0.8)
	pstyle.corner_radius_top_left = 8
	pstyle.corner_radius_top_right = 8
	pstyle.corner_radius_bottom_left = 8
	pstyle.corner_radius_bottom_right = 8
	pstyle.content_margin_left = 12
	pstyle.content_margin_right = 12
	pstyle.content_margin_top = 10
	pstyle.content_margin_bottom = 10
	_quest_panel.add_theme_stylebox_override("panel", pstyle)
	add_child(_quest_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	_quest_panel.add_child(main_vbox)

	_quest_header = Label.new()
	_quest_header.text = "DOSTON VAZIFALARI (0/4)"
	_quest_header.add_theme_font_size_override("font_size", 14)
	_quest_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	main_vbox.add_child(_quest_header)

	var rows := [
		{"id": "qultoy", "title": "Qultoy Cho'pon sadosi", "hint": "O'tovda suhbatlashish [ E ]"},
		{"id": "boychibor", "title": "Boychibor tulpori", "hint": "Otga minish va chopish [ F ]"},
		{"id": "giant", "title": "Qoyali Dasht Devi", "hint": "Sharqdagi devni yengish"},
		{"id": "boss", "title": "Surxayil Alp arenasi", "hint": "Shimoliy arenadagi botirni yengish"}
	]

	for r in rows:
		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 8)
		main_vbox.add_child(row_hbox)

		var chk := Label.new()
		chk.text = "[○]"
		chk.add_theme_font_size_override("font_size", 13)
		chk.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
		row_hbox.add_child(chk)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_hbox.add_child(info)

		var tlbl := Label.new()
		tlbl.text = r.title
		tlbl.add_theme_font_size_override("font_size", 13)
		tlbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		info.add_child(tlbl)

		var hlbl := Label.new()
		hlbl.text = r.hint
		hlbl.add_theme_font_size_override("font_size", 11)
		hlbl.add_theme_color_override("font_color", Color(0.72, 0.7, 0.65))
		info.add_child(hlbl)

		_quest_items[r.id] = {
			"check": chk,
			"title": tlbl,
			"hint": hlbl
		}


func _refresh_quest_tracker() -> void:
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem == null:
		return
	var quests: Array[Dictionary] = qsystem.get_all_quests()
	var completed_count: int = qsystem.get_completed_count()
	var total_count: int = qsystem.get_total_count()

	_quest_header.text = "DOSTON VAZIFALARI (%d/%d)" % [completed_count, total_count]
	if completed_count == total_count:
		_quest_header.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45))
	else:
		_quest_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	for q in quests:
		var qid: String = q.get("id", "")
		if not _quest_items.has(qid):
			continue
		var item: Dictionary = _quest_items[qid]
		var is_comp: bool = q.get("completed", false)
		var check: Label = item.check
		var title: Label = item.title
		var hint: Label = item.hint

		if is_comp:
			check.text = "[✓]"
			check.add_theme_color_override("font_color", Color(0.25, 0.95, 0.4))
			title.add_theme_color_override("font_color", Color(0.65, 0.85, 0.65))
			hint.text = "Bajarildi (+%d XP)" % q.get("xp", 50)
			hint.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5))
		else:
			check.text = "[○]"
			check.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
			title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
			hint.text = q.get("hint", q.get("desc", ""))
			hint.add_theme_color_override("font_color", Color(0.72, 0.7, 0.65))


func _setup_banner_ui() -> void:
	_banner_panel = PanelContainer.new()
	_banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner_panel.offset_top = 40
	_banner_panel.offset_left = -230
	_banner_panel.offset_right = 230
	_banner_panel.offset_bottom = 112

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.94)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.82, 0.25)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_banner_panel.add_theme_stylebox_override("panel", style)
	_banner_panel.modulate.a = 0.0
	add_child(_banner_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner_panel.add_child(vbox)

	_banner_title = Label.new()
	_banner_title.text = "VAZIFA BAJARILDI!"
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.add_theme_font_size_override("font_size", 20)
	_banner_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(_banner_title)

	_banner_sub = Label.new()
	_banner_sub.text = "Qultoy Cho'pon sadosi"
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.add_theme_font_size_override("font_size", 15)
	_banner_sub.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	vbox.add_child(_banner_sub)


func show_banner(title: String, subtitle: String) -> void:
	_banner_title.text = title
	_banner_sub.text = subtitle
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_panel, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(2.6)
	_banner_tween.tween_property(_banner_panel, "modulate:a", 0.0, 0.45)


func _connect_quests() -> void:
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem == null:
		return
	if qsystem.has_signal("quest_state_changed"):
		qsystem.connect("quest_state_changed", func(_id: String, _comp: bool):
			_refresh_quest_tracker())
	if qsystem.has_signal("banner_requested"):
		qsystem.connect("banner_requested", show_banner)
	if qsystem.has_signal("all_quests_completed"):
		qsystem.connect("all_quests_completed", _on_all_quests_completed)

	_refresh_quest_tracker()


func _connect_progression() -> void:
	var prog = get_tree().get_first_node_in_group("progression")
	if prog == null:
		return
	if prog.has_signal("xp_gained"):
		prog.connect("xp_gained", func(c_xp: int, n_xp: int):
			_xp_bar.max_value = n_xp
			_xp_bar.value = c_xp
			_lvl_label.text = "LVL %d (%d/%d XP)" % [prog.get("level"), c_xp, n_xp])
	if prog.has_signal("level_up"):
		prog.connect("level_up", func(lvl: int, sp: int):
			_lvl_label.text = "LVL %d" % lvl
			_skill_hint.visible = sp > 0)
	if prog.has_signal("skill_unlocked"):
		prog.connect("skill_unlocked", func(_id: String):
			_skill_hint.visible = prog.get("skill_points") > 0)
