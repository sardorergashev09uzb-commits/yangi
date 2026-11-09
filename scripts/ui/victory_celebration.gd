class_name VictoryCelebration
extends CanvasLayer
## 9-bosqich: Yakuniy Doston Zafari va G'alaba Tantanasi (Epic Victory Screen).
## Barchinoy ozod bo'lib, Qalmoq qal'asi qamali yakunlangach namoyish etiladi.

signal celebration_closed()

var _panel: PanelContainer
var _gold_label: Label
var _enemies_label: Label


func _ready() -> void:
	layer = 100
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Qoramtir shaffof fojiyaviy/tantanali fon
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.06, 0.88)
	root.add_child(bg)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(720, 520)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08, 0.96)
	style.border_color = Color(0.95, 0.78, 0.25)
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)

	# Bosh sarlavha
	var title := Label.new()
	title.text = "★ BUYUK DOSTON ZAFARI ★"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Qalmoq Qal'asi Fath Etildi — Go'zal Barchinoy Ozod Bo'ldi!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	vbox.add_child(subtitle)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Epik Doston matni
	var desc := Label.new()
	desc.text = "Alpomish botir o'zining sadoqatli tulpari Boychibor, qondosh do'sti Karajon va Qo'ng'irot botirlari bilan birgalikda yovuzlik ustidan buyuk g'alaba qozondi. Amakisi Boysari eli tinchlikka erishdi, adolat qaror topdi va doston qahramonining shon-shavkati asrlarga muhrlandi!"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	vbox.add_child(desc)

	# Mukofotlar bloki
	var reward_box := VBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 8)

	var rw_title := Label.new()
	rw_title.text = "EL-YURT EHTIROMI VA SARPOLAR:"
	rw_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rw_title.add_theme_font_size_override("font_size", 18)
	rw_title.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
	reward_box.add_child(rw_title)

	_gold_label = Label.new()
	_gold_label.text = "💰 Xazinadan in'om: +500 Oltin Tilla"
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 16)
	reward_box.add_child(_gold_label)

	_enemies_label = Label.new()
	_enemies_label.text = "👑 Unvon: 'Boysun Qalbi — Alp Alpomish'"
	_enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemies_label.add_theme_font_size_override("font_size", 16)
	reward_box.add_child(_enemies_label)

	vbox.add_child(reward_box)

	var btn_continue := Button.new()
	btn_continue.text = "O'YINNI ERKIN DAVOM ETTIRISH (OPEN WORLD)"
	btn_continue.custom_minimum_size = Vector2(360, 48)
	btn_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_continue.add_theme_font_size_override("font_size", 16)
	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)


func show_celebration() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play_victory()

	# O'yinchiga sarpo oltinlarini berish
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold"):
		player.add_gold(500)


func _on_continue_pressed() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	celebration_closed.emit()
