# 2D 俯视角撤离射击游戏：快速开发参考文档
> 基于 Godot 4.x  
> 当前日期：2026-03-12

---

# 1. 文档目的

本文档用于指导项目快速启动与早期架构落地，目标是在尽量少重复造轮子的前提下，组合多个现成插件/模板，搭建出一个适合本项目的 **可快速开发、可长���扩展、与注册表数据驱动框架相容** 的 Godot 工程基础。

本文档包含：
- 选型结果
- 搜索得到的插件/模板信息
- 推荐集成方式
- 项目构建步骤
- 推荐目录结构
- 架构分层
- 关键组件设计
- 快速开发阶段建议
- 风险与替代方案

---

# 2. 最终技术选型

## 2.1 核心组合

### 1. 基础项目壳
**`Maaack/Godot-Game-Template`**  
用途：
- Main Menu
- Options Menus
- Pause Menu
- Credits
- Loading Screen
- Scene Loader
- Persistent Settings
- Keyboard/Mouse Support
- Gamepad Support
- UI Sound Controller
- Background Music Controller

该模板明确面向 Godot 4.5，且标注 **4.3+ compatible**，可以作为新项目模板，也可以作为插件接入已有项目。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

### 2. 内容系统核心
**`0999312/Minecraft-Style-Framework`**  
用途：
- 注册表系统
- 内容数据定义
- 模块化内容组织
- 作为 item / entity / scene / quest / tech / recipe 等内容的核心管理层

> 注：当前公开可确认的信息有限，但根据你提供的仓库描述“基于 Minecraft 部分底层设计的 Godot 游戏功能框架”，本方案默认其承担“注册表驱动内容系统核心”的职责。此部分为方案化设计，不假设具体 API 名称。

### 3. 输入处理
**`godotneers/G.U.I.D.E`**  
用途：
- 统一处理 keyboard / mouse / gamepad / touch 输入
- 输入修饰与预处理（dead-zone、sensitivity、inversion 等）
- 多输入上下文切换
- Runtime rebinding
- 输入冲突处理
- 输入提示与图标展示
- 可并行配合 Godot 原生输入系统使用

Godot Asset Library 条目显示，G.U.I.D.E 支持统一输入、上下文、多种触发条件、运行时重绑定和自动提示图标，是一个很适合本项目的输入层方案。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))

### 4. 摄像机处理
**`ramokz/phantom-camera`**  
用途：
- Godot 4 摄像机行为插件
- 2D/3D camera follow / damp / group / path / framed
- 多 camera 优先级切换
- 平滑过渡
- 类似 Cinemachine 的镜头逻辑

Phantom Camera 明确是 Godot 4 插件，支持跟随、平滑阻尼、多目标取景、不同相机之间的动态切换，非常适合俯视角射击中的战斗镜头、对话镜头和撤离镜头。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))

---

## 2.2 搜索后补充选型

### A. 音频管理方案
#### 主推荐：先使用 Maaack 模板内置能力
Maaack 的 Game Template 和 Menus Template 都明确包含：
- **UI Sound Controller**
- **Background Music Controller**

这意味着在项目早期，菜单、按钮、基础 BGM 切换等常见需求已经被覆盖。对本项目的 MVP 和早期 Vertical Slice 来说，这已经足够。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

#### 增强候选：Godautdio
**Godautdio** 是一个面向 Godot 4.0+ 的简单音频管理插件，主打简化音频播放与资源管理。适合作为后续扩展候选，如果项目进入中后期，需要更统一的：
- 音效分类播放
- 统一音频资源访问
- 更明确的音频接口层

可以再评估接入。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))

#### 结论
- **MVP / 原型期**：使用 Maaack 自带音频控制即可
- **中后期增强**：如确实需要，再引入 Godautdio 作为独立 AudioManager 后端

---

### B. 场景切换与加载方案
#### 主推荐：使用 Maaack 自带 Scene Loader
Maaack Game Template 已明确自带：
- Scene Loader
- Loading Screen
- 相关 loading scenes 文档

