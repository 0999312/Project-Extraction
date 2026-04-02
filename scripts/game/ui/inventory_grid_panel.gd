class_name InventoryGridPanel
extends Control
## Renders the Tetris-style grid and handles drag & drop of items.

const CELL_SIZE := 64
const GRID_LINE_COLOR := Color(0.3, 0.3, 0.3, 0.6)
const HOVER_VALID_COLOR := Color(0.2, 0.8, 0.2, 0.25)
const HOVER_INVALID_COLOR := Color(0.8, 0.2, 0.2, 0.25)
const ITEM_BG_COLOR := Color(0.45, 0.55, 0.65, 0.5)

# ── Rarity background tints ───────────────────────────────────────────────────
const RARITY_COLOR_COMMON    := Color(0.45, 0.55, 0.65, 0.5)   # same as default
const RARITY_COLOR_UNCOMMON  := Color(0.25, 0.65, 0.30, 0.50)  # green tint
const RARITY_COLOR_RARE      := Color(0.25, 0.45, 0.80, 0.50)  # blue tint
const RARITY_COLOR_EPIC      := Color(0.55, 0.25, 0.75, 0.50)  # purple tint
const RARITY_COLOR_LEGENDARY := Color(0.85, 0.65, 0.15, 0.55)  # gold tint

var _grid: GridInventory = null
var _slots: Array[InventorySlot] = []
var _external_drop_handler: Callable = Callable()

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

func setup(grid: GridInventory, _slot_tex: Texture2D = null) -> void:
	_grid = grid
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
			if _external_drop_handler.is_valid() and _external_drop_handler.call(mb.position):
				accept_event()
				return
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
	# Attempt to merge into an existing stack of the same item
	if _try_merge_stack(stack, gx, gy):
		item_dropped.emit(stack.item_id, gx, gy, false)
		_clear_drag()
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

## Try to merge the dragged stack into an existing placement at (gx, gy).
## Returns true if the merge was performed (full or partial).
func _try_merge_stack(stack: ItemStack, gx: int, gy: int) -> bool:
	if _grid == null or stack == null:
		return false
	var target := _grid.get_placement_at(gx, gy)
	if target.is_empty():
		return false
	if target.get("item_id", "") != stack.item_id:
		return false
	var target_stack: ItemStack = target.get("stack")
	if target_stack == null:
		return false
	var def := ItemCatalog.get_item_definition(stack.item_id)
	if def == null or def.max_stack <= 1:
		return false
	var space := def.max_stack - target_stack.count
	if space <= 0:
		return false
	var transfer := mini(stack.count, space)
	target_stack.count += transfer
	stack.count -= transfer
	if stack.count <= 0:
		# Fully merged
		_grid.inventory_changed.emit()
		return true
	# Partial merge — remaining count stays in the drag
	_grid.inventory_changed.emit()
	return false

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

func get_grid() -> GridInventory:
	return _grid

func set_external_drop_handler(handler: Callable) -> void:
	_external_drop_handler = handler

func commit_drag() -> void:
	if not _dragging:
		return
	_clear_drag()

func get_drag_item_id() -> String:
	if _drag_placement.is_empty():
		return ""
	return str(_drag_placement.get("item_id", ""))

func try_place_external_stack(stack: ItemStack, local_pos: Vector2, rotated: bool = false) -> bool:
	if _grid == null or stack == null:
		return false
	var gx := int(local_pos.x) / CELL_SIZE
	var gy := int(local_pos.y) / CELL_SIZE
	if not _grid._is_in_bounds(gx, gy):
		return false
	if not _grid.can_place(stack.item_id, gx, gy, rotated):
		return false
	return _grid.place_item(stack, gx, gy, rotated)

func _draw() -> void:
	if _grid == null:
		return
	# Draw grid lines first (below items)
	for gx in range(_grid.width + 1):
		draw_line(Vector2(gx * CELL_SIZE, 0), Vector2(gx * CELL_SIZE, _grid.height * CELL_SIZE), GRID_LINE_COLOR)
	for gy in range(_grid.height + 1):
		draw_line(Vector2(0, gy * CELL_SIZE), Vector2(_grid.width * CELL_SIZE, gy * CELL_SIZE), GRID_LINE_COLOR)
	# Draw placed items on top of grid lines
	for p in _grid.placements:
		_draw_placement(p)
	# Draw drag preview on top of everything
	if _dragging and not _drag_placement.is_empty():
		_draw_drag_preview()

