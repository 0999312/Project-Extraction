class_name InventoryMenu
extends CanvasLayer
## Tetris-style inventory menu. Toggled via pe_inventory (Tab).
## While open: pauses gameplay input, shows mouse cursor.
## Generates separate grid panels per container equipment
## (backpack 6×6, tactical vest 3×2) and mirrors equipment slot state.

const HOTBAR_SLOT_SIZE := 56
const PANEL_BG_COLOR := Color(0.05, 0.05, 0.05, 0.92)

# ── Hotbar StyleBox constants (match HUD hotbar theme) ─────────────────────────
const HOTBAR_BG_COLOR := Color(0.0, 0.0, 0.0, 64.0 / 255.0)
const HOTBAR_SELECTED_BG_COLOR := Color(0.0, 1.0, 0.0, 64.0 / 255.0)
const HOTBAR_BORDER_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const HOTBAR_BORDER_WIDTH := 6
const HOTBAR_CORNER_RADIUS := 8

# ── Equipment placeholder slot visual constants ────────────────────────────────
const EQUIP_SLOT_SIZE := Vector2(64, 64)
const EQUIP_BG_COLOR := Color(0.08, 0.08, 0.08, 0.85)
const EQUIP_BORDER_COLOR := Color(0.5, 0.5, 0.5, 0.8)
const EQUIP_BORDER_COLOR_ACTIVE := Color(0.3, 0.85, 0.3, 0.9)
const EQUIP_EMPTY_TEXT := "Empty"
const EQUIPMENT_LAYOUT := [
	[
		{"slot_key": "primary_weapon", "label": "Primary"},
		{"slot_key": "secondary_weapon", "label": "Secondary"},
		{"slot_key": "melee_weapon", "label": "Melee"},
	],
	[
		{"slot_key": "helmet", "label": "Helmet"},
		{"slot_key": "headset", "label": "Headset"},
		{"slot_key": "armor", "label": "Armor"},
	],
	[
		{"slot_key": "backpack", "label": "Backpack"},
		{"slot_key": "tactical_vest", "label": "Vest"},
	],
]

var _is_open: bool = false
var _grid_panels: Array[InventoryGridPanel] = []
var _hotbar_container: HBoxContainer = null
var _hotbar_slots_ui: Array[Control] = []
var _equipment_slots_ui: Dictionary = {}
var _grid: GridInventory = null
var _equipment: EquipmentState = null
var _root_panel: PanelContainer = null
var _title_label: Label = null
var _grids_vbox: VBoxContainer = null

signal inventory_toggled(is_open: bool)
signal held_item_changed(item_id: String)

func _ready() -> void:
	layer = 20
	visible = false
	_is_open = false
	_build_ui()

func bind_inventory(grid: GridInventory) -> void:
	if _grid != null and _grid.inventory_changed.is_connected(_on_inventory_changed):
		_grid.inventory_changed.disconnect(_on_inventory_changed)
	_grid = grid
	if _grid != null and not _grid.inventory_changed.is_connected(_on_inventory_changed):
		_grid.inventory_changed.connect(_on_inventory_changed)
	_sync_equipment_from_hotbar()
	_refresh_hotbar_ui()
	_refresh_equipment_panel()

func bind_equipment(equip: EquipmentState) -> void:
	if _equipment != null and _equipment.equipment_changed.is_connected(_on_equipment_changed):
		_equipment.equipment_changed.disconnect(_on_equipment_changed)
	_equipment = equip
	if _equipment != null and not _equipment.equipment_changed.is_connected(_on_equipment_changed):
		_equipment.equipment_changed.connect(_on_equipment_changed)
	_sync_equipment_from_hotbar()
	_refresh_equipment_panel()
	_rebuild_equipment_grids()

func _on_inventory_changed() -> void:
	_sync_equipment_from_hotbar()
	_refresh_hotbar_ui()
	_refresh_equipment_panel()

func _on_equipment_changed(_slot_key: String) -> void:
	_refresh_equipment_panel()
	_rebuild_equipment_grids()
	_refresh_hotbar_ui()

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_rebuild_equipment_grids()
	_refresh_hotbar_ui()
	inventory_toggled.emit(true)

func close() -> void:
	if not _is_open:
		return
	for gp in _grid_panels:
		if gp != null and gp.is_dragging():
			gp._cancel_drag()
	_is_open = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	inventory_toggled.emit(false)

func is_open() -> bool:
	return _is_open

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_9:
			var idx := key_event.keycode - KEY_1
			if _grid != null:
				_grid.set_active_hotbar(idx)
				held_item_changed.emit(_grid.get_active_item_id())
				_refresh_hotbar_ui()
			get_viewport().set_input_as_handled()