另外，Maaack 的独立 Scene Loader 插件也被公开介绍为支持：
- 异步资源加载
- 进度条 loading screen
- 错误处理。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

#### 增强候选：YASM（Yet Another Scene Manager）
YASM 是 Godot 4 的异步场景加载插件，支持：
- 后台异步加载
- 可自定义 loading scene
- 可等待额外 signal 后切换
- 通过 Animation 处理 transitions。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))

#### 不作为首选的原因
因为你已经选定 Maaack 为基础壳，而 Maaack 本身已经覆盖 scene loader / loading screen。  
为减少重复系统，本项目应先坚持：
- **一个主场景加载系统**
- 避免早期同时接入两套 scene manager

#### 结论
- **主方案**：Maaack Scene Loader
- **备选增强**：YASM，仅在后续需要更复杂异步与前置等待逻辑时评估

---

# 3. 搜索结论摘要

## 3.1 已确认可用能力
### Maaack/Godot-Game-Template
- For Godot 4.5（4.3+ compatible）
- 提供主菜单、选项、暂停、Credits、Loading Screen、Scene Loader、持久设置、手柄支持、UI Sound Controller、Background Music Controller。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

### G.U.I.D.E
- 统一 keyboard / mouse / gamepad / touch 输入
- 多 input context
- runtime rebinding
- collision handling
- prompt text/icon
- 支持与 Godot 原生输入并行使用。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))

### Phantom Camera
- Godot 4 插件
- 跟随、平滑、群组、多镜头切换、路径跟随。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))

### Maaack Scene Loader
- 异步加载
- loading screen
- progress bar
- error handling。 ([allgodot.com](https://allgodot.com/godot/maaack-s-scene-loader?utm_source=openai))

### Godautdio
- Godot 4.0+
- 简化音频管理与播放。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))

### YASM
- Godot 4
- 后台异步加载
- 支持过渡动画
- 支持等待特定 signal 后切换场景。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))

---

# 4. 总体集成策略

## 4.1 设计原则
项目中每个外部模板/插件必须职责清晰，避免职责重叠。

### 职责分配
- **Maaack**：工程壳、菜单、设置、基础场景加载、基础音频 UI/BGM 控制
- **Minecraft-Style-Framework**：内容注册、数据驱动内容、内容工厂
- **G.U.I.D.E**：输入层、上下文切换、重绑定、输入提示
- **Phantom Camera**：镜头行为层
- **项目自定义代码**：战斗、背包、AI、任务、科技、安全区、农业、工业自动化

---

## 4.2 避免重复造轮子
### 不建议重复实现
- 输入上下文切换
- 基础设置页
- 场景 loading 过渡
- 基础 BGM/UI 音频总线
- 摄像机跟随阻尼与过渡

### 建议自己实现
- 注册表到运行时对象的装配
- item / entity / quest / tech 数据 schema
- raid/safe_zone 双循环
- inventory / combat / AI / loot / extraction 逻辑
- 任务 / 商人 / 科技 / 农业 / 自动化

---

# 5. 项目构建操作方法

## 5.1 推荐安装顺序
建议严格按以下顺序构建项目：

1. 创建项目 / 导入 Maaack 模板
2. 验证菜单、设置、暂停、Scene Loader 正常
3. 导入 Minecraft-Style-Framework
4. 搭建内容注册入口
5. 导入 G.U.I.D.E
6. 用 G.U.I.D.E 替换/桥接项目输入层
7. 导入 Phantom Camera
8. 创建基础 Game Scene、Player、Camera Rig
9. 搭建 Raid / Safe Zone 状态切换
10. 再接入背包、战斗、敌人、任务等模块

---

## 5.2 具体操作步骤

### 步骤 1：创建基础项目
#### 方案 A：以 Maaack 模板直接起项目
1. 在 Godot 中打开 `Asset Library Projects`
2. 搜索 `Maaack's Game Template`
3. 下载并创建新项目  
或：
1. 从 GitHub 下载/克隆 `Maaack/Godot-Game-Template`
2. 直接作为项目起点打开

