# 实体注册表

## 1. 注册表概览

- **注册表名称：** `entity`
- **业务目标：** 集中管理所有运行时角色（玩家、人类敌人、非人类敌人）的定义与实例化，使玩法代码无需硬编码场景路径。
- **主要负责人：** 玩法运行时
- **关联内容范围：** 玩家生成、敌人生成、Demo 场景初始化

## 2. ResourceLocation 规则

- **条目命名空间：** `game`
- **条目 ID 命名规范：** `game:entity/<entity_name>`（例如 `game:entity/player`）
- **所需标签命名规范：** 无
- **跨注册表引用：** 实体的战斗状态通过 `projectile_definition_id` 引用 **projectile** 注册表中的抛射物定义（例如 `game:projectile/bullet`）

## 3. 加载时机与生命周期

- **何时创建注册表？** 在游戏加载时，首次调用 `EntityCatalog.ensure_registry()` 时创建（通常由 `DemoGameRuntime` 触发）。
- **何时注册条目？** 在 `EntityCatalog.ensure_registry()` 执行期间，将 `ENTITY_DEFINITIONS` 中的所有条目注册（如未存在）。
- **是否允许运行时扩展？** 是 — 初始批次注册后，可通过 `EntityRegistry.register(...)` 注册额外条目。
- **是否跨场景持久存在？** 是 — 注册表存储在全局 `RegistryManager` 自动加载节点中，跨场景切换不丢失。

## 4. 条目结构

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `scene_path` | `String` | 是 | — | 实体 `.tscn` 场景文件的完整 `res://` 路径。必须是有效的 `PackedScene`。 |
| `class_name` | `String` | 否 | `""` | 人类可读的类名，用于调试/日志输出。不用于实例化。 |

## 5. 校验规则

- 条目必须为 `Dictionary`，且包含非空 `scene_path` 字段。
- `scene_path` 在实例化时必须指向一个存在的 `PackedScene` 资源。
- 重复的 `ResourceLocation` ID 会被静默跳过（先注册者优先）。

## 6. 运行时访问方式

- **查询 API：** `EntityCatalog.get_entity_definition(entity_id)` 返回定义字典的副本。
- **实例化 API：** `EntityCatalog.instantiate_entity(entity_id, node_name)` 加载对应 PackedScene 并返回新节点实例。
- **典型调用方：** `DemoGameRuntime`（角色生成）、未来的关卡生成系统。
- **缓存策略：** 场景资源通过 `ResourceLoader` 加载，其内部自行管理缓存。
- **失败处理：** 场景缺失或定义无效时，输出 `push_error(...)` 日志并返回 `null`。

## 7. 编写流程

1. 在 `scenes/entities/` 下创建实体场景（`.tscn`）并附加对应 GDScript。
2. 在 `EntityCatalog.ENTITY_DEFINITIONS` 中添加新的常量与定义条目。
3. 条目会在 `EntityCatalog.ensure_registry()` 运行时自动注册。
4. 通过 `EntityCatalog.instantiate_entity(EntityCatalog.NEW_ENTITY_ID)` 实例化。

## 8. 存档 / 迁移说明

- **是否直接保存条目 ID？** 目前不保存 — 存档系统尚未实现。
- **删除条目后的兼容策略：** 待存档系统设计后确定。
- **是否需要版本字段？** 否 — 当前阶段不需要。

## 9. 当前条目

| ID | 场景路径 | 类名 |
|---|---|---|
| `game:entity/player` | `res://scenes/entities/player.tscn` | `Player` |
| `game:entity/human_enemy` | `res://scenes/entities/human_enemy.tscn` | `HumanEnemy` |
| `game:entity/non_human_enemy` | `res://scenes/entities/non_human_enemy.tscn` | `NonHumanEnemy` |

## 10. 示例条目

```json
{
  "scene_path": "res://scenes/entities/player.tscn",
  "class_name": "Player"
}
```

## 11. 源文件

- `scripts/game/registry/entity_registry.gd` — 注册表实现（继承 `RegistryBase`）。
- `scripts/game/registry/entity_catalog.gd` — 静态目录，包含定义常量和辅助方法。

## 12. 实施检查清单

- [x] 已确认注册表类型名（`entity`）
- [x] 已确认 ResourceLocation 命名规则（`game:entity/<name>`）
- [x] 已敲定条目结构
- [x] 已记录校验规则
- [x] 已记录运行时加载时机
- [x] 已记录存档/迁移行为（延后处理）
- [x] 已评审示例条目
