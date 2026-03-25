# 实体注册表说明

## 1. 目的

实体注册表用于集中定义“实体 ID -> 场景资源”的映射，统一玩家与敌人的实例化入口，避免在运行时脚本中硬编码场景路径。

## 2. 相关文件

- `scripts/game/registry/entity_registry.gd`
- `scripts/game/registry/entity_catalog.gd`
- `scripts/game/gameplay/demo_game_runtime.gd`

## 3. 注册表类型与键格式

- 注册表类型名：`entity`
- 注册表实现：`EntityRegistry`
- 命名空间：`game`
- ResourceLocation 形式：`game:entity/<name>`

当前实体键：

- `game:entity/player`
- `game:entity/human_enemy`
- `game:entity/non_human_enemy`

## 4. 条目结构

每个条目为 `Dictionary`，当前字段如下：

| 字段 | 类型 | 必填 | 含义 |
|---|---|---|---|
| `scene_path` | `String` | 是 | 实体场景路径 (`PackedScene`) |
| `class_name` | `String` | 否 | 预期脚本类名（用于文档与调试） |

示例：

```json
{
  "scene_path": "res://scenes/entities/player.tscn",
  "class_name": "Player"
}
```

## 5. 加载时机与生命周期

`EntityCatalog.ensure_registry()` 负责：

1. 若不存在 `entity` 注册表，创建并注册 `EntityRegistry`。
2. 将 `ENTITY_DEFINITIONS` 中声明的实体条目写入注册表（避免重复注册）。

调用位置：

- `DemoGameRuntime._ready()` 在运行时生成实体之前调用。

注册表由 `RegistryManager` 管理，跨场景可复用（在应用生命周期内持久）。

## 6. 运行时访问方式

### 6.1 查询定义

- `EntityCatalog.get_entity_definition(entity_id: String) -> Dictionary`

### 6.2 实例化实体

- `EntityCatalog.instantiate_entity(entity_id: String, node_name: String = "") -> Node`

行为：

1. 根据 `entity_id` 取定义。
2. 校验 `scene_path` 是否存在。
3. 加载 `PackedScene` 并实例化。
4. 可选覆盖节点名。

## 7. 校验与失败处理

`EntityRegistry._validate_entry(entry)` 当前规则：

- 条目必须为 `Dictionary`
- `scene_path` 不可为空

失败处理：

- 目录层使用 `push_error(...)` 记录错误并返回 `null` / 空字典。

## 8. 当前工作流

1. 在 `EntityCatalog.ENTITY_DEFINITIONS` 中新增或修改实体定义。
2. 运行时通过 `EntityCatalog.instantiate_entity(...)` 消费。
3. 场景脚本（如 DemoGame）只依赖实体 ID，不直接硬编码场景路径。

## 9. 存档与迁移建议

- 存档中建议保存 `entity_id`（ResourceLocation 字符串），避免直接保存场景路径。
- 删除实体条目时，应提供回退实体或迁移映射，避免旧存档无法加载。

## 10. 实施检查清单

- [x] 已确认注册表类型名（`entity`）
- [x] 已确认 ResourceLocation 命名规则
- [x] 已记录条目结构
- [x] 已记录校验规则
- [x] 已记录运行时加载时机
- [x] 已记录运行时访问 API
