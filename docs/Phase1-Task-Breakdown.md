# 第一阶段落地任务清单
> 阶段目标：完成工程壳、基础插件接入、适配层建立，并跑通“主菜单 -> 测试场景 -> 返回”的最小流程  
> 当前日期：2026-03-12

---

# 1. 阶段目标定义

第一阶段只关注以下目标：

1. 建立可运行 Godot 工程基础壳
2. 接入并验证：
   - Maaack/Godot-Game-Template
   - 0999312/Minecraft-Style-Framework
   - godotneers/G.U.I.D.E
   - ramokz/phantom-camera
3. 建立核心适配层：
   - RegistryService
   - InputService
   - CameraService
   - AudioService
   - SceneFlowService
4. 跑通最小流程：
   - 启动项目
   - 进入 Main Menu
   - 切换到测试场景
   - 相机跟随玩家
   - 输入可正常工作
   - 返回菜单
5. 不进入复杂玩法系统实现

---

# 2. 第一阶段不包含内容

以下内容不在第一阶段范围内：
- 完整战斗系统
- Grid inventory
- 敌人 AI
- 撤离逻辑
- 任务系统
- 商人交易
- 科技树
- 农业/工业自动化
- 存档版本迁移
- 高级音频系统增强
- 第二套 Scene Manager 引入

---

# 3. 任务分组总览

## 3.1 工程初始化
- T001 创建项目基础仓库结构
- T002 导入 Maaack 模板
- T003 验证主菜单/设置/暂停/加载页面

## 3.2 内容系统接入
- T010 导入 Minecraft-Style-Framework
- T011 建立 RegistryService
- T012 注册最小测试内容
- T013 完成注册内容查询验证

## 3.3 输入系统接入
- T020 导入 G.U.I.D.E
- T021 建立输入上下文
- T022 建立 InputService
- T023 验证键鼠/手柄切换
- T024 验证输入提示

## 3.4 摄像机系统接入
- T030 导入 Phantom Camera
- T031 创建测试 Player Scene 与 Camera Rig
- T032 建立 CameraService
- T033 验证基础跟随镜头

## 3.5 服务层与流程接入
- T040 建立 SceneFlowService
- T041 建立 AudioService
- T042 建立 AppBootstrap
- T043 建立 GameStateMachine 最小版本

## 3.6 测试场景打通
- T050 创建 TestMap
- T051 创建 TestPlayer
- T052 主菜单进入 TestMap
- T053 TestMap 返回菜单
- T054 完成阶段验收

---

# 4. 详细任务清单

## T001 创建项目基础仓库结构
### 目标
建立统一目录结构，为后续插件与项目代码接入留出空间。

### 输出
- `addons/`
- `game/core/`
- `game/content/`
- `game/runtime/`
- `game/scenes/`
- `game/resources/`

### 完成标准
- 目录结构可在 Godot 工程中正常识别
- 不存在命名冲突
- 约定结构已写入 README 或项目说明

---

## T002 导入 Maaack 模板
### 目标
将 Maaack/Godot-Game-Template 作为项目基础壳导入。

### 子任务
- 下载/克隆模板
- 导入工程或提取模板功能
- 识别其菜单、设置、暂停、loading 相关结构
- 确认 Godot 版本兼容

### 完成标准
- 项目能正常打开
- Main Menu 可显示
- Options 页面可进入
- Pause 页面可正常触发
- Loading Screen 可调用

### 依赖
- T001

---

## T003 验证主菜单/设置/暂停/加载页面
### 目标
确认 Maaack 基础壳在本项目中可正常工作。

### 子任务
- 验证 UI 导航
- 验证分辨率/音量等设置可生效
- 验证暂停流程
- 验证加载页面不会报错

### 完成标准
- 所有基础页面无阻塞性错误
- Settings 可持久化至少一个配置项
- Main Menu -> 任意测试场景 -> 返回流程可运行

### 依赖
- T002

---

## T010 导入 Minecraft-Style-Framework
### 目标
接入内容系统核心框架。

### 子任务
- 将框架放入 `addons/` 或第三方目录
- 若为插件则启用插���
- 明确最小初始化入口
- 检查是否能在 Godot 中正常加载

### 完成标准
- 工程打开后不报插件级错误
- 项目启动时能执行内容系统初始化

### 依赖
- T001

---

## T011 建立 RegistryService
### 目标
创建项目内部内容注册适配层，避免业务层直接依赖外部框架。

