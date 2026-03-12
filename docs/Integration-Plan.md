# Integration Plan
> 项目：2D 俯视角撤离射击游戏  
> 引擎：Godot 4.x  
> 当前日期：2026-03-12

---

# 1. 文档目标

本文档定义项目在启动阶段的外部模板/插件集成方案、模块职责边界、工程接入顺序、兼容策略与实施原则，用于指导项目从“可运行工程壳”快速演进到“可持续扩展的玩法项目”。

本文档的核心目标：

- 明确各第三方项目在本工程中的职责
- 避免多个插件之间的能力重叠与架构冲突
- 给出统一的集成顺序与适配层方案
- 为后续战斗、背包、任务、交易、科技、农业、自动化等系统开发提供稳定底座

---

# 2. 集成范围

本计划覆盖以下外部项目/插件：

## 2.1 已确定使用
- `Maaack/Godot-Game-Template`
- `0999312/Minecraft-Style-Framework`
- `godotneers/G.U.I.D.E`
- `ramokz/phantom-camera`

## 2.2 经检索后纳入方案设计
- 音频管理：Maaack 模板自带能力为主，`Godautdio` 作为增强候选。Maaack 模板明确包含 UI Sound Controller 与 Background Music Controller。Godautdio 为 Godot 4.0+ 简化音频管理插件。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))
- 场景切换与加载：Maaack Scene Loader 为主，`YASM` 作为增强候选。Maaack 模板明确包含 loading screen 与 scene loader；YASM 支持 Godot 4 的异步场景加载与 transition 控制。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

---

# 3. 选型结论

## 3.1 最终组合

### 3.1.1 Maaack/Godot-Game-Template
作为项目基础壳，负责：
- 主菜单
- 设置界面
- 暂停界面
- 场景基础切换与 loading screen
- 持久化设置
- 键鼠/手柄基础支持
- UI 音效与背景音乐基础控制

Maaack 的模板说明其可用于 Godot 4.5，且兼容 4.3+，并提供 main menu、options、pause、loading、scene loader、persistent settings、gamepad support、UI sound controller、background music controller。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

### 3.1.2 0999312/Minecraft-Style-Framework
作为内容系统核心，负责：
- 注册表系统
- 数据驱动内容定义
- item/entity/scene/quest/tech/recipe 等定义与查询
- 内容按大类注册、按标签细分

> 注：本项目仅基于你提供的仓库描述进行方案设计，不假设具体 API 名称。

### 3.1.3 godotneers/G.U.I.D.E
作为统一输入层，负责：
- keyboard / mouse / gamepad / touch 的统一输入处理
- 多输入上下文切换
- 输入重绑定
- 输入提示与图标
- 输入冲突处理与设备检测

Godot Asset Library 公开说明中，G.U.I.D.E 提供 unified input、contexts、runtime rebinding、prompt text/icons、collision handling。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))

### 3.1.4 ramokz/phantom-camera
作为摄像机行为层，负责：
- 玩家跟随镜头
- 战斗镜头
- 对话镜头
- 撤离镜头
- 多镜头优先级切换
- 镜头平滑与 framing

Phantom Camera 公开介绍中明确支持 follow/group/path/framed 等摄像机模式及镜头切换。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))

---

# 4. 搜索与补充方案说明

## 4.1 音频管理方案

### 主方案
优先使用 Maaack 模板已提供的：
- UI Sound Controller
- Background Music Controller

这样可以在不增加额外插件耦合的前提下，立即满足：
- 主菜单 BGM
- 安全区 BGM
- 战局 BGM
- UI 点击与切换音效
- 音量设置持久化

Maaack 模板公开说明中已明确包含以上能力。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

### 增强候选
`Godautdio` 可作为中后期增强方案。其定位为 Godot 4.0+ 的简单音频管理插件，适合在后续战局音频变复杂时承担统一播放与资源访问职责。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))

### 结论
- **阶段 1~2**：仅使用 Maaack 音频能力
- **阶段 3 以后**：如需更强音频事件系统，再评估 Godautdio

---

## 4.2 场景切换与加载方案

### 主方案
优先使用 Maaack 模板自带 Scene Loader 与 Loading Screen。  
原因：
- 已是当前基础壳的一部分
- 职责明确
- 足够支持主菜单、安全区、战局准备、战局、结算之间的切换

Maaack 模���说明中包含 loading screen、scene loader。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

