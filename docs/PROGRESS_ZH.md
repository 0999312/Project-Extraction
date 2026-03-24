# Project Extraction — 开发进度

## 更新 6 — DemoGame ECS 场景对齐、生物基类重构与文档同步

### 变更内容

- **DemoGame 场景/运行时对齐 GECS 场景内 World 模式**：
  - `demo_game_runtime.gd` 现在绑定 `DemoGame.tscn` 中已有的 `World` 节点，不再运行时创建第二个 World。
  - 系统节点引用改为 `World/Systems/*`，并移除运行时重挂载系统节点的做法。
  - 系统注册改为幂等（仅在缺失时 `add_system`），与 GECS 推荐场景组织一致。
  - 涉及文件：`scenes/game_scene/pe_scene/DemoGame.tscn`、`scripts/ecs/gameplay/demo_game_runtime.gd`。
- **统一玩家/人类敌人/非人类敌人的生物体基类**：
  - 新增 `e_biological_body_base.gd`，作为生物角色共享的 Body↔ECS 桥接基类。
  - 统一封装 ECS 实体注册与 `ECS.world_changed` 延迟注册流程，支持 World 晚于角色创建的时序。
  - `HumanBase` 与 `NonHumanEnemyBody` 统一继承 `BiologicalBodyBase`；玩家/人类敌人/非人类敌人使用同一注册路径。
  - 涉及文件：`e_biological_body_base.gd`、`e_human_base.gd`、`e_player.gd`、`e_human_enemy_body.gd`、`e_non_human_enemy_body.gd`。
- **Demo 场景中体现三类生物实体**：
  - 在 `DemoGame.tscn` 中加入 `HumanEnemyBody` 与 `NonHumanEnemyBody` 实例，使玩家/人类敌人/非人类敌人在同一游戏场景与 ECS 运行流程中可见。
- **音效移除项核查**：
  - 全仓库审计音频资源引用，确认不存在指向已删除音效文件的遗留调用。
  - 当前战斗音频（`handgun_shoot`、`reload`、`mag_empty`）及已注册的游戏音频文件均存在。
- **技术栈文档同步**：
  - 同步更新架构说明，反映当前音频/本地化初始化流与生物体基类场景契约。

---

## 更新 5 — 抛射物精灵碰撞、音频运行时联动、注册表调试输出

### 变更内容

- **抛射物精灵可配置与基于精灵图的碰撞半径**：
  - 为战斗/抛射物数据增加可配置的抛射物精灵路径。
  - 抛射物默认精灵图设为 `res://assets/game/textures/projectiles/bullet.png`。
  - 运行时根据配置精灵图尺寸自动计算抛射物碰撞半径。
  - 抛射物运动系统增加轻量 ECS 碰撞检测：对存活且敌对目标做线段到点距离检测（使用精灵半径）。
  - 涉及文件：`c_combat_state.gd`、`c_projectile_data.gd`、`s_combat_fire_system.gd`、`s_projectile_motion_system.gd`。
- **SoundManager 与现有音频配置联动**：
  - 在音频目录中增加“按注册表获取音频流”和“按注册表播放音乐”辅助方法。
  - Opening 场景现在会基于启动阶段注册表条目自动播放主菜单音乐。
  - LoadingScreen 场景现在会基于游戏阶段注册表条目在进入游戏前自动播放游戏音乐。
  - 菜单 UI 音效控制器已绑定到注册表中的 UI 音频流，菜单聚焦/选中与点击可播放对应音效。
  - 涉及文件：`audio_catalog.gd`、`opening.gd`、`loading_screen.gd`。
- **修复 `Condition \"found\" is true. Returning: Ref()` 相关路径**：
  - 在音频目录辅助方法中，调用 `RegistryManager.get_registry(...)` 前增加注册表存在性防护检查。
  - 注册表解析失败时输出显式错误日志。
  - 涉及文件：`audio_catalog.gd`。
- **注册表加载后调试输出**：
  - 启动阶段/游戏阶段注册后，调试日志会输出注册表键和条目摘要（分类、阶段、路径、文件列表、音频路径列表）。
  - 涉及文件：`audio_catalog.gd`。

---

## 更新 4 — 视频设置配置 & 移除抗锯齿

### 变更内容

- **配置了 `video_options_menu_with_extras`**，使视频设置能正确作用于游戏：
  - 全屏、分辨率、垂直同步设置已通过 `AppConfig` → `AppSettings.set_video_from_config()` 在启动时正确应用，运行时则通过基类 `video_options_menu.gd` 中的信号连接处理器实时生效。
  - 保留了镜头抖动选项（当前隐藏），留待后续功能启用。