### 建议接口
- `get_item_definition(id)`
- `get_entity_definition(id)`
- `get_scene_prefab(id)`
- `query_by_tag(tag)`
- `has_definition(id)`

### 完成标准
- RegistryService 可被单例或服务定位正常调用
- 至少一类注册内容可以被查询

### 依赖
- T010

---

## T012 注册最小测试内容
### 目标
准备一组最小测试数据，验证内容注册工作流。

### 推荐测试内容
- `item.test_bandage`
- `entity.test_player_dummy`
- `scene.test_map`
- `status.test_heal`

### 完成标准
- 数据可成功注册
- 不同类型定义可按 ID 查询

### 依赖
- T011

---

## T013 完成注册内容查询验证
### 目标
验证 RegistryService 在工程中的可用性。

### 子任务
- 启动时打印部分定义信息
- 按 ID 查询
- 按 Tag 查询
- 查询不存在 ID 的失败处理

### 完成标准
- 查询结果稳定
- 错误处理明确
- 查询接口可供后续模块复用

### 依赖
- T012

---

## T020 导入 G.U.I.D.E
### 目标
接入统一输入插件。

### 子任务
- 安装插件
- 启用插件
- 确认插件在当前 Godot 版本下正常运行

### 完成标准
- 工程启���无插件级报错
- 插件功能可在项目中调用

### 依赖
- T001

---

## T021 建立输入上下文
### 目标
定义项目输入上下文，为后续玩法开发打基础。

### 建议上下文
- `global`
- `main_menu`
- `raid`
- `inventory`
- `dialogue`
- `pause_menu`

### 完成标准
- 至少 `main_menu` 与 `raid` 两个 context 可切换
- 切换后对应输入行为生效范围正确

### 依赖
- T020

---

## T022 建立 InputService
### 目标
封装 G.U.I.D.E 对外接口。

### 建议接口
- `set_context(name)`
- `push_context(name)`
- `pop_context()`
- `is_action_pressed(action)`
- `is_action_just_pressed(action)`
- `get_move_vector()`
- `get_aim_vector()`
- `get_prompt(action)`

### 完成标准
- 菜单与测试场景都通过 InputService 访问输入
- 业务代码不直接散落依赖插件 API

### 依赖
- T021

---

## T023 验证键鼠/手柄切换
### 目标
确认 G.U.I.D.E 在项目中的多设备输入正常。

### 子任务
- 键盘导航菜单
- 手柄导航菜单
- 测试场景中键盘移动
- 测试场景中手柄移动/瞄准

### 完成标准
- 键鼠与手柄都可工作
- 设备切换后输入不中断

### 依赖
- T022

---

## T024 验证输入提示
### 目标
确认项目可获取对应设备的输入提示。

### 子任务
- 读取某个 action 的当前 prompt
- 在 UI 中显示提示
- 切换设备后验证提示变化

### 完成标准
- 至少一个 UI 组件成功显示动态提示
- 键鼠与手柄提示能切换

### 依赖
- T022

---

## T030 导入 Phantom Camera
### 目标
接入摄像机插件。

### 子任务
- 安装插件
- 启用插件
- 验证无工程冲突

### 完成标准
- 工程打开正常
- 插件可创建相关节点/组件

### 依赖
- T001

---

## T031 创建测试 Player Scene 与 Camera Rig
### 目标
建立最小测试玩家与相机绑定结构。

### 场景建议
- `TestPlayer.tscn`
- `FollowCameraRig.tscn`

### 完成标准
- Player 场景可实例化
- 相机可绑定并跟随玩家

### 依赖
- T030

---

## T032 建立 CameraService
### 目标
封��� Phantom Camera 使用方式。

### 建议接口
- `set_follow_mode()`
- `set_dialogue_mode()`
- `set_combat_mode()`
- `reset_default_camera()`

### 完成标准
- 外部代码无需直接控制插件细节
- 至少默认跟随模式可正常切换/恢复

### 依赖
- T031

---

## T033 验证基础跟随镜头
### 目标
确认玩家移动时镜头可稳定跟随。

### 子任务
- 测试不同移动方向
- 测试镜头平滑参数
- 测试场景切换后镜头初始化

### 完成标准
- 镜头不抖动
- 场景进入与退出无异常残留状态
- CameraService 可稳定控制默认镜头

### 依赖
- T032

---

## T040 建立 SceneFlowService
### 目标
对 Maaack Scene Loader 做统一封装。

