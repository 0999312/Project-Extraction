# Project Extraction — 开发进度

## 更新 12 — 准星放松态隐藏、ADS 自由鼠标跟随、ADS 暗角蒙版与 UI 按钮音效修正

### 变更内容

- **准星放松状态改为隐藏节点，不再切换纹理**：
  - 放松（暂停 / UI）状态下将准星 `visible` 设为 `false`。
  - 移除了 `mouse.png` 纹理切换；暂停菜单启用系统光标时由系统光标接管显示。
- **ADS 时准星自由跟随鼠标**：
  - 移除了准星位置的 `ads_distance` 限制；无论腰射还是 ADS，准星始终跟随鼠标。
  - 新增不可见的 `CameraAimTarget` 节点，其位置受 `CombatState.ads_distance` 约束。
  - ADS 时 phantom-camera 跟随目标切换为 `CameraAimTarget`（而非准星），使镜头受距离限制但准星不受限。
- **新增 ADS 暗角蒙版效果**：
  - 新增 `AdsVignetteOverlay`（CanvasLayer），使用 Shader 驱动的全屏 `ColorRect`。
  - 一个透明圆形区域（默认半径 32 px，与 64 × 64 准星精灵匹配）随准星屏幕位置移动。
  - 圆形外区域变暗（默认 50 % 黑色）；可通过 `enabled`、`radius_px`、`darkness`、`softness_px` 属性配置。
  - 效果默认开启，ADS 时自动激活。
  - Shader 文件：`resources/shaders/ads_vignette.gdshader`。
- **UI 按钮点击改为播放 `select.mp3`，不再播放 `click.mp3`**：
  - `opening.gd` 将 `button_pressed_player` 绑定到 `select.mp3`，与 `button_focused_player` 一致。
  - `cancel.mp3` 仍在音频目录中注册为占位项；注册表内容未更改。
- **同步更新文档以匹配新的准星/镜头/蒙版/音频行为**。

---

## 更新 11 — 准星节点、放松态鼠标与 ADS 镜头跟随目标切换

### 变更内容

- **新增运行时鼠标/准星节点与三种视觉状态**：
  - 放松状态（UI 交互）：`assets/game/textures/ui/mouse.png`
  - 腰射状态：`assets/game/textures/ui/crosshair_normal.png`
  - ADS 瞄准状态：`assets/game/textures/ui/crosshair_aiming.png`
- **按状态应用原点/居中规则**：
  - 放松态鼠标精灵不居中（左上角原点）
  - 腰射 / ADS 准星精灵居中
- **重写 ADS 相关镜头跟随逻辑**：
  - ADS 时将 phantom-camera 跟随目标从玩家切换为准星。
  - ADS 准星位置受 `CombatState.ads_distance` 限制，超出范围后镜头不再继续向外跟随。
  - 退出 ADS（进入腰射）后跟随目标切回玩家。
- **新增“瞄准时间”枪械属性用于平滑切换**：
  - 新增 `CombatState.aim_transition_sec`。
  - 镜头跟随目标切换的平滑时长通过该参数驱动 phantom-camera damping。
- **同步更新文档以匹配新的准星/镜头运行时行为**。

---

## 更新 10 — 运行时命名清理、实体注册表与抛射物注册表

### 变更内容

- **移除了当前玩法运行时里最明显的 ECS 时代命名痕迹**：
  - 将 `C_*` 风格的运行时状态/资源统一整理为中性命名，例如 `CombatState`、`ProjectileData`、`HealthState`、`FactionState`、`AIState`。
  - 将 `S_*` 风格的处理器整理为 `CombatFireRuntime` 与 `ProjectileMotionRuntime`。
  - 将 `e_*` 风格的实体/抛射物脚本与场景定义整理为 `player.gd`、`human_enemy.gd`、`non_human_enemy.gd`、`projectile.gd`、`player.tscn` 等形式。
- **为运行时角色定义与实例化新增实体注册表**：
  - 新增 `EntityRegistry` 与 `EntityCatalog`，注册当前实体定义（`player`、`human_enemy`、`non_human_enemy`）。
  - 调整 `DemoGame`，改为通过实体注册表实例化运行时角色，而不是在 `DemoGame.tscn` 中直接摆放角色场景实例。
- **为抛射物定义与射击流程新增抛射物注册表**：
  - 新增 `ProjectileRegistry` 与 `ProjectileCatalog`，注册标准子弹与生物抛射物等定义。
  - 将射击流程改为通过 `ProjectileCatalog.instantiate_projectile(...)` 生成抛射物。
  - 将 `CombatState` 中原本分散的抛射物数值改为 `projectile_definition_id` 形式，通过定义表寻址。
- **同步更新文档以匹配注册表化后的运行时流程**：
  - 更新 API / 架构 / 进度文档，使其与新的命名、实体注册表、抛射物注册表和运行时实例化流程保持一致。

---

