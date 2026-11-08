class_name MainMenu
extends CanvasLayer
## Bosh menyu: Yangi o'yin, Davom etish (saqlangan o'yin bo'lsa) va Chiqish.
## O'yin menyu ochiq turganda to'xtatilgan (pause) holatda bo'ladi.

signal game_started(from_save: bool)

var _continue_btn: Button
var _info: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("main_menu")
	_build_ui()
	open()


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_continue_btn.disabled = not SaveGame.has_save()
	_info.text = "Saqlangan o'yin topildi" if SaveGame.has_save() else "Saqlangan o'yin yo'q"


func start_new() -> void:
	_close()
	game_started.emit(false)


func continue_game() -> void:
	if not SaveGame.has_save():
		return
	_close()
	SaveGame.load_game()
	game_started.emit(true)


func _close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.05, 0.035, 0.03, 0.94)
	add_child(backdrop)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -200
	box.offset_right = 200
	box.offset_top = -190
	box.offset_bottom = 190
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "ALPOMISH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Qo'ng'irot eli dostoni"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	box.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	box.add_child(gap)

	var new_btn := _button("Yangi o'yin")
	new_btn.pressed.connect(start_new)
	box.add_child(new_btn)

	_continue_btn = _button("Davom etish")
	_continue_btn.pressed.connect(continue_game)
	box.add_child(_continue_btn)

	var quit_btn := _button("Chiqish")
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit_btn)

	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 14)
	_info.add_theme_color_override("font_color", Color(0.6, 0.58, 0.52))
	box.add_child(_info)

	new_btn.grab_focus.call_deferred()


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 22)
	return b
