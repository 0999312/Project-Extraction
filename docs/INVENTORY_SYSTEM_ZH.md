# 物品栏系统设计 – 俄罗斯方块式拖拽网格

> 版本 0.2 – 2026-03-29

## 1. 概述

物品栏系统是 **俄罗斯方块式网格物品栏（Tetris-style grid inventory）**，物品根据其 `size_w × size_h` 占据矩形格子区域。玩家可以 **拖拽** 物品进行放置、移动和交换。系统现在根据**装备生成不同的网格** — 每个容器装备（背包、战术弹挂）拥有各自独立的网格。系统还包括 **快捷栏**（快速访问槽位）和 **手持物品** 指示。

## 2. 数据模型

### 2.1 GridInventory（纯数据）

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `width` | `int` | 10 | 网格列数 |
| `height` | `int` | 6 | 网格行数 |
| `cells` | `Array[String]` | `[]`（大小 = w×h，"" = 空） | 扁平数组；每个格子存储占据它的物品的 `item_id`，空格子为 `""` |
| `placements` | `Array[Dictionary]` | `[]` | 每个字典：`{ "item_id": String, "grid_x": int, "grid_y": int, "rotated": bool, "stack": ItemStack }` |

### 2.2 基于装备的网格

物品栏菜单从 `EquipmentState` 为每个容器装备 **生成一个网格**：

| 装备 | 槽位键名 | 默认网格尺寸 |
|------|---------|-------------|
| 背包 | `backpack` | 6 × 6（36 格） |
| 战术弹挂 | `tactical_vest` | 3 × 2（6 格） |

详见 [EQUIPMENT_SYSTEM_ZH.md](EQUIPMENT_SYSTEM_ZH.md) 获取完整装备槽位说明。

### 2.3 ItemStack（未变更）

已定义：`item_id`、`count`、`durability`、`custom_data`。

### 2.4 ItemDefinition（已在任务 1 中更新）

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

快捷栏引用 **已放置在网格中** 的物品。将快捷栏槽位设为存在于 `placements` 中的 `item_id` 即可关联。当前激活槽位决定 **手持物品**。快捷栏第 0–2 格保留给武器（详见装备系统）。

## 5. UI 架构

### 5.1 InventoryMenu（CanvasLayer）

- 通过 **Tab** 键切换（输入动作 `pe_inventory`）。
- 打开时：暂停游戏输入，显示鼠标光标。
- 包含 **装备面板**（左侧）、**容器网格**（右侧）和 **快捷栏条带**（底部）。

### 5.2 装备面板

- 显示所有装备类别的绑定槽位：主武器、副武器、近战武器、头盔、耳机、护甲、背包、弹挂。
- 每个槽位会同步当前 `EquipmentState` 中的值，并显示已装备物品的显示名称（若该物品仅有数据 ID，则显示可读的回退名称）。
- 当玩家把网格中的物品拖到兼容的装备槽上时，该物品会被装备。
- 非背包装备槽中的已装备物品可以拖回网格格子，从而完成卸下。

### 5.3 网格面板

- 每个已装备的容器对应一个 `InventoryGridPanel`，由 `EquipmentState.get_all_container_grids()` 动态生成。
- 每个格子 `64 × 64` 像素，使用 `PanelContainer` + `StyleBoxFlat` 渲染。
- 格子样式：**6 px 纯黑边框，0 px 圆角**，背景透明度 = 64。
- 不使用任何贴图/材质资源。

### 5.4 物品渲染

- 每个已放置的物品使用其 `icon_path` 贴图，以**按高度适宜比例缩放**模式渲染（保持纵横比，缩放至格子高度，水平居中）。
- 物品贴图通过 `_draw()` 绘制在网格上方，**不受物品栏面板蒙版裁切**。
- 没有图标的物品显示居中的 `display_name` 标签。

### 5.5 拖拽操作

- **拾取**：点击已占用的格子 → 将放置记录从网格移除，附着到光标作为浮动精灵。
- **放下**：在网格空白区域点击 → 尝试 `can_place`；有效则 `place_item`；无效则返回原位。
- **交换**：如果放下目标恰好与另一件物品重叠，则交换位置（前提是两者都能放下）。
- **右键旋转**：手持物品时右键切换 `rotated`（交换宽高）。

### 5.6 快捷栏交互

- 底部显示 9 个快捷栏槽位。
- 快捷栏样式：**6 px 纯黑边框，8 px 圆角**，背景透明度 = 64。选中格保持固定正方形尺寸，仅切换为绿色填充。
- 将物品拖到快捷栏槽位上可进行绑定。
- 快捷栏第 0–2 格仅接受带有 `weapon` 标签的物品，以符合装备系统中“前三格保留给武器”的规则。
- 按数字键（1–9）选择激活槽位。
- 当激活槽位中是已注册的武器物品时，该物品会成为玩家战斗态下的**手持武器**（`combat_state.equipped_weapon_id`）。

## 6. 文件清单

| 路径 | 类型 | 用途 |
|------|------|------|
| `scripts/game/components/gameplay/grid_inventory.gd` | 数据 | 基于格子的网格与放置记录 |
| `scripts/game/components/gameplay/equipment_state.gd` | 数据 | 装备槽位 + 容器网格 |
| `scripts/game/ui/inventory_menu.gd` | UI 脚本 | 装备面板 + 容器网格 + 快捷栏 |
| `scripts/game/ui/inventory_grid_panel.gd` | UI 脚本 | 网格渲染 + 拖拽 |
| `scripts/game/ui/inventory_slot.gd` | UI 脚本 | 单格视觉（StyleBoxFlat，无贴图） |
| `scenes/game_scene/inventory_menu.tscn` | 场景 | 物品栏菜单场景 |

## 7. 集成

- `DemoGameRuntime._ready()` 现在会实例化 `scenes/game_scene/inventory_menu.tscn`，创建默认背包（6×6）与战术弹挂（3×2）的 `EquipmentState`，并把它与玩家自身的 `InventoryState.inventory` 绑定起来。
- `PlayerHUD` 的快捷栏显示与物品栏界面共用同一份背包 `GridInventory.hotbar_slots` 数据。
- 装备系统支持未来新增容器类型和 Mod 拓展。