## Compute a destination rect that fits the texture inside the cell rect while
## maintaining aspect ratio. Scales down if texture exceeds the cell; centres
## both axes.  This replaces the old fit-by-height approach so item icons never
## overflow their slot boundaries.
static func _fit_inside_rect(tex: Texture2D, cell_rect: Rect2) -> Rect2:
	var tex_size := tex.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return cell_rect
	var scale_factor := minf(cell_rect.size.x / tex_size.x, cell_rect.size.y / tex_size.y)
	var draw_w := tex_size.x * scale_factor
	var draw_h := tex_size.y * scale_factor
	var offset_x := (cell_rect.size.x - draw_w) * 0.5
	var offset_y := (cell_rect.size.y - draw_h) * 0.5
	return Rect2(cell_rect.position + Vector2(offset_x, offset_y), Vector2(draw_w, draw_h))

func _draw_placement(p: Dictionary) -> void:
	var item_id: String = p.get("item_id", "")
	var gx: int = p.get("grid_x", 0)
	var gy: int = p.get("grid_y", 0)
	var rotated: bool = p.get("rotated", false)
	var stack: ItemStack = p.get("stack")
	var bg_color := _get_rarity_bg_color(item_id)

	# Draw per-cell background for pattern-aware rendering
	var item_cells := _grid._get_item_cells(item_id, rotated)
	for offset in item_cells:
		var cell_rect := Rect2(Vector2((gx + offset.x) * CELL_SIZE, (gy + offset.y) * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(cell_rect, bg_color)

	# Bounding rect for icon and text rendering
	var sz := _grid._get_item_size(item_id, rotated)
	var rect := Rect2(Vector2(gx * CELL_SIZE, gy * CELL_SIZE), Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE))

	var def := ItemCatalog.get_item_definition(item_id)
	if def != null and not def.icon_path.is_empty() and ResourceLoader.exists(def.icon_path):
		var tex := ResourceLoader.load(def.icon_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			var icon_rect := _fit_inside_rect(tex, rect)
			draw_texture_rect(tex, icon_rect, false)
			_draw_stack_count(stack, rect)
			return
	# Fallback: draw name label
	if def != null:
		var font := ThemeDB.fallback_font
		var font_size := ThemeDB.fallback_font_size
		if font != null:
			draw_string(font, rect.position + Vector2(4, font_size + 2), def.display_name, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8, font_size, Color.WHITE)
	_draw_stack_count(stack, rect)

## Draw stack count in the bottom-right corner of the item rect (only if count > 1).
func _draw_stack_count(stack: ItemStack, rect: Rect2) -> void:
	if stack == null or stack.count <= 1:
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var font_size := 12
	var count_text := str(stack.count)
	var text_pos := rect.position + rect.size - Vector2(4, 4)
	# Draw shadow for readability
	draw_string(font, text_pos + Vector2(-1, 1), count_text, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 8, font_size, Color(0, 0, 0, 0.7))
	draw_string(font, text_pos, count_text, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 8, font_size, Color.WHITE)

## Return a background colour based on item rarity. Falls back to ITEM_BG_COLOR
## when no rarity is defined.
static func _get_rarity_bg_color(item_id: String) -> Color:
	var def := ItemCatalog.get_item_definition(item_id)
	if def == null:
		return ITEM_BG_COLOR
	match def.rarity:
		1: return RARITY_COLOR_COMMON
		2: return RARITY_COLOR_UNCOMMON
		3: return RARITY_COLOR_RARE
		4: return RARITY_COLOR_EPIC
		5: return RARITY_COLOR_LEGENDARY
		_: return ITEM_BG_COLOR

func _draw_drag_preview() -> void:
	var mouse_pos := get_local_mouse_position()
	var item_id: String = _drag_placement.get("item_id", "")
	var sz := _grid._get_item_size(item_id, _drag_rotated)
	# Snap to grid cell
	var gx := clampi(int(mouse_pos.x) / CELL_SIZE, 0, _grid.width - 1)
	var gy := clampi(int(mouse_pos.y) / CELL_SIZE, 0, _grid.height - 1)
	var valid := _grid.can_place(item_id, gx, gy, _drag_rotated)
	var color := HOVER_VALID_COLOR if valid else HOVER_INVALID_COLOR
	# Draw per-cell highlight for pattern-aware preview
	var item_cells := _grid._get_item_cells(item_id, _drag_rotated)
	for offset in item_cells:
		var cell_rect := Rect2(Vector2((gx + offset.x) * CELL_SIZE, (gy + offset.y) * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(cell_rect, color)
	# Draw item icon on cursor (fit by bounding rect, not affected by mask)
	var rect := Rect2(Vector2(gx * CELL_SIZE, gy * CELL_SIZE), Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE))
	var def := ItemCatalog.get_item_definition(item_id)
	if def != null and not def.icon_path.is_empty() and ResourceLoader.exists(def.icon_path):
		var tex := ResourceLoader.load(def.icon_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			var icon_rect := _fit_inside_rect(tex, rect)
			draw_texture_rect(tex, icon_rect, false, Color(1, 1, 1, 0.7))
