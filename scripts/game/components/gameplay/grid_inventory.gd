class_name GridInventory
extends Resource

## Grid dimensions
@export var width: int = 10
@export var height: int = 6

## Flat cell array (size = width * height). Each cell stores the item_id of
## the stack that occupies it, or "" if empty.
@export var cells: Array[String] = []

## Placement records – each dict:
## { "item_id": String, "grid_x": int, "grid_y": int,
##   "rotated": bool, "stack": ItemStack }
@export var placements: Array[Dictionary] = []

## Hotbar slots (size = 9). Each entry is an item_id reference or "".
@export var hotbar_slots: Array[String] = ["", "", "", "", "", "", "", "", ""]

## Currently selected hotbar slot (0-8).
@export var active_hotbar_index: int = 0

# ── Signals ────────────────────────────────────────────────────────────────────
signal inventory_changed

func _init(w: int = 10, h: int = 6) -> void:
	width = maxi(1, w)
	height = maxi(1, h)
	_ensure_cells()

func _ensure_cells() -> void:
	var expected := width * height
	if cells.size() != expected:
		cells.resize(expected)
		for i in range(expected):
			if cells[i] == null:
				cells[i] = ""

# ── Cell helpers ───────────────────────────────────────────────────────────────
func _cell_index(gx: int, gy: int) -> int:
	return gy * width + gx

func _is_in_bounds(gx: int, gy: int) -> bool:
	return gx >= 0 and gy >= 0 and gx < width and gy < height

func _get_item_size(item_id: String, rotated: bool) -> Vector2i:
	var def := ItemCatalog.get_item_definition(item_id)
	if def == null:
		return Vector2i(1, 1)
	var w := def.size_w
	var h := def.size_h
	return Vector2i(h, w) if rotated else Vector2i(w, h)

# ── Core operations ────────────────────────────────────────────────────────────
func can_place(item_id: String, gx: int, gy: int, rotated: bool = false) -> bool:
	_ensure_cells()
	var size := _get_item_size(item_id, rotated)
	if gx < 0 or gy < 0 or gx + size.x > width or gy + size.y > height:
		return false
	for cy in range(gy, gy + size.y):
		for cx in range(gx, gx + size.x):
			if cells[_cell_index(cx, cy)] != "":
				return false
	return true

func place_item(stack: ItemStack, gx: int, gy: int, rotated: bool = false) -> bool:
	if stack == null:
		return false
	_ensure_cells()
	if not can_place(stack.item_id, gx, gy, rotated):
		return false
	var size := _get_item_size(stack.item_id, rotated)
	for cy in range(gy, gy + size.y):
		for cx in range(gx, gx + size.x):
			cells[_cell_index(cx, cy)] = stack.item_id
	placements.append({
		"item_id": stack.item_id,
		"grid_x": gx,
		"grid_y": gy,
		"rotated": rotated,
		"stack": stack,
	})
	inventory_changed.emit()
	return true

func remove_item(gx: int, gy: int) -> Dictionary:
	_ensure_cells()
	var placement := get_placement_at(gx, gy)
	if placement.is_empty():
		return {}
	var size := _get_item_size(placement["item_id"], placement.get("rotated", false))
	var px: int = placement["grid_x"]
	var py: int = placement["grid_y"]
	for cy in range(py, py + size.y):
		for cx in range(px, px + size.x):
			if _is_in_bounds(cx, cy):
				cells[_cell_index(cx, cy)] = ""
	placements.erase(placement)
	# Clean up hotbar references
	for i in range(hotbar_slots.size()):
		if hotbar_slots[i] == placement["item_id"]:
			# Check if item is still placed elsewhere
			var still_present := false
			for p in placements:
				if p["item_id"] == placement["item_id"]:
					still_present = true
					break
			if not still_present:
				hotbar_slots[i] = ""
	inventory_changed.emit()
	return placement

func get_placement_at(gx: int, gy: int) -> Dictionary:
	_ensure_cells()
	if not _is_in_bounds(gx, gy):
		return {}
	var cell_id := cells[_cell_index(gx, gy)]
	if cell_id.is_empty():
		return {}
	for p in placements:
		var size := _get_item_size(p["item_id"], p.get("rotated", false))
		var px: int = p["grid_x"]
		var py: int = p["grid_y"]
		if gx >= px and gx < px + size.x and gy >= py and gy < py + size.y:
			return p
	return {}

func find_first_fit(item_id: String, rotated: bool = false) -> Vector2i:
	for gy in range(height):
		for gx in range(width):
			if can_place(item_id, gx, gy, rotated):
				return Vector2i(gx, gy)
	return Vector2i(-1, -1)

func auto_place(stack: ItemStack) -> bool:
	if stack == null:
		return false
	var pos := find_first_fit(stack.item_id, false)
	if pos.x >= 0:
		return place_item(stack, pos.x, pos.y, false)
	# Try rotated
	pos = find_first_fit(stack.item_id, true)
	if pos.x >= 0:
		return place_item(stack, pos.x, pos.y, true)
	return false

# ── Hotbar ─────────────────────────────────────────────────────────────────────
func set_hotbar_slot(index: int, item_id: String) -> void:
	if index < 0 or index >= hotbar_slots.size():
		return
	hotbar_slots[index] = item_id
	inventory_changed.emit()

func get_active_item_id() -> String:
	if active_hotbar_index < 0 or active_hotbar_index >= hotbar_slots.size():
		return ""
	return hotbar_slots[active_hotbar_index]

func set_active_hotbar(index: int) -> void:
	active_hotbar_index = clampi(index, 0, hotbar_slots.size() - 1)
	inventory_changed.emit()

# ── Weight ─────────────────────────────────────────────────────────────────────
func compute_total_weight() -> float:
	var total := 0.0
	for p in placements:
		var stack: ItemStack = p.get("stack")
		if stack == null:
			continue
		var def := ItemCatalog.get_item_definition(stack.item_id)
		if def == null:
			continue
		total += def.weight * float(maxi(1, stack.count))
	return total

# ── Legacy compat helpers ──────────────────────────────────────────────────────
func add_stack(stack: ItemStack) -> void:
	auto_place(stack)

func remove_stack_at(index: int) -> void:
	if index < 0 or index >= placements.size():
		return
	var p := placements[index]
	remove_item(p["grid_x"], p["grid_y"])

var stacks: Array[ItemStack]:
	get:
		var arr: Array[ItemStack] = []
		for p in placements:
			if p.get("stack") is ItemStack:
				arr.append(p["stack"])
		return arr

