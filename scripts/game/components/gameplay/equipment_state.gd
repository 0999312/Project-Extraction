class_name EquipmentState
extends Resource
## Holds all equipment slots for a character.
## Designed for extensibility — new slots can be added as exported properties
## and registered in SLOT_KEYS without breaking existing saves.
##
## Slot semantics (see EQUIPMENT_SYSTEM docs):
##   primary_weapon   → hotbar slot 0  (main weapon)
##   secondary_weapon → hotbar slot 1  (sidearm)
##   melee_weapon     → hotbar slot 2  (knife / hatchet)
##   hotbar_usable_*  → hotbar slots 3-8 (consumables / throwables)
##   armor, headset, helmet → protective gear
##   backpack         → storage container (GridInventory, default 6×6)
##   tactical_vest    → storage container (GridInventory, default 3×2)

# ── Slot keys (used for iteration / serialisation) ─────────────────────────────
const SLOT_KEYS: PackedStringArray = [
	"primary_weapon",
	"secondary_weapon",
	"melee_weapon",
	"hotbar_usable_1",
	"hotbar_usable_2",
	"hotbar_usable_3",
	"hotbar_usable_4",
	"hotbar_usable_5",
	"hotbar_usable_6",
	"armor",
	"headset",
	"helmet",
	"backpack",
	"tactical_vest",
]

## Maps slot_key → item_id (or "" if empty).
@export var slots: Dictionary = {}

## Inventory grids owned by container-type equipment.
## key = slot_key ("backpack", "tactical_vest", …), value = GridInventory.
var container_grids: Dictionary = {}

signal equipment_changed(slot_key: String)

func _init() -> void:
	_ensure_slots()

func _ensure_slots() -> void:
	for key in SLOT_KEYS:
		if not slots.has(key):
			slots[key] = ""

# ── Public API ─────────────────────────────────────────────────────────────────
func equip(slot_key: String, item_id: String) -> void:
	_ensure_slots()
	slots[slot_key] = item_id
	equipment_changed.emit(slot_key)

func unequip(slot_key: String) -> void:
	_ensure_slots()
	slots[slot_key] = ""
	if container_grids.has(slot_key):
		container_grids.erase(slot_key)
	equipment_changed.emit(slot_key)

func get_equipped(slot_key: String) -> String:
	_ensure_slots()
	return slots.get(slot_key, "")

func is_slot_empty(slot_key: String) -> bool:
	return get_equipped(slot_key).is_empty()

## Register (or replace) a GridInventory for a container slot.
func set_container_grid(slot_key: String, grid: GridInventory) -> void:
	container_grids[slot_key] = grid

## Retrieve the GridInventory for a container slot, or null.
func get_container_grid(slot_key: String) -> GridInventory:
	return container_grids.get(slot_key) as GridInventory

## Convenience: collect all container grids in slot-key order.
func get_all_container_grids() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in SLOT_KEYS:
		if container_grids.has(key):
			result.append({"slot_key": key, "grid": container_grids[key]})
	return result

## Sync weapon slots → hotbar_slots[0..2] on a GridInventory.
func sync_weapons_to_hotbar(grid: GridInventory) -> void:
	if grid == null:
		return
	var weapon_keys := ["primary_weapon", "secondary_weapon", "melee_weapon"]
	for i in range(mini(weapon_keys.size(), grid.hotbar_slots.size())):
		grid.hotbar_slots[i] = get_equipped(weapon_keys[i])