## 更新 9 — 脚本目录整理、运行时辅助复用与文档同步

### 变更内容

- **按去 ECS 后的实际架构整理运行时脚本目录**：
  - 将已经不再准确的 `scripts/ecs/` 目录整体重命名为 `scripts/game/`，使目录结构与当前基于节点的玩法运行时保持一致。
  - 同步更新场景与脚本中的运行时路径引用。
- **对当前可安全优化的代码设计做了低风险整理**：
  - 将重复出现的角色移动与目标解析辅助逻辑下沉到 `BiologicalActor`。
  - 在 `guide_input_runtime.gd` 中补充可复用的 GUIDE 输入查询辅助方法。
  - 简化 `Player`、敌人身体脚本、Demo 运行时暂停输入轮询，以及 GUIDE 输入选项菜单中的重复逻辑。
- **同步整理文档**：
  - 更新架构/API/进度说明，使文档中的脚本结构与辅助职责描述和当前代码状态保持一致。

---

## 更新 8 — 节点驱动运行时重写、插件移除与文档整理

### 变更内容

- **在不依赖 ECS 运行时的前提下重建了当前可玩的 DemoGame 流程**：
  - 重写了玩家、生物角色基类、人类敌人、非人类敌人、抛射物、战斗处理和抛射物处理脚本，改为由节点自身持有运行时状态，而不是依赖 World / Entity / System 框架。
  - `DemoGame.tscn` 不再依赖 `World`、`World/Systems/*` 或 GECS 运行时节点。
- **保留菜单、加载、输入、镜头和音频适配流程**：
  - 保持 GUIDE 输入轮询、暂停菜单流程、phantom-camera 瞄准偏移和音频播放与新运行时兼容。
  - 调整调试菜单中的运行时计数逻辑，改为显示角色/抛射物数量，而不是查询 ECS World。
- **移除了不再使用的插件及项目配置**：
  - 移除 `addons/gecs` 及其在项目配置和编辑器插件列表中的引用。
  - 移除 `addons/gdUnit4` 及其在项目配置和编辑器插件列表中的引用。
- **同步整理文档**：
  - 更新进度/API/架构说明，使文档中的运行时描述与插件移除后的当前代码状态一致。

---

## 更新 7 — 文档重规划、音频注册表文档补充，以及正式放弃 ECS 架构

### 变更内容

- **当前文档方向已统一为场景/节点 + 数据驱动运行时**：
  - 重新整理设计与架构文档，改为描述玩家、敌人、抛射物、容器、门锁和交易终端的场景化实现方案，不再依赖框架绑定的实体模拟方案。
  - 进度记录中正式确认：当前项目方案将放弃此前的 ECS 架构方向。
- **新增音频注册表参考文档**：
  - 新增当前音频注册表说明文档，记录注册表结构、加载阶段、分类以及运行时注册流程。
  - 新增可复用的注册表设计文档模板，用于后续物品 / POI / 战利品 / 商人 / 家园系统等注册表规划。
- **同步核心文档**：
  - 更新 GDD、技术栈说明和 API 概览，使其与当前场景驱动运行时和内容注册表工作流保持一致。

---

## 更新 6 — DemoGame 运行时对齐、生物体基类重构与文档同步

### 变更内容

- **DemoGame 场景/运行时对齐**：
  - `demo_game_runtime.gd` 现在复用 `DemoGame.tscn` 中现有的运行时节点，不再在进入场景时复制额外处理分支。
  - 运行时引用保持在场景树内部，并且重复进入同一场景时初始化行为保持幂等。
  - 涉及文件：`DemoGame.tscn`、`demo_game_runtime.gd`。
- **统一玩家 / 人类敌人 / 非人类敌人的生物体基类**：
  - 新增 `biological_actor.gd`，作为生物角色共享的初始化基类。
  - 统一封装延迟运行时挂接与共享初始化流程，使玩家 / 人类敌人 / 非人类敌人的身体脚本走同一套初始化路径。
  - 涉及文件：`biological_actor.gd`、`human_actor.gd`、`player.gd`、`human_enemy.gd`、`non_human_enemy.gd`。
- **Demo 场景中体现三类生物角色**：
  - 在 `DemoGame.tscn` 中加入 `HumanEnemy` 与 `NonHumanEnemy` 实例，使玩家 / 人类敌人 / 非人类敌人都能在同一可玩场景流程中出现。
- **音效移除项核查**：
  - 全仓库审计音频资源引用，确认不存在指向已删除音效文件的遗留调用。
  - 当前战斗音频（`handgun_shoot`、`reload`、`mag_empty`）及已注册的游戏音频文件均存在。
- **技术栈文档同步**：
  - 同步更新架构说明，反映当前音频/本地化初始化流程与生物体基类场景契约。

---

## 更新 5 — 抛射物精灵碰撞、音频运行时联动、注册表调试输出

### 变更内容

