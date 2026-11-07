extends CanvasLayer
## HUD: salomatlik, kuch, kamon zaryadi, dushmanlar soni va Epik Boss salomatlik paneli.

var _health_bar: ProgressBar
var _stamina_bar: ProgressBar
var _charge_bar: ProgressBar
var _crosshair: Label
var _death_label: Label
var _enemy_label: Label
var _player: Player

# Boss UI elementlari
var _boss_container: VBoxContainer
var _boss_name_label: Label
var _boss_bar: ProgressBar
var _boss_phase_label: Label
var _boss_victory_label: Label


func _ready() -> void:
	_health_bar = _make_bar(Vector2(30, 28), Vector2(320, 18), Color(0.8, 0.15, 0.15))
	_stamina_bar = _make_bar(Vector2(30, 52), Vector2(260, 12), Color(0.3, 0.75, 0.3))

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

	_death_label = Label.new()
	_death_label.text = "ALPAMISH YIQILDI\nQayta tiklanmoqda..."
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_label.add_theme_font_size_override("font_size", 44)
	_death_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	_death_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_label.visible = false
	add_child(_death_label)

	_boss_victory_label = Label.new()
	_boss_victory_label.text = "SURXAYIL ALP MAG'LUB ETILDI!"
	_boss_victory_label.add_theme_font_size_override("font_size", 42)
	_boss_victory_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_boss_victory_label.set_anchors_preset(Control.PRESET_CENTER)
	_boss_victory_label.position += Vector2(-300, -100)
	_boss_victory_label.visible = false
	add_child(_boss_victory_label)

	_setup_boss_ui()

	var help := Label.new()
	help.position = Vector2(30, 76)
	help.text = "WASD - yurish | Sichqoncha - kamera/burilish | Shift - yugurish | Space - qochish | X - sakrash\n" \
			+ "Chap tugma - qilich kombosi (3 zarba) | R - og'ir zarba | O'ng tugma ushlab - kamon, chap tugma - otish\n" \
			+ "Shimolga (oldinga) yuring: Surxayil Arenasi kutmoqda!"
	add_child(help)

	_connect_player.call_deferred()
	_connect_boss.call_deferred()


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
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player == null:
		return
	_health_bar.max_value = _player.max_health
	_health_bar.value = _player.health
	_stamina_bar.max_value = _player.max_stamina
	_player.stamina_changed.connect(func(c: float, m: float) -> void:
		_stamina_bar.max_value = m
		_stamina_bar.value = c)
	_player.health_changed.connect(func(c: float, m: float) -> void:
		_health_bar.max_value = m
		_health_bar.value = c)
	_player.died.connect(func() -> void:
		_death_label.visible = true
		_boss_container.visible = false)
	_player.respawned.connect(func() -> void:
		_death_label.visible = false)


func _connect_boss() -> void:
	var boss := get_tree().get_first_node_in_group("bosses") as BossSurxayil
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
	_boss_victory_label.visible = true
	await get_tree().create_timer(4.5).timeout
	var t := create_tween()
	t.tween_property(_boss_victory_label, "modulate:a", 0.0, 1.0)
	t.tween_callback(func() -> void:
		_boss_victory_label.visible = false
		_boss_victory_label.modulate.a = 1.0)


func _process(_delta: float) -> void:
	var enemies_count := get_tree().get_nodes_in_group("enemies").size()
	_enemy_label.text = "Dushmanlar: %d" % enemies_count
	if _player == null:
		return
	_crosshair.visible = _player.aiming
	_charge_bar.visible = _player.aiming and _player.bow_charge > 0.0
	_charge_bar.max_value = 1.0
	_charge_bar.value = _player.bow_charge