### 增强候选
`YASM` 可作为中后期替代/增强方案，适用于：
- 更复杂的异步资源加载
- 在切场前等待额外 signal
- 更复杂的过渡动画与加载控制

Godot Asset Library 对 YASM 的公开介绍中说明其支持异步加载和可配置的 loading scene。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))

### 结论
- **当前阶段**：只使用 Maaack Scene Loader
- **不建议**：早期引入第二套主场景管理器

---

# 5. 集成设计原则

## 5.1 单一职责
每个外部插件只承担一类核心职责：
- Maaack：项目壳
- Minecraft-Style-Framework：内容系统
- G.U.I.D.E：输入系统
- Phantom Camera：镜头系统

## 5.2 适配层优先
所有业务层代码不应直接散落调用第三方插件 API，而应优先通过项目内部服务层统一访问：
- `RegistryService`
- `InputService`
- `CameraService`
- `AudioService`
- `SceneFlowService`

## 5.3 内容定义与运行时逻辑分离
- 内容定义：交由 Minecraft-Style-Framework
- 运行时逻辑：由项目自定义 Runtime Systems 承担
- 表现层：Godot scene/node + Phantom Camera + UI

## 5.4 先可运行，再工程化增强
- 先打通“最小工程闭环”
- 再优化适配层、事件总线、存档边界与模块解耦
- 不在项目初期堆叠多个重型插件

---

# 6. 高层架构方案

## 6.1 总体分层

### 6.1.1 Shell Layer
主要由 Maaack 提供：
- Main Menu
- Settings
- Pause
- Loading
- Persistent Settings
- UI Sound / BGM 基础控制

### 6.1.2 Core Layer
项目自定义：
- App Bootstrap
- State Machine
- Event Bus
- Save/Config
- Registry Adapter
- Input Adapter
- Scene Flow Adapter
- Audio Facade

### 6.1.3 Content Layer
以 Minecraft-Style-Framework 为核心：
- item registry
- entity registry
- scene registry
- quest registry
- dialogue registry
- recipe registry
- tech registry
- loot table registry
- faction registry

### 6.1.4 Runtime Systems Layer
项目自定义：
- Combat
- Inventory
- AI
- Loot
- Extraction
- Dialogue Runtime
- Quest Runtime
- Trade
- Tech
- Farming
- Automation

### 6.1.5 Presentation Layer
- Godot scenes
- UI widgets
- animations
- Phantom Camera camera rigs
- G.U.I.D.E prompts
- VFX / SFX

---

# 7. 职责边界定义

## 7.1 Maaack/Godot-Game-Template 负责
- 项目基础菜单结构
- 基础配置存储
- 标准 UI 流程
- loading scene
- 场景过渡基础流程
- UI 音效与背景音乐基础功能

## 7.2 Maaack 不负责
- 战斗
- 背包
- 任务
- 敌人
- 数据注册
- 内容工厂
- 交易
- 科技树
- 农业/工业自动化

---

## 7.3 Minecraft-Style-Framework 负责
- 内容注册
- 内容查询
- 数据定义组织
- 标签系统
- 可能的内容工厂基础

## 7.4 Minecraft-Style-Framework 不负责
- 输入
- 镜头
- 主菜单
- 游戏状态机
- UI 流程
- 场景 loading 过场

---

## 7.5 G.U.I.D.E 负责
- 输入设备统一
- 输入上下文切换
- 输入重绑定
- 输入提示图标/文本

## 7.6 G.U.I.D.E 不负责
- 游戏玩法逻辑
- UI 页面结构
- 摄像机
- 注册表
- 存档

---

## 7.7 Phantom Camera 负责
- 摄像机跟随/过渡/优先级
- 对话镜头
- 战斗镜头
- 撤离镜头

## 7.8 Phantom Camera 不负责
- 角色移动
- 目标锁定逻辑本身
- 战斗状态判定
- UI 镜头提示逻辑以外的系统

---

# 8. 工程接入顺序

## 8.1 推荐顺序
1. 基于 Maaack 建立工程
2. 验证菜单、设置、暂停、loading
3. 接入 Minecraft-Style-Framework
4. 建立 Registry Adapter
5. 接入 G.U.I.D.E
6. 建立 Input Adapter 与输入上下文
7. 接入 Phantom Camera
8. 建立 Camera Service
9. 建立 SceneFlowService / AudioService 适配层
10. 进入最小战局闭环开发

