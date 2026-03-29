# Buff 注册表设计文档

**日期：** 2026-03-29  
**状态：** 有效  

---

## 1. 注册表概览

- **注册表名称：** `buff`
- **业务目标：** 集中定义和查询所有可应用于生物角色的临时或持久状态修改器（Buff 与 Debuff）。以数据驱动、可扩展的方式替代 `StatusEffectsState` 中硬编码的布尔标志。
- **主要负责人：** 游戏系统 / 玩家与敌人战斗
- **关联内容范围：** 玩家状态、敌人状态、医疗物品、战斗伤害、HUD 显示

---

## 2. ResourceLocation 规则

- **条目命名空间：** `game`
- **条目 ID 命名规范：** `game:buff/<buff名称>`（例如 `game:buff/bleed_light`）
- **标签命名规范：** `BuffDefinition.tags` 内部使用纯字符串标签（如 `"bleed"`、`"debuff"`、`"fracture"`），不采用 ResourceLocation 格式。
- **跨注册表引用：** 医疗物品效果（通过 `game:item_med` 标签规则）引用 Buff ID 来施加/移除 Buff。当前阶段无需其他注册表交叉引用。

---

## 3. 加载时机与生命周期

- **何时创建注册表？** 首次调用 `BuffCatalog.ensure_registry()` 时，通常在游戏场景加载时或首次应用 Buff 时触发。
- **何时注册条目？** 内置条目在 `BuffCatalog.ensure_registry()` 中注册；自定义条目可通过 `BuffRegistry.register(rl, definition)` 添加。
- **是否允许运行时扩展？** 是——模组或扩展内容可在游戏开始前注册额外的 `BuffDefinition` 条目。
- **是否跨场景持久存在？** 是——存于全局 `RegistryManager` 自动加载节点。

---

## 4. 条目结构

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | `String`（ResourceLocation） | 是 | — | 唯一 Buff 标识符，例如 `game:buff/bleed_light` |
| `display_name` | `String` | 是 | `""` | HUD/日志显示的可读名称 |
| `stackable` | `bool` | 否 | `false` | 是否允许多个实例叠加 |
| `max_stacks` | `int` | 否 | `1` | `stackable = true` 时的最大叠加层数；`0` = 无限制 |
| `base_duration` | `float` | 否 | `0.0` | 持续时间（秒）；`0.0` = 永久直到主动移除 |
| `damage_per_second` | `float` | 否 | `0.0` | 每秒周期伤害（正值）或治疗（负值），按层数累计 |
| `move_speed_mult` | `float` | 否 | `1.0` | 作用于角色移动速度的倍率 |
| `aim_sway_mult` | `float` | 否 | `1.0` | 作用于角色瞄准晃动的倍率 |
| `interaction_speed_mult` | `float` | 否 | `1.0` | 作用于交互速度的倍率 |
| `tags` | `Array[String]` | 否 | `[]` | 分类标签，例如 `["bleed", "debuff"]` |

### 4.1 运行时结构

**`BuffInstance`**（一个 `BuffDefinition` 的激活应用实例）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `definition` | `BuffDefinition` | 对应注册表条目的引用 |
| `remaining_duration` | `float` | 剩余倒计时（秒）；`-1.0` = 永久 |
| `stack_count` | `int` | 当前叠加层数 |

**`BuffComponent`**（挂载于角色上的节点）：
- 持有以 Buff ID 为键的激活 `BuffInstance` 字典。
- 每帧物理过程调用 `tick(delta)`，推进倒计时、施加周期伤害，并移除已到期的 Buff。
- 每次激活集合变化后，重新计算 `StatusEffectsState` 的各倍率字段。

---

## 5. 校验规则

- `id` 必须为合法的 `ResourceLocation` 字符串（`命名空间:路径`）。
- 重复 ID 静默忽略（先注册者优先）。
- `damage_per_second` 无强制范围限制——负值代表治疗。
- `max_stacks` 必须 `>= 0`；`0` 代表无上限。
- `base_duration` 必须 `>= 0.0`。
- 倍率字段（`move_speed_mult`、`aim_sway_mult`、`interaction_speed_mult`）必须 `> 0.0`；运行时对 `<= 0.0` 的值强制夹取至最小值 `0.01`。

