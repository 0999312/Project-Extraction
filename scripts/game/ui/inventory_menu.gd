class_name InventoryMenu
extends CanvasLayer
## Tetris-style inventory menu. Toggled via pe_inventory (Tab).
## While open: pauses gameplay input, shows mouse cursor.
## Generates separate grid panels per container equipment
## (backpack 6×6, tactical vest 3×2) and shows equipment slot placeholders.

const HOTBAR_SLOT_SIZE := 56
const PANEL_BG_COLOR := Color(0.05, 0.05, 0.05, 0.92)
const HOTBAR_ACTIVE_BORDER := Color(0.95, 0.85, 0.2, 1.0)
const HOTBAR_NORMAL_BORDER := Color(0.6, 0.6, 0.6, 1.0)

# ── Hotbar StyleBox constants (match HUD hotbar theme) ─────────────────────────
const HOTBAR_BG_COLOR := Color(0.0, 0.0, 0.0, 64.0 / 255.0)
const HOTBAR_SELECTED_BG_COLOR := Color(0.0, 0.0, 0.3, 64.0 / 255.0)
const HOTBAR_BORDER_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const HOTBAR_BORDER_WIDTH := 6
const HOTBAR_CORNER_RADIUS := 8

# ── Equipment placeholder slot visual constants ────────────────────────────────
const EQUIP_SLOT_SIZE := Vector2(64, 64)
const EQUIP_BG_COLOR := Color(0.08, 0.08, 0.08, 0.85)
const EQUIP_BORDER_COLOR := Color(0.5, 0.5, 0.5, 0.8)

var _is_open: bool = false
var _grid_panels: Array[InventoryGridPanel] = []
var _hotbar_container: HBoxContainer = null
var _hotbar_slots_ui: Array[Control] = []
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
	_grid = grid
	if _grid != null and not _grid.inventory_changed.is_connected(_on_inventory_changed):
		_grid.inventory_changed.connect(_on_inventory_changed)
	_refresh_hotbar_ui()

func bind_equipment(equip: EquipmentState) -> void:
	_equipment = equip
	_rebuild_equipment_grids()

func _on_inventory_changed() -> void:
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

	# Weapon row
	var weapon_row := HBoxContainer.new()
	weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_row.add_theme_constant_override("separation", 8)
	vbox.add_child(weapon_row)
	_add_equip_placeholder(weapon_row, "Primary")
	_add_equip_placeholder(weapon_row, "Secondary")
	_add_equip_placeholder(weapon_row, "Melee")

	# Gear row
	var gear_row := HBoxContainer.new()
	gear_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gear_row.add_theme_constant_override("separation", 8)
	vbox.add_child(gear_row)
	_add_equip_placeholder(gear_row, "Helmet")
	_add_equip_placeholder(gear_row, "Headset")
	_add_equip_placeholder(gear_row, "Armor")

	# Container row
	var container_row := HBoxContainer.new()
	container_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container_row.add_theme_constant_override("separation", 8)
	vbox.add_child(container_row)
	_add_equip_placeholder(container_row, "Backpack")
	_add_equip_placeholder(container_row, "Vest")

func _add_equip_placeholder(parent: Control, label_text: String) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = EQUIP_SLOT_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = EQUIP_BG_COLOR
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = EQUIP_BORDER_COLOR
	slot.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	slot.add_child(lbl)
	parent.add_child(slot)

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
				if not item_id.is_empty() and _grid != null:
					_grid.set_hotbar_slot(slot_index, item_id)
					gp._cancel_drag()
					_refresh_hotbar_ui()
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
