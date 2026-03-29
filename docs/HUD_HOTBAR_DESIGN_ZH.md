# HUD 与快捷栏系统设计

> 版本 0.1 – 2026-03-29

## 1. 概述

HUD（抬头显示）系统提供实时游戏信息，包括玩家状态（生命值、体力、能量、口渴度）和 9 格快捷栏用于快速选择物品。快捷栏集成了 GUIDE 输入系统，支持可重映射的按键绑定，并提供完整的双语（英文/中文）本地化。

## 2. HUD 加载

`PlayerHUD` 场景（`scenes/game_scene/player_hud.tscn`）由 `DemoGameRuntime._setup_player_hud()` 在运行时加载。HUD 是一个 `CanvasLayer`（层级 10），渲染在游戏世界之上。

- **加载方式**：`load("res://scenes/game_scene/player_hud.tscn")` → `instantiate()` → `add_child()`
- **物品栏绑定**：`PlayerHUD.bind_inventory(grid)` 将 HUD 连接到玩家的 `GridInventory`
- **默认选中**：快捷栏第 0 格默认选中（`active_hotbar_index = 0`）

## 3. 快捷栏设计

### 3.1 视觉设计

| 属性 | 普通格子 | 选中格子 |
|------|---------|---------|
| 尺寸 | 56 × 56 px | 64 × 64 px |
| 基底贴图 | `hud_item.png` | `hud_item.png` |
| 调制颜色 | 白色 (1.0, 1.0, 1.0) | 淡蓝色 (0.7, 0.85, 1.0) |

每个格子是一个 `TextureRect` 节点，使用 `res://assets/game/textures/ui/hud_item.png` 作为基底贴图。选中的格子通过更大的尺寸和淡蓝色色调来突出显示。

### 3.2 按键绑定

所有快捷栏按键绑定使用 GUIDE 输入系统（`GUIDEMappingContext`），支持完全重映射。

| 动作名称 | 默认按键 | 显示名称（英文） | 显示名称（中文） |
|---------|---------|-----------------|-----------------|
| `pe_hotbar_1` | `1` | Hotbar Slot 1 | 快捷栏 1 |
| `pe_hotbar_2` | `2` | Hotbar Slot 2 | 快捷栏 2 |
| `pe_hotbar_3` | `3` | Hotbar Slot 3 | 快捷栏 3 |
| `pe_hotbar_4` | `4` | Hotbar Slot 4 | 快捷栏 4 |
| `pe_hotbar_5` | `5` | Hotbar Slot 5 | 快捷栏 5 |
| `pe_hotbar_6` | `6` | Hotbar Slot 6 | 快捷栏 6 |
| `pe_hotbar_7` | `7` | Hotbar Slot 7 | 快捷栏 7 |
| `pe_hotbar_8` | `8` | Hotbar Slot 8 | 快捷栏 8 |
| `pe_hotbar_9` | `9` | Hotbar Slot 9 | 快捷栏 9 |

### 3.3 输入轮询

快捷栏输入在 `PlayerHUD._poll_hotbar_input()` 中每帧通过 `GuideInputRuntime.is_action_triggered()` 轮询。`_hotbar_pressed` 数组跟踪每个格子上一帧的状态以检测上升沿（按键按下事件）。

当快捷栏按键被按下时：
1. `GridInventory.set_active_hotbar(index)` 更新数据模型
2. `_update_hotbar_selection()` 刷新视觉状态
3. 发出 `hotbar_selection_changed` 信号，携带当前活动物品 ID
4. `DemoGameRuntime._on_held_item_changed()` 更新玩家的装备武器

## 4. 物品栏切换

| 动作名称 | 默认按键 | 显示名称（英文） | 显示名称（中文） |
|---------|---------|-----------------|-----------------|
| `pe_inventory` | `Tab` | Inventory | 物品栏 |

物品栏菜单通过 GUIDE 动作 `pe_inventory` 切换（替代之前直接使用 `Input.is_key_pressed(KEY_TAB)` 的方式），从而支持按键重映射。

## 5. 受击粒子效果增强

受击粒子效果（`scenes/vfx/hit_particle_effect.tscn`）已增强以提高可见度：

| 参数 | 修改前 | 修改后 |
|------|-------|-------|
| 数量 (amount) | 14 | 24 |
| 生命周期 (lifetime) | 0.28s | 0.45s |
| 扩散角度 (spread) | 42° | 55° |
| 最小初始速度 | 120 | 160 |
| 最大初始速度 | 250 | 340 |
| 最小缩放 | 1.0 | 2.0 |
| 最大缩放 | 1.8 | 3.5 |
| 爆发性 (explosiveness) | 0.85 | 0.92 |
| 重力 Y | 420 | 350 |
| 颜色 | (0.95, 0.24, 0.18) | (1.0, 0.22, 0.15) |

## 6. 文件清单

| 路径 | 类型 | 用途 |
|------|------|------|
| `scripts/game/ui/player_hud.gd` | 脚本 | HUD + 快捷栏逻辑 |
| `scenes/game_scene/player_hud.tscn` | 场景 | HUD 场景布局 |
| `scripts/game/gameplay/demo_game_runtime.gd` | 脚本 | 游戏运行时（加载 HUD） |
| `scripts/game/input/player_input_context.gd` | 脚本 | GUIDE 输入绑定 |
| `resources/i18n/ui_text.en.json` | 国际化 | 英文本地化 |
| `resources/i18n/ui_text.zh.json` | 国际化 | 中文本地化 |
| `scenes/vfx/hit_particle_effect.tscn` | 场景 | 增强的受击粒子效果 |
| `assets/game/textures/ui/hud_item.png` | 贴图 | 快捷栏格子基底贴图 |
