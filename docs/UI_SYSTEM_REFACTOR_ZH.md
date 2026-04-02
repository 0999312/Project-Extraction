# UI 系统重构设计 — MSF UIManager 集成

> 版本 0.1 – 2026-04-01

## 概述

本文档描述了将所有游戏 UI 系统（玩家 HUD、物品栏菜单、暂停菜单）重构为使用 **Minecraft-Style-Framework (MSF)** `UIManager` 栈式面板管理系统的过程。目标是消除 UI 层之间的输入冲突，为所有面板提供一致的生命周期，并利用注册表驱动的实例化来提高可扩展性。

## 问题描述

### 重构前

| 组件 | 基类 | 管理方式 | 输入处理 |
|------|------|---------|---------|
| PlayerHUD | `CanvasLayer` | DemoGameRuntime 中直接 `add_child` | 无（始终可见） |
| InventoryMenu | `CanvasLayer` | 直接 `add_child` + 手动 `toggle()` | `_input()` 配合手动 `_is_open` 标志 |
| 暂停菜单 | Maaacks `PauseMenuController` | `_unhandled_input("ui_cancel")` 自动触发 | 内置 `OverlaidWindow` 处理 |

### 关键问题

1. **ESC 按键冲突**：打开物品栏后按 ESC 会触发 `PauseMenuController` 的 `_unhandled_input`，而不是关闭物品栏，因为物品栏没有消费 `ui_cancel` 事件。
2. **无统一生命周期**：每个 UI 组件独立管理自己的可见性、打开/关闭状态和输入消费。
3. **无层级排序**：多个 `CanvasLayer` 节点使用硬编码的层级索引（10、20），没有正式的层级系统。
4. **无缓存/池化**：面板仅实例化一次后切换显隐，没有框架级的内存管理。

## 重构后的架构

### MSF UIManager 集成

所有游戏 UI 现在都通过 `UIManager`（自动加载单例）管理：

| 组件 | 基类 | UIManager 角色 | 层级 |
|------|------|---------------|------|
| PlayerHUD | `Control` | `UIManager.add_overlay()` | `UILayer.SCENE` (0) |
| InventoryMenu | `UIPanel` | `UIManager.open_panel()` / `UIManager.back()` | `UILayer.NORMAL` (100) |
| PauseMenuPanel | `UIPanel` | `UIManager.open_panel()` / `UIManager.back()` | `UILayer.POPUP` (200) |

### 面板注册

所有面板通过 `UICatalog.ensure_registry()` 在游戏启动时注册：

```
UICatalog.ensure_registry()
  → UIRegistry.register_panel("game:ui/pause_menu", ..., UILayer.POPUP, CacheMode.NONE)
  → UIRegistry.register_panel("game:ui/inventory", ..., UILayer.NORMAL, CacheMode.CACHE)
```

### 输入流程（ESC 按键解决方案）

```
ESC 按下
  ├── 物品栏已打开？ → InventoryMenu._unhandled_input() → UIManager.back(NORMAL) → 关闭物品栏
  ├── 暂停菜单已打开？ → PauseMenuPanel._unhandled_input() → UIManager.back(POPUP) → 关闭暂停
  └── 无面板打开？ → DemoGameRuntime._poll_pause_input() → UIManager.open_panel(pause_menu)
```

栈式方式确保最高活跃层级的栈顶面板始终优先获得输入处理权。由于 `UIManager` 管理可见性且 Godot 输入传播从上到下流动，正确的面板总是处理 ESC。

### 生命周期

所有面板遵循 `UIPanel` 生命周期：

```
_on_init()    → 首次创建时调用（仅一次）
_on_open()    → 每次打开时调用（接收数据字典）
_on_pause()   → 被新面板覆盖时调用
_on_resume()  → 上方面板关闭后恢复时调用
_on_close()   → 从栈中移除时调用
_on_destroy() → 销毁前调用（仅 CacheMode.NONE 时）
```

### HUD 作为覆盖层

`PlayerHUD` 不再是栈中的面板。它使用 `UIManager.add_overlay()` 注册在 `UILayer.SCENE`，使其成为始终可见的持久元素，不受面板栈状态影响。

## 文件变更

| 文件 | 类型 | 变更 |
|------|------|------|
| `scripts/game/registry/ui_catalog.gd` | 新增 | UI 面板注册表目录 |
| `scripts/game/ui/pause_menu_panel.gd` | 新增 | 暂停菜单 UIPanel 实现 |
| `scenes/game_scene/ui/pause_menu_panel.tscn` | 新增 | 暂停菜单场景（Godot 场景，非脚本构建） |
| `scenes/game_scene/ui/inventory_panel.tscn` | 新增 | 物品栏面板场景，供 UIRegistry 使用 |
| `scripts/game/ui/inventory_menu.gd` | 修改 | 从 `CanvasLayer` 改为 `UIPanel` |
| `scripts/game/ui/player_hud.gd` | 修改 | 从 `CanvasLayer` 改为 `Control` |
| `scenes/game_scene/player_hud.tscn` | 修改 | 根节点从 `CanvasLayer` 改为 `Control` |
| `scripts/game/gameplay/demo_game_runtime.gd` | 修改 | 使用 UIManager 管理所有 UI 操作 |
| `scenes/game_scene/pe_scene/DemoGame.tscn` | 修改 | 移除 `PauseMenuController` 节点 |

## 设计决策

1. **暂停菜单位于 POPUP 层**：暂停菜单使用 `UILayer.POPUP`（200）而非 `NORMAL`（100），确保在物品栏之上渲染，并能独立暂停游戏树。
2. **物品栏使用 CacheMode.CACHE**：关闭时缓存物品栏以保留装备格子状态，避免重新实例化开销。
3. **暂停菜单使用 CacheMode.NONE**：暂停菜单较轻量，关闭时销毁；重新创建成本低。
4. **HUD 使用覆盖层而非面板**：HUD 需要始终可见，不参与栈的推入/弹出，因此使用覆盖层 API。
5. **通过 _on_open() 传递数据**：物品栏通过 `_on_open()` 的 `data` 字典接收网格和装备引用，遵循 MSF 数据传递模式。