Maaack 官方说明支持作为模板项目或插件安装。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

#### 步骤 1 验证项
- 项目���以正常打开
- Main Menu 正常显示
- Options Menu 正常工作
- Pause Menu 正常工作
- Loading Screen 可调用

---

### 步骤 2：接入 Minecraft-Style-Framework
#### 操作
1. 将 `0999312/Minecraft-Style-Framework` 放入：
   - `addons/`  
   或
   - `framework/` / `thirdparty/` 下，再做统一入口封装
2. 启用其插件（若其为 Godot 插件）
3. 建立项目内部 `RegistryBootstrap` 脚本
4. 在游戏启动时注册：
   - item
   - entity
   - scene_prefab
   - quest
   - dialogue
   - recipe
   - tech
   - loot_table
   - status_effect
   - faction

#### 验证项
- 能成功读取最小样例注册数据
- 能按 ID 查到定义
- 能使用标签查询内容

---

### 步骤 3：接入 G.U.I.D.E
#### 操作
1. 从 Godot Asset Library 或仓库安装 `G.U.I.D.E`
2. 启用插件
3. 建立项目的输入上下文：
   - `global`
   - `menu`
   - `raid`
   - `inventory`
   - `dialogue`
   - `trade`
   - `safe_zone_build`
4. 定义动作映射，例如：
   - move
   - aim
   - fire
   - reload
   - melee
   - interact
   - sprint
   - open_inventory
   - quick_use_1..8
   - pause
   - confirm
   - cancel
5. 开启 prompt icon / prompt text 方案

G.U.I.D.E 支持多输入上下文、运行时重绑定和输入提示，这对本项目非常关键。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))

#### 验证项
- 键鼠与手柄都能驱动主菜单
- 在游戏中可切换到 `raid` context
- 打开背包后自动切换 `inventory` context
- 输入提示随设备变化

---

### 步骤 4：接入 Phantom Camera
#### 操作
1. 通过 Asset Library 或 GitHub 安装 `phantom-camera`
2. 启用插件
3. 在 Player Scene 中建立 Camera Rig：
   - 主跟随相机
   - 战斗聚焦相机
   - 交互/对话相机
   - 撤离镜头
4. 通过优先级切换控制活跃镜头

Phantom Camera 支持通过优先级切换不同镜头，并提供 follow/group/path/framed 等模式。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))

#### 验证项
- 正常跟随玩家
- 冲刺时镜头有轻微前视
- 对话时镜头可平滑切换
- 撤离点交互时镜头可转为固定构图

---

### 步骤 5：音频方案接入
#### MVP 方案
先直接使用 Maaack 内置：
- UI Sound Controller
- Background Music Controller

用于：
- 按钮点击音效
- 页面切换音效
- 主菜单 BGM
- 安全区 BGM
- 战局 BGM 基础切换。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

#### 中后期增强方案
如后续需要更完整的游戏内音频事件层，再评估接入 Godautdio。它要求 Godot 4.0+，可作为统一音频管理插件候选。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))

#### 验证项
- UI 点击音效正常
- 主菜单与战局 BGM 切换正常
- 音量设置持久化保存

---

### 步骤 6：场景切换与加载方案接入
#### MVP 方案
使用 Maaack 自带 Scene Loader：
- 主菜单 → 安全区
- 安全区 → 战局准备
- 战局准备 → 战局地图
- 战局结束 → 结算 → 安全区

Maaack 的模板已明确自带 scene loader / loading screen。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

#### 增强备选
若未来需要：
- 等待网络状态
- 等待数据预热
- 等待 shader warm-up
可评估 YASM。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))

---

# 6. 推荐项目架构

## 6.1 分层结构

### A. Shell 层
由 Maaack 提供为主：
- Main Menu
- Settings
- Pause
- Credits
- Scene Loading
- 基础 UI 音效 / BGM

### B. Core 层
项目自定义：
- App Bootstrap
- Game State Machine
- Event Bus
- Save/Config Service
- Registry Service Adapter
- Input Adapter
- Audio Facade
- Scene Flow Facade

