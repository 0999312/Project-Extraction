# Inventory System Design – Tetris-Style Drag & Drop Grid

> Version 0.1 – 2026-03-29

## 1. Overview

The inventory system is a **Tetris-style grid inventory** where items occupy rectangular cells defined by their `size_w × size_h`. Players can **drag and drop** items to place, move, or swap them. The system also includes a **hotbar** (quick-access slots) and a **held item** indicator.

## 2. Data Model

### 2.1 GridInventory (Pure Data)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `width` | `int` | 10 | Grid columns |
| `height` | `int` | 6 | Grid rows |
| `cells` | `Array[String]` | `[]` (size = w×h, "" = empty) | Flat array; each cell stores the `item_id` of the stack that occupies it, or `""` if empty |
| `placements` | `Array[Dictionary]` | `[]` | Each dict: `{ "item_id": String, "grid_x": int, "grid_y": int, "rotated": bool, "stack": ItemStack }` |

### 2.2 ItemStack (Unchanged)

Already defined: `item_id`, `count`, `durability`, `custom_data`.

### 2.3 ItemDefinition (Updated in Task 1)

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

The hotbar references items **already placed** in the grid. Setting a hotbar slot to an `item_id` that exists in `placements` links it. The active slot determines the **held item**.

## 5. UI Architecture

### 5.1 InventoryMenu (CanvasLayer)

- Toggled with the **Tab** key (input action `pe_inventory`).
- While open: pauses gameplay input, shows mouse cursor.
- Contains the grid panel plus the hotbar strip.

### 5.2 Grid Panel

- A `Control` node with size `width × height` cells.
- Each cell is `64 × 64` px.
- Background texture: `inventory_item.png` tiled per cell.
- When a cell is occupied, a **light white-gray overlay** (`Color(1, 1, 1, 0.18)`) is drawn on top.

### 5.3 Item Rendering

- Each placed item renders its `icon_path` texture (if set) stretched across its bounding cells.
- Items with no icon show their `display_name` as a centered label.

### 5.4 Drag & Drop

- **Pick up**: Click on an occupied cell → the placement is removed from the grid and attached to the cursor as a floating sprite.
- **Drop**: Click on an empty area in the grid → attempt `can_place`; if valid, `place_item`; if not, return to original position.
- **Swap**: If drop target overlaps exactly one other item, swap positions (if both fit).
- **Right-click rotate**: While holding an item, right-click to toggle `rotated` (swap w/h).

### 5.5 Hotbar Interaction

- The 9 hotbar slots are displayed at the bottom.
- Dragging an item onto a hotbar slot assigns it.
- Clicking a hotbar slot number key (1–9) selects the active slot.
- The active slot's item becomes the player's **held item** (`combat_state.equipped_weapon_id`).

## 6. File Manifest

| Path | Type | Purpose |
|------|------|---------|
| `scripts/game/components/gameplay/grid_inventory.gd` | Data | Cell-based grid with placements |
| `scripts/game/ui/inventory_menu.gd` | UI Script | CanvasLayer toggle + main layout |
| `scripts/game/ui/inventory_grid_panel.gd` | UI Script | Grid rendering + drag & drop |
| `scripts/game/ui/inventory_slot.gd` | UI Script | Single cell visual |
| `scenes/game_scene/inventory_menu.tscn` | Scene | Inventory menu scene |

## 7. Integration

- `DemoGameRuntime._ready()` adds an `InventoryMenu` child.
- `Player._setup_runtime_state()` populates initial items via `GridInventory.place_item()`.
- `PlayerHUD` hotbar display updates from the player's `InventoryState.hotbar_slots`.
