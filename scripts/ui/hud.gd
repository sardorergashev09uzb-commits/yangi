extends CanvasLayer
## HUD: salomatlik, kuch, kamon zaryadi, dushmanlar soni, Boss paneli va qayta boshlash menyusi.

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

# Kvest va Banner UI
var _quest_container: VBoxContainer
var _quest_title_label: Label
var _quest_desc_label: Label
var _banner_panel: PanelContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_tween: Tween

# XP va Level UI
var _xp_bar: ProgressBar
var _lvl_label: Label
var _skill_hint: Label


func _ready() -> void:
	_health_bar = _make_bar(Vector2(30, 24), Vector2(320, 16), Color(0.85, 0.15, 0.15))
	_stamina_bar = _make_bar(Vector2(30, 44), Vector2(260, 10), Color(0.3, 0.75, 0.3))
	_xp_bar = _make_bar(Vector2(30, 58), Vector2(200, 8), Color(0.65, 0.35, 0.95))

	_lvl_label = Label.new()
	_lvl_label.text = "LVL 1 (0/100 XP)"
	_lvl_label.position = Vector2(238, 52)
	_lvl_label.add_theme_font_size_override("font_size", 12)
	_lvl_label.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	add_child(_lvl_label)

	_skill_hint = Label.new()
	_skill_hint.text = "★ [ TAB ] - Yangi ko'nikma ochkosi!"
	_skill_hint.position = Vector2(30, 70)
	_skill_hint.add_theme_font_size_override("font_size", 13)
	_skill_hint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_skill_hint.visible = false
	add_child(_skill_hint)

	_enemy_label = Label.new()
	_enemy_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_enemy_label.position = Vector2(-220, 28)
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
	help.text = "WASD - yurish | Sichqoncha - kamera | TAB - ko'nikmalar & pauza | E - suhbatlashish | F - Boychibor | H - hushtak\n" \
			+ "Ot ustida Shift - shiddatli galop (16 m/s) va toptash (trample) | Space / X - sakrash | O'ng tugma - kamon otish\n" \
			+ "Sharqqa: Boysun O'tovi, Qultoy Cho'pon va Dev | Shimolga: Surxayil Arenasi | T - qayta boshlash"
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
	title.text = "ALPAMISH YIQILDI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Qayta boshlash uchun [ SPACE ] yoki [ R ] bosing"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75))
	vbox.add_child(sub)

	var space := Control.new()
	space.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(space)

	var btn := Button.new()
	btn.text = "Qayta boshlash (Restart)"
	btn.custom_minimum_size = Vector2(260, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_restart_scene)
	vbox.add_child(btn)


func _setup_victory_ui() -> void:
	_victory_panel = Panel.new()
	_victory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.03, 0.88)
	_victory_panel.add_theme_stylebox_override("panel", style)
	_victory_panel.visible = false
	add_child(_victory_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300
	vbox.offset_right = 300
	vbox.offset_top = -130
	vbox.offset_bottom = 130
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_victory_panel.add_child(vbox)

	var title := Label.new()
	title.text = "SURXAYIL ALP MAG'LUB ETILDI!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Qalmoq botiri tiz cho'kdi. Qo'ng'irot sari yo'l ochildi!\n[ SPACE ] yoki [ R ] – Boss bilan qayta jang qilish"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	vbox.add_child(sub)

	var space := Control.new()
	space.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(space)

	var btn := Button.new()
	btn.text = "Boss bilan qayta jang qilish"
	btn.custom_minimum_size = Vector2(280, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_restart_scene)
	vbox.add_child(btn)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			_restart_scene()
			return
		if _death_panel.visible or _victory_panel.visible:
			if event.keycode == KEY_SPACE or event.keycode == KEY_R or event.keycode == KEY_ENTER:
				_restart_scene()


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
	_player.connect("died", func() -> void:
		_death_panel.visible = true
		_boss_container.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	_player.connect("respawned", func() -> void:
		_death_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)


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
	_boss_container.visible = false
	_victory_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
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


func _setup_quest_ui() -> void:
	_quest_container = VBoxContainer.new()
	_quest_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quest_container.offset_left = -340
	_quest_container.offset_right = -30
	_quest_container.offset_top = 58
	_quest_container.offset_bottom = 150
	add_child(_quest_container)

	var header := Label.new()
	header.text = "DOSTON VAZIFASI"
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	_quest_container.add_child(header)

	_quest_title_label = Label.new()
	_quest_title_label.text = "1. Qultoy Cho'pon sadosi"
	_quest_title_label.add_theme_font_size_override("font_size", 16)
	_quest_title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	_quest_container.add_child(_quest_title_label)

	_quest_desc_label = Label.new()
	_quest_desc_label.text = "Boysun o'toviga boring va Qultoy bilan gaplashing [ E ]"
	_quest_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_desc_label.add_theme_font_size_override("font_size", 13)
	_quest_desc_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	_quest_container.add_child(_quest_desc_label)


func _setup_banner_ui() -> void:
	_banner_panel = PanelContainer.new()
	_banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner_panel.offset_top = 40
	_banner_panel.offset_left = -220
	_banner_panel.offset_right = 220
	_banner_panel.offset_bottom = 110

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.8, 0.2)
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
	_banner_tween.tween_property(_banner_panel, "modulate:a", 1.0, 0.3)
	_banner_tween.tween_interval(2.5)
	_banner_tween.tween_property(_banner_panel, "modulate:a", 0.0, 0.5)


func _connect_quests() -> void:
	var qsystem = get_tree().get_first_node_in_group("quest_system")
	if qsystem == null:
		return
	if qsystem.has_signal("quest_updated"):
		qsystem.connect("quest_updated", func(_id: String, title: String, text: String, _comp: bool):
			_quest_title_label.text = title
			_quest_desc_label.text = text)
	if qsystem.has_signal("banner_requested"):
		qsystem.connect("banner_requested", show_banner)

	if qsystem.has_method("get_active_quest"):
		var q: Dictionary = qsystem.get_active_quest()
		if not q.is_empty():
			_quest_title_label.text = q.get("title", "")
			_quest_desc_label.text = q.get("desc", "")


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
