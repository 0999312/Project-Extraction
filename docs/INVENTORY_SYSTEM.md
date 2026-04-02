# Inventory System Design – Tetris-Style Drag & Drop Grid

> Version 0.4 – 2026-04-02

## 1. Overview

The inventory system is a **Tetris-style grid inventory** where items occupy cells defined by their `size_w × size_h` bounding box or by a custom **occupancy pattern** for irregular shapes. Players can **drag and drop** items to place and move them. Items can be **rotated** (right-click) to fit, and matching stacks **merge automatically** when dropped onto each other. The system generates **equipment-based grids** — each container equipment (backpack, tactical vest) owns its own grid. A **hotbar** provides quick-access slots, an **item rarity system** provides visual feedback, and a **save/load API** supports game persistence.

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

### 2.3 ItemStack

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `item_id` | `String` | `""` | Reference to ItemDefinition.id |
| `count` | `int` | 1 | Current stack size (min 1) |
| `durability` | `float` | 1.0 | Item condition (0.0 – 1.0) |
| `custom_data` | `Dictionary` | `{}` | Arbitrary extension data (enchantments, mods, etc.) |

### 2.4 ItemDefinition

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | `String` | `""` | Item resource-location key |
| `display_name` | `String` | `""` | Display name |
| `category` | `String` | `""` | Item category |
| `size_w` | `int` | 1 | Grid width (bounding box) |
| `size_h` | `int` | 1 | Grid height (bounding box) |
| `weight` | `float` | 0.0 | Unit weight |
| `max_stack` | `int` | 1 | Maximum stack count |
| `icon_path` | `String` | `""` | Path to icon texture |
| `rarity` | `int` | 0 | Rarity level (0 = none, 1–5 = common → legendary) |
| `pattern` | `Array[Vector2i]` | `[]` | Custom cell occupancy pattern (empty = filled rectangle) |

## 3. Core Operations

| Operation | Signature | Description |
|-----------|-----------|-------------|
| `can_place(item_id, gx, gy, rotated)` | `→ bool` | Check whether the item fits at `(gx, gy)` using its pattern (or bounding rect) |
| `place_item(stack, gx, gy, rotated)` | `→ bool` | Place an `ItemStack`, writing per-cell ownership |
| `remove_item(gx, gy)` | `→ Dictionary` | Remove the placement at `(gx, gy)` and return the placement dict |
| `get_placement_at(gx, gy)` | `→ Dictionary` | Return placement info for the item at cell `(gx, gy)` |
| `find_first_fit(item_id, rotated)` | `→ Vector2i` | Auto-find the first valid position (top-left scan) |
| `auto_place(stack)` | `→ bool` | Try non-rotated then rotated placement |
| `compute_total_weight()` | `→ float` | Sum weight of all placements |
| `save_to_dict()` | `→ Dictionary` | Serialize full inventory state |
| `load_from_dict(data)` | `→ void` | Restore inventory from saved data |

### 3.1 Custom Patterns

Items may define a `pattern` array of `Vector2i` offsets from the top-left origin. When empty, a filled `size_w × size_h` rectangle is used. Patterns support rotation: each offset `(x, y)` rotates 90° clockwise to `(max_y - y, x)`.

### 3.2 Stack Merging

When a dragged stack is dropped onto an existing stack of the **same item**, the counts merge up to `max_stack`. If the dragged stack is fully consumed, the drag ends. If only partially merged, the remainder stays in the drag.

## 4. Hotbar

| Field | Type | Description |
|-------|------|-------------|
| `hotbar_slots` | `Array[String]` | Size = 9; each entry is an `item_id` reference or `""` |
| `active_hotbar_index` | `int` | Currently selected slot (0–8), default 0 |

The hotbar references items **already placed** in the grid.

- **Slots 0–2** are reserved for weapons and can **only** be assigned through the equipment panel (primary/secondary/melee weapon slots). Direct grid-drag assignment to these slots is blocked.
- **Slots 3–8** accept any item and can be assigned by dragging from a grid.
- The active slot determines the **held item**.

## 5. UI Architecture

### 5.1 InventoryMenu (UIPanel — MSF Managed)

- Opened/closed via `UIManager.open_panel()` / `UIManager.back()` on `UILayer.NORMAL` (layer 100).
- Toggled with the **Tab** key (input action `pe_inventory`) in `DemoGameRuntime._poll_inventory_input()`.
- **ESC key closes inventory**: `_unhandled_input()` consumes `ui_cancel` and calls `UIManager.back(UILayer.NORMAL)`.
- While open: pauses gameplay input, shows mouse cursor.
- Contains an **equipment panel** (left), **container grids** (right), and a **hotbar strip** (bottom).
- Data (grid, equipment) is passed via `_on_open(data)` dictionary.
- Uses `CacheMode.CACHE` to preserve state between open/close cycles.

### 5.2 Equipment Panel

- Displays bound slots for all equipment categories: Primary Weapon, Secondary Weapon, Melee Weapon, Helmet, Headset, Armor, Backpack, Vest.
- Each slot mirrors the current `EquipmentState` value and shows the equipped item's display name.
- Dragging an inventory item from a grid onto a compatible equipment slot equips it.
- Equipped items can be dragged back from non-backpack equipment slots into a grid cell to unequip them.

