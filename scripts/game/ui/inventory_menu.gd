class_name InventoryMenu
extends CanvasLayer
## Tetris-style inventory menu. Toggled with Tab (pe_inventory).
## While open: pauses gameplay input, shows mouse cursor.

const SLOT_TEXTURE_PATH := "res://assets/game/textures/ui/inventory_item.png"
const HOTBAR_SLOT_SIZE := 56
const PANEL_BG_COLOR := Color(0.05, 0.05, 0.05, 0.92)
const HOTBAR_ACTIVE_BORDER := Color(0.95, 0.85, 0.2, 1.0)
const HOTBAR_NORMAL_BORDER := Color(0.6, 0.6, 0.6, 1.0)
const HOTBAR_OCCUPIED_OVERLAY := Color(1.0, 1.0, 1.0, 0.18)

var _is_open: bool = false
var _grid_panel: InventoryGridPanel = null
var _hotbar_container: HBoxContainer = null
var _hotbar_slots_ui: Array[Control] = []
var _grid: GridInventory = null
var _slot_texture: Texture2D = null
var _root_panel: PanelContainer = null
var _title_label: Label = null

signal inventory_toggled(is_open: bool)
signal held_item_changed(item_id: String)

func _ready() -> void:
	layer = 20
	visible = false
	_is_open = false
	if ResourceLoader.exists(SLOT_TEXTURE_PATH):
		_slot_texture = ResourceLoader.load(SLOT_TEXTURE_PATH, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
	_build_ui()

func bind_inventory(grid: GridInventory) -> void:
	_grid = grid
	if _grid_panel != null:
		_grid_panel.setup(_grid, _slot_texture)
	_refresh_hotbar_ui()
	if _grid != null and not _grid.inventory_changed.is_connected(_on_inventory_changed):
		_grid.inventory_changed.connect(_on_inventory_changed)

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
	if _grid_panel != null and _grid != null:
		_grid_panel.setup(_grid, _slot_texture)
	_refresh_hotbar_ui()
	inventory_toggled.emit(true)

func close() -> void:
	if not _is_open:
		return
	# If dragging, cancel
	if _grid_panel != null and _grid_panel.is_dragging():
		_grid_panel._cancel_drag()
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
		# Number keys 1-9 for hotbar selection
		if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_9:
			var idx := key_event.keycode - KEY_1
			if _grid != null:
				_grid.set_active_hotbar(idx)
				held_item_changed.emit(_grid.get_active_item_id())
				_refresh_hotbar_ui()
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	# Root control fills the screen
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	# Background dimmer
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	# Main VBox
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "INVENTORY"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title_label)

	# Grid panel wrapper with background
	_root_panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BG_COLOR
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.8, 0.8, 0.8, 0.7)
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_right = 8.0
	panel_style.content_margin_bottom = 8.0
	_root_panel.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(_root_panel)

	_grid_panel = InventoryGridPanel.new()
	_grid_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root_panel.add_child(_grid_panel)

	# Hotbar section
	var hotbar_label := Label.new()
	hotbar_label.text = "HOTBAR"
	hotbar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hotbar_label)

	_hotbar_container = HBoxContainer.new()
	_hotbar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_hotbar_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_hotbar_container)

	_build_hotbar_slots()

func _build_hotbar_slots() -> void:
	for child in _hotbar_container.get_children():
		child.queue_free()
	_hotbar_slots_ui.clear()
	for i in range(9):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(HOTBAR_SLOT_SIZE, HOTBAR_SLOT_SIZE)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.04, 0.04, 1.0)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = HOTBAR_NORMAL_BORDER
		slot.add_theme_stylebox_override("panel", sb)

		# Number label
		var label := Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		slot.add_child(label)

		# Slot texture if available
		if _slot_texture != null:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _slot_texture
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			tex_rect.modulate = Color(1, 1, 1, 0.3)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(tex_rect)

		# Make slot clickable for drag-drop from grid
		var slot_idx := i
		slot.gui_input.connect(func(event: InputEvent) -> void:
			_on_hotbar_slot_input(event, slot_idx)
		)
		_hotbar_container.add_child(slot)
		_hotbar_slots_ui.append(slot)

func _on_hotbar_slot_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _grid_panel != null and _grid_panel.is_dragging():
			# Assign dragged item to hotbar
			var item_id := _grid_panel.get_drag_item_id()
			if not item_id.is_empty() and _grid != null:
				_grid.set_hotbar_slot(slot_index, item_id)
				_grid_panel._cancel_drag()
				_refresh_hotbar_ui()
		elif _grid != null:
			# Select this hotbar slot
			_grid.set_active_hotbar(slot_index)
			held_item_changed.emit(_grid.get_active_item_id())
			_refresh_hotbar_ui()

func _refresh_hotbar_ui() -> void:
	if _grid == null:
		return
	for i in range(mini(_hotbar_slots_ui.size(), _grid.hotbar_slots.size())):
		var slot: PanelContainer = _hotbar_slots_ui[i]
		var sb: StyleBoxFlat = slot.get_theme_stylebox("panel") as StyleBoxFlat
		if sb == null:
			continue
		# Active indicator
		sb.border_color = HOTBAR_ACTIVE_BORDER if i == _grid.active_hotbar_index else HOTBAR_NORMAL_BORDER
		# Occupied overlay
		var item_id: String = _grid.hotbar_slots[i]
		if not item_id.is_empty():
			sb.bg_color = Color(0.15, 0.15, 0.15, 1.0)
		else:
			sb.bg_color = Color(0.04, 0.04, 0.04, 1.0)
