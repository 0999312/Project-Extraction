# 物品栏系统设计 – 俄罗斯方块式拖拽网格

> 版本 0.4 – 2026-04-02

## 1. 概述

物品栏系统是 **俄罗斯方块式网格物品栏（Tetris-style grid inventory）**，物品根据其 `size_w × size_h` 边界框或自定义**占位形状（pattern）** 占据格子区域。玩家可以 **拖拽** 物品进行放置和移动。物品可**旋转**（右键）以适配网格，相同物品的堆叠可在拖放时**自动合并**。系统根据**装备生成不同的网格** — 每个容器装备（背包、战术弹挂）拥有各自独立的网格。系统包括 **快捷栏**（快速访问槽位）、**物品稀有度**视觉系统，以及**存档/读取 API**。

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

### 2.3 ItemStack

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `item_id` | `String` | `""` | 对 ItemDefinition.id 的引用 |
| `count` | `int` | 1 | 当前堆叠数量（最小 1） |
| `durability` | `float` | 1.0 | 物品耐久度（0.0 – 1.0） |
| `custom_data` | `Dictionary` | `{}` | 任意扩展数据（附魔、改装等） |

### 2.4 ItemDefinition

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `id` | `String` | `""` | 物品资源定位键 |
| `display_name` | `String` | `""` | 显示名称 |
| `category` | `String` | `""` | 物品分类 |
| `size_w` | `int` | 1 | 网格宽度（边界框） |
| `size_h` | `int` | 1 | 网格高度（边界框） |
| `weight` | `float` | 0.0 | 单位重量 |
| `max_stack` | `int` | 1 | 最大堆叠数量 |
| `icon_path` | `String` | `""` | 图标贴图路径 |
| `rarity` | `int` | 0 | 稀有度等级（0 = 无, 1–5 = 普通 → 传说） |
| `pattern` | `Array[Vector2i]` | `[]` | 自定义占位形状（空 = 填充矩形） |

## 3. 核心操作

| 操作 | 签名 | 说明 |
|------|------|------|
| `can_place(item_id, gx, gy, rotated)` | `→ bool` | 使用物品的形状（pattern 或边界矩形）检查是否能放入 |
| `place_item(stack, gx, gy, rotated)` | `→ bool` | 放置物品，按格子写入占用 |
| `remove_item(gx, gy)` | `→ Dictionary` | 移除 `(gx, gy)` 处的放置记录 |
| `get_placement_at(gx, gy)` | `→ Dictionary` | 返回 `(gx, gy)` 处物品的放置信息 |
| `find_first_fit(item_id, rotated)` | `→ Vector2i` | 自动查找第一个有效位置 |
| `auto_place(stack)` | `→ bool` | 尝试不旋转放置，再尝试旋转放置 |
| `compute_total_weight()` | `→ float` | 计算所有放置物品的总重量 |
| `save_to_dict()` | `→ Dictionary` | 序列化完整物品栏状态 |
| `load_from_dict(data)` | `→ void` | 从存档数据恢复物品栏 |

### 3.1 自定义形状（Pattern）

物品可定义 `pattern` 数组，包含以左上角为原点的 `Vector2i` 偏移量。为空时使用 `size_w × size_h` 的填充矩形。形状支持旋转：每个偏移 `(x, y)` 顺时针旋转 90° 变为 `(max_y - y, x)`。

### 3.2 堆叠合并

将拖拽的物品堆叠放到已有的**同类物品堆叠**上时，数量会自动合并（上限为 `max_stack`）。若拖拽堆叠被完全消耗则拖拽结束，否则剩余数量继续保持拖拽状态。

## 4. 快捷栏

| 字段 | 类型 | 说明 |
|------|------|------|
| `hotbar_slots` | `Array[String]` | 大小 = 9；每项是对 `item_id` 的引用，或 `""` |
| `active_hotbar_index` | `int` | 当前选中的槽位（0–8），默认 0 |

快捷栏引用 **已放置在网格中** 的物品。

- **第 0–2 格** 保留给武器，**只能**通过装备面板（主武器/副武器/近战武器槽）进行分配。从容器网格直接拖拽到这些槽位的操作会被阻止。
- **第 3–8 格** 接受任何物品，可从网格拖拽分配。
- 当前激活槽位决定 **手持物品**。

## 5. UI 架构

### 5.1 InventoryMenu（UIPanel — MSF 管理）

- 通过 `UIManager.open_panel()` / `UIManager.back()` 在 `UILayer.NORMAL`（层级 100）上打开/关闭。
- 通过 **Tab** 键切换（输入动作 `pe_inventory`），在 `DemoGameRuntime._poll_inventory_input()` 中处理。
- **ESC 键关闭物品栏**：`_unhandled_input()` 消费 `ui_cancel` 并调用 `UIManager.back(UILayer.NORMAL)`。
- 打开时：暂停游戏输入，显示鼠标光标。
- 包含 **装备面板**（左侧）、**容器网格**（右侧）和 **快捷栏条带**（底部）。
- 数据（网格、装备）通过 `_on_open(data)` 字典传递。
- 使用 `CacheMode.CACHE` 以在打开/关闭周期间保留状态。

### 5.2 装备面板

- 显示所有装备类别的绑定槽位：主武器、副武器、近战武器、头盔、耳机、护甲、背包、弹挂。
- 每个槽位会同步当前 `EquipmentState` 中的值，并显示已装备物品的显示名称。
- 当玩家把网格中的物品拖到兼容的装备槽上时，该物品会被装备。
- 非背包装备槽中的已装备物品可以拖回网格格子，从而完成卸下。

### 5.3 网格面板