---

## 6. 运行时访问方式

- **查询 API：** `BuffCatalog.get_definition(buff_id: String) -> BuffDefinition`
- **施加 API：** `buff_component.apply_buff(buff_id: String)`
- **移除 API：** `buff_component.remove_buff(buff_id: String)`
- **状态查询 API：** `buff_component.has_buff(buff_id: String) -> bool`
- **典型调用方：** 医疗物品使用处理器、伤害结算、战斗命中效果、HUD 显示。
- **缓存策略：** `RegistryManager` 在首次查询后缓存条目。
- **失败处理：** 未知 Buff ID 时 `push_error(...)` 并返回 `null`。

---

## 7. 编写流程

1. 遵循 `game:buff/<名称>` 规范确定 Buff ID。
2. 创建 `BuffDefinition` 资源（可在编辑器内创建，也可通过 `BuffCatalog` 工厂方法生成）。
3. 将条目注册至 `BuffCatalog._BUILT_IN_FACTORIES`（内置 Buff），或通过 `BuffRegistry.register(rl, def)` 动态注册。
4. 在游戏逻辑代码中调用：`actor.get_node("BuffComponent").apply_buff(BuffCatalog.BLEED_LIGHT)` 施加 Buff。
5. 通过同一 API 治疗并移除：`actor.get_node("BuffComponent").remove_buff(...)`。

---

## 8. 存档 / 迁移说明

- **是否直接保存条目 ID？** 是——存档系统实现后，应将激活 Buff ID 和剩余时长序列化至玩家存档状态中。
- **删除条目后的兼容策略：** 加载时遇到未知 Buff ID 跳过并输出警告，无需返还机制。
- **是否需要版本字段？** 否——当前阶段不需要。

---

## 9. 内置条目

| ID | 显示名称 | 每秒伤害 | 移速倍率 | 瞄准晃动倍率 | 持续时间 | 备注 |
|---|---|---|---|---|---|---|
| `game:buff/bleed_light` | 轻度流血 | 1.0 | 1.0 | 1.0 | 永久 | 使用绷带治疗 |
| `game:buff/bleed_heavy` | 重度流血 | 5.0 | 1.0 | 1.0 | 永久 | 使用止血钳治疗 |
| `game:buff/fracture` | 骨折 | 0.0 | 0.6 | 1.0 | 永久 | 使用夹板治疗 |

---

## 10. 条目示例（GDScript 工厂方法）

```gdscript
static func _make_bleed_light() -> BuffDefinition:
    var d := BuffDefinition.new()
    d.id = "game:buff/bleed_light"
    d.display_name = "轻度流血"
    d.stackable = false
    d.base_duration = 0.0       # 永久
    d.damage_per_second = 1.0
    d.tags = ["bleed", "debuff"]
    return d
```

---

## 11. 相关文件

- `scripts/game/components/gameplay/buff_definition.gd` — 描述 Buff 类型的数据资源。
- `scripts/game/components/gameplay/buff_instance.gd` — 激活 Buff 的运行时实例。
- `scripts/game/components/gameplay/buff_component.gd` — 管理角色上所有激活 Buff 的节点组件。
- `scripts/game/registry/buff_registry.gd` — 注册表实现（继承 `RegistryBase`）。
- `scripts/game/registry/buff_catalog.gd` — 包含内置定义和辅助方法的静态目录类。

---

## 12. 待确认问题

- 多层叠加时，各倍率应使用加法聚合还是乘法聚合？
- HUD 是否需要显示激活 Buff 图标，还是仅体现于属性条的净效果上？
- 是否需要冷却系统（治疗后的短暂 Debuff 免疫）？

---

## 13. 实施检查清单

- [x] 已确认注册表类型名（`buff`）
- [x] 已确认 ResourceLocation 命名规则（`game:buff/<名称>`）
- [x] 已敲定条目结构（`BuffDefinition`）
- [x] 已记录校验规则
- [x] 已记录运行时加载时机
- [x] 已实现运行时组件（`BuffComponent`）
- [x] 已记录存档/迁移行为（延期实现）
- [x] 已评审内置条目（`bleed_light`、`bleed_heavy`、`fracture`）
