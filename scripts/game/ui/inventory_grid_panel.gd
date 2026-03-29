class_name InventoryGridPanel
extends Control
## Renders the Tetris-style grid and handles drag & drop of items.

const CELL_SIZE := 64
const GRID_LINE_COLOR := Color(0.3, 0.3, 0.3, 0.6)
const HOVER_VALID_COLOR := Color(0.2, 0.8, 0.2, 0.25)
const HOVER_INVALID_COLOR := Color(0.8, 0.2, 0.2, 0.25)
const ITEM_BG_COLOR := Color(0.45, 0.55, 0.65, 0.5)

var _grid: GridInventory = null
var _slot_texture: Texture2D = null
var _slots: Array[InventorySlot] = []

# Drag state
var _dragging: bool = false
var _drag_placement: Dictionary = {}
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_rotated: bool = false
var _drag_origin_gx: int = -1
var _drag_origin_gy: int = -1

signal item_dropped(item_id: String, grid_x: int, grid_y: int, rotated: bool)
signal item_picked_up(placement: Dictionary)
signal hotbar_assign_requested(item_id: String, slot_index: int)

func setup(grid: GridInventory, slot_tex: Texture2D) -> void:
	_grid = grid
	_slot_texture = slot_tex
	_rebuild_slots()
	if _grid != null and not _grid.inventory_changed.is_connected(_on_inventory_changed):
		_grid.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed() -> void:
	_refresh_slot_states()
	queue_redraw()

func _rebuild_slots() -> void:
	for child in get_children():
		child.queue_free()
	_slots.clear()
	if _grid == null:
		return
	custom_minimum_size = Vector2(_grid.width * CELL_SIZE, _grid.height * CELL_SIZE)
	size = custom_minimum_size
	for gy in range(_grid.height):
		for gx in range(_grid.width):
			var slot := InventorySlot.new(gx, gy)
			slot.setup(_slot_texture)
			slot.position = Vector2(gx * CELL_SIZE, gy * CELL_SIZE)
			slot.size = Vector2(CELL_SIZE, CELL_SIZE)
			add_child(slot)
			_slots.append(slot)
	_refresh_slot_states()

func _refresh_slot_states() -> void:
	if _grid == null:
		return
	_grid._ensure_cells()
	for slot in _slots:
		var idx := slot.grid_y * _grid.width + slot.grid_x
		slot.set_occupied(idx < _grid.cells.size() and _grid.cells[idx] != "")

func _gui_input(event: InputEvent) -> void:
	if _grid == null:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_left_click(mb.position)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and _dragging:
			_drag_rotated = not _drag_rotated
			queue_redraw()
			accept_event()
	if event is InputEventMouseMotion and _dragging:
		queue_redraw()

func _handle_left_click(pos: Vector2) -> void:
	var gx := int(pos.x) / CELL_SIZE
	var gy := int(pos.y) / CELL_SIZE
	if _dragging:
		_try_drop(gx, gy)
	else:
		_try_pickup(gx, gy, pos)

func _try_pickup(gx: int, gy: int, mouse_pos: Vector2) -> void:
	if _grid == null:
		return
	var placement := _grid.get_placement_at(gx, gy)
	if placement.is_empty():
		return
	_drag_origin_gx = placement["grid_x"]
	_drag_origin_gy = placement["grid_y"]
	_drag_rotated = placement.get("rotated", false)
	_drag_placement = _grid.remove_item(gx, gy)
	_drag_offset = mouse_pos - Vector2(_drag_origin_gx * CELL_SIZE, _drag_origin_gy * CELL_SIZE)
	_dragging = true
	item_picked_up.emit(_drag_placement)
	queue_redraw()

func _try_drop(gx: int, gy: int) -> void:
	if _grid == null or _drag_placement.is_empty():
		return
	var stack: ItemStack = _drag_placement.get("stack")
	if stack == null:
		_cancel_drag()
		return
	if _grid.can_place(stack.item_id, gx, gy, _drag_rotated):
		_grid.place_item(stack, gx, gy, _drag_rotated)
		item_dropped.emit(stack.item_id, gx, gy, _drag_rotated)
		_clear_drag()
	else:
		# Try returning to original position
		if _grid.can_place(stack.item_id, _drag_origin_gx, _drag_origin_gy, _drag_placement.get("rotated", false)):
			_grid.place_item(stack, _drag_origin_gx, _drag_origin_gy, _drag_placement.get("rotated", false))
		else:
			_grid.auto_place(stack)
		_clear_drag()