# ── UI construction ────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# ScrollContainer so content can exceed viewport
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	# Main horizontal layout: equipment panel | inventory grids
	var hbox_main := HBoxContainer.new()
	hbox_main.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_main.add_theme_constant_override("separation", 16)
	center.add_child(hbox_main)

	# Left side: equipment slots
	_build_equipment_panel(hbox_main)

	# Right side: inventory grids + hotbar
	var vbox_right := VBoxContainer.new()
	vbox_right.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_right.add_theme_constant_override("separation", 12)
	hbox_main.add_child(vbox_right)

	_title_label = Label.new()
	_title_label.text = "INVENTORY"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	vbox_right.add_child(_title_label)

	# Container for dynamically generated grid panels
	_grids_vbox = VBoxContainer.new()
	_grids_vbox.add_theme_constant_override("separation", 12)
	vbox_right.add_child(_grids_vbox)

	# Hotbar section
	var hotbar_label := Label.new()
	hotbar_label.text = "HOTBAR"
	hotbar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_right.add_child(hotbar_label)

	_hotbar_container = HBoxContainer.new()
	_hotbar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_hotbar_container.add_theme_constant_override("separation", 4)
	vbox_right.add_child(_hotbar_container)

	_build_hotbar_slots()

# ── Equipment panel (left side) ────────────────────────────────────────────────
func _build_equipment_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = PANEL_BG_COLOR
	ps.border_width_left = 2
	ps.border_width_top = 2
	ps.border_width_right = 2
	ps.border_width_bottom = 2
	ps.border_color = Color(0.8, 0.8, 0.8, 0.7)
	ps.content_margin_left = 12.0
	ps.content_margin_top = 12.0
	ps.content_margin_right = 12.0
	ps.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", ps)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var equip_title := Label.new()
	equip_title.text = "EQUIPMENT"
	equip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(equip_title)

	for row_entries in EQUIPMENT_LAYOUT:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		for entry in row_entries:
			_add_equip_slot(row, entry["slot_key"], entry["label"])
	_refresh_equipment_panel()

func _add_equip_slot(parent: Control, slot_key: String, label_text: String) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = EQUIP_SLOT_SIZE
	slot.add_theme_stylebox_override("panel", _make_equip_stylebox(false))

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(vbox)

	var title_label := Label.new()
	title_label.text = label_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	vbox.add_child(title_label)

	var item_label := Label.new()
	item_label.text = EQUIP_EMPTY_TEXT
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_label.add_theme_font_size_override("font_size", 9)
	item_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	vbox.add_child(item_label)
	parent.add_child(slot)
	_equipment_slots_ui[slot_key] = {
		"panel": slot,
		"title": title_label,
		"value": item_label,
		"label": label_text,
	}

