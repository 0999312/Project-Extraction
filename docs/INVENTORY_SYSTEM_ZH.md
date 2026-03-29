# 物品栏系统设计 – 俄罗斯方块式拖拽网格

> 版本 0.1 – 2026-03-29

## 1. 概述

物品栏系统是 **俄罗斯方块式网格物品栏（Tetris-style grid inventory）**，物品根据其 `size_w × size_h` 占据矩形格子区域。玩家可以 **拖拽** 物品进行放置、移动和交换。系统还包括 **快捷栏**（快速访问槽位）和 **手持物品** 指示。

## 2. 数据模型

### 2.1 GridInventory（纯数据）

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `width` | `int` | 10 | 网格列数 |
| `height` | `int` | 6 | 网格行数 |
| `cells` | `Array[String]` | `[]`（大小 = w×h，"" = 空） | 扁平数组；每个格子存储占据它的物品的 `item_id`，空格子为 `""` |
| `placements` | `Array[Dictionary]` | `[]` | 每个字典：`{ "item_id": String, "grid_x": int, "grid_y": int, "rotated": bool, "stack": ItemStack }` |

### 2.2 ItemStack（未变更）

已定义：`item_id`、`count`、`durability`、`custom_data`。

### 2.3 ItemDefinition（已在任务 1 中更新）

新增 `icon_path`，标签改为 MSF TagRegistry 集成。

## 3. 核心操作

| 操作 | 签名 | 说明 |
|------|------|------|
| `can_place(item_id, gx, gy, rotated)` | `→ bool` | 检查物品的边界矩形是否能放入 `(gx, gy)` 而不重叠 |
| `place_item(stack, gx, gy, rotated)` | `→ bool` | 将 `ItemStack` 放置于 `(gx, gy)`，写入格子占用 |
| `remove_item(gx, gy)` | `→ Dictionary` | 移除边界矩形覆盖 `(gx, gy)` 的放置记录，返回放置字典 |
| `get_placement_at(gx, gy)` | `→ Dictionary` | 返回 `(gx, gy)` 处物品的放置信息，无物品返回 `{}` |
| `find_first_fit(item_id, rotated)` | `→ Vector2i` | 自动查找第一个有效位置（从左上扫描），未找到返回 `Vector2i(-1, -1)` |
| `compute_total_weight()` | `→ float` | 计算所有放置物品的总重量 |

## 4. 快捷栏

| 字段 | 类型 | 说明 |
|------|------|------|
| `hotbar_slots` | `Array[String]` | 大小 = 9；每项是对放置记录中某个 `item_id` 的引用，或 `""` |
| `active_hotbar_index` | `int` | 当前选中的槽位（0–8），默认 0 |

快捷栏引用 **已放置在网格中** 的物品。将快捷栏槽位设为存在于 `placements` 中的 `item_id` 即可关联。当前激活槽位决定 **手持物品**。

## 5. UI 架构

### 5.1 InventoryMenu（CanvasLayer）

- 通过 **Tab** 键切换（输入动作 `pe_inventory`）。
- 打开时：暂停游戏输入，显示鼠标光标。
- 包含网格面板和快捷栏条带。

### 5.2 网格面板

- `Control` 节点，大小为 `width × height` 个格子。
- 每个格子 `64 × 64` 像素。
- 背景贴图：每个格子平铺 `inventory_item.png`。
- 当格子被占用时，在其上绘制 **淡白灰色蒙版**（`Color(1, 1, 1, 0.18)`）。

### 5.3 物品渲染

- 每个已放置的物品使用其 `icon_path` 贴图（如果设置了的话），拉伸覆盖其边界格子。
- 没有图标的物品显示居中的 `display_name` 标签。

### 5.4 拖拽操作

- **拾取**：点击已占用的格子 → 将放置记录从网格移除，附着到光标作为浮动精灵。
- **放下**：在网格空白区域点击 → 尝试 `can_place`；有效则 `place_item`；无效则返回原位。
- **交换**：如果放下目标恰好与另一件物品重叠，则交换位置（前提是两者都能放下）。
- **右键旋转**：手持物品时右键切换 `rotated`（交换宽高）。

### 5.5 快捷栏交互

- 底部显示 9 个快捷栏槽位。
- 将物品拖到快捷栏槽位上可进行绑定。
- 按数字键（1–9）选择激活槽位。
- 激活槽位的物品成为玩家的 **手持物品**（`combat_state.equipped_weapon_id`）。

## 6. 文件清单

| 路径 | 类型 | 用途 |
|------|------|------|
| `scripts/game/components/gameplay/grid_inventory.gd` | 数据 | 基于格子的网格与放置记录 |
| `scripts/game/ui/inventory_menu.gd` | UI 脚本 | CanvasLayer 切换 + 主布局 |
| `scripts/game/ui/inventory_grid_panel.gd` | UI 脚本 | 网格渲染 + 拖拽 |
| `scripts/game/ui/inventory_slot.gd` | UI 脚本 | 单格视觉 |
| `scenes/game_scene/inventory_menu.tscn` | 场景 | 物品栏菜单场景 |

## 7. 集成

- `DemoGameRuntime._ready()` 添加 `InventoryMenu` 子节点。
- `Player._setup_runtime_state()` 通过 `GridInventory.place_item()` 填充初始物品。
- `PlayerHUD` 快捷栏显示从玩家的 `InventoryState.hotbar_slots` 更新。
