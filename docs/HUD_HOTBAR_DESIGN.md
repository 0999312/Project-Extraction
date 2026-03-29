# HUD & Hotbar System Design

> Version 0.1 – 2026-03-29

## 1. Overview

The HUD (Heads-Up Display) system provides real-time gameplay information including player stats (HP, Stamina, Energy, Thirst) and a 9-slot hotbar for quick-access item selection. The hotbar integrates with the GUIDE input system for remappable key bindings with full bilingual (English/Chinese) localization.

## 2. HUD Loading

The `PlayerHUD` scene (`scenes/game_scene/player_hud.tscn`) is loaded at runtime by `DemoGameRuntime._setup_player_hud()`. The HUD is a `CanvasLayer` (layer 10) that renders above the game world.

- **Loading**: `load("res://scenes/game_scene/player_hud.tscn")` → `instantiate()` → `add_child()`
- **Inventory binding**: `PlayerHUD.bind_inventory(grid)` connects the HUD to the player's `GridInventory`
- **Default selection**: Hotbar slot 0 is selected by default (`active_hotbar_index = 0`)

## 3. Hotbar Design

### 3.1 Visual Design

| Property | Normal Slot | Selected Slot |
|----------|------------|---------------|
| Size | 56 × 56 px | 64 × 64 px |
| Base texture | `hud_item.png` | `hud_item.png` |
| Modulate color | White (1.0, 1.0, 1.0) | Light blue (0.7, 0.85, 1.0) |

Each slot is a `TextureRect` node using `res://assets/game/textures/ui/hud_item.png` as its base texture. The selected slot is visually distinguished by a larger size and a light blue tint.

### 3.2 Key Bindings

All hotbar key bindings use the GUIDE input system (`GUIDEMappingContext`) for full remappability.

| Action Name | Default Key | Display Name (EN) | Display Name (ZH) |
|-------------|-------------|--------------------|--------------------|
| `pe_hotbar_1` | `1` | Hotbar Slot 1 | 快捷栏 1 |
| `pe_hotbar_2` | `2` | Hotbar Slot 2 | 快捷栏 2 |
| `pe_hotbar_3` | `3` | Hotbar Slot 3 | 快捷栏 3 |
| `pe_hotbar_4` | `4` | Hotbar Slot 4 | 快捷栏 4 |
| `pe_hotbar_5` | `5` | Hotbar Slot 5 | 快捷栏 5 |
| `pe_hotbar_6` | `6` | Hotbar Slot 6 | 快捷栏 6 |
| `pe_hotbar_7` | `7` | Hotbar Slot 7 | 快捷栏 7 |
| `pe_hotbar_8` | `8` | Hotbar Slot 8 | 快捷栏 8 |
| `pe_hotbar_9` | `9` | Hotbar Slot 9 | 快捷栏 9 |

### 3.3 Input Polling

Hotbar input is polled in `PlayerHUD._poll_hotbar_input()` each frame via `GuideInputRuntime.is_action_triggered()`. A `_hotbar_pressed` array tracks per-slot previous frame state to detect rising edges (key-down events).

When a hotbar key is pressed:
1. `GridInventory.set_active_hotbar(index)` updates the data model
2. `_update_hotbar_selection()` refreshes the visual state
3. `hotbar_selection_changed` signal is emitted with the active item ID
4. `DemoGameRuntime._on_held_item_changed()` updates the player's equipped weapon

## 4. Inventory Toggle

| Action Name | Default Key | Display Name (EN) | Display Name (ZH) |
|-------------|-------------|--------------------|--------------------|
| `pe_inventory` | `Tab` | Inventory | 物品栏 |

The inventory menu is toggled via the GUIDE action `pe_inventory` (replacing the previous direct `Input.is_key_pressed(KEY_TAB)` approach). This enables key remapping support.

## 5. Hit Particle Enhancement

The hit particle effect (`scenes/vfx/hit_particle_effect.tscn`) was enhanced for better visibility:

| Parameter | Previous | Enhanced |
|-----------|----------|----------|
| amount | 14 | 24 |
| lifetime | 0.28s | 0.45s |
| spread | 42° | 55° |
| initial_velocity_min | 120 | 160 |
| initial_velocity_max | 250 | 340 |
| scale_min | 1.0 | 2.0 |
| scale_max | 1.8 | 3.5 |
| explosiveness | 0.85 | 0.92 |
| gravity.y | 420 | 350 |
| color | (0.95, 0.24, 0.18) | (1.0, 0.22, 0.15) |

## 6. File Manifest

| Path | Type | Purpose |
|------|------|---------|
| `scripts/game/ui/player_hud.gd` | Script | HUD + hotbar logic |
| `scenes/game_scene/player_hud.tscn` | Scene | HUD scene layout |
| `scripts/game/gameplay/demo_game_runtime.gd` | Script | Game runtime (loads HUD) |
| `scripts/game/input/player_input_context.gd` | Script | GUIDE input bindings |
| `resources/i18n/ui_text.en.json` | i18n | English localization |
| `resources/i18n/ui_text.zh.json` | i18n | Chinese localization |
| `scenes/vfx/hit_particle_effect.tscn` | Scene | Enhanced hit particles |
| `assets/game/textures/ui/hud_item.png` | Texture | Hotbar slot base texture |
