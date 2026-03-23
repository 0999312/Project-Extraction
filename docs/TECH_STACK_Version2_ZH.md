# Project Extraction — 技术栈与架构 v0.3 (中文)

**日期:** 2026-03-16  
**目标:** 定义具体的技术栈，以及 MSF (注册表/标签/事件/国际化) + GECS (ECS) + Maaack 模板如何集成，包括实体类型特定的实现、安全屋家园系统和 Raid 地图生成工作流。

---

## 1) 仓库 / 插件 (已扫描并集成)

### 1.1 基础项目
- **Maaack/Godot-Game-Template**
  - 提供场景/菜单/选项/暂停模式，以及适合模板的项目结构。

### 1.2 内容框架 (ID、注册表、标签、事件、国际化)
- **0999312/Minecraft-Style-Framework (MSF)**
  - **ResourceLocation** (`命名空间:路径`) 是核心标识符。
  - **RegistryBase** 存储以 ResourceLocation 字符串为键的条目。
  - **RegistryManager** 自动加载，按类型名称管理注册表。
  - **TagRegistry** 管理 `Tag` 对象；每个标签引用一个 `registry_type: ResourceLocation`，并包含 RL 条目列表。
  - **EventBus** 用于解耦事件（以及取消/信号桥接）。
  - **I18n** 基于 JSON 的本地化。

### 1.3 ECS 运行时
- **csprance/gecs (GECS)**
  - 实体是持有组件资源的节点；系统查询并处理实体。
  - QueryBuilder 支持流畅查询、属性过滤器、关系和 `iterate()` 快速路径。
  - CommandBuffer 支持安全的延迟结构变更。

### 1.4 输入
- **godotneers/G.U.I.D.E**
  - 上下文驱动的输入，支持按键重绑定，设备支持。
  - 输出必须转换为模拟命令（而非直接操作节点）。

### 1.5 摄像机
- **ramokz/phantom-camera**
  - 跟随、平滑、约束、震动/抖动。
  - 通过摄像机桥接器由模拟事件控制。

### 1.6 场景加载/切换
- **Maaack Scene Loader** (优先选择，与 Maaack 模板生态系统配合)
  - 大型过渡（安全屋 ↔ Raid）强制使用。
  - 标准化加载画面和异步资源加载。

### 1.7 音频管理
- **@nathanhoad/godot_sound_manager**（推荐，易于使用）
  - 自动加载播放音效/背景音乐。
  - 通过音频桥接器包装，以便日后轻松替换。
  - 当前项目音频注册改为“按文件夹 + 文件名配置”
    （`scripts/audio/audio_catalog.gd`），由
    `scripts/audio/audio_registry_bootstrap.gd` 初始化。

### 1.8 本地化
- UI JSON 本地化由 `scripts/localization/localization_bootstrap.gd`
  独立初始化（与音频注册解耦）。
- 当前支持语言：`en`、`zh`。
- 当前语言写入 `AppSettings.GAME_SECTION` 的 `Language` 键，
  并可在 `game_options` 中切换。

---

## 2) 项目架构 (性能优先，ECS + 节点混合)

### 2.1 核心原则
**模拟是数据驱动的，可通过注册表寻址；表现层是节点驱动的。**  
任何游戏系统都不应依赖硬编码字符串；处处使用 `ResourceLocation`。

### 2.2 分层
1. **内容层 (MSF)**
   - 注册表：物品、标签、兴趣点、战利品表、任务、对话、科技、家园模块、Raid 模板。
2. **模拟层 (GECS)**
   - ECS 世界处理高频和高数量逻辑：
     - AI、抛射物、状态效果、战利品生成决策、任务状态转换。
3. **表现层 (Godot 节点)**
   - 玩家身体、精灵、视觉特效、UI、摄像机、场景片段。
4. **桥接层 (自动加载服务)**
   - InputBridge、AudioBridge、UIBridge、SceneFlowBridge、CameraBridge
   - 桥接器是**唯一**允许调用插件 API 的地方。

---

## 3) ResourceLocation (RL) 标准 (具体)

### 3.1 命名约定
- `game:*` 用于第一方内容。
- `core:*` 保留给框架注册表类型。
- 标签也是 RL，推荐模式：`game:tag/<标签名>`。

示例：
- 注册表类型：
  - `core:item`、`core:poi`、`core:loot_table`、`core:quest`、`core:scene`、`core:tag`
- 内容：
  - `game:item_weapon`、`game:item_med`
  - `game:poi_metro_station`
  - `game:loot_table_industrial`
  - `game:extract/edge_gate` *（如果您将撤离点实现为注册表条目）*

### 3.2 标签 (MSF TagRegistry)
- 每个标签必须声明它应用于哪个注册表类型：
  - 例如 `tag_id = game:tag/weapon_smg`
  - `registry_type = core:item`
- 标签条目是 RL（在 `Tag` 内以字符串形式存储）。

---

## 4) 数据定义与运行时结构 (实现细节)

### 4.1 物品定义 (MSF 注册表条目)
MSF 演示使用带有 `scene/script` 的 `ItemInfo`。对于本项目：
- 将核心物品元数据存储在类似 `ItemInfo` 的资源中（扩展或包装）。
- 保持背包物品为数据，而非节点。

**背包运行时：**
- `ItemStack { item_id: RL, count, durability?, custom_data }`
- `GridInventory { width, height, placements }`

**世界掉落物运行时：**
- ECS 实体 `E_ItemDrop` 带有组件 `C_ItemStack`，引用 `item_id` 和数量。
- 可选的节点视图用于精灵拾取提示。