func _cancel_drag() -> void:
	if _drag_placement.is_empty():
		return
	var stack: ItemStack = _drag_placement.get("stack")
	if stack != null and _grid != null:
		if _grid.can_place(stack.item_id, _drag_origin_gx, _drag_origin_gy, _drag_placement.get("rotated", false)):
			_grid.place_item(stack, _drag_origin_gx, _drag_origin_gy, _drag_placement.get("rotated", false))
		else:
			_grid.auto_place(stack)
	_clear_drag()

func _clear_drag() -> void:
	_dragging = false
	_drag_placement = {}
	_drag_offset = Vector2.ZERO
	_drag_rotated = false
	_drag_origin_gx = -1
	_drag_origin_gy = -1
	queue_redraw()

func is_dragging() -> bool:
	return _dragging

func get_drag_item_id() -> String:
	if _drag_placement.is_empty():
		return ""
	return str(_drag_placement.get("item_id", ""))

func _draw() -> void:
	if _grid == null:
		return
	# Draw placed items
	for p in _grid.placements:
		_draw_placement(p)
	# Draw grid lines
	for gx in range(_grid.width + 1):
		draw_line(Vector2(gx * CELL_SIZE, 0), Vector2(gx * CELL_SIZE, _grid.height * CELL_SIZE), GRID_LINE_COLOR)
	for gy in range(_grid.height + 1):
		draw_line(Vector2(0, gy * CELL_SIZE), Vector2(_grid.width * CELL_SIZE, gy * CELL_SIZE), GRID_LINE_COLOR)
	# Draw drag preview
	if _dragging and not _drag_placement.is_empty():
		_draw_drag_preview()

## Compute a destination rect that fits the texture by height while maintaining
## aspect ratio, centred horizontally inside the cell rect.
static func _fit_by_height_rect(tex: Texture2D, cell_rect: Rect2) -> Rect2:
	var tex_size := tex.get_size()
	if tex_size.y <= 0:
		return cell_rect
	var scale_factor := cell_rect.size.y / tex_size.y
	var draw_w := tex_size.x * scale_factor
	var draw_h := cell_rect.size.y
	var offset_x := (cell_rect.size.x - draw_w) * 0.5
	return Rect2(cell_rect.position + Vector2(offset_x, 0), Vector2(draw_w, draw_h))

func _draw_placement(p: Dictionary) -> void:
	var item_id: String = p.get("item_id", "")
	var gx: int = p.get("grid_x", 0)
	var gy: int = p.get("grid_y", 0)
	var rotated: bool = p.get("rotated", false)
	var sz := _grid._get_item_size(item_id, rotated)
	var rect := Rect2(Vector2(gx * CELL_SIZE, gy * CELL_SIZE), Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE))
	draw_rect(rect, ITEM_BG_COLOR)
	var def := ItemCatalog.get_item_definition(item_id)
	if def != null and not def.icon_path.is_empty() and ResourceLoader.exists(def.icon_path):
		var tex := ResourceLoader.load(def.icon_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			var icon_rect := _fit_by_height_rect(tex, rect)
			draw_texture_rect(tex, icon_rect, false)
			return
	# Fallback: draw name label
	if def != null:
		var font := ThemeDB.fallback_font
		var font_size := ThemeDB.fallback_font_size
		if font != null:
			draw_string(font, rect.position + Vector2(4, font_size + 2), def.display_name, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8, font_size, Color.WHITE)

func _draw_drag_preview() -> void:
	var mouse_pos := get_local_mouse_position()
	var item_id: String = _drag_placement.get("item_id", "")
	var sz := _grid._get_item_size(item_id, _drag_rotated)
	# Snap to grid cell
	var gx := clampi(int(mouse_pos.x) / CELL_SIZE, 0, _grid.width - 1)
	var gy := clampi(int(mouse_pos.y) / CELL_SIZE, 0, _grid.height - 1)
	var valid := _grid.can_place(item_id, gx, gy, _drag_rotated)
	var color := HOVER_VALID_COLOR if valid else HOVER_INVALID_COLOR
	var rect := Rect2(Vector2(gx * CELL_SIZE, gy * CELL_SIZE), Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE))
	draw_rect(rect, color)
	# Draw item icon on cursor (fit by height, not affected by mask)
	var def := ItemCatalog.get_item_definition(item_id)
	if def != null and not def.icon_path.is_empty() and ResourceLoader.exists(def.icon_path):
		var tex := ResourceLoader.load(def.icon_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			var icon_rect := _fit_by_height_rect(tex, rect)
			draw_texture_rect(tex, icon_rect, false, Color(1, 1, 1, 0.7))