---

## 8.2 为什么必须按这个顺序
- 若先接玩法，再接项目壳，容易导致状态切换和 UI 流程返工
- 若先直接使用外部插件 API，再补适配层，会导致后期难以替换
- 先把基础壳、内容系统、输入系统、镜头系统接好，后面的 combat / inventory / AI 可稳定落位

---

# 9. 项目目录结构建议

```text name=project_structure.txt
addons/
  maaacks_game_template/
  guide/
  phantom_camera/
  minecraft_style_framework/
  godautdio/                     # 可选，当前阶段不启用

game/
  core/
    bootstrap/
    app_state/
    config/
    save/
    events/
    services/
      registry/
      input/
      camera/
      audio/
      scene_flow/
  content/
    items/
    entities/
    scene_prefabs/
    biomes/
    encounters/
    quests/
    dialogues/
    recipes/
    tech/
    loot_tables/
    factions/
    status_effects/
  runtime/
    actors/
    combat/
    inventory/
    ai/
    loot/
    extraction/
    trade/
    quest_runtime/
    tech_runtime/
    farming/
    automation/
    world/
  scenes/
    app/
    menus/
    safe_zone/
    raid/
    ui/
    actors/
    props/
    cameras/
  resources/
    audio/
    textures/
    fonts/
    themes/
```

---

# 10. 核心适配层设计

## 10.1 RegistryService
用途：
- 隐藏 Minecraft-Style-Framework 的具体接口
- 提供统一查询入口

建议接口：
- `get_item_definition(id)`
- `get_entity_definition(id)`
- `get_scene_prefab(id)`
- `query_definitions_by_tag(tag)`
- `create_runtime_entity(def_id)`

---

## 10.2 InputService
用途：
- 隐藏 G.U.I.D.E 具体实现
- 对玩法层统一提供输入访问

建议接口：
- `set_context(context_name)`
- `push_context(context_name)`
- `pop_context()`
- `is_action_pressed(action)`
- `is_action_just_pressed(action)`
- `get_move_vector()`
- `get_aim_vector()`
- `get_prompt(action)`

---

## 10.3 CameraService
用途：
- 统一控制镜头模式切换
- 封装 Phantom Camera 优先级切换

建议接口：
- `set_follow_mode()`
- `set_combat_mode(target = null)`
- `set_dialogue_mode(subject_a, subject_b)`
- `set_extract_mode(extract_zone)`
- `reset_default_camera()`

---

## 10.4 AudioService
用途：
- 当前封装 Maaack 自带音频控制
- 后续如切换 Godautdio，不影响业务层

建议接口：
- `play_ui_click()`
- `play_ui_back()`
- `play_sfx(event_id, position = null)`
- `play_bgm(track_id)`
- `crossfade_bgm(track_id)`
- `set_bus_volume(bus_name, value)`

---

## 10.5 SceneFlowService
用途：
- 当前封装 Maaack Scene Loader
- 后续必要时可替换为 YASM

建议接口：
- `go_to_main_menu()`
- `go_to_safe_zone()`
- `go_to_raid_prepare()`
- `go_to_raid(map_id)`
- `go_to_raid_result(result_data)`
- `reload_current_scene()`

---

# 11. 输入集成方案

## 11.1 输入上下文设计
建议定义以下上下文：
- `global`
- `main_menu`
- `safe_zone`
- `raid`
- `inventory`
- `dialogue`
- `trade`
- `pause_menu`
- `map_overlay`

G.U.I.D.E 的公开说明已确认其支持多上下文与动态启用/禁用。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))

## 11.2 关键动作映射
### 通用
- `confirm`
- `cancel`
- `pause`

### 战局
- `move`
- `aim`
- `fire`
- `reload`
- `melee`
- `interact`
- `sprint`
- `open_inventory`
- `quick_use_1` ~ `quick_use_8`

### UI / 背包
- `ui_tab_left`
- `ui_tab_right`
- `split_stack`
- `rotate_item`
- `quick_move`
- `inspect_item`

---

# 12. 摄像机集成方案

## 12.1 目标
使用 Phantom Camera 提供战局与交互状态下的镜头切换能力。

## 12.2 首批镜头类型
- FollowCam
- CombatCam
- DialogueCam
- ExtractCam
- ResultCam

