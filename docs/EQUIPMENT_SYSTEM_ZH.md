# 装备系统设计

## 概述

**装备系统**管理角色所有可穿戴和可装备的物件。每个角色拥有一个 `EquipmentState` 资源，用于追踪各槽位当前装备的物品。系统设计以**易于拓展**为核心——新增槽位或装备类型只需在 `SLOT_KEYS` 中追加条目并添加导出属性，无需改动已有存档或重写代码。

## 装备槽位

| 槽位键名 | 显示名称 | 快捷栏映射 | 说明 |
|---|---|---|---|
| `primary_weapon` | 主武器 | 快捷栏第 0 格 | 主要枪械（步枪、冲锋枪、霰弹枪…） |
| `secondary_weapon` | 副武器 | 快捷栏第 1 格 | 副手武器（手枪、微冲…） |
| `melee_weapon` | 近战武器 | 快捷栏第 2 格 | 近战武器（匕首、手斧…） |
| `hotbar_usable_1` – `hotbar_usable_6` | 可用物品 1–6 | 快捷栏第 3–8 格 | 消耗品、投掷物、工具 |
| `armor` | 护甲 | — | 防弹衣 / 板甲 |
| `headset` | 耳机 | — | 听力防护 / 通讯设备 |
| `helmet` | 头盔 | — | 头部防护 |
| `backpack` | 背包 | — | 存储容器（默认 6×6 格） |
| `tactical_vest` | 战术弹挂 | — | 存储容器（默认 3×2 格） |

### 武器槽位 → 快捷栏

快捷栏前三格为武器保留：

- **第 0 格** → `primary_weapon`（主武器）
- **第 1 格** → `secondary_weapon`（副武器）
- **第 2 格** → `melee_weapon`（近战武器）

调用 `EquipmentState.sync_weapons_to_hotbar(grid)` 可将已装备的武器 ID 同步至 `GridInventory.hotbar_slots[0..2]`。

### 容器槽位

提供存储功能的装备（`backpack`、`tactical_vest`）各自持有独立的 `GridInventory` 实例。通过 `EquipmentState.set_container_grid(slot_key, grid)` 注册，通过 `get_container_grid(slot_key)` 查询。

默认容器容量：

| 容器 | 格子尺寸 |
|---|---|
| 背包 | 6 × 6（36 格） |
| 战术弹挂 | 3 × 2（6 格） |

## 数据模型

### EquipmentState（Resource）

```
class_name EquipmentState
extends Resource

SLOT_KEYS: PackedStringArray          # 所有合法槽位键名
slots: Dictionary                     # slot_key → item_id（空为 ""）
container_grids: Dictionary           # slot_key → GridInventory（仅容器类型）

signal equipment_changed(slot_key)

equip(slot_key, item_id)              # 将物品设置到槽位
unequip(slot_key)                     # 清空槽位（同时移除容器网格）
get_equipped(slot_key) → String       # 读取当前 item_id
is_slot_empty(slot_key) → bool
set_container_grid(slot_key, grid)    # 为容器槽位绑定 GridInventory
get_container_grid(slot_key) → GridInventory
get_all_container_grids() → Array[Dictionary]
sync_weapons_to_hotbar(grid)          # 将武器 ID 推送至快捷栏 0-2
```

## UI 集成

`InventoryMenu` 现在显示：

1. **装备面板**（左侧）— 所有装备类别的占位槽（武器、护甲、耳机、头盔、容器）。
2. **容器网格**（右侧）— 每个已装备容器对应一个 `InventoryGridPanel`，由 `EquipmentState.get_all_container_grids()` 动态生成。
3. **快捷栏**（底部）— 9 格，前 3 格保留给武器。

### 视觉风格

- **快捷栏格子**：`PanelContainer` + `StyleBoxFlat`，6 px 纯黑边框，8 px 圆角，背景透明度 = 64。选中格略微放大（56 × 56 → 64 × 64）并填充深蓝色。
- **物品栏网格格子**：`PanelContainer` + `StyleBoxFlat`，6 px 纯黑边框，0 px 圆角（无圆角），背景透明度 = 64。
- 槽位渲染不使用任何贴图/材质资源。
- 物品图标使用**按高度适宜比例缩放**（保持纵横比，缩放至格子高度，水平居中）。物品图标绘制在网格上方，**不受面板蒙版裁切**。

## 可拓展性

添加新装备槽位的步骤：

1. 在 `EquipmentState.SLOT_KEYS` 中添加槽位键名。
2. 若该槽位提供存储功能，通过 `set_container_grid()` 注册 `GridInventory`。
3. 在 `InventoryMenu._build_equipment_panel()` 中添加占位符。
4. （可选）映射到快捷栏索引或添加自定义 UI 交互。

此设计支持 **Mod 拓展**：Mod 作者可继承 `EquipmentState`，扩展 `SLOT_KEYS`，并注册额外的容器网格，无需修改核心脚本。

## 按键绑定

| 操作 | 默认按键 | GUIDE 动作名 |
|---|---|---|
| 打开物品栏 | Tab | `pe_inventory` |
| 快捷栏第 1–9 格 | 1–9 | `pe_hotbar_1` – `pe_hotbar_9` |

所有绑定均可通过 GUIDE 输入系统重新映射。

## 文件清单

| 文件 | 职责 |
|---|---|
| `scripts/game/components/gameplay/equipment_state.gd` | 装备数据模型 |
| `scripts/game/ui/inventory_menu.gd` | 装备 + 物品栏 UI |
| `scripts/game/ui/inventory_grid_panel.gd` | 网格渲染（按高度缩放图标） |
| `scripts/game/ui/inventory_slot.gd` | 单个网格格子（StyleBoxFlat，无贴图） |
| `scripts/game/ui/player_hud.gd` | HUD 快捷栏（StyleBoxFlat，无贴图） |
| `scripts/game/gameplay/demo_game_runtime.gd` | 接线：创建 EquipmentState 并绑定到 UI |
| `scripts/game/input/player_input_context.gd` | GUIDE 输入动作定义 |
| `resources/i18n/ui_text.en.json` | 英文 UI 文本 |
| `resources/i18n/ui_text.zh.json` | 中文 UI 文本 |