### 4.2 兴趣点定义
兴趣点注册表条目包含：
- 片段场景 (PackedScene)
- 放置占地面积和规则
- 战利品配置 RL
- 生成配置 RL
- 任务挂钩 RL（可选）

### 4.3 战利品表
战利品表条目应由注册表驱动：
- 按生物群系/兴趣点/容器标签的规则
- 输出为 RL 物品 ID 或物品标签
- 约束：稀有度、最小/最大数量、权重

**延迟生成策略（性能）：**
- 仅在以下情况下生成战利品：
  - 容器打开时
  - 或区块激活时（玩家进入区块）

---

## 5) 实体类型实现 (按需求)

### 5.1 玩家 (节点 + ECS 混合)
- 节点：`CharacterBody2D` 用于移动/碰撞和动画。
- ECS：权威的游戏状态和战斗决策。

**同步路径：**
- 节点 → ECS：位置/瞄准
- ECS → 节点：状态效果、武器状态、摄像机抖动事件

### 5.2 敌人 (ECS 优先)
- ECS 处理 AI 状态、目标选择、武器使用、生命值。
- 节点视图最小化，并可根据区块激活/停用。

### 5.3 抛射物 (仅 ECS)
- ECS 更新位置，执行命中检测，施加伤害事件。
- 池化视觉特效，避免每个抛射物创建节点。

### 5.4 容器 (惰性 ECS 状态)
- 容器是兴趣点片段中的节点，用于交互触发。
- 首次交互时创建或激活 ECS 容器状态实体。

### 5.5 商人 (固定交互点；不是实体)
- 商人是安全屋中的**交互终端**（节点）。
- 商人行为通过 `trader_id: RL` 和注册表定义进行数据驱动。
- 不存在 NPC 商人 ECS 实体。

---

## 6) 安全屋家园系统 (架构)

### 6.1 家园模块注册表
创建一个注册表 `core:home_module`：
- 每个模块：建造花费（物品标签）、前置条件（科技 RL）、解锁效果（配方、仓库容量、商人等级、地图扩展）

### 6.2 自动化模型
使用基于图的物流模拟：
- 节点：生产者/处理器/存储/电源
- 边：传输链接
- 基于 tick 的处理，带有吞吐量上限

这有利于确定性且可扩展。

### 6.3 地图扩展
安全屋划分为多个区域：
- 扩展解锁新房间/地块/站点
- 扩展也解锁新的商人终端/制作站

所有扩展由 RL 定义，以确保存档稳定。

---

## 7) Raid 地图生成 (具体管道)

### 7.1 输入
- `raid_template_id: RL`
- 种子
- 生物群系标签
- 难度标量

### 7.2 步骤
1. 生成基础地形 TileMap。
2. 划分为区域（城市/工业区/田野/森林）。
3. 放置主要兴趣点，带有距离约束。
4. 按区域密度散布次要兴趣点。
5. 验证出生点、兴趣点和撤离候选点之间的连通性。
6. 为每个兴趣点分配战利品/生成配置。
7. 选择出生区域。
8. 放置撤离点：
   - 1–2 个始终可用的固定撤离点，远离出生点
   - 1–4 个条件撤离点（钥匙/支付/电源开关/时间窗口）
9. 预计算区块元数据以用于激活/停用。

### 7.3 区块激活 (优化)
- 当区块激活时：
  - 如果未加载，实例化兴趣点片段
  - 激活敌人生成
  - 启用容器交互
- 当区块停用时：
  - 使半径外的实体 AI 系统休眠
  - 如果安全，卸载高负载视觉效果

---

## 8) 存档系统 (多存档位，RL 安全)

### 8.1 存档位结构
每个存档位存储：
- 仓库网格背包
- 安全屋模块状态
- 科技树解锁（情报驱动）
- 任务和商人进度
- 对内容的引用以 RL 字符串形式

### 8.2 版本控制与兼容性
存储：
- `save_version`
- 基于 RL 键的 `content_manifest_hash`
缺失 RL 的回退：
- 转换为 `game:item_unknown_salvage` 或退还价值

---

## 9) 桥接器 (集成契约)

- **InputBridge:** G.U.I.D.E → MSF EventBus 命令事件 → ECS 消费
- **AudioBridge:** ECS `PlaySfxEvent` → @nathanhoad/godot_sound_manager
- **SceneFlowBridge:** 撤离/死亡请求 → Maaack Scene Loader 过渡
- **UIBridge:** ECS 状态 → UI 更新（事件驱动）
- **CameraBridge:** ECS 受击/爆炸事件 → phantom-camera 震动/抖动

---

## 10) 实施清单 (面向待办事项)
- [ ] 定义 RL 命名空间和注册表类型 RL
- [ ] 实现物品/兴趣点/战利品/任务/科技/家园模块的注册表条目
- [ ] 实现武器/医疗/弹药/情报等的标签集
- [ ] 实现背包数据结构 + 网格放置逻辑
- [ ] 实现 Raid 生成管道 + 撤离点放置规则
- [ ] 实现容器延迟战利品生成系统
- [ ] 实现安全屋家园系统模块 + 建造/升级 + 自动化图
- [ ] 实现多存档位保存 + 版本控制/迁移
- [ ] 实现 ECS 桥接器和实体类型特定的管道

---

## 11) 当前选项与输入界面调整

- `game_options` 已增加语言切换（English / 简体中文），并持久化到
  `GameSettings.Language`。
- 按键绑定界面整理为表格：
  - 列：`键盘` / `鼠标` / `手柄`
  - 行：具体操作
  - 方向移动采用明确文本行：
    - `向上移动`、`向下移动`、`向左移动`、`向右移动`
