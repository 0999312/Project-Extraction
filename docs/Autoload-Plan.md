# Autoload Plan
> 项目：2D 俯视角撤离射击游戏  
> 引擎：Godot 4.x  
> 当前日期：2026-03-12

---

# 1. 文档目标

本文档用于定义项目建议使用的 **Godot Autoload / 全局单例** 结构，明确哪些系统应该作为全局服务存在，哪些系统不应进入 Autoload，并给出初始化顺序、职责边界与依赖关系。

目标包括：

- 控制全局单例数量，避免“什么都塞进 Autoload”
- 保证工程启动顺序稳定
- 为输入、场景切换、内容查询、音频、存档、状态机等跨场景系统提供统一入口
- 为后续阶段开发提供稳定依赖面

---

# 2. 设计原则

## 2.1 只有跨场景、跨模块、需要长期常驻的系统才进入 Autoload
适合放入 Autoload 的一般是：
- 配置/设置
- 全局状态机
- 场景切换
- 输入服务
- 内容注册访问
- 事件总线
- 存档服务
- 音频服务

不适合放入 Autoload 的一般是：
- 玩家实体
- 当前地图对象
- 敌人管理器
- 容器 UI
- 某一局战斗逻辑
- 安全区具体控制器
- 战局控制器

这些应属于场景内运行时对象，而不是全局常驻单例。

---

## 2.2 Autoload 不直接暴露第三方插件细节
外部插件能力应先收敛为项目内部服务，例如：
- G.U.I.D.E → `InputService`
- Phantom Camera → `CameraService`
- Maaack Scene Loader → `SceneFlowService`
- Maaack 音频控制 → `AudioService`
- Minecraft-Style-Framework → `RegistryService`

这样即使未来替换外部插件，也不需要大规模修改业务代码。

---

## 2.3 控制依赖方向
推荐依赖方向：

- 高层流程依赖服务层
- 服务层依赖适配器和插件
- 场景运行时对象依赖服务层
- 服务层尽量不要依赖具体 gameplay scene

避免：
- `InputService` 直接依赖 `Player`
- `RegistryService` 直接依赖某张地图
- `AudioService` 依赖 UI 节点实例
- `GameStateMachine` 依赖某个特定战局控制器

---

# 3. 建议 Autoload 清单

以下为推荐的核心 Autoload：

1. `AppBootstrap`
2. `GameStateMachine`
3. `EventBus`
4. `ConfigService`
5. `SaveService`
6. `RegistryService`
7. `InputService`
8. `AudioService`
9. `SceneFlowService`

以下为**可选** Autoload：
10. `DebugService`
11. `TelemetryService`（若后续需要）

以下为**不建议**做成 Autoload 的服务：
- `CameraService`（建议作为当前场景服务或通过场景根节点注入）
- `RaidController`
- `SafeZoneController`
- `TradeSystem`
- `QuestSystem`
- `FarmingSystem`
- `AutomationSystem`

---

# 4. 推荐 Autoload 详解

## 4.1 AppBootstrap
### 作用
工程启动入口，负责初始化全局服务、执行预检查、设置启动状态。

### 主要职责
- 初始化基础配置
- 检查项目版本与存档版本
- 初始化注册表
- 初始化输入系统
- 初始化音频系统
- 初始化事件总线订阅
- 进入主菜单或测试入口

### 不应承担
- 具体 gameplay 逻辑
- 战局控制
- 安全区控制
- UI 页面细节

### 建议接口
- `startup()`
- `shutdown()`
- `restart_to_main_menu()`

---

## 4.2 GameStateMachine
### 作用
管理全局流程状态。

### 建议状态
- `BOOT`
- `MAIN_MENU`
- `SAFE_ZONE`
- `RAID_PREPARE`
- `RAID_LOADING`
- `RAID_RUNNING`
- `RAID_RESULT`
- `SETTINGS`
- `PAUSED`

### 主要职责
- 切换全局状态
- 发出状态变化事件
- 驱动输入上下文切换
- 驱动场景流转

### 建议接口
- `change_state(next_state, payload = {})`
- `get_state()`
- `is_in_state(state_name)`

### 依赖
- `SceneFlowService`
- `InputService`
- `EventBus`

---

## 4.3 EventBus
### 作用
全局事件总线，用于降低模块耦合。

### 典型事件
- `game_state_changed`
- `raid_started`
- `raid_finished`
- `item_looted`
- `actor_damaged`
- `actor_killed`
- `quest_updated`
- `settings_changed`
- `input_context_changed`

### 主要职责
- 提供统一发布/订阅机制
- 支持跨模块通知
- 减少直接引用链

