extends MarginContainer

@onready var _tree: Tree = %BindingsTree
@onready var _status_label: Label = %StatusLabel
@onready var _rebind_button: Button = %RebindButton
@onready var _clear_button: Button = %ClearButton
@onready var _reset_button: Button = %ResetButton
@onready var _detector: GUIDEInputDetector = $GUIDEInputDetector

var _row_to_column_config: Dictionary = {}
var _selected_item: TreeItem
var _selected_config_item
var _formatter: GUIDEInputFormatter
var _is_rebinding: bool = false


func _ready() -> void:
	GuideInputRuntime.ensure_initialized()
	_formatter = GUIDEInputFormatter.for_context(GuideInputRuntime.get_context(), 20)
	_tree.hide_root = true
	_tree.columns = 4
	_tree.column_titles_visible = true
	_tree.set_column_title(0, tr("ui.input.table_action"))
	_tree.set_column_title(1, tr("ui.input.table_keyboard"))
	_tree.set_column_title(2, tr("ui.input.table_mouse"))
	_tree.set_column_title(3, tr("ui.input.table_gamepad"))
	_build_table()
	_tree.item_selected.connect(_on_tree_item_selected)
	_tree.item_activated.connect(_on_tree_item_activated)
	_rebind_button.pressed.connect(_on_rebind_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_detector.input_detected.connect(_on_input_detected)
	_refresh_buttons()


func _build_table() -> void:
	_row_to_column_config.clear()
	_tree.clear()
	var root := _tree.create_item()
	var remapper := GuideInputRuntime.get_remapper()
	var remappable_items: Array = remapper.get_remappable_items()
	var move_items_by_index: Dictionary = {}
	var action_rows: Dictionary = {}
	for item in remappable_items:
		if item.action.name == &"pe_move":
			move_items_by_index[item.index] = item
			continue
		var action_name: StringName = item.action.name
		var columns: Dictionary = action_rows.get(action_name, {})
		var column := _get_device_column(item)
		if column > 0 and not columns.has(column):
			columns[column] = item
		action_rows[action_name] = columns

	var rows: Array = [
		{"label_key": "ui.input.action_move_up", "columns": {1: move_items_by_index.get(2)}},
		{"label_key": "ui.input.action_move_down", "columns": {1: move_items_by_index.get(3)}},
		{"label_key": "ui.input.action_move_left", "columns": {1: move_items_by_index.get(0)}},
		{"label_key": "ui.input.action_move_right", "columns": {1: move_items_by_index.get(1)}},
		{"label_key": "ui.input.action_move_gamepad", "columns": {3: move_items_by_index.get(4)}},
		{"label_key": "ui.input.action_aim", "columns": action_rows.get(&"pe_aim_axis", {})},
		{"label_key": "ui.input.action_fire", "columns": action_rows.get(&"pe_fire", {})},
		{"label_key": "ui.input.action_aim_hold", "columns": action_rows.get(&"pe_aim_hold", {})},
		{"label_key": "ui.input.action_reload", "columns": action_rows.get(&"pe_reload", {})},
		{"label_key": "ui.input.action_fire_mode_toggle", "columns": action_rows.get(&"pe_fire_mode_toggle", {})},
		{"label_key": "ui.input.action_sprint", "columns": action_rows.get(&"pe_sprint", {})},
		{"label_key": "ui.input.action_pause", "columns": action_rows.get(&"pe_pause", {})},
	]
	for row in rows:
		_add_table_row(root, row.label_key, row.columns)


func _add_table_row(root: TreeItem, label_key: String, columns: Dictionary) -> void:
	var line := _tree.create_item(root)
	line.set_text(0, tr(label_key))
	var column_map: Dictionary = {}
	for column in [1, 2, 3]:
		var config_item = columns.get(column)
		column_map[column] = config_item
		if config_item == null:
			line.set_text(column, tr("ui.input.not_applicable"))
			line.set_selectable(column, false)
			continue
		line.set_text(column, _format_binding(config_item))
		line.set_selectable(column, true)
	_row_to_column_config[line] = column_map


func _format_binding(item) -> String:
	var remapper := GuideInputRuntime.get_remapper()
	var binding: GUIDEInput = remapper.get_bound_input_or_null(item)
	if binding == null:
		return tr("ui.input.unbound")
	return _formatter.input_as_text(binding)


func _refresh_buttons() -> void:
	var has_selection := _selected_config_item != null
	_rebind_button.disabled = not has_selection or _is_rebinding
	_clear_button.disabled = not has_selection


func _on_tree_item_selected() -> void:
	_selected_item = _tree.get_selected()
	var selected_column := _tree.get_selected_column()
	var column_map: Dictionary = _row_to_column_config.get(_selected_item, {})
	_selected_config_item = column_map.get(selected_column)
	_refresh_buttons()


func _on_rebind_pressed() -> void:
	if _selected_config_item == null:
		return
	_is_rebinding = true
	_refresh_buttons()
	_status_label.text = tr("ui.input.press_for_action").format([tr(_selected_config_item.display_name)])
	var value_type: GUIDEAction.GUIDEActionValueType = _selected_config_item.value_type
	match value_type:
		GUIDEAction.GUIDEActionValueType.BOOL:
			_detector.detect_bool()
		GUIDEAction.GUIDEActionValueType.AXIS_1D:
			_detector.detect_axis_1d()
		GUIDEAction.GUIDEActionValueType.AXIS_2D:
			_detector.detect_axis_2d()
		_:
			_detector.detect_axis_3d()


func _on_clear_pressed() -> void:
	if _selected_config_item == null:
		return
	var remapper := GuideInputRuntime.get_remapper()
	remapper.set_bound_input(_selected_config_item, null)
	GuideInputRuntime.apply_remapping_config(remapper.get_mapping_config())
	_status_label.text = tr("ui.input.cleared")
	_build_table()


func _on_reset_pressed() -> void:
	GuideInputRuntime.apply_remapping_config(GUIDERemappingConfig.new())
	GuideInputRuntime.ensure_initialized()
	_status_label.text = tr("ui.input.restored_defaults")
	_build_table()


func _on_input_detected(input: GUIDEInput) -> void:
	_is_rebinding = false
	_refresh_buttons()
	if _selected_config_item == null:
		return
	if input == null:
		_status_label.text = tr("ui.input.rebind_cancelled")
		return
	var remapper := GuideInputRuntime.get_remapper()
	remapper.set_bound_input(_selected_config_item, input)
	GuideInputRuntime.apply_remapping_config(remapper.get_mapping_config())
	_status_label.text = tr("ui.input.bound_action").format([tr(_selected_config_item.display_name)])
	_build_table()


func _on_tree_item_activated() -> void:
	_on_rebind_pressed()


func _get_device_column(item) -> int:
	var remapper := GuideInputRuntime.get_remapper()
	var input: GUIDEInput = remapper.get_default_input(item)
	if input is GUIDEInputKey:
		return 1
	if input is GUIDEInputMouseButton:
		return 2
	if input is GUIDEInputJoyButton or input is GUIDEInputJoyAxis1D or input is GUIDEInputJoyAxis2D:
		return 3
	return 0
