extends CanvasLayer
## HUD: salomatlik, kuch, kamon zaryadi, nishon (crosshair), o'lim yozuvi va yordam matni.

var _health_bar: ProgressBar
var _stamina_bar: ProgressBar
var _charge_bar: ProgressBar
var _crosshair: Label
var _death_label: Label
var _player: Player
var _enemy_label: Label


func _ready() -> void:
	_health_bar = _make_bar(Vector2(30, 28), Vector2(320, 18), Color(0.8, 0.15, 0.15))
	_stamina_bar = _make_bar(Vector2(30, 52), Vector2(260, 12), Color(0.3, 0.75, 0.3))

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
	_death_label.text = "Alpamish yiqildi..."
	_death_label.add_theme_font_size_override("font_size", 48)
	_death_label.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	_death_label.set_anchors_preset(Control.PRESET_CENTER)
	_death_label.position += Vector2(-200, -30)
	_death_label.visible = false
	add_child(_death_label)

	_enemy_label = Label.new()
	_enemy_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_enemy_label.position = Vector2(-220, 28)
	add_child(_enemy_label)

	var help := Label.new()
	help.position = Vector2(30, 76)
	help.text = "WASD - yurish | Sichqoncha - kamera/burilish | Shift - yugurish | Space - qochish | X - sakrash\nFaqat sichqoncha personaj yuzini buradi, WASD faqat harakat\n" \
			+ "Chap tugma - qilich kombosi (3 zarba) | R - og'ir zarba | O'ng tugma ushlab - kamon, chap tugmani ushlab qo'yib yuborish - otish\n" \
			+ "Esc - sichqoncha"
	add_child(help)
	_connect_player.call_deferred()


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
	_player.died.connect(func() -> void: _death_label.visible = true)
	_player.respawned.connect(func() -> void: _death_label.visible = false)


func _process(_delta: float) -> void:
	_enemy_label.text = "Dushmanlar: %d" % get_tree().get_nodes_in_group("enemies").size()
	if _player == null:
		return
	_crosshair.visible = _player.aiming
	_charge_bar.visible = _player.aiming and _player.bow_charge > 0.0
	_charge_bar.max_value = 1.0
	_charge_bar.value = _player.bow_charge