## 12.3 切换时机
- 默认探索：FollowCam
- 玩家开火/被发现：CombatCam
- 与 NPC 对话：DialogueCam
- 进入撤离读条：ExtractCam
- 战局结束：ResultCam

Phantom Camera 支持多相机行为与优先级控制。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))

---

# 13. 音频集成方案

## 13.1 阶段 1 主方案
仅使用 Maaack 模板能力：
- UI Sound Controller
- Background Music Controller

## 13.2 使用范围
- 菜单点击音效
- 页面切换音效
- Main Menu BGM
- Safe Zone BGM
- Raid BGM
- Result BGM

## 13.3 后续升级条件
出现以下需求时，再评估 Godautdio：
- 战局内复杂动态混音
- 更统一的事件式音频触发
- 更复杂的区域氛围切换
- 更复杂的资源预载与路由

Godautdio 公开定位为 Godot 4.0+ 的音频管理插件。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))

---

# 14. 场景切换与加载集成方案

## 14.1 当前主方案
使用 Maaack Scene Loader 统一管理：
- 主菜单 → 安全区
- 安全区 → 战局准备
- 战局准备 → 战局
- 战局 → 结算
- 结算 → 安全区

Maaack 公开模板说明已包含 scene loader / loading screen。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

## 14.2 增强替代条件
如后续出现以下需求，可评估 YASM：
- 更复杂的资源预热流程
- 自定义异步加载控制粒度
- 等待外部 signal 后再切换
- 更复杂 transition 逻辑

YASM 公开介绍支持异步加载与可配置 loading 流程。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))

---

# 15. 内容系统集成方案

## 15.1 Minecraft-Style-Framework 在项目中的角色
作为内容定义中心，管理：
- item
- entity
- scene_prefab
- quest
- dialogue
- recipe
- tech
- loot_table
- faction
- status_effect

## 15.2 内容组织原则
- 大类注册
- 标签细分
- 定义层与运行时实例层分离
- 业务逻辑通过 `RegistryService` 查询定义

## 15.3 关键收益
- 易扩展
- 可统一工具化
- 方便多人协作
- 便于后续做 mod-like 内容扩展

---

# 16. 风险与控制策略

## 16.1 风险：插件单例冲突
控制策略：
- 统一通过项目服务层访问外部插件
- 避免业务层直接依赖第三方单例

## 16.2 风险：输入系统与 UI 交互冲突
控制策略：
- UI 页面的导航逻辑保留与 Maaack 页结构兼容
- 游戏玩法输入统一走 G.U.I.D.E
- 用 context 切换隔离状态

## 16.3 风险：场景管理重复建设
控制策略：
- 当前阶段仅保留 Maaack Scene Loader
- 不并行引入第二套 Scene Manager

## 16.4 风险：音频系统过度设计
控制策略：
- 先用 Maaack 内置音频控制满足 MVP
- 明确触发升级条件后再考虑 Godautdio

## 16.5 风险：内容系统 API 未来变化
控制策略：
- 所有外部框架调用收敛到 Adapter 层
- 不让业务层散落引用内容框架 API

---

# 17. 里程碑建议

## 17.1 Milestone A：工程壳可运行
- Maaack 正常运行
- Scene Loader 正常
- Settings 正常
- G.U.I.D.E 正常
- Phantom Camera 正常

## 17.2 Milestone B：最小内容系统接通
- 最小 item/entity registry 可查询
- 一个测试实体可通过注册定义生成
- 一个测试场景可完成 load -> play -> return

## 17.3 Milestone C：最小战局闭环
- 玩家进入测试战局
- 可移动/瞄准/交互
- 可搜刮一个容器
- 可抵达撤离点
- 可返回结算界面

---

# 18. 搜索来源摘要

本集成计划使用的检索结论来自以下公开来源：

- Maaack/Godot-Game-Template：模板包含 main menu、options、pause、loading screen、scene loader、persistent settings、UI sound controller、background music controller，并说明适用于 Godot 4.5 / 4.3+ compatible。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))
- G.U.I.D.E：支持 unified input、multiple contexts、runtime rebinding、prompts、collision handling。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))
- Phantom Camera：Godot 4 camera plugin，支持 follow/group/path/framed 等模式。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))
- Godautdio：Godot 4.0+ 音频管理插件。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))
- YASM：Godot 4 异步场景加载插件。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))