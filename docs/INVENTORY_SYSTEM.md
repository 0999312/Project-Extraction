# Inventory System Design – Tetris-Style Drag & Drop Grid

> Version 0.2 – 2026-03-29

## 1. Overview

The inventory system is a **Tetris-style grid inventory** where items occupy rectangular cells defined by their `size_w × size_h`. Players can **drag and drop** items to place, move, or swap them. The system now generates **equipment-based grids** — each container equipment (backpack, tactical vest) owns its own grid. The system also includes a **hotbar** (quick-access slots) and a **held item** indicator.

## 2. Data Model

### 2.1 GridInventory (Pure Data)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `width` | `int` | 10 | Grid columns |
| `height` | `int` | 6 | Grid rows |
| `cells` | `Array[String]` | `[]` (size = w×h, "" = empty) | Flat array; each cell stores the `item_id` of the stack that occupies it, or `""` if empty |
| `placements` | `Array[Dictionary]` | `[]` | Each dict: `{ "item_id": String, "grid_x": int, "grid_y": int, "rotated": bool, "stack": ItemStack }` |

### 2.2 Equipment-Based Grids

The inventory menu generates **one grid per container equipment** from `EquipmentState`:

| Equipment | Slot Key | Default Grid Size |
|---|---|---|
| Backpack | `backpack` | 6 × 6 (36 cells) |
| Tactical Vest | `tactical_vest` | 3 × 2 (6 cells) |

See [EQUIPMENT_SYSTEM.md](EQUIPMENT_SYSTEM.md) for full equipment slot details.

### 2.3 ItemStack (Unchanged)

Already defined: `item_id`, `count`, `durability`, `custom_data`.

### 2.4 ItemDefinition (Updated in Task 1)

Added `icon_path` and MSF tag integration.

## 3. Core Operations

| Operation | Signature | Description |
|-----------|-----------|-------------|
| `can_place(item_id, gx, gy, rotated)` | `→ bool` | Check whether the item's bounding rectangle fits at `(gx, gy)` without overlap |
| `place_item(stack, gx, gy, rotated)` | `→ bool` | Place an `ItemStack` at `(gx, gy)`, writing cell ownership |
| `remove_item(gx, gy)` | `→ Dictionary` | Remove the placement whose bounding box covers `(gx, gy)`, returning the placement dict |
| `get_placement_at(gx, gy)` | `→ Dictionary` | Return placement info for the item at cell `(gx, gy)` or `{}` |
| `find_first_fit(item_id, rotated)` | `→ Vector2i` | Auto-find the first valid position (top-left scan) or `Vector2i(-1, -1)` |
| `compute_total_weight()` | `→ float` | Sum weight of all placements |

## 4. Hotbar

| Field | Type | Description |
|-------|------|-------------|
| `hotbar_slots` | `Array[String]` | Size = 9; each entry is an `item_id` reference from a placement, or `""` |
| `active_hotbar_index` | `int` | Currently selected slot (0–8), default 0 |

The hotbar references items **already placed** in the grid. Setting a hotbar slot to an `item_id` that exists in `placements` links it. The active slot determines the **held item**. Hotbar slots 0–2 are reserved for weapons (see Equipment System).

## 5. UI Architecture

### 5.1 InventoryMenu (CanvasLayer)

- Toggled with the **Tab** key (input action `pe_inventory`).
- While open: pauses gameplay input, shows mouse cursor.
- Contains an **equipment panel** (left), **container grids** (right), and a **hotbar strip** (bottom).

### 5.2 Equipment Panel

- Displays bound slots for all equipment categories: Primary Weapon, Secondary Weapon, Melee Weapon, Helmet, Headset, Armor, Backpack, Vest.
- Each slot mirrors the current `EquipmentState` value and shows the equipped item's display name (or a readable fallback if the item is data-only).
- Dragging an inventory item from a grid onto a compatible equipment slot equips it.
- Equipped items can be dragged back from non-backpack equipment slots into a grid cell to unequip them.

### 5.3 Grid Panels

- One `InventoryGridPanel` per equipped container, dynamically generated from `EquipmentState.get_all_container_grids()`.
- Each cell is `64 × 64` px, rendered as a `PanelContainer` + `StyleBoxFlat`.
- Cell style: **6 px pure-black border, 0 px corner radius**, background alpha = 64.
- No texture/material assets.

### 5.4 Item Rendering

- Each placed item renders its `icon_path` texture with **fit-by-height** scaling (maintain aspect ratio, scale to cell height, centre horizontally).
- Item textures are drawn via `_draw()` above the grid and are **not clipped by the inventory panel mask**.
- Items with no icon show their `display_name` as a centred label.

### 5.5 Drag & Drop

- **Pick up**: Click on an occupied cell → the placement is removed from the grid and attached to the cursor as a floating sprite.
- **Drop**: Click on an empty area in the grid → attempt `can_place`; if valid, `place_item`; if not, return to original position.
- **Swap**: If drop target overlaps exactly one other item, swap positions (if both fit).
- **Right-click rotate**: While holding an item, right-click to toggle `rotated` (swap w/h).

### 5.6 Hotbar Interaction

- The 9 hotbar slots are displayed at the bottom.
- Hotbar slot style: **6 px pure-black border, 8 px corner radius**, background alpha = 64. Selected slot keeps the same fixed square size and switches to a green fill.
- Dragging an item onto a hotbar slot assigns it.
- Hotbar slots 0–2 only accept items tagged as `weapon`, matching the equipment-system reservation for weapon slots.
- Clicking a hotbar slot number key (1–9) selects the active slot.
- When the active slot contains a registered weapon item, that item becomes the player's combat **held weapon** (`combat_state.equipped_weapon_id`).

## 6. File Manifest

| Path | Type | Purpose |
|------|------|---------|
| `scripts/game/components/gameplay/grid_inventory.gd` | Data | Cell-based grid with placements |
| `scripts/game/components/gameplay/equipment_state.gd` | Data | Equipment slots + container grids |
| `scripts/game/ui/inventory_menu.gd` | UI Script | Equipment panel + container grids + hotbar |
| `scripts/game/ui/inventory_grid_panel.gd` | UI Script | Grid rendering + drag & drop |
| `scripts/game/ui/inventory_slot.gd` | UI Script | Single cell (StyleBoxFlat, no texture) |
| `scenes/game_scene/inventory_menu.tscn` | Scene | Inventory menu scene |

## 7. Integration

- `DemoGameRuntime._ready()` instantiates `scenes/game_scene/inventory_menu.tscn`, creates an `EquipmentState` with default backpack (6×6) and tactical vest (3×2), and binds both the equipment state and the player's actual `InventoryState.inventory`.
- `PlayerHUD` hotbar display updates from the same backpack `GridInventory.hotbar_slots` used by the inventory menu.
- The equipment system is fully extensible for future container types and mod support.