### C. Content 层
由 Minecraft-Style-Framework 作为核心：
- item registry
- entity registry
- quest registry
- dialogue registry
- recipe registry
- tech registry
- loot table registry
- faction registry

### D. Runtime Systems 层
项目自定义：
- Combat
- Inventory
- Loot
- AI
- Extraction
- Quest Runtime
- Dialogue Runtime
- Trade Runtime
- Tech Runtime
- Farming
- Automation

### E. Presentation 层
- Godot scenes/nodes
- UI widgets
- Animation
- Camera rigs via Phantom Camera
- Input prompts via G.U.I.D.E

---

## 6.2 推荐目录结构

```text name=project_structure.txt
addons/
  maaacks_game_template/
  phantom_camera/
  guide/
  minecraft_style_framework/
  godautdio/               # 可选，中后期再接

game/
  core/
    bootstrap/
    state_machine/
    events/
    save/
    config/
    registry/
    input/
    scene_flow/
    audio/
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
    loot/
    ai/
    extraction/
    world/
    farming/
    automation/
    trade/
    quest_runtime/
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
    icons/
    fonts/
    themes/
```

---

# 7. 组件设计方案

## 7.1 核心单例/服务

### AppBootstrap
职责：
- 初始化项目
- 加载配置
- 初始化 Registry
- 初始化输入
- 初始化音频
- 进入主菜单

### GameStateMachine
状态：
- BOOT
- MAIN_MENU
- SAFE_ZONE
- RAID_PREPARE
- RAID_LOADING
- RAID_RUNNING
- RAID_RESULT
- SETTINGS
- PAUSED

### RegistryService
职责：
- 统一封装 Minecraft-Style-Framework 的查询接口
- 提供：
  - `get_item_def(id)`
  - `get_entity_def(id)`
  - `query_by_tag(tag)`
  - `spawn_from_registry(id)`

### InputService
职责：
- 对 G.U.I.D.E 做一层项目适配
- 管理上下文切换
- 对外暴露：
  - `set_context(name)`
  - `is_action_pressed(action)`
  - `get_aim_vector()`
  - `get_move_vector()`
  - `get_prompt_for_action(action)`

### CameraService
职责：
- 管理 Phantom Camera 优先级切换
- 对外暴露：
  - `set_camera_mode("follow")`
  - `set_camera_mode("combat")`
  - `set_camera_mode("dialogue")`
  - `set_camera_mode("extract")`

### AudioService
职责：
- 统一封装 Maaack 自带音频控制
- 后续可切换到 Godautdio 后端而不改业务层
- 对外暴露：
  - `play_ui_sfx(id)`
  - `play_sfx(id, position)`
  - `play_bgm(track_id)`
  - `crossfade_bgm(track_id)`

### SceneFlowService
职责：
- 封装 Maaack Scene Loader
- 后续如换成 YASM，只改这一层
- 对外暴露：
  - `load_menu()`
  - `load_safe_zone()`
  - `load_raid_prepare()`
  - `load_raid(map_id)`

---

## 7.2 场景与玩法组件

### PlayerRoot
组件建议：
- MovementComponent
- CombatComponent
- InventoryComponent
- InteractionComponent
- StatusComponent
- CameraAnchor
- PromptAnchor

### EnemyRoot
组件建议：
- StatsComponent
- AIComponent
- CombatComponent
- LootDropComponent
- PerceptionComponent

### LootContainer
组件建议：
- InventoryContainerComponent
- LootTableResolver
- InteractionPromptProvider

### ExtractionZone
组件建议：
- RuleChecker
- CountdownUIBinder
- CameraOverrideTrigger

### TraderNPC
组件建议：
- DialogueStarter
- TradeProvider
- QuestProvider
- CameraFocusTrigger

---

# 8. 输入架构方案

## 8.1 输入上下文设计
使用 G.U.I.D.E 的多 context 能力，建议定义：

- `global`
- `main_menu`
- `safe_zone`
- `raid`
- `inventory`
- `dialogue`
- `trade`
- `map`
- `pause_menu`