### 5.3 Grid Panels

- One `InventoryGridPanel` per equipped container, dynamically generated from `EquipmentState.get_all_container_grids()`.
- Each cell is `64 × 64` px, rendered as a `PanelContainer` + `StyleBoxFlat`.
- Cell style: **6 px pure-black border, 0 px corner radius**, background alpha = 64.
- Grid panel uses `clip_contents = false` so item textures are not clipped by borders.

### 5.4 Item Rendering

- Grid lines are drawn first (lowest layer), then placed items (above grid lines), then drag preview (topmost).
- Each placed item renders its `icon_path` texture with **fit-inside** scaling (maintain aspect ratio, fit within bounding rect, centre both axes). Icons never overflow their slot boundaries.
- Items with custom patterns render per-cell backgrounds individually; the icon is drawn over the bounding rect.
- Items with no icon show their `display_name` as a centred label.
- Stack count (>1) is displayed in the bottom-right corner of the item rect.
- Rarity-tinted background: the item background colour varies by rarity level (common = default, uncommon = green, rare = blue, epic = purple, legendary = gold).

### 5.5 Drag & Drop

- **Pick up**: Click on an occupied cell → the placement is removed from the grid and attached to the cursor.
- **Drop on empty**: Click on an empty area → attempt `can_place`; if valid, `place_item`; if not, return to original position.
- **Drop on matching stack**: If dropping onto a stack of the same item, merge counts up to `max_stack`.
- **Invalid placement fallback**: If the drop target is invalid, the item returns to its original position when possible; otherwise `auto_place` finds the first valid slot.
- **Right-click rotate**: While holding an item, right-click toggles `rotated` (swap w/h or rotate pattern 90° clockwise).
- **Pattern preview**: Drag preview highlights individual cells for pattern items.

### 5.6 Hotbar Interaction

- The 9 hotbar slots are displayed at the bottom.
- Hotbar slot style: **6 px pure-black border, 8 px corner radius**, background alpha = 64. Selected slot switches to a green fill.
- Dragging an item onto a hotbar slot **3–8** assigns it.
- Hotbar slots **0–2 are read-only** in the inventory grid — they are managed exclusively through the equipment panel (primary/secondary/melee weapon).
- Clicking a hotbar slot number key (1–9) selects the active slot (for editing, not direct item selection).
- When the active slot contains a registered weapon item, that item becomes the player's combat **held weapon**.

### 5.7 Item Rarity System

| Rarity | Level | Background Tint |
|--------|-------|----------------|
| None | 0 | Default gray-blue |
| Common | 1 | Default gray-blue |
| Uncommon | 2 | Green |
| Rare | 3 | Blue |
| Epic | 4 | Purple |
| Legendary | 5 | Gold |

Rarity is defined in `ItemDefinition.rarity` and rendered as a coloured background tint on the item's grid cells.

## 6. Save/Load

### 6.1 GridInventory

- `save_to_dict() → Dictionary` — serializes width, height, placements (with inlined ItemStack data), hotbar slots, and active index.
- `load_from_dict(data: Dictionary)` — clears existing content and restores from dictionary.

### 6.2 EquipmentState

- `save_to_dict() → Dictionary` — serializes equipment slots and all container grids (each grid is serialized via `GridInventory.save_to_dict()`).
- `load_from_dict(data: Dictionary)` — restores slots and recreates container grids.

## 7. File Manifest

| Path | Type | Purpose |
|------|------|---------|
| `scripts/game/components/gameplay/grid_inventory.gd` | Data | Cell-based grid with pattern support + save/load |
| `scripts/game/components/gameplay/equipment_state.gd` | Data | Equipment slots + container grids + save/load |
| `scripts/game/components/gameplay/item_definition.gd` | Data | Item schema with rarity and pattern fields |
| `scripts/game/components/gameplay/item_stack.gd` | Data | Stack resource with count, durability, custom_data |
| `scripts/game/components/gameplay/equipment_rules.gd` | Logic | Equip/hotbar validation rules |
| `scripts/game/ui/inventory_menu.gd` | UI Script | Equipment panel + container grids + hotbar (extends UIPanel) |
| `scripts/game/ui/inventory_grid_panel.gd` | UI Script | Grid rendering + drag & drop + stacking + rarity |
| `scripts/game/ui/inventory_slot.gd` | UI Script | Single cell (StyleBoxFlat, no texture) |
| `scenes/game_scene/ui/inventory_panel.tscn` | Scene | Inventory panel scene (UIPanel root) |
| `scripts/game/registry/ui_catalog.gd` | Registry | UI panel registration catalog |

## 8. Integration

- `DemoGameRuntime._ready()` calls `UICatalog.ensure_registry()` to register `game:ui/inventory` with `UIRegistry`.
- `DemoGameRuntime._poll_inventory_input()` opens the inventory via `UIManager.open_panel()` with grid and equipment data.
- `PlayerHUD` hotbar display updates from the same backpack `GridInventory.hotbar_slots` used by the inventory menu.
- The equipment system is fully extensible for future container types and mod support.
- Save/load is performed through `GridInventory.save_to_dict()`/`load_from_dict()` and `EquipmentState.save_to_dict()`/`load_from_dict()`.
