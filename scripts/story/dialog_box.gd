extends CanvasLayer
## Alpomish dostoni: Dialog oynasi va tanlov tizimi.

signal dialog_finished(chosen_option_index: int)

var _panel: Panel
var _speaker_label: Label
var _text_label: Label
var _continue_hint: Label
var _choices_box: VBoxContainer
var _btn_choice_a: Button
var _btn_choice_b: Button

var _dialog_queue: Array[Dictionary] = []
var _current_index := 0
var _is_waiting_choice := false
var _active := false


func _ready() -> void:
	layer = 10
	_build_ui()
	visible = false


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -210
	_panel.offset_bottom = -24
	_panel.offset_left = 120
	_panel.offset_right = -120

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.92)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.68, 0.22) # Oltin hoshiya
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.text = "QULTOY CHO'PON"
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(_speaker_label)

	_text_label = Label.new()
	_text_label.text = "Doston matni shu yerda bo'ladi..."
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 18)
	_text_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88))
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text_label)

	_choices_box = VBoxContainer.new()
	_choices_box.visible = false
	vbox.add_child(_choices_box)

	_btn_choice_a = Button.new()
	_btn_choice_a.custom_minimum_size = Vector2(0, 32)
	_btn_choice_a.pressed.connect(func(): _on_choice_selected(0))
	_choices_box.add_child(_btn_choice_a)

	_btn_choice_b = Button.new()
	_btn_choice_b.custom_minimum_size = Vector2(0, 32)
	_btn_choice_b.pressed.connect(func(): _on_choice_selected(1))
	_choices_box.add_child(_btn_choice_b)

	_continue_hint = Label.new()
	_continue_hint.text = "[ SPACE / E / ENTER ] – Davom etish"
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_hint.add_theme_font_size_override("font_size", 13)
	_continue_hint.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	vbox.add_child(_continue_hint)


func start_dialog(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		return
	_dialog_queue = lines
	_current_index = 0
	_active = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_current_line()


func _show_current_line() -> void:
	var item: Dictionary = _dialog_queue[_current_index]
	_speaker_label.text = item.get("speaker", "Noma'lum")
	_text_label.text = item.get("text", "")

	if item.has("choices") and item.choices is Array and item.choices.size() >= 2:
		_is_waiting_choice = true
		_choices_box.visible = true
		_continue_hint.visible = false
		_btn_choice_a.text = "1. " + str(item.choices[0])
		_btn_choice_b.text = "2. " + str(item.choices[1])
	else:
		_is_waiting_choice = false
		_choices_box.visible = false
		_continue_hint.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not _active or _is_waiting_choice:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E or event.keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			_next_line()


func _next_line() -> void:
	_current_index += 1
	if _current_index < _dialog_queue.size():
		_show_current_line()
	else:
		_close_dialog(-1)


func _on_choice_selected(index: int) -> void:
	_close_dialog(index)


func _close_dialog(choice: int) -> void:
	_active = false
	visible = false
	_is_waiting_choice = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	dialog_finished.emit(choice)