- **抛射物精灵可配置与基于精灵图的碰撞半径**：
  - 为战斗/抛射物数据增加可配置的抛射物精灵路径。
  - 抛射物默认精灵图设为 `res://assets/game/textures/projectiles/bullet.png`。
  - 运行时根据配置精灵图尺寸自动计算抛射物碰撞半径。
  - 抛射物运动流程现在会基于精灵半径，对存活且敌对的目标执行轻量级运行时碰撞检测。
  - 涉及文件：`combat_state.gd`、`projectile_data.gd`、`combat_fire_runtime.gd`、`projectile_motion_runtime.gd`。
- **SoundManager 与现有音频配置联动**：
  - 在音频目录中增加“按注册表获取音频流”和“按注册表播放音乐”辅助方法。
  - Opening 场景现在会基于启动阶段注册表条目自动播放主菜单音乐。
  - LoadingScreen 场景现在会基于游戏阶段注册表条目在进入游戏前自动播放游戏音乐。
  - 菜单 UI 音效控制器已绑定到注册表中的 UI 音频流，菜单聚焦/选中与点击可播放对应音效。
  - 涉及文件：`audio_catalog.gd`、`opening.gd`、`loading_screen.gd`。
- **修复 `Condition "found" is true. Returning: Ref()` 相关路径**：
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
  - `demo_game_runtime.gd` — 移除了旧的游戏音频注册引导调用。
  - `level_and_state_manager.gd` — 移除了旧的游戏音频注册引导调用。
  - `project.godot` — 移除了 `LocalizationBootstrap` 和 `AudioRegistryBootstrap` 自动加载条目。
- **新增选项菜单标签页本地化**：通过 `localized_options_tab_container.gd` 实现标签页标题翻译。
- **新增中文翻译**：为所有模板菜单字符串添加中文翻译（新游戏、选项、音频/视频标签等），保存在 `resources/i18n/ui_text.zh.json`。
- **战斗音效管道**：射击/换弹/空弹匣音效现在通过 `SoundManager.play_sound()` 正确播放，音频流已缓存。
- **玩家输入处理顺序**：DemoGame 设置 `process_physics_priority = 100`，确保玩家输入在每次物理帧的游戏处理之前完成轮询。
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
  - 弹丸生成支持多弹丸射击和武器化弹丸属性。
  - 新增射击模式模型（`SAFE/SEMI/AUTO`）和运行时模式切换。
  - 新增玩家换弹输入和换弹处理状态。
  - 新增非玩家空弹匣自动换弹行为。
  - 新增空弹匣提示音效播放。
  - 文件：`combat_fire_runtime.gd`、`combat_state.gd`、`player_input_context.gd`、`player.gd`。
- 实现弹丸距离衰减和基于距离的过期机制：
  - `projectile_data.gd`、`projectile_motion_runtime.gd`。
- 新增瞄准镜头跟随偏移（ADS 时准星跟随风格）：
  - `demo_game_runtime.gd`。
- 扩展输入/按键绑定/国际化以支持战斗控制：
  - 新增换弹和切换射击模式操作到输入上下文和按键绑定表。
  - 更新 `ui_text.en.json`、`ui_text.zh.json`。
- 更新 API 文档（射击/换弹/射击模式/衰减/镜头行为）。
- 将本地化引导从音频注册引导中解耦：
  - 新增 `localization_bootstrap.gd`（后在更新 3 中移除）。
- 新增基于文件夹+文件名的音频注册配置：
  - `audio_catalog.gd`、`audio_registry_bootstrap.gd`。
- 新增游戏核心选项中的语言选择：
  - `language_option_control.gd`、`language_option_control.tscn` → `game_options_menu.tscn`。
- 重构按键绑定菜单为表格格式：
  - 列按输入方式分类（键盘 / 鼠标 / 手柄），行按具体操作分类。
  - `guide_input_options_menu.gd`。
- 将游戏运行时脚本迁移到专用目录，并更新场景脚本路径。
- 新增 GUIDE 驱动的玩家输入上下文和运行时重映射持久化：
  - `player_input_context.gd`、`guide_input_runtime.gd`。
- 新增 GUIDE 按键绑定选项面板：
  - `guide_input_options_menu.tscn`、`guide_input_options_menu.gd`、`master_options_menu_with_tabs.tscn`。
- 实现玩家操作流程（移动 / 瞄准 / 射击）：
  - `player.gd`。
- 实现瞄准 + 射击处理流程（含后坐力和腰射/ADS 精度差异）：
  - `combat_fire_runtime.gd`、`projectile_motion_runtime.gd`、`projectile.gd`。
  - `combat_state.gd`、`projectile_data.gd`、`aim_state.gd`。
- 新增 Demo 游戏处理引导和逐帧运行流程：
  - `demo_game_runtime.gd`、`DemoGame.tscn`。
- 新增轻量级游戏全局阶段状态：
  - `game_state.gd`、`level_and_state_manager.gd`。

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
