extends Node
## Barcha boshqaruv tugmalarini kodda ro'yxatdan o'tkazadi (klaviatura + sichqoncha + gamepad).

func _ready() -> void:
	_action("move_left", [_key(KEY_A)], [_axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", [_key(KEY_D)], [_axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("move_forward", [_key(KEY_W)], [_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_back", [_key(KEY_S)], [_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("cam_left", [], [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("cam_right", [], [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("cam_up", [], [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action("cam_down", [], [_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_action("jump", [_key(KEY_X)], [_button(JOY_BUTTON_A)])
	_action("dodge", [_key(KEY_SPACE)], [_button(JOY_BUTTON_B)])
	_action("sprint", [_key(KEY_SHIFT)], [_button(JOY_BUTTON_LEFT_STICK)])
	_action("attack_light", [_mouse(MOUSE_BUTTON_LEFT)], [_button(JOY_BUTTON_X), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action("attack_heavy", [_key(KEY_R)], [_button(JOY_BUTTON_Y)])
	_action("skill_special", [_key(KEY_C)], [_button(JOY_BUTTON_RIGHT_SHOULDER)])
	_action("block", [_key(KEY_Q)], [_button(JOY_BUTTON_LEFT_SHOULDER)])
	_action("battle_cry", [_key(KEY_V)], [_button(JOY_BUTTON_DPAD_DOWN)])
	_action("aim", [_mouse(MOUSE_BUTTON_RIGHT)], [_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_action("interact", [_key(KEY_F)], [_button(JOY_BUTTON_Y)])
	_action("talk", [_key(KEY_E)], [_button(JOY_BUTTON_X)])
	_action("whistle", [_key(KEY_H)], [_button(JOY_BUTTON_DPAD_UP)])
	_action("pause", [_key(KEY_ESCAPE)], [_button(JOY_BUTTON_START)])


func _action(action: String, keys: Array, pads: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for e in keys:
		InputMap.action_add_event(action, e)
	for e in pads:
		InputMap.action_add_event(action, e)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	return e


func _button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