static func _make_equip_stylebox(is_filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = EQUIP_BG_COLOR
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = EQUIP_BORDER_COLOR_ACTIVE if is_filled else EQUIP_BORDER_COLOR
	return sb

func _refresh_equipment_panel() -> void:
	for row_entries in EQUIPMENT_LAYOUT:
		for entry in row_entries:
			var slot_key := str(entry["slot_key"])
			var refs: Dictionary = _equipment_slots_ui.get(slot_key, {})
			if refs.is_empty():
				continue
			var item_id := ""
			if _equipment != null:
				item_id = _equipment.get_equipped(slot_key)
			var item_label := refs.get("value") as Label
			if item_label != null:
				var has_item := not item_id.is_empty()
				item_label.text = _get_item_display_name(item_id) if has_item else EQUIP_EMPTY_TEXT
				item_label.add_theme_color_override("font_color", Color.WHITE if has_item else Color(0.75, 0.75, 0.75, 1.0))
			var panel := refs.get("panel") as PanelContainer
			if panel != null:
				panel.add_theme_stylebox_override("panel", _make_equip_stylebox(not item_id.is_empty()))
				panel.tooltip_text = "%s: %s" % [refs.get("label", slot_key), item_id if not item_id.is_empty() else EQUIP_EMPTY_TEXT]

func _get_item_display_name(item_id: String) -> String:
	if item_id.is_empty():
		return EQUIP_EMPTY_TEXT
	var item_def := ItemCatalog.get_item_definition(item_id)
	if item_def != null and not item_def.display_name.is_empty():
		return item_def.display_name
	var fallback := item_id.get_file()
	if fallback.is_empty():
		fallback = item_id
	if fallback.contains(":"):
		fallback = fallback.get_slice(":", 1)
	return fallback.replace("_", " ").capitalize()

# ── Equipment-based grid generation ────────────────────────────────────────────
func _rebuild_equipment_grids() -> void:
	if _grids_vbox == null:
		return
	for child in _grids_vbox.get_children():
		child.queue_free()
	_grid_panels.clear()

	if _equipment == null:
		# Fallback: show single grid from bound inventory
		if _grid != null:
			_add_grid_section("BACKPACK (default)", _grid)
		return

	var containers := _equipment.get_all_container_grids()
	for entry in containers:
		var slot_key: String = entry["slot_key"]
		var grid: GridInventory = entry["grid"]
		var display := slot_key.replace("_", " ").to_upper()
		var item_id := _equipment.get_equipped(slot_key)
		if not item_id.is_empty():
			display = "%s — %s" % [display, _get_item_display_name(item_id)]
		var dims := "%d×%d" % [grid.width, grid.height]
		_add_grid_section("%s (%s)" % [display, dims], grid)

func _add_grid_section(title: String, grid: GridInventory) -> void:
	var section_label := Label.new()
	section_label.text = title
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_label.add_theme_font_size_override("font_size", 14)
	_grids_vbox.add_child(section_label)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = PANEL_BG_COLOR
	ps.border_width_left = 2
	ps.border_width_top = 2
	ps.border_width_right = 2
	ps.border_width_bottom = 2
	ps.border_color = Color(0.8, 0.8, 0.8, 0.7)
	ps.content_margin_left = 8.0
	ps.content_margin_top = 8.0
	ps.content_margin_right = 8.0
	ps.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", ps)
	_grids_vbox.add_child(panel)

	var gp := InventoryGridPanel.new()
	gp.mouse_filter = Control.MOUSE_FILTER_STOP
	gp.clip_contents = true
	panel.add_child(gp)
	gp.setup(grid, null)
	_grid_panels.append(gp)

# ── Hotbar ─────────────────────────────────────────────────────────────────────
func _build_hotbar_slots() -> void:
	for child in _hotbar_container.get_children():
		child.queue_free()
	_hotbar_slots_ui.clear()
	for i in range(9):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(HOTBAR_SLOT_SIZE, HOTBAR_SLOT_SIZE)
		slot.add_theme_stylebox_override("panel", _make_hotbar_sb(false))

		var label := Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		slot.add_child(label)

		var slot_idx := i
		slot.gui_input.connect(func(event: InputEvent) -> void:
			_on_hotbar_slot_input(event, slot_idx)
		)
		_hotbar_container.add_child(slot)
		_hotbar_slots_ui.append(slot)

static func _make_hotbar_sb(is_selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = HOTBAR_SELECTED_BG_COLOR if is_selected else HOTBAR_BG_COLOR
	sb.border_width_left = HOTBAR_BORDER_WIDTH
	sb.border_width_top = HOTBAR_BORDER_WIDTH
	sb.border_width_right = HOTBAR_BORDER_WIDTH
	sb.border_width_bottom = HOTBAR_BORDER_WIDTH
	sb.border_color = HOTBAR_BORDER_COLOR
	sb.corner_radius_top_left = HOTBAR_CORNER_RADIUS
	sb.corner_radius_top_right = HOTBAR_CORNER_RADIUS
	sb.corner_radius_bottom_right = HOTBAR_CORNER_RADIUS
	sb.corner_radius_bottom_left = HOTBAR_CORNER_RADIUS
	return sb

func _on_hotbar_slot_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var any_dragging := false
		for gp in _grid_panels:
			if gp != null and gp.is_dragging():
				any_dragging = true
				var item_id := gp.get_drag_item_id()
				if not item_id.is_empty() and _grid != null and _can_assign_item_to_hotbar(slot_index, item_id):
					_grid.set_hotbar_slot(slot_index, item_id)
					_sync_equipment_slot_from_hotbar(slot_index)
					gp._cancel_drag()
					_refresh_hotbar_ui()
					_refresh_equipment_panel()
				break
		if not any_dragging and _grid != null:
			_grid.set_active_hotbar(slot_index)
			held_item_changed.emit(_grid.get_active_item_id())
			_refresh_hotbar_ui()

func _refresh_hotbar_ui() -> void:
	if _grid == null:
		return
	for i in range(mini(_hotbar_slots_ui.size(), _grid.hotbar_slots.size())):
		var slot: PanelContainer = _hotbar_slots_ui[i]
		var is_active := (i == _grid.active_hotbar_index)
		slot.add_theme_stylebox_override("panel", _make_hotbar_sb(is_active))
		slot.tooltip_text = "Hotbar %d: %s" % [i + 1, _get_item_display_name(_grid.hotbar_slots[i])]

func _can_assign_item_to_hotbar(slot_index: int, item_id: String) -> bool:
	if slot_index < 0 or slot_index >= 3:
		return true
	return ItemCatalog.has_tag(item_id, "weapon")

func _sync_equipment_from_hotbar() -> void:
	if _grid == null or _equipment == null:
		return
	for i in range(mini(_grid.hotbar_slots.size(), EquipmentState.HOTBAR_SLOT_KEYS.size())):
		_sync_equipment_slot_from_hotbar(i)

func _sync_equipment_slot_from_hotbar(slot_index: int) -> void:
	if _grid == null or _equipment == null:
		return
	var slot_key := EquipmentState.get_hotbar_slot_key(slot_index)
	if slot_key.is_empty():
		return
	var item_id := _grid.hotbar_slots[slot_index]
	var current_item_id := _equipment.get_equipped(slot_key)
	if item_id == current_item_id:
		return
	if item_id.is_empty():
		_equipment.unequip(slot_key)
	else:
		_equipment.equip(slot_key, item_id)
