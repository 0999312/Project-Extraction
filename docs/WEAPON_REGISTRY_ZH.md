# 武器注册表文档

## 1. 注册表概览

- **注册表名称：** `weapon`
- **业务目标：** 通过数据定义武器行为参数，并从已装备物品 ID 映射到战斗参数，避免在角色脚本中硬编码武器行为。
- **主要负责人：** Combat Runtime
- **关联内容范围：** 射击、换弹时序、散布/后坐、弹丸类型选择

## 2. ResourceLocation 规则

- **条目命名空间：** `game`
- **条目 ID 命名规范：** `game:weapon/<名称>`（例如 `game:weapon/pistol`）
- **标签命名规范：** 无
- **跨注册表引用：** `item_id` 引用 `core:item`；`projectile_definition_id` 引用弹丸注册表 ID

## 3. 加载时机与生命周期

- **何时创建注册表？** 首次调用 `WeaponCatalog.ensure_registry()` 时。
- **何时注册条目？** 在 `WeaponCatalog.ensure_registry()` 内批量注册。
- **是否允许运行时扩展？** 是。
- **是否跨场景持久存在？** 是（全局 `RegistryManager`）。

## 4. 条目结构

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | `String`（RL） | 是 | — | 武器 RL 唯一键 |
| `display_name` | `String` | 是 | `""` | 显示名称 |
| `item_id` | `String`（RL） | 是 | `""` | 反向绑定的物品 ID |
| `projectile_definition_id` | `String`（RL） | 是 | `game:projectile/bullet` | 弹丸类型 |
| `ammo_capacity` | `int` | 是 | `0` | 弹匣容量 |
| `fire_interval` | `float` | 是 | `0.14` | 射击间隔 |
| `reload_duration_sec` | `float` | 是 | `1.5` | 换弹时长 |
| `hipfire_spread_deg` | `float` | 否 | `6.0` | 腰射散布 |
| `ads_spread_deg` | `float` | 否 | `1.5` | 瞄准散布 |
| `recoil_per_shot` | `float` | 否 | `0.6` | 每发后坐累计 |
| `recoil_recovery_per_sec` | `float` | 否 | `2.0` | 后坐恢复速度 |
| `pellets_per_shot` | `int` | 否 | `1` | 每次射击弹丸数量 |

## 5. 运行时访问方式

- `WeaponCatalog.get_weapon_for_item(item_id)`：将已装备物品解析为武器定义。
- `WeaponCatalog.apply_to_combat_state(combat_state)`：将武器定义写入战斗状态参数。

## 6. 当前内置条目

- `game:weapon/pistol`（对应物品 `game:item/weapon/pistol`，弹丸 `game:projectile/bullet`）
- `game:weapon/creature_organ`（对应物品 `game:item/weapon/creature`，弹丸 `game:projectile/creature_bolt`）

## 7. 相关文件

- `scripts/game/components/combat/weapon_definition.gd`
- `scripts/game/registry/weapon_registry.gd`
- `scripts/game/registry/weapon_catalog.gd`