### 建议接口
- `go_to_main_menu()`
- `go_to_test_map()`
- `reload_current_scene()`

### 完成标准
- 场景切换逻辑从业务层分离
- 至少主菜单和测试地图切换可通过该服务完成

### 依赖
- T002

---

## T041 建立 AudioService
### 目标
对 Maaack 自带音频功能建立统一访问层。

### 建议接口
- `play_ui_click()`
- `play_ui_back()`
- `play_bgm(id)`
- `set_bus_volume(bus, value)`

### 完成标准
- 菜单点击音效可经 AudioService 触发
- 至少一条 BGM 可经 AudioService 切换

### 依赖
- T002

---

## T042 建立 AppBootstrap
### 目标
建立工程统一启动入口。

### 职责
- 初始化服务
- 初始化 Registry
- 初始化输入系统
- 初始化音频系统
- 进入初始状态

### 完成标准
- 启动顺序稳定
- 所有服务初始化有明确日志
- 启动失败可定位问题

### 依赖
- T011
- T022
- T032
- T040
- T041

---

## T043 建立 GameStateMachine 最小版本
### 目标
建立最小全局状态机。

### 建议状态
- `BOOT`
- `MAIN_MENU`
- `TEST_MAP`
- `PAUSED`

### 完成标准
- 项目可在状态间切换
- 状态变化有日志
- 不同状态会切换输入上下文

### 依赖
- T042

---

## T050 创建 TestMap
### 目标
建立一个最小测试场景，用于验证输入、相机、切场。

### 内容建议
- 简单地面
- 障碍物
- 玩家出生点
- 返回菜单触发点或快捷键

### 完成标准
- TestMap 可独立运行
- 玩家可在其中移动

### 依赖
- T031

---

## T051 创建 TestPlayer
### 目标
建立最小可操作角色。

### 内容建议
- CharacterBody2D / Node2D 根节点
- 简单移动组件
- 输入读取
- 相机锚点

### 完成标准
- 玩家可在 TestMap 中响应输入移动
- 后续可作为 Combat/Inventory 容器继续扩展

### 依赖
- T022
- T031

---

## T052 主菜单进入 TestMap
### 目标
打通主菜单到测试场景的流程。

### 子任务
- 新增菜单入口
- 调用 SceneFlowService
- 切换 GameState

### 完成标准
- 从主菜单点击开始可进入 TestMap
- 进入时加载流程正常显示

### 依赖
- T040
- T043
- T050
- T051

---

## T053 TestMap 返回菜单
### 目标
打通测试场景返回主菜单流程。

### 子任务
- 增加快捷键或按钮
- 调用 SceneFlowService
- 恢复菜单输入上下文

### 完成标准
- 可稳定返回 Main Menu
- 返回后菜单输入可正常使用
- 镜头/输入状态正确重置

### 依赖
- T052

---

## T054 完成阶段验收
### 目标
确认第一阶段目标全部达成。

### 验收清单
- 项目可启动
- 主菜单正常
- 设置正常
- 加载页面正常
- RegistryService 可查询最小测试内容
- InputService 可处理键鼠/手柄
- CameraService 可控制默认跟随相机
- 主菜单 -> TestMap -> 返回菜单 流程完整

### 产出
- 阶段总结
- 已知问题清单
- 第二阶段输入条件清单

### 依赖
- 所有前置任务

---

# 5. 验收标准

## 5.1 功能验收
必须满足：
- 项目启动后可进入主菜单
- 至少一个设置项可保存
- TestMap 可加载
- TestPlayer 可移动
- 相机可跟随
- 返回菜单可成功
- 最小注册内容可查询
- 键鼠/手柄至少一套流程验证通过

## 5.2 工程验收
必须满足：
- 没有阻塞性启动错误
- 插件间无明显冲突
- 核心适配层已建立
- 业务代码不直接散落依赖外部插件

---

# 6. 优先级建议

## P0
- T001
- T002
- T010
- T020
- T030
- T040
- T042

## P1
- T011
- T021
- T022
- T031
- T032
- T050
- T051
- T052
- T053

## P2
- T012
- T013
- T023
- T024
- T033
- T041
- T043
- T054

---

# 7. 第一阶段完成后的下一步

阶段 1 完成后，建议立即进入阶段 2：
- 基础战斗输入
- 基础交互
- 最小敌人
- 最小容器
- 最小撤离点
- 最小战局结算

这样可以尽快从“工程壳”进入“玩法闭环”。