### 建议接口
- `emit_event(event_name, payload = {})`
- `subscribe(event_name, callable_ref)`
- `unsubscribe(event_name, callable_ref)`

---

## 4.4 ConfigService
### 作用
管理项目设置与用户偏好。

### 管理内容
- 画面设置
- 音量设置
- 语言设置
- 输入偏好
- UI 缩放
- 辅助选项

### 主要职责
- 读取配置
- 写入配置
- 通知配置变化
- 启动时应用配置

### 建议接口
- `load_config()`
- `save_config()`
- `get_value(section, key, default_value = null)`
- `set_value(section, key, value)`

### 依赖
- 文件系统
- `EventBus`

---

## 4.5 SaveService
### 作用
管理长期进度存档。

### 管理内容
- 玩家进度
- 安全区进度
- 科技树进度
- 任务状态
- 战局外仓库
- 元数据与版本号

### 主要职责
- 读档
- 写档
- 自动存档
- 存档版本检查
- 迁移入口调度

### 建议接口
- `save_game(slot_id)`
- `load_game(slot_id)`
- `has_save(slot_id)`
- `delete_save(slot_id)`
- `list_saves()`

### 不应承担
- 场景内临时战局对象序列化细节，除非明确需要

---

## 4.6 RegistryService
### 作用
统一封装 `Minecraft-Style-Framework` 的内容查询与注册访问。

### 管理内容
- item definitions
- entity definitions
- quest definitions
- dialogue definitions
- tech definitions
- loot tables
- status effects
- factions
- scene prefabs

### 主要职责
- 启动时加载/注册内容
- 按 ID 查询内容
- 按标签查询内容
- 为工厂/运行时系统提供 definition

### 建议接口
- `initialize_registries()`
- `get_definition(type_name, id)`
- `query_by_tag(type_name, tag)`
- `has_definition(type_name, id)`

### 风险控制
业务层不应直接依赖外部框架 API。

---

## 4.7 InputService
### 作用
统一封装 `G.U.I.D.E` 输入层。

### 管理内容
- 输入上下文
- action 查询
- 设备切换
- prompt 获取
- 重绑定入口

### 主要职责
- context 切换
- 获取 move / aim vector
- 获取 action 状态
- 暴露 prompt/icon 信息
- 对接菜单和玩法输入

### 建议接口
- `set_context(context_name)`
- `push_context(context_name)`
- `pop_context()`
- `is_action_pressed(action_name)`
- `is_action_just_pressed(action_name)`
- `get_move_vector()`
- `get_aim_vector()`
- `get_prompt(action_name)`

### 依赖
- `G.U.I.D.E`
- `EventBus`

---

## 4.8 AudioService
### 作用
统一封装 Maaack 提供的基础音频控制，并为后续扩展预留接口。

### 管理内容
- UI 音效
- 背景音乐
- 总线音量
- 基础 SFX 播放接口

### 主要职责
- 播放 UI 音效
- 切换 BGM
- 应用音量设置
- 提供后续接入 Godautdio 的替换点

### 建议接口
- `play_ui_click()`
- `play_ui_back()`
- `play_bgm(track_id)`
- `crossfade_bgm(track_id)`
- `set_bus_volume(bus_name, value)`

### 依赖
- Maaack 音频能力
- `ConfigService`

---

## 4.9 SceneFlowService
### 作用
统一封装 Maaack 的 scene loader / loading screen 工作流。

### 管理内容
- 主菜单切换
- 安全区切换
- 战局切换
- 结算切换
- loading screen 的统一进入/退出

### 主要职责
- 执行场景切换
- 传递场景载荷
- 加载时显示进度
- 捕捉场景切换错误

### 建议接口
- `go_to_main_menu()`
- `go_to_safe_zone(payload = {})`
- `go_to_raid_prepare(payload = {})`
- `go_to_raid(map_id, payload = {})`
- `go_to_raid_result(result_data)`
- `reload_current_scene()`

### 依赖
- Maaack Scene Loader
- `EventBus`

---

# 5. 可选 Autoload

## 5.1 DebugService
### 建议仅在开发期启用
用于：
- 控制台命令
- 调试开关
- 调试菜单入口
- 注册表内容检查
- 快速跳转测试场景

### 建议接口
- `toggle_debug_overlay()`
- `spawn_test_item(id)`
- `jump_to_test_map()`
- `unlock_test_tech(id)`

---

## 5.2 TelemetryService
### 仅在项目后期需要时启用
用于：
- 收集性能统计
- 记录崩溃前上下文
- 上报调试事件

当前阶段不是必须。

---

# 6. 不建议放入 Autoload 的系统

