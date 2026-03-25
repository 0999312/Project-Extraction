# 碰撞层设计文档

## 1. 目标

统一当前运行时的碰撞层语义，覆盖以下约束：

1. 所有实体都具备受击碰撞层。
2. 人类（玩家 + 人类敌人）具备地面碰撞层。
3. 非人类敌人在空中时具备空中碰撞层。
4. Tile 可分别配置地面碰撞和空中碰撞（可同时存在）。
5. 子弹定义为空中碰撞层，并使用空中碰撞规则筛选命中目标。

## 2. 层位分配

实现说明：当前碰撞常量按需直接定义在使用处（例如 `scripts/game/components/combat/projectile_data.gd`）。

| 位索引（1-based） | 常量 | 含义 |
|---|---|---|
| 1 | `ENTITY_HIT` | 实体受击层 |
| 2 | `ENTITY_GROUND` | 实体地面层 |
| 3 | `ENTITY_AIR` | 实体空中层 |
| 4 | `TILE_GROUND` | Tile 地面层 |
| 5 | `TILE_AIR` | Tile 空中层 |
| 6 | `PROJECTILE_AIR` | 子弹（空中）层 |

## 3. 实体配置

### 3.1 玩家 / 人类敌人

- 场景：
  - `scenes/entities/player.tscn`
  - `scenes/entities/human_enemy.tscn`
- 根节点 `CharacterBody2D`：
  - `collision_layer = ENTITY_HIT | ENTITY_GROUND`
  - `collision_mask = TILE_GROUND | ENTITY_GROUND | ENTITY_AIR`

说明：人类只与地面 Tile 交互，不参与空中 Tile 碰撞。

### 3.2 非人类敌人

- 场景：`scenes/entities/non_human_enemy.tscn`
- 根节点 `CharacterBody2D`：
  - `collision_layer = ENTITY_HIT | ENTITY_AIR`
  - `collision_mask = TILE_AIR | ENTITY_GROUND | ENTITY_AIR`

说明：非人类敌人按“空中实体”参与碰撞，同时仍可与其他实体层交互。

## 4. Tile 层配置

- 场景：`scenes/game_scene/pe_scene/DemoGame.tscn`
- `ground` (`TileMapLayer`)：
  - `collision_enabled = true`
  - `collision_layer = TILE_GROUND`
- `TileMapLayer` (`TileMapLayer`)：
  - `collision_enabled = true`
  - `collision_layer = TILE_AIR`

说明：地面与空中 Tile 使用不同图层，支持同一关卡同时存在两类碰撞。

## 5. 子弹（空中碰撞）配置

- 数据：`scripts/game/components/combat/projectile_data.gd`
  - `collision_layer = PROJECTILE_AIR`
  - `collision_mask = ENTITY_HIT | TILE_AIR`

当前子弹命中逻辑由 `ProjectileMotionRuntime` 执行轻量运行时检测，不直接依赖 Godot 物理体碰撞回调；上述层定义用于统一语义和后续扩展（例如切换到物理查询或混合查询）。

## 6. 设计约束与扩展建议

1. 新增人类实体时，默认加入 `ENTITY_HIT | ENTITY_GROUND`。
2. 新增飞行敌人时，默认加入 `ENTITY_HIT | ENTITY_AIR`。
3. 需要“同时阻挡地面与空中”的 Tile，可在两个 `TileMapLayer` 中各放置一份，或后续扩展为同层多碰撞配置。
4. 子弹若需要地面拦截（例如低空弹体），可将 `TILE_GROUND` 加入子弹 mask。
