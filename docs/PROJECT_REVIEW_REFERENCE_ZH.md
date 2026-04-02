# 项目人工审查参考

> 用于人工审查整个项目的最简参考文档。

## 1. 审查顺序

1. 项目配置与插件集成
2. 注册表数据与内容定义
3. 核心玩法状态与运行时逻辑
4. 实体、场景与流程
5. UI、输入与本地化
6. 现有文档一致性

## 2. 审查内容范围

| 步骤 | 区域 | 审查内容 | 关键路径 |
|---|---|---|---|
| 1 | 配置层 | 确认启动场景、自动加载、启用插件、输入动作、全局主题是否正确。 | `project.godot`, `override.cfg`, `addons/` |
| 2 | 注册表数据 | 检查物品、武器、抛射物、Buff、实体、标签定义是否完整，ID 是否与运行时使用保持一致。 | `resources/registries/`, `scripts/game/registry/`, `addons/mc_game_framework/` |
| 3 | 玩法系统 | 审查战斗、移动、背包、装备、AI、玩家状态逻辑是否正确，是否存在耦合过深或缺失边界情况。 | `scripts/game/components/`, `scripts/game/systems/`, `scripts/game/projectiles/` |
| 4 | 运行时流程 | 核对场景加载、玩家/敌人初始化、关卡/状态切换、运行时编排是否一致。 | `scripts/game/gameplay/`, `scripts/game/entities/`, `scenes/game_scene/`, `prefabs/entity/` |
| 5 | UI / 本地化 | 审查 HUD、物品栏、暂停/菜单流程、输入映射，以及中英文文本一致性。 | `scripts/game/ui/`, `scenes/`, `resources/i18n/` |
| 6 | 文档 | 检查设计文档与进度文档是否和当前实现一致，双语文档是否成对维护。 | `docs/` |

## 3. 最简输出要求

每一步仅记录：

- **状态：** 通过 / 有问题 / 需跟进
- **主要发现：** 最多 3 条
- **处理动作：** 立即修复 / 延后 / 需澄清需求