## 6.1 CameraService
### 原因
镜头与当前活动场景强绑定。  
如果做成全局单例，容易出现：
- 场景切换后引用失效
- 当前相机 rig 生命周期混乱
- 多场景下镜头持有对象不一致

### 推荐方案
- 作为当前活动场景根节点下的服务
- 或通过 `SceneContext` 注入给 runtime 系统
- 由 `GameStateMachine` 或当前场景自行获取

---

## 6.2 RaidController
### 原因
只在战局场景中存在，属于场景运行时逻辑，不应全局常驻。

---

## 6.3 SafeZoneController
### 原因
只在安全区场景中存在，不应全局常驻。

---

## 6.4 QuestSystem / TradeSystem / FarmingSystem / AutomationSystem
### 原因
这些可以有**全局进度数据**，但具体运行时控制器应由安全区场景承载。  
真正需要全局常驻的是它们的**存档数据与配置访问**，不是 scene controller 本身。

---

# 7. 初始化顺序建议

推荐初始化顺序如下：

1. `AppBootstrap`
2. `EventBus`
3. `ConfigService`
4. `SaveService`
5. `RegistryService`
6. `InputService`
7. `AudioService`
8. `SceneFlowService`
9. `GameStateMachine`

> 注：实现层面可以由 `AppBootstrap` 协调其余服务初始化，但逻辑顺序建议按上面执行。

---

# 8. 建议的 Autoload 注册顺序

Godot 中建议的 Autoload 注册表顺序如下：

1. `EventBus`
2. `ConfigService`
3. `SaveService`
4. `RegistryService`
5. `InputService`
6. `AudioService`
7. `SceneFlowService`
8. `GameStateMachine`
9. `AppBootstrap`

这样做的原因是：
- `AppBootstrap` 在 `_ready()` 时可以直接访问前面所有服务
- `GameStateMachine` 可以直接调用 `SceneFlowService` 与 `InputService`
- `AudioService` 启动时可以读取 `ConfigService`
- `RegistryService` 初始化时可读取存档或配置中的 debug/content 选项

---

# 9. 推荐目录位置

```text name=autoload_structure.txt
game/core/
  bootstrap/
    AppBootstrap.gd
  app_state/
    GameStateMachine.gd
  events/
    EventBus.gd
  config/
    ConfigService.gd
  save/
    SaveService.gd
  services/
    registry/RegistryService.gd
    input/InputService.gd
    audio/AudioService.gd
    scene_flow/SceneFlowService.gd
```

---

# 10. 与第三方插件的对应关系

| 项目内服务 | 第三方来源 | 说明 |
|---|---|---|
| `RegistryService` | `0999312/Minecraft-Style-Framework` | 内容注册与查询适配层 |
| `InputService` | `godotneers/G.U.I.D.E` | 输入上下文、重绑定、prompt 适配层 |
| `AudioService` | `Maaack/Godot-Game-Template` | UI 音效/BGM 基础能力统一入口 |
| `SceneFlowService` | `Maaack/Godot-Game-Template` | loading + scene loader 统一入口 |
| `CameraService` | `ramokz/phantom-camera` | 不建议做全局 Autoload，建议做场景级服务 |

---

# 11. 最小实现建议

如果想在最短时间内落地，建议第一批只实现以下 6 个核心 Autoload：

- `EventBus`
- `ConfigService`
- `RegistryService`
- `InputService`
- `SceneFlowService`
- `GameStateMachine`

随后再补：
- `AudioService`
- `SaveService`
- `AppBootstrap`

这样可以先把“能跑起来”和“能切状态”打通，再逐步补全工程服务。

---

# 12. 风险与控制

## 12.1 风险：Autoload 过多导致全局依赖网膨胀
控制方案：
- 所有新单例都必须通过“是否跨场景常驻”审查
- 场景内控制器禁止升级为全局单例，除非有强理由

## 12.2 风险：服务之间循环依赖
控制方案：
- 只允许 `AppBootstrap` 负责协调初始化
- 服务之间尽量单向依赖
- 事件通知优先于直接调用

## 12.3 风险：业务层直接使用插件 API
控制方案：
- 在 code review 规则中明确禁止
- 统一通过服务层访问第三方能力

---

# 13. 结论

本项目推荐采用“**少量核心 Autoload + 场景级运行时控制器**”结构。

核心建议：
- 全局只保留跨场景基础服务
- 玩法与场景逻辑留在 runtime scene 中
- 第三方插件必须通过项目适配层暴露
- `CameraService` 不做全局单例，避免镜头生命周期问题

这种方式最适合当前项目的组合方案：
- Maaack 作为工程壳
- Minecraft-Style-Framework 作为内容系统核心
- G.U.I.D.E 作为输入层
- Phantom Camera 作为场景级镜头系统