G.U.I.D.E 明确支持在运行时启用/禁用不同输入上下文。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))

## 8.2 输入动作建议
### 通用
- confirm
- cancel
- pause
- tab_left
- tab_right

### 战局
- move
- aim
- fire
- reload
- melee
- interact
- sprint
- crouch
- quick_use_1..8
- open_inventory
- open_map

### 背包
- drag
- rotate_item
- split_stack
- quick_move
- inspect_item

### 交易/对话
- next
- prev
- select_option
- buy
- sell
- compare

## 8.3 输入提示
利用 G.U.I.D.E 的 prompt 功能，在 UI 中统一显示：
- `Press [E] to Loot`
- `Press [LT+A] to Quick Heal`
- `Press [RB] to Switch Tab`

且提示图标可根据实际设备变化。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))

---

# 9. 摄像机设计方案

## 9.1 摄像机模式
借助 Phantom Camera，建议至少设计以下相机：

### FollowCam
- 常规探索
- 平滑跟随玩家
- 轻度前视偏移

### CombatCam
- 玩家进入战斗时启用
- 根据瞄准方向前移视野
- 稍微拉远 FOV/Zoom

### DialogueCam
- 与 NPC 对话时激活
- 锁定角色与 NPC 的中间区域

### ExtractCam
- 靠近撤离点时启用
- 强化撤离区环境表现

### DeathCam / ResultCam
- 玩家死亡或战局结束时激活
- 用于结算前过场

Phantom Camera 支持优先级切换与多种 follow mode。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))

---

# 10. 音频设计方案

## 10.1 MVP 音频方案
直接建立以下总线与层次：
- Master
- UI
- BGM
- SFX
- Ambience

使用 Maaack 已有的：
- UI Sound Controller
- Background Music Controller

先解决：
- 按钮点击
- 页面开关
- 菜单音乐
- 战局音乐
- 安全区音乐。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

## 10.2 中后期升级方向
如果后面战局音频更复杂，可引入独立 `AudioService` 统一管理：
- UI 音效
- 武器音效
- 命中音效
- 脚步与材质音效
- 环境循环
- 区域氛围切换
- 战斗态 BGM 分层

如现有 Maaack 能力不够，再评估接入 Godautdio。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))

---

# 11. 场景切换与加载方案

## 11.1 主方案：Maaack Scene Loader
适用于：
- 菜单 → 安全区
- 安全区 → 战局准备
- 战局准备 → 战局场景
- 战局结束 → 结算 → 安全区

使用理由：
- 已包含在你选定的基础模板中
- 内建 loading screen
- 已知支持异步加载与错误处理。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))

## 11.2 增强方案：YASM
当项目后期需要：
- 更复杂 transition animation
- 等待 shader prewarm
- 等待多人同步/信号条件
时可考虑替换或局部引入 YASM。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))

## 11.3 不建议
- 早期同时引入多个 Scene Manager 插件
- 在 Maaack 已覆盖基础需求时再叠加另一个主加载系统

---

# 12. 内容系统设计方案

## 12.1 Minecraft-Style-Framework 的角色
在本项目中，它应只负责：
- 定义内容
- 注册内容
- 查询内容
- 通过 ID/Tag 驱动工厂生成对象

## 12.2 建议注册类别
- item
- entity
- scene_prefab
- biome
- encounter
- quest
- dialogue
- recipe
- tech
- loot_table
- faction
- status_effect

## 12.3 推荐内容 ID 规范
- `item.bandage_basic`
- `item.rifle_pipe_556`
- `entity.enemy.raider_scout`
- `entity.npc.trader_medic`
- `scene.poi.gas_station`
- `quest.fetch.sample_01`
- `tech.agriculture.planter_1`

---

# 13. 快速开发里程碑

## 13.1 第一阶段：工程壳打通
目标：
- Maaack 模板跑通
- G.U.I.D.E 跑通
- Phantom Camera 跑通
- 最小注册表可查询
- 主菜单 → 测试场景切换成功

