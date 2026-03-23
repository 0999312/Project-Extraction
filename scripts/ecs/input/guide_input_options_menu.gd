extends MarginContainer

@onready var _tree: Tree = %BindingsTree
@onready var _status_label: Label = %StatusLabel
@onready var _rebind_button: Button = %RebindButton
@onready var _clear_button: Button = %ClearButton
@onready var _reset_button: Button = %ResetButton
@onready var _detector: GUIDEInputDetector = $GUIDEInputDetector

var _item_to_config: Dictionary = {}
var _selected_item: TreeItem
var _selected_config_item
var _formatter: GUIDEInputFormatter


func _ready() -> void:
	GuideInputRuntime.ensure_initialized()
	_formatter = GUIDEInputFormatter.for_context(GuideInputRuntime.get_context(), 20)
	_tree.hide_root = true
	_tree.columns = 2
	_tree.column_titles_visible = true
	_tree.set_column_title(0, "Action")
	_tree.set_column_title(1, "Binding")
	_build_tree()
	_tree.item_selected.connect(_on_tree_item_selected)
	_rebind_button.pressed.connect(_on_rebind_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_detector.input_detected.connect(_on_input_detected)
	_refresh_buttons()


func _build_tree() -> void:
	_item_to_config.clear()
	_tree.clear()
	var root := _tree.create_item()
	var remapper := GuideInputRuntime.get_remapper()
	for item in remapper.get_remappable_items():
		var line := _tree.create_item(root)
		line.set_text(0, item.display_name)
		line.set_text(1, _format_binding(item))
		_item_to_config[line] = item


func _format_binding(item) -> String:
	var remapper := GuideInputRuntime.get_remapper()
	var binding: GUIDEInput = remapper.get_bound_input_or_null(item)
	if binding == null:
		return "(Unbound)"
	return _formatter.input_as_text(binding)


func _refresh_buttons() -> void:
	var has_selection := _selected_config_item != null
	_rebind_button.disabled = not has_selection
	_clear_button.disabled = not has_selection


func _on_tree_item_selected() -> void:
	_selected_item = _tree.get_selected()
	_selected_config_item = _item_to_config.get(_selected_item)
	_refresh_buttons()


func _on_rebind_pressed() -> void:
	if _selected_config_item == null:
		return
	_status_label.text = "Press a key/button/axis for \"%s\"..." % _selected_config_item.display_name
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
	_status_label.text = "Cleared binding."
	_build_tree()


func _on_reset_pressed() -> void:
	GuideInputRuntime.apply_remapping_config(GUIDERemappingConfig.new())
	GuideInputRuntime.ensure_initialized()
	_status_label.text = "Restored defaults."
	_build_tree()


func _on_input_detected(input: GUIDEInput) -> void:
	if _selected_config_item == null:
		return
	if input == null:
		_status_label.text = "Rebind cancelled."
		return
	var remapper := GuideInputRuntime.get_remapper()
	remapper.set_bound_input(_selected_config_item, input)
	GuideInputRuntime.apply_remapping_config(remapper.get_mapping_config())
	_status_label.text = "Bound \"%s\"." % _selected_config_item.display_name
	_build_tree()
