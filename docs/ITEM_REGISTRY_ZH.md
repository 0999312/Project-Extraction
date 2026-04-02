# 物品注册表文档

## 1. 注册表概览

- **注册表名称：** `item`
- **业务目标：** 以数据驱动方式定义所有运行时物品（武器、医疗、弹药、材料），供背包系统与战斗映射使用。
- **主要负责人：** Gameplay Runtime
- **关联内容范围：** 背包、战利品、装备、战斗武器解析

## 2. ResourceLocation 规则

- **条目命名空间：** `game`
- **条目 ID 命名规范：** `game:item/<类别>/<名称>`（例如 `game:item/weapon/pistol`）
- **标签命名规范：** 标签通过 MSF TagRegistry 管理，路径为 `game:tag/item/<标签名>`。标签定义在 `resources/registries/tags/items/` 下的独立 JSON 文件中，在物品注册完成后加载。运行时使用 `ItemCatalog.has_tag()` 和 `ItemCatalog.get_items_with_tag()` 查询。
- **跨注册表引用：** 武器注册表通过 `WeaponDefinition.item_id` 引用物品 ID

## 3. 加载时机与生命周期

- **何时创建注册表？** 首次调用 `ItemCatalog.ensure_registry()` 时。
- **何时注册条目？** 在 `ItemCatalog.ensure_registry()` 内 – 从 `resources/registries/items/` 目录下的 `.tres` 资源文件加载。
- **是否允许运行时扩展？** 是。
- **是否跨场景持久存在？** 是（全局 `RegistryManager`）。

## 4. 条目结构

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | `String`（RL） | 是 | — | 物品 RL 唯一键 |
| `display_name` | `String` | 是 | `""` | 显示名称 |
| `category` | `String` | 是 | `""` | 物品类别 |
| `size_w` | `int` | 否 | `1` | 网格宽度（边界框） |
| `size_h` | `int` | 否 | `1` | 网格高度（边界框） |
| `weight` | `float` | 否 | `0.0` | 单位重量 |
| `max_stack` | `int` | 否 | `1` | 最大堆叠数量 |
| `icon_path` | `String` | 否 | `""` | 物品图标贴图路径 |
| `rarity` | `int` | 否 | `0` | 稀有度等级（0 = 无，1–5 = 普通 → 传说） |
| `pattern` | `Array[Vector2i]` | 否 | `[]` | 自定义占位形状（空 = 填充矩形） |

## 5. 校验规则

- 条目必须为 `ItemDefinition`，且 `id` 非空。
- 重复 ID 跳过（先注册优先）。
- `size_w`、`size_h`、`max_stack` 应为正值。
- `rarity` 必须在 0–5 范围内。

## 6. 运行时访问方式

- **查询 API：** `ItemCatalog.get_item_definition(item_id)`
- **标签查询：** `ItemCatalog.has_tag(item_id, tag_name)`、`ItemCatalog.get_items_with_tag(tag_name)`
- **典型调用方：** `InventoryState`、`GridInventory`、武器映射流程
- **缓存策略：** 通过 `RegistryManager` 进行注册表查找
- **失败处理：** 返回 `null` 并记录错误日志

## 7. 当前内置条目

- `game:item/weapon/pistol` – 加载自 `resources/registries/items/pistol.tres`
- `game:item/weapon/creature` – 加载自 `resources/registries/items/creature_weapon.tres`
- `game:item/med/bandage` – 加载自 `resources/registries/items/bandage.tres`
- `game:item/ammo/9x19` – 加载自 `resources/registries/items/ammo_9x19.tres`

## 8. 相关文件

- `scripts/game/components/gameplay/item_definition.gd`
- `scripts/game/registry/item_registry.gd`
- `scripts/game/registry/item_catalog.gd`
- `resources/registries/items/*.tres`
- `resources/registries/tags/items/*.json` – 标签定义文件（每个 JSON 将标签映射到物品条目）

