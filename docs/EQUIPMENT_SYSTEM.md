# Equipment System Design

## Overview

The **Equipment System** manages all wearable and equippable gear for a character. Each character has an `EquipmentState` resource that tracks which item occupies each slot. The system is designed for **easy extensibility** — new slots or equipment types can be added by appending to `SLOT_KEYS` and adding an exported property, without breaking existing save data or requiring code rewrites.

## Equipment Slots

| Slot Key | Display Name | Hotbar Mapping | Description |
|---|---|---|---|
| `primary_weapon` | Primary Weapon | Hotbar slot 0 | Main firearm (rifle, SMG, shotgun…) |
| `secondary_weapon` | Secondary Weapon | Hotbar slot 1 | Sidearm (pistol, machine pistol…) |
| `melee_weapon` | Melee Weapon | Hotbar slot 2 | Close-quarters weapon (knife, hatchet…) |
| `hotbar_usable_1` – `hotbar_usable_6` | Usable Item 1–6 | Hotbar slots 3–8 | Consumables, throwables, tools |
| `armor` | Armor | — | Body armor / plate carrier |
| `headset` | Headset | — | Hearing protection / comms |
| `helmet` | Helmet | — | Head protection |
| `backpack` | Backpack | — | Storage container (default 6×6 grid) |
| `tactical_vest` | Tactical Vest | — | Storage container (default 3×2 grid) |

### Weapon Slots → Hotbar

The first three hotbar slots are reserved for weapons:

- **Slot 0** → `primary_weapon`
- **Slot 1** → `secondary_weapon`
- **Slot 2** → `melee_weapon`

`EquipmentState.sync_weapons_to_hotbar(grid)` copies the equipped weapon item IDs into `GridInventory.hotbar_slots[0..2]`.

### Container Slots

Equipment pieces that provide storage (`backpack`, `tactical_vest`) each own their own `GridInventory` instance. These are registered via `EquipmentState.set_container_grid(slot_key, grid)` and queried with `get_container_grid(slot_key)`.

Default container capacities:

| Container | Grid Size |
|---|---|
| Backpack | 6 × 6 (36 cells) |
| Tactical Vest | 3 × 2 (6 cells) |

## Data Model

### EquipmentState (Resource)

```
class_name EquipmentState
extends Resource

SLOT_KEYS: PackedStringArray          # all valid slot key names
slots: Dictionary                     # slot_key → item_id (or "")
container_grids: Dictionary           # slot_key → GridInventory (containers only)

signal equipment_changed(slot_key)

equip(slot_key, item_id)              # set an item into a slot
unequip(slot_key)                     # clear a slot (also removes container grid)
get_equipped(slot_key) → String       # read current item_id
is_slot_empty(slot_key) → bool
set_container_grid(slot_key, grid)    # attach a GridInventory to a container slot
get_container_grid(slot_key) → GridInventory
get_all_container_grids() → Array[Dictionary]
sync_weapons_to_hotbar(grid)          # push weapon IDs to hotbar slots 0-2
```

## UI Integration

The `InventoryMenu` now displays:

1. **Equipment Panel** (left side) — live slots for all gear categories (weapons, armor, headset, helmet, containers), showing the currently bound equipment item ID / display name for each slot.
2. **Container Grids** (right side) — one `InventoryGridPanel` per equipped container, dynamically generated from `EquipmentState.get_all_container_grids()` and bound to the player's active inventory resources.
3. **Hotbar** (bottom) — 9 slots, first 3 reserved for weapons.

### Equipment Slot Interaction

- Dragging an item out of an inventory grid and dropping it onto a compatible equipment slot equips that item into the slot.
- Dragging an equipped item from a non-backpack equipment slot and dropping it onto a grid cell unequips it back into a container grid.
- Dragging an equipped item from one compatible equipment slot to another moves the equipment binding between those slots.
- The currently bound backpack slot remains locked while it is the active storage source for the inventory UI, so it cannot be dragged out directly.

### Visual Style

- **Hotbar slots**: `PanelContainer` + `StyleBoxFlat`, 6 px pure-black border, 8 px corner radius, background alpha = 64. Selected slot keeps the same square footprint (56 × 56) and switches to a green fill.
- **Inventory grid cells**: `PanelContainer` + `StyleBoxFlat`, 6 px pure-black border, 0 px corner radius (no rounding), background alpha = 64.
- No texture/material assets are used for slot rendering.
- Item icon textures are rendered with **fit-by-height** scaling (maintain aspect ratio, scale to cell height, centre horizontally). Item icons are drawn above the grid and are **not clipped** by the panel mask.

### Runtime Binding

- `DemoGameRuntime` instantiates `scenes/game_scene/inventory_menu.tscn` rather than constructing the menu script directly.
- The player's `InventoryState.inventory` is used as the backpack grid, so the inventory scene, HUD, and player runtime now all point at the same data.
- `EquipmentState.sync_hotbar_to_grid(grid)` initializes the hotbar from equipment-backed slots, and `InventoryMenu` mirrors hotbar assignments back into the corresponding equipment slots.
- Hotbar slots 0–2 only accept items tagged as `weapon`, preserving the design rule that those slots are reserved for weapons.
- Equipment-slot drag/equip validation is slot-aware: weapon slots accept weapon-tagged items, while non-weapon slots wait for matching item categories when those item types are added to the registries.

## Extensibility

To add a new equipment slot:

1. Add the slot key to `EquipmentState.SLOT_KEYS`.
2. If the slot provides storage, register a `GridInventory` via `set_container_grid()`.
3. Add a placeholder in `InventoryMenu._build_equipment_panel()`.
4. (Optional) Map to a hotbar index or add custom UI interaction.

This design supports **mod extensibility**: mod authors can subclass `EquipmentState`, extend `SLOT_KEYS`, and register additional container grids without modifying core scripts.

## Key Bindings

| Action | Default Key | GUIDE Action Name |
|---|---|---|
| Open Inventory | Tab | `pe_inventory` |
| Hotbar Slot 1–9 | 1–9 | `pe_hotbar_1` – `pe_hotbar_9` |

All bindings are remappable through the GUIDE input system.

## File Manifest

| File | Role |
|---|---|
| `scripts/game/components/gameplay/equipment_state.gd` | Equipment data model |
| `scripts/game/ui/inventory_menu.gd` | Equipment + inventory UI |
| `scripts/game/ui/inventory_grid_panel.gd` | Grid rendering with fit-by-height icons |
| `scripts/game/ui/inventory_slot.gd` | Single grid cell (StyleBoxFlat, no texture) |
| `scripts/game/ui/player_hud.gd` | HUD hotbar (StyleBoxFlat, no texture) |
| `scripts/game/gameplay/demo_game_runtime.gd` | Wiring: creates EquipmentState, binds to UI |
| `scripts/game/input/player_input_context.gd` | GUIDE input action definitions |
| `resources/i18n/ui_text.en.json` | English UI strings |
| `resources/i18n/ui_text.zh.json` | Chinese UI strings |