- **移除了抗锯齿（MSAA）配置**：项目使用 `gl_compatibility` 渲染器，MSAA 支持有限；已移除该选项及其运行时应用逻辑。
- **修复了视频设置本地化缺失**：
  - 在 `ui_text.en.json` 和 `ui_text.zh.json` 中添加了缺失的 `"V-Sync :"` 翻译键。
  - 添加了垂直同步下拉菜单选项标题翻译：禁用 / 启用 / 自适应 / 三重缓冲。
  - 添加了镜头抖动下拉菜单选项标题翻译：正常 / 减少 / 最低 / 无（预留未来使用）。
  - 移除了已废弃的 `"Anti-Aliasing :"` / `"抗锯齿："` 翻译条目。

### 本次删除内容（更新 4）

| 删除的文件 | 删除原因 |
|---|---|
| `scenes/game_scene/configurable_sub_viewport.gd` (+.uid) | 用于将 MSAA 抗锯齿设置应用到 SubViewport；因项目使用 `gl_compatibility` 渲染器，随抗锯齿选项一并移除 |
| `video_options_menu_with_extras.tscn` 中的 AntiAliasingControl 节点 | 按需求移除抗锯齿 UI 控件 |

---

## 更新 3 — 移除 Bootstrap 自动加载 & 代码清理

### 变更内容

- **移除了 bootstrap 自动加载脚本**，将其职责迁移到游戏流程场景中：
  - `scenes/opening/opening.gd` — 现在负责本地化初始化（加载 i18n JSON 翻译文件、应用已配置的语言）以及启动阶段音频注册。继承自 Maaacks 模板 Opening 场景。
  - `scenes/loading_screen/loading_screen.gd` — 现在在 `_ready()` 中注册游戏阶段音频组，确保音频在游戏场景加载前可用。
  - `scenes/menus/options_menu/game/language_option_control.gd` — 语言切换现在直接调用 `I18NManager` + `PlayerConfig`，不再依赖 `LocalizationBootstrap`。
  - `scripts/ecs/gameplay/demo_game_runtime.gd` — 移除了 `AudioRegistryBootstrap.register_gameplay_audio()` 调用。
  - `scripts/ecs/level_and_state_manager.gd` — 移除了 `AudioRegistryBootstrap.register_gameplay_audio()` 调用。
  - `project.godot` — 移除了 `LocalizationBootstrap` 和 `AudioRegistryBootstrap` 自动加载条目。
- **新增选项菜单标签页本地化**：通过 `localized_options_tab_container.gd` 实现标签页标题翻译。
- **新增中文翻译**：为所有模板菜单字符串添加中文翻译（新游戏、选项、音频/视频标签等），保存在 `resources/i18n/ui_text.zh.json`。
- **战斗音效管道**：射击/换弹/空弹匣音效现在通过 `SoundManager.play_sound()` 正确播放，音频流已缓存。
- **玩家输入处理顺序**：DemoGame 设置 `process_physics_priority = 100`，确保玩家输入在 ECS 系统运行前完成轮询。
- **DEBUG 日志**：为玩家移动、瞄准、射击、换弹、冲刺和射击模式切换添加了 `[DEBUG]` 前缀的全面日志。

### 本次删除内容（更新 3）

| 删除的文件 | 删除原因 |
|---|---|
| `scripts/localization/localization_bootstrap.gd` (+.uid) | 已被 `scenes/opening/opening.gd` 替代 — 本地化初始化移入 opening 场景 |
| `scripts/audio/audio_registry_bootstrap.gd` (+.uid) | 已被 `scenes/opening/opening.gd`（启动音频）和 `scenes/loading_screen/loading_screen.gd`（游戏音频）替代 |
| `scenes/menus/options_menu/mini_options_menu.tscn` | 未被引用的选项菜单变体；当前流程使用 `master_options_menu_with_tabs.tscn` |
| `scenes/menus/options_menu/input/input_options_menu.tscn` | 已被 `guide_input_options_menu.tscn`（GUIDE 按键绑定表格）取代 |
| `scenes/menus/options_menu/input/input_options_menu_with_mouse_sensitivity.tscn` | 已被 `guide_input_options_menu.tscn` + `input_extras_menu.tscn` 取代 |
| `scenes/menus/options_menu/input/input_icon_mapper.tscn` | 仅被已删除的 `input_options_menu.tscn` 引用 |
| `scenes/menus/options_menu/video/video_options_menu.tscn` | 已被 `video_options_menu_with_extras.tscn` 取代 |
| `scenes/game_scene/input_display_label.gd` (+.uid) | 未被引用的模板遗留文件 — 无运行时或场景使用 |
| `scenes/game_scene/tutorial_manager.gd` (+.uid) | 未被引用的模板遗留文件 — 无运行时或场景使用 |
| `scenes/game_scene/tutorials/tutorial_1.tscn` | 未被引用的模板教程 — 不属于当前游戏流程 |
| `scenes/game_scene/tutorials/tutorial_2.tscn` | 未被引用的模板教程 — 不属于当前游戏流程 |
| `scenes/game_scene/tutorials/tutorial_3.tscn` | 未被引用的模板教程 — 不属于当前游戏流程 |

---

## 更新 2 — 战斗、输入与音频系统

### 变更内容

- 实现射击系统扩展（瞄准/射击/换弹工作流）：
  - 弹丸生成支持多弹丸射击和武器化弹丸属性
  - 新增射击模式模型（`SAFE/SEMI/AUTO`）和运行时模式切换
  - 新增玩家换弹输入和换弹处理状态
  - 新增非玩家空弹匣自动换弹行为
  - 新增空弹匣提示音效播放
  - 文件：`s_combat_fire_system.gd`、`c_combat_state.gd`、`player_input_context.gd`、`e_player.gd`
- 实现弹丸距离衰减和基于距离的过期机制：
  - `c_projectile_data.gd`、`s_projectile_motion_system.gd`
- 新增瞄准镜头跟随偏移（ADS 时准星跟随风格）：
  - `demo_game_runtime.gd`
- 扩展输入/按键绑定/国际化以支持战斗控制：
  - 新增换弹和切换射击模式操作到输入上下文和按键绑定表
  - 更新 `ui_text.en.json`、`ui_text.zh.json`
- 更新 API 文档（射击/换弹/射击模式/衰减/镜头行为）
- 将本地化引导从音频注册引导中解耦：
  - 新增 `localization_bootstrap.gd`（后在更新 3 中移除）
- 新增基于文件夹+文件名的音频注册配置：
  - `audio_catalog.gd`、`audio_registry_bootstrap.gd`
- 新增游戏核心选项中的语言选择：
  - `language_option_control.gd`、`language_option_control.tscn` → `game_options_menu.tscn`
- 重构按键绑定菜单为表格格式：
  - 列按输入方式分类（键盘 / 鼠标 / 手柄），行按具体操作分类
  - `guide_input_options_menu.gd`
- 将 ECS 相关游戏代码移至 `scripts/ecs` 并更新场景脚本路径
- 新增 GUIDE 驱动的玩家输入上下文和运行时重映射持久化：
  - `player_input_context.gd`、`guide_input_runtime.gd`
- 新增 GUIDE 按键绑定选项面板：
  - `guide_input_options_menu.tscn`、`guide_input_options_menu.gd`、`master_options_menu_with_tabs.tscn`
- 实现玩家操作系统基础流程（移动/瞄准/射击输入接入）：
  - `e_player.gd`
- 实现瞄准 + 射击系统（含后坐力和腰射/ADS 精度差异）：
  - `s_combat_fire_system.gd`、`s_projectile_motion_system.gd`、`e_base_projectile.gd`
  - `c_combat_state.gd`、`c_projectile_data.gd`、`c_aim_state.gd`
- 新增 Demo 运行时 ECS 世界引导和系统处理：
  - `demo_game_runtime.gd`、`DemoGame.tscn`
- 新增轻量级游戏全局阶段状态：
  - `game_state.gd`、`level_and_state_manager.gd`

### 本次删除内容（更新 2）

| 删除的文件 | 删除原因 |
|---|---|
| `scenes/menus/options_menu/mini_options_menu_with_reset.gd` (+.uid, +.tscn) | 未使用的重复菜单变体 |
| `scripts/items/base_item.gd` (+.uid) | 未使用的基础脚本，无任何引用 |

---

## 待完成工作

- 全局状态机重新设计（覆盖所有游戏流程和菜单）。
- 完善弹丸命中检测和伤害应用管道。
- 完整的敌人 AI 瞄准/射击集成。
- 背包 / 物品系统实现。
- 完整的关卡推进流程集成。