- 每个已装备的容器对应一个 `InventoryGridPanel`，由 `EquipmentState.get_all_container_grids()` 动态生成。
- 每个格子 `64 × 64` 像素，使用 `PanelContainer` + `StyleBoxFlat` 渲染。
- 格子样式：**6 px 纯黑边框，0 px 圆角**，背景透明度 = 64。
- 网格面板使用 `clip_contents = false`，物品贴图不受面板边框裁切。

### 5.4 物品渲染

- 绘制顺序：网格线（最底层）→ 已放置物品（在网格线之上）→ 拖拽预览（最顶层）。
- 每个已放置的物品使用其 `icon_path` 贴图，以**适配内部**模式渲染（保持纵横比，适配边界框，双轴居中）。图标不会超出格子边界。
- 拥有自定义形状的物品会逐格渲染背景色；图标绘制在边界框上方。
- 没有图标的物品显示居中的 `display_name` 标签。
- 堆叠数量（>1）显示在物品矩形的右下角。
- 稀有度着色背景：物品的背景色随稀有度等级变化（普通 = 默认，优良 = 绿色，稀有 = 蓝色，史诗 = 紫色，传说 = 金色）。

### 5.5 拖拽操作

- **拾取**：点击已占用的格子 → 将放置记录从网格移除，附着到光标。
- **放到空位**：在空白区域点击 → 尝试 `can_place`；有效则 `place_item`；无效则返回原位。
- **放到同类堆叠**：若目标是同类物品的堆叠，自动合并数量（上限为 `max_stack`）。
- **无效放置回退**：如果目标位置无效，物品会优先返回原始位置；若原位也不可用，`auto_place` 查找第一个有效位置。
- **右键旋转**：手持物品时右键切换 `rotated`（交换宽高或将 pattern 顺时针旋转 90°）。
- **形状预览**：拖拽预览会逐格高亮自定义形状物品的占位区域。

### 5.6 快捷栏交互

- 底部显示 9 个快捷栏槽位。
- 快捷栏样式：**6 px 纯黑边框，8 px 圆角**，背景透明度 = 64。选中格切换为绿色填充。
- 将物品拖到快捷栏 **第 3–8 格** 可进行绑定。
- 快捷栏 **第 0–2 格为只读**（在物品栏网格中），仅通过装备面板（主武器/副武器/近战武器）管理。
- 按数字键（1–9）选择激活槽位（用于编辑选择，不直接选择物品）。
- 当激活槽位中是已注册的武器物品时，该物品会成为玩家战斗态下的**手持武器**。

### 5.7 物品稀有度系统

| 稀有度 | 等级 | 背景着色 |
|--------|------|----------|
| 无 | 0 | 默认蓝灰色 |
| 普通 | 1 | 默认蓝灰色 |
| 优良 | 2 | 绿色 |
| 稀有 | 3 | 蓝色 |
| 史诗 | 4 | 紫色 |
| 传说 | 5 | 金色 |

稀有度在 `ItemDefinition.rarity` 中定义，以格子背景着色的形式在网格中渲染。

## 6. 存档/读取

### 6.1 GridInventory

- `save_to_dict() → Dictionary` — 序列化宽高、放置记录（含内联的 ItemStack 数据）、快捷栏和激活索引。
- `load_from_dict(data: Dictionary)` — 清除已有内容并从字典恢复。

### 6.2 EquipmentState

- `save_to_dict() → Dictionary` — 序列化装备槽和所有容器网格（每个网格通过 `GridInventory.save_to_dict()` 序列化）。
- `load_from_dict(data: Dictionary)` — 恢复槽位并重建容器网格。

## 7. 文件清单

| 路径 | 类型 | 用途 |
|------|------|------|
| `scripts/game/components/gameplay/grid_inventory.gd` | 数据 | 基于格子的网格 + 形状支持 + 存档/读取 |
| `scripts/game/components/gameplay/equipment_state.gd` | 数据 | 装备槽位 + 容器网格 + 存档/读取 |
| `scripts/game/components/gameplay/item_definition.gd` | 数据 | 物品模式：含稀有度和形状字段 |
| `scripts/game/components/gameplay/item_stack.gd` | 数据 | 堆叠资源：数量、耐久度、自定义数据 |
| `scripts/game/components/gameplay/equipment_rules.gd` | 逻辑 | 装备/快捷栏验证规则 |
| `scripts/game/ui/inventory_menu.gd` | UI 脚本 | 装备面板 + 容器网格 + 快捷栏（继承 UIPanel） |
| `scripts/game/ui/inventory_grid_panel.gd` | UI 脚本 | 网格渲染 + 拖拽 + 堆叠合并 + 稀有度 |
| `scripts/game/ui/inventory_slot.gd` | UI 脚本 | 单格视觉（StyleBoxFlat，无贴图） |
| `scenes/game_scene/ui/inventory_panel.tscn` | 场景 | 物品栏面板场景（UIPanel 根节点） |
| `scripts/game/registry/ui_catalog.gd` | 注册表 | UI 面板注册目录 |

## 8. 集成

- `DemoGameRuntime._ready()` 调用 `UICatalog.ensure_registry()` 将 `game:ui/inventory` 注册到 `UIRegistry`。
- `DemoGameRuntime._poll_inventory_input()` 通过 `UIManager.open_panel()` 打开物品栏，并传入网格和装备数据。
- `PlayerHUD` 的快捷栏显示与物品栏界面共用同一份背包 `GridInventory.hotbar_slots` 数据。
- 装备系统支持未来新增容器类型和 Mod 拓展。
- 存档/读取通过 `GridInventory.save_to_dict()`/`load_from_dict()` 和 `EquipmentState.save_to_dict()`/`load_from_dict()` 执行。