交付：
- 能从主菜单进入测试场景并返回
- 设置、手柄、按键重绑可用
- 相机跟随正常

---

## 13.2 第二阶段：最小战局闭环
目标：
- 玩家移动/瞄准/射击
- 1 个敌人
- 1 个 loot container
- 1 个 extraction zone
- 1 个战局结算界面

交付：
- 完成“进入战局 → 搜刮 → 战斗 → 撤离 → 结算”

---

## 13.3 第三阶段：安全区闭环
目标：
- 1 个安全区场景
- 1 个商人
- 1 个任务 NPC
- 1 个基础科技节点

交付：
- 完成“战局外整理 → 接任务 → 进入战局 → 回来交付”

---

# 14. 风险与应对

## 14.1 风险：Maaack 与 G.U.I.D.E 输入体系重叠
### 应对
- UI 层尽量保留 Maaack 已有工作流
- 游戏玩法层统一走 G.U.I.D.E
- 通过 `InputService` 做桥接，不让业务代码直接耦合插件

## 14.2 风险：多个插件都想做“全局单例”
### 应对
- 项目内部再做一层 Facade
- 业务代码只依赖：
  - `InputService`
  - `SceneFlowService`
  - `AudioService`
  - `RegistryService`
  - `CameraService`

## 14.3 风险：Minecraft-Style-Framework API 不明确
### 应对
- 先定义项目内部注册适配层
- 不直接在业务层散用外部框架 API
- 后续若框架 API 变化，只改 Adapter

## 14.4 风险：音频系统过早复杂化
### 应对
- 先用 Maaack 自带音频控制完成 MVP
- 不在项目初期引入过多音频中间层
- 只有在战局内动态音频需求明显增长后，再接入 Godautdio

---

# 15. 最终推荐结论

## 15.1 推荐主实现方案
- **壳层**：Maaack/Godot-Game-Template
- **内容层**：0999312/Minecraft-Style-Framework
- **输入层**：godotneers/G.U.I.D.E
- **摄像机层**：ramokz/phantom-camera
- **音频层**：先用 Maaack 内置 UI/BGM 控制，后续按需评估 Godautdio
- **场景加载层**：先用 Maaack Scene Loader，后续按需评估 YASM

## 15.2 这个方案的优点
- 快速开工
- 模块职责清晰
- 与注册表驱动架构相容
- 不会过早引入太多重叠框架
- 支持后续平滑增强

## 15.3 适合的开发策略
- 先跑通基础壳与上下文切换
- 再打通最小战局闭环
- 再叠加安全区、任务、交易、科技
- 最后扩展农业与工业自动化

---

# 16. 搜索来源记录

以下内容基于在线检索整理：

- Maaack Game Template：Godot 4.5（4.3+ compatible），包含 main menu、options、pause、scene loader、persistent settings、UI sound controller、background music controller。 ([github.com](https://github.com/Maaack/Godot-Game-Template?utm_source=openai))
- Maaack Menus Template：同样说明了 UI sound controller、background music controller、loading screen、persistent settings 等基础能力。 ([github.com](https://github.com/Maaack/Godot-Menus-Template?utm_source=openai))
- G.U.I.D.E：Godot Unified Input Detection Engine，支持统一输入、多上下文、重绑定、提示图标。 ([godotengine.org](https://godotengine.org/asset-library/asset/3503?utm_source=openai))
- Phantom Camera：Godot 4 摄像机插件，支持 follow/group/path/framed、多镜头优先级切换。 ([github.com](https://github.com/ramokz/phantom-camera?utm_source=openai))
- Maaack Scene Loader：支持异步加载、loading screen、progress bar、error handling。 ([allgodot.com](https://allgodot.com/godot/maaack-s-scene-loader?utm_source=openai))
- YASM：Godot 4 异步场景加载与转场插件。 ([godotengine.org](https://godotengine.org/asset-library/asset/2428?utm_source=openai))
- Godautdio：Godot 4.0+ 的简单音频管理插件。 ([huntrox.itch.io](https://huntrox.itch.io/godautdio?utm_source=openai))