class_name PlayerInputContext
extends GUIDEMappingContext

func _init() -> void:
	display_name = "Player"
	mappings = [
		_make_move_mapping(),
		_make_aim_mapping(),
		_make_fire_mapping(),
		_make_aim_hold_mapping(),
		_make_reload_mapping(),
		_make_fire_mode_toggle_mapping(),
		_make_sprint_mapping(),
		_make_pause_mapping(),
	]


func _make_move_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_move"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.AXIS_2D
	action.is_remappable = true
	action.display_name = "ui.input.action_move"
	action.display_category = "Movement"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_move_keys_mapping(-1.0, 0.0, KEY_A),
		_make_move_keys_mapping(1.0, 0.0, KEY_D),
		_make_move_keys_mapping(0.0, -1.0, KEY_W),
		_make_move_keys_mapping(0.0, 1.0, KEY_S),
		_make_joy_axis_2d_mapping(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y),
	]
	return mapping


func _make_aim_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_aim_axis"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.AXIS_2D
	action.is_remappable = true
	action.display_name = "ui.input.action_aim"
	action.display_category = "Combat"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_joy_axis_2d_mapping(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y),
	]
	return mapping


func _make_fire_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_fire"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.BOOL
	action.is_remappable = true
	action.display_name = "ui.input.action_fire"
	action.display_category = "Combat"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_mouse_button_mapping(MOUSE_BUTTON_LEFT),
		_make_key_mapping(KEY_SPACE),
		_make_joy_button_mapping(JOY_BUTTON_RIGHT_SHOULDER),
	]
	return mapping


func _make_aim_hold_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_aim_hold"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.BOOL
	action.is_remappable = true
	action.display_name = "ui.input.action_aim_hold"
	action.display_category = "Combat"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_mouse_button_mapping(MOUSE_BUTTON_RIGHT),
		_make_joy_axis_1d_mapping(JOY_AXIS_TRIGGER_LEFT),
	]
	return mapping


func _make_sprint_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_sprint"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.BOOL
	action.is_remappable = true
	action.display_name = "ui.input.action_sprint"
	action.display_category = "Movement"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_key_mapping(KEY_SHIFT),
		_make_joy_button_mapping(JOY_BUTTON_LEFT_SHOULDER),
	]
	return mapping


func _make_reload_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_reload"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.BOOL
	action.is_remappable = true
	action.display_name = "ui.input.action_reload"
	action.display_category = "Combat"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_key_mapping(KEY_R),
		_make_joy_button_mapping(JOY_BUTTON_X),
	]
	return mapping


func _make_fire_mode_toggle_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_fire_mode_toggle"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.BOOL
	action.is_remappable = true
	action.display_name = "ui.input.action_fire_mode_toggle"
	action.display_category = "Combat"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_key_mapping(KEY_B),
		_make_joy_button_mapping(JOY_BUTTON_Y),
	]
	return mapping


func _make_pause_mapping() -> GUIDEActionMapping:
	var action := GUIDEAction.new()
	action.name = &"pe_pause"
	action.action_value_type = GUIDEAction.GUIDEActionValueType.BOOL
	action.is_remappable = true
	action.display_name = "ui.input.action_pause"
	action.display_category = "System"

	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = [
		_make_key_mapping(KEY_ESCAPE),
		_make_key_mapping(KEY_P),
		_make_joy_button_mapping(JOY_BUTTON_START),
	]
	return mapping


func _make_move_keys_mapping(scale_x: float, scale_y: float, keycode: Key) -> GUIDEInputMapping:
	var input := GUIDEInputKey.new()
	input.key = keycode
	var scale := GUIDEModifierScale.new()
	scale.scale = Vector3(scale_x, scale_y, 0.0)
	var mapping := GUIDEInputMapping.new()
	mapping.input = input
	mapping.is_remappable = true
	if is_zero_approx(scale_x):
		var swizzle := GUIDEModifierInputSwizzle.new()
		swizzle.order = GUIDEModifierInputSwizzle.GUIDEInputSwizzleOperation.YXZ
		mapping.modifiers = [swizzle, scale]
	else:
		mapping.modifiers = [scale]
	return mapping


func _make_joy_axis_2d_mapping(axis_x: JoyAxis, axis_y: JoyAxis) -> GUIDEInputMapping:
	var mapping := GUIDEInputMapping.new()
	var input := GUIDEInputJoyAxis2D.new()
	input.x = axis_x
	input.y = axis_y
	var deadzone := GUIDEModifierDeadzone.new()
	deadzone.lower_threshold = 0.18
	mapping.input = input
	mapping.is_remappable = true
	mapping.modifiers = [deadzone]
	return mapping


func _make_joy_axis_1d_mapping(axis: JoyAxis) -> GUIDEInputMapping:
	var mapping := GUIDEInputMapping.new()
	var input := GUIDEInputJoyAxis1D.new()
	input.axis = axis
	var deadzone := GUIDEModifierDeadzone.new()
	deadzone.lower_threshold = 0.2
	mapping.input = input
	mapping.is_remappable = true
	mapping.modifiers = [deadzone]
	return mapping


func _make_mouse_button_mapping(button: MouseButton) -> GUIDEInputMapping:
	var mapping := GUIDEInputMapping.new()
	var input := GUIDEInputMouseButton.new()
	input.button = button
	mapping.input = input
	mapping.is_remappable = true
	return mapping


func _make_joy_button_mapping(button: JoyButton) -> GUIDEInputMapping:
	var mapping := GUIDEInputMapping.new()
	var input := GUIDEInputJoyButton.new()
	input.button = button
	mapping.input = input
	mapping.is_remappable = true
	return mapping


func _make_key_mapping(keycode: Key) -> GUIDEInputMapping:
	var mapping := GUIDEInputMapping.new()
	var input := GUIDEInputKey.new()
	input.key = keycode
	mapping.input = input
	mapping.is_remappable = true
	return mapping
