# UI System Refactor Design — MSF UIManager Integration

> Version 0.1 – 2026-04-01

## Overview

This document describes the refactoring of all gameplay UI systems (Player HUD, Inventory Menu, Pause Menu) to use the **Minecraft-Style-Framework (MSF)** `UIManager` stack-based panel management system. The goal is to eliminate input conflicts between UI layers, provide a consistent lifecycle for all panels, and leverage registry-driven instantiation for better extensibility.

## Problem Statement

### Before Refactor

| Component | Base Class | Management | Input Handling |
|-----------|-----------|-----------|---------------|
| PlayerHUD | `CanvasLayer` | Direct `add_child` in DemoGameRuntime | N/A (always visible) |
| InventoryMenu | `CanvasLayer` | Direct `add_child` + manual `toggle()` | `_input()` with manual `_is_open` flag |
| Pause Menu | Maaacks `PauseMenuController` | `_unhandled_input("ui_cancel")` auto-trigger | Built-in `OverlaidWindow` handling |

### Key Issues

1. **ESC Key Conflict**: Opening inventory then pressing ESC would trigger the `PauseMenuController`'s `_unhandled_input` instead of closing the inventory, because the inventory didn't consume the `ui_cancel` event.
2. **No Unified Lifecycle**: Each UI component managed its own visibility, open/close state, and input consumption independently.
3. **No Layer Ordering**: Multiple `CanvasLayer` nodes with hardcoded layer indices (10, 20) without a formal layer system.
4. **No Caching/Pooling**: Panels were instantiated once and toggled, with no framework-level memory management.

## Architecture After Refactor

### MSF UIManager Integration

All gameplay UI now flows through `UIManager` (autoload singleton):

| Component | Base Class | UIManager Role | Layer |
|-----------|-----------|---------------|-------|
| PlayerHUD | `Control` | `UIManager.add_overlay()` | `UILayer.SCENE` (0) |
| InventoryMenu | `UIPanel` | `UIManager.open_panel()` / `UIManager.back()` | `UILayer.NORMAL` (100) |
| PauseMenuPanel | `UIPanel` | `UIManager.open_panel()` / `UIManager.back()` | `UILayer.POPUP` (200) |

### Panel Registration

All panels are registered via `UICatalog.ensure_registry()` at game startup:

```
UICatalog.ensure_registry()
  → UIRegistry.register_panel("game:ui/pause_menu", ..., UILayer.POPUP, CacheMode.NONE)
  → UIRegistry.register_panel("game:ui/inventory", ..., UILayer.NORMAL, CacheMode.CACHE)
```

### Input Flow (ESC Key Resolution)

```
ESC pressed
  ├── InventoryMenu open? → InventoryMenu._unhandled_input() → UIManager.back(NORMAL) → closes inventory
  ├── PauseMenu open?     → PauseMenuPanel._unhandled_input() → UIManager.back(POPUP) → closes pause
  └── Nothing open?       → DemoGameRuntime._poll_pause_input() → UIManager.open_panel(pause_menu)
```

The stack-based approach ensures that the topmost panel on the highest active layer always gets first chance at handling input. Since `UIManager` manages visibility and the Godot input propagation flows from top to bottom, the correct panel always handles ESC.

### Lifecycle

All panels follow the `UIPanel` lifecycle:

```
_on_init()    → First-time creation (once)
_on_open()    → Every time opened (receives data dict)
_on_pause()   → Covered by new panel on same layer
_on_resume()  → Panel above closed
_on_close()   → Removed from stack
_on_destroy() → Before deletion (CacheMode.NONE only)
```

### HUD as Overlay

`PlayerHUD` is no longer a panel in the stack. It uses `UIManager.add_overlay()` on `UILayer.SCENE`, making it a persistent element that is always visible regardless of panel stack state.

## File Changes

| File | Type | Change |
|------|------|--------|
| `scripts/game/registry/ui_catalog.gd` | New | UI panel registry catalog |
| `scripts/game/ui/pause_menu_panel.gd` | New | Pause menu UIPanel implementation |
| `scenes/game_scene/ui/pause_menu_panel.tscn` | New | Pause menu scene (Godot scene, not script-built) |
| `scenes/game_scene/ui/inventory_panel.tscn` | New | Inventory panel scene for UIRegistry |
| `scripts/game/ui/inventory_menu.gd` | Modified | Changed from `CanvasLayer` to `UIPanel` |
| `scripts/game/ui/player_hud.gd` | Modified | Changed from `CanvasLayer` to `Control` |
| `scenes/game_scene/player_hud.tscn` | Modified | Root changed from `CanvasLayer` to `Control` |
| `scripts/game/gameplay/demo_game_runtime.gd` | Modified | Uses UIManager for all UI operations |
| `scenes/game_scene/pe_scene/DemoGame.tscn` | Modified | Removed `PauseMenuController` node |

## Design Decisions

1. **Pause menu on POPUP layer**: The pause menu uses `UILayer.POPUP` (200) rather than `NORMAL` (100) to ensure it renders above inventory and can independently pause the game tree.
2. **Inventory uses CacheMode.CACHE**: The inventory is cached when closed to preserve equipment grid state and avoid re-instantiation overhead.
3. **Pause menu uses CacheMode.NONE**: The pause menu is lightweight and destroyed on close; re-creation is trivial.
4. **HUD uses overlay, not panel**: The HUD needs to be always-visible and never participates in stack push/pop, so it uses the overlay API.
5. **Data passed via _on_open()**: Inventory receives its grid and equipment references through the `data` dictionary in `_on_open()`, following the MSF data-passing pattern.
