# 手持物渲染设计

## 1. 范围

- 定义人形角色如何解析并显示 `AimPivot/Item/ItemPivot/ItemSprite` 上的手持物贴图。
- 通过独立的 ID 映射层，将渲染数据与物品/武器注册表解耦。
- 适用于玩家与人形敌人；非人形敌人继续使用各自场景内视觉表现。

## 2. 渲染配置资源

- **资源类型：** `HeldItemRenderConfig`
- **资源目录：** `res://resources/registries/held_item_render_configs/`
- **当前字段：**
  - `id` —— 渲染配置 RL
  - `sprite_path` —— Sprite 贴图路径
  - `sprite_offset` —— `ItemSprite` 本地偏移
  - `sprite_scale` —— `ItemSprite` 本地缩放
  - `sprite_rotation_deg` —— `ItemSprite` 本地旋转角度

## 3. 映射表

- **当前实现选择：** JSON
- **映射文件：** `res://resources/registries/held_item_render_configs/held_item_render_mappings.json`
- **Key 格式：** 注册表 key / `ResourceLocation` 字符串
- **支持两层映射：**
  - `weapon_render_configs`：`武器 RL -> 渲染配置 RL`
  - `item_render_configs`：`物品 RL -> 渲染配置 RL`
- **默认回退：** `default_render_config_id`

设计层面仍保留“JSON 或 Dictionary Resource 二选一”的自由度；当前实现选择 JSON，并统一使用 RL 字符串作为 key。

## 4. 解析优先级

1. 先按武器 RL 解析。
2. 未命中则按物品 RL 解析。
3. 仍未命中则使用默认渲染配置。
4. 若最终配置引用的 Sprite 贴图不可用，则回退到默认渲染配置贴图。

## 5. 运行时责任边界

- `HeldItemRenderCatalog` 负责加载渲染配置与解析映射。
- `HumanActor` 负责把解析后的渲染配置应用到手持物 Sprite。
- `DemoGameRuntime` 负责在没有可用枪械时于上层短路 fire 请求。
- `CombatFireRuntime` **不**负责“无枪械短路”判断，只处理已通过上层筛选的有效发射请求。

## 6. 缺失资源规则

- 在该流程中，“材质资源缺失”与“贴图缺失”统一视为同一问题：
  - **Sprite 缺失贴图**
- 当手持物渲染配置引用了缺失贴图时，运行时与校验流程都回退到默认渲染配置。

## 7. 相关文件

- `scripts/game/components/rendering/held_item_render_config.gd`
- `scripts/game/registry/held_item_render_catalog.gd`
- `resources/registries/held_item_render_configs/*.tres`
- `resources/registries/held_item_render_configs/held_item_render_mappings.json`
- `scripts/game/entities/gameplay/human_actor.gd`
- `scripts/game/gameplay/demo_game_runtime.gd`
