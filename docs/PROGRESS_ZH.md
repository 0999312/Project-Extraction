# Project Extraction — 开发进度

## 更新 21 — 物品栏设计整改（移除形状、隐藏武器快捷栏、场景化布局）

### 变更内容

- **移除自定义物品形状（pattern）**：
  - 从 `ItemDefinition` 移除 `pattern` 字段。所有物品现在均为严格矩形（`size_w × size_h`）。
  - 简化 `GridInventory` 中 `_get_item_cells()` 为始终生成填充矩形。
  - 简化 `InventoryGridPanel` 中渲染和拖拽预览——不再逐格迭代。
- **物品栏菜单中隐藏武器快捷栏槽位（0–2）**：
  - 物品栏菜单快捷栏条带仅显示第 3–8 格。
  - 武器槽专门通过装备面板管理。
  - `_refresh_hotbar_ui()` 正确映射 UI 索引到数据索引。
- **物品栏菜单应用 `minimal_vector.tres` 主题**：
  - 主题通过场景文件（`inventory_menu.tscn`）设置，不在运行时加载。
  - 所有快捷栏槽圆角设为 0 px（原为 8 px）。网格格子圆角已是 0 px。
- **保留存档/读取接口（不实际调用）**：
  - `save_to_dict()` / `load_from_dict()` 存在于 `GridInventory` 和 `EquipmentState`。
  - 运行时不调用——保留给后续持久化使用。
- **将静态 UI 布局转为场景文件**：
  - 静态布局（根控件、背景、滚动容器、居中容器、主横向布局、装备面板、右侧纵向布局、标题标签、网格容器、快捷栏容器）定义在 `inventory_menu.tscn` 中。
  - 动态部分（装备槽行、快捷栏槽面板、网格面板）仍在代码中生成。
  - 脚本使用 `@onready` 引用替代 `Control.new()` 创建静态节点。
- **更新文档**：
  - 更新 `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md` 至 v0.5。
  - 更新 `ITEM_REGISTRY.md` / `ITEM_REGISTRY_ZH.md` 移除 pattern 字段。
  - 更新进度文档。

---

## 更新 20 — 物品栏系统增强（形状、稀有度、堆叠合并、存档/读取）

### 变更内容

- **修复物品栏格子内贴图渲染**：
  - 物品图标现在绘制在网格线和边框之上（绘制顺序：网格线 → 物品 → 拖拽预览）。
  - 用 `fit_inside_rect` 替换 `fit_by_height_rect`，确保物品图标不会超出格子边界（按宽高双向缩放，双轴居中）。
  - 网格面板使用 `clip_contents = false`，物品贴图不被 PanelContainer 边框裁切。
- **限制物品栏快捷栏武器槽位**：
  - 快捷栏第 0–2 格（武器槽）不再允许从容器网格直接拖拽分配。在物品栏网格视图中为只读，只能通过装备面板（主武器/副武器/近战武器）管理。
  - 快捷栏第 3–8 格仍可通过网格拖拽接受任何物品。
- **实现物品堆叠合并**：
  - 将拖拽的物品堆叠放到已有的同类物品堆叠上时，数量自动合并（上限为 `max_stack`）。
  - 完全合并则结束拖拽，部分合并则剩余数量保持拖拽状态。
  - 堆叠数量（>1）显示在物品矩形的右下角，带阴影以增强可读性。
- **新增物品稀有度系统**：
  - `ItemDefinition` 新增 `rarity` 字段（`int`，0–5：无/普通/优良/稀有/史诗/传说）。
  - 物品以稀有度着色背景渲染：默认蓝灰色、绿色（优良）、蓝色（稀有）、紫色（史诗）、金色（传说）。
- **新增自定义物品形状（不规则占位）**：
  - `ItemDefinition` 新增 `pattern` 字段（`Array[Vector2i]`），用于定义非矩形占位形状。
  - `GridInventory` 的 `can_place()`、`place_item()`、`remove_item()`、`get_placement_at()` 均使用形状感知的逐格迭代。
  - 形状旋转：拖拽时右键将形状格子顺时针旋转 90°。
  - 网格面板为形状物品逐格渲染背景色；拖拽预览逐格高亮占位区域。
- **新增物品栏存档/读取 API**：
  - `GridInventory.save_to_dict()` / `load_from_dict()` 序列化/恢复完整物品栏状态，包括放置记录、快捷栏和 ItemStack 数据。
  - `EquipmentState.save_to_dict()` / `load_from_dict()` 序列化/恢复装备槽位和所有容器网格。
- **更新文档**：
  - 更新 `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md` 至 v0.4。
  - 更新进度文档。

---

## 更新 19 — MSF UIManager 集成 / UI 系统重构

### 变更内容

- **将所有游戏 UI 重构为使用 MSF `UIManager` 栈式面板管理**：
  - `PlayerHUD` 从 `CanvasLayer` 改为 `Control`，通过 `UIManager.add_overlay()` 注册在 `UILayer.SCENE`。
  - `InventoryMenu` 从 `CanvasLayer` 改为 `UIPanel`，通过 `UIManager.open_panel()` / `UIManager.back()` 在 `UILayer.NORMAL` 管理。
  - 新增 `PauseMenuPanel` 继承 `UIPanel`，通过 `UIManager.open_panel()` 在 `UILayer.POPUP` 打开。
  - 从 `DemoGame.tscn` 中移除了旧的 Maaacks `PauseMenuController` 依赖。
- **修复了物品栏与暂停菜单的 ESC 按键冲突**：
  - `InventoryMenu._unhandled_input()` 现在消费 `ui_cancel` 以通过 `UIManager.back(NORMAL)` 关闭物品栏。
  - `PauseMenuPanel._unhandled_input()` 消费 `ui_cancel` 以通过 `UIManager.back(POPUP)` 关闭暂停。
  - `DemoGameRuntime._poll_pause_input()` 仅在没有其他面板打开时才打开暂停菜单。
  - 栈式层级排序保证正确的输入优先级。
- **引入 `UICatalog` 实现注册表驱动的 UI 面板注册**：
  - 遵循与 `ItemCatalog`、`WeaponCatalog` 等相同的目录模式。
  - 注册 `game:ui/pause_menu`（POPUP，CacheMode.NONE）和 `game:ui/inventory`（NORMAL，CacheMode.CACHE）。
- **将脚本构建的 UI 转换为 Godot 场景**：
  - 新增 `scenes/game_scene/ui/pause_menu_panel.tscn`，包含完整按钮布局和确认对话框。
  - 新增 `scenes/game_scene/ui/inventory_panel.tscn` 作为物品栏的 UIPanel 根节点。
  - 更新 `scenes/game_scene/player_hud.tscn` 根节点从 `CanvasLayer` 改为 `Control`。
- **按 MSF 模式进行结构改进**：
  - 所有 HUD 元素现使用 `mouse_filter = MOUSE_FILTER_IGNORE` 避免阻挡输入。
  - 物品栏数据（网格、装备）通过 `_on_open(data)` 字典传递，而非直接方法调用。
  - 面板生命周期回调取代手动的打开/关闭/切换。
- **新增文档**：
  - 新增 `UI_SYSTEM_REFACTOR.md` / `UI_SYSTEM_REFACTOR_ZH.md`。
  - 更新进度文档。

---

## 更新 18 — Minimal Vector 主题设计文档补全

### 变更内容

- **将当前 `minimal_vector` 主题提炼为独立设计文档**：
  - 新增 `MINIMAL_VECTOR_THEME_DESIGN.md` 与 `MINIMAL_VECTOR_THEME_DESIGN_ZH.md`。
  - 记录了主题的作用范围、配色结构、控件覆盖情况以及后续修改准则。
  - 明确区分了全局主题资源与游戏内局部样式覆写（背包格子、快捷栏格子、装备占位槽）的边界。
- **不改动实现逻辑**：
  - 本次更新仅补充文档，不修改现有主题资源和游戏 UI 行为。

---

## 更新 17 — 装备槽拖拽卸下流程 + Minimal Vector 主题配色整理

### 变更内容

- **装备面板现在支持基于拖拽的装备 / 卸下**：
  - 现在可以把容器网格中的物品拖到兼容的装备槽上完成装备。
  - 现在可以把非背包装备槽中的已装备物品拖回容器网格，从而完成卸下。
  - 把已装备物品从一个兼容装备槽拖到另一个兼容装备槽时，会把该物品重新绑定到新的槽位。
  - 背包槽在它仍作为物品栏主存储来源时保持锁定，避免主背包网格被意外拆下。
- **在尽量少改现有结构的前提下复用了原有拖拽流程**：
  - `InventoryGridPanel` 新增了轻量级外部放下钩子，用于接收从装备槽拖出的物品。
  - 装备槽交互逻辑集中补在 `InventoryMenu` 中，没有重写原有网格拖拽系统。
- **更新 `minimal_vector.tres` 配色，但不改已定型按钮颜色**：
  - 保持 `Button` 的 normal / hover / pressed / focus 配色不变。
  - 调整了面板背景、标签页表面、滚动条、进度条背景、输入框选区 / 填充等非按钮主题元素。
  - 新配色更贴近参考图：更明亮的青蓝、水绿色、更鲜艳的草地绿、更暖的橙棕，以及更醒目的黄色标签页强调色。
- **文档同步更新**：
  - 更新 `EQUIPMENT_SYSTEM.md` / `EQUIPMENT_SYSTEM_ZH.md`。
  - 更新 `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md`。
  - 更新进度文档。

---

## 更新 16 — 快捷栏正方形布局 + 物品栏场景/玩家库存绑定

### 变更内容

- **快捷栏视觉更新为固定正方形**：
  - HUD 快捷栏在普通态与选中态下都保持 `56 × 56`。
  - 选中快捷栏格现在只会把填充色切换为半透明绿色（`alpha = 64`），不再放大尺寸。
  - 物品栏菜单中的快捷栏样式也已同步到与 HUD 一致。
- **物品栏场景现在绑定到玩家真实库存**：
  - `DemoGameRuntime` 现在会实例化 `scenes/game_scene/inventory_menu.tscn`，而不是仅通过 `InventoryMenu.new()` 构造菜单。
  - 玩家自身的 `InventoryState.inventory` 现在作为背包网格使用，因此玩家运行时、HUD 与物品栏菜单共享同一份库存数据。
  - 玩家初始库存尺寸已整理为文档规定的默认背包大小 `6 × 6`。
- **装备面板现在镜像实时装备状态**：
  - 物品栏菜单的装备面板现在会显示每个可见装备槽当前绑定的物品名称 / 回退标签。
  - 背包与弹挂的网格标题现在会同时展示已装备容器名称与网格尺寸。
  - 快捷栏槽位绑定结果会反向同步回 `EquipmentState`，使武器 / 可用物槽位状态与物品栏界面保持一致。
- **快捷栏保留规则进一步收紧**：
  - 快捷栏 `0–2` 号槽位现在只接受带有 `weapon` 标签的物品，和装备系统设计保持一致。
  - 选中非武器快捷栏物品时，不再覆盖 `combat_state.equipped_weapon_id`。
- **文档已同步更新**：
  - 更新 `HUD_HOTBAR_DESIGN.md` / `HUD_HOTBAR_DESIGN_ZH.md`。
  - 更新 `EQUIPMENT_SYSTEM.md` / `EQUIPMENT_SYSTEM_ZH.md`。
  - 更新 `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md`。
  - 更新进度文档。

---

## 更新 15 — 装备系统 + UI 全面重构（无贴图）

### 变更内容

- **新增装备系统（`EquipmentState`）**：
  - 新组件：`scripts/game/components/gameplay/equipment_state.gd`。
  - 定义 14 个装备槽位：主武器/副武器/近战武器、6 格可用物品快捷栏、护甲、耳机、头盔、背包、战术弹挂。
  - 容器槽位（背包、弹挂）各自拥有独立的 `GridInventory` 实例。
  - 设计注重拓展性 — 在 `SLOT_KEYS` 中追加条目即可新增槽位，不影响已有代码/存档。
  - `sync_weapons_to_hotbar()` 将已装备武器推送至快捷栏第 0-2 格。
- **重写快捷栏 UI 为 StyleBoxFlat（无贴图/材质）**：
  - 每个快捷栏格子现为 `PanelContainer` + `StyleBoxFlat`（原为 `TextureRect` + `hud_item.png`）。
  - 主题：6 px 纯黑边框，8 px 圆角，背景透明度 = 64。
  - 选中格：略微放大（56→64 px），深蓝色填充。
- **重写物品栏网格格子为 StyleBoxFlat（无贴图/材质）**：
  - `InventorySlot` 从 `TextureRect` 改为 `PanelContainer` + `StyleBoxFlat`。
  - 主题：6 px 纯黑边框，0 px 圆角（无圆角），背景透明度 = 64。
- **物品栏菜单改为按装备生成不同的网格**：
  - 默认玩家装备背包（6×6）和战术弹挂（3×2）。
  - 装备面板（左侧）显示所有装备类别的占位槽。
  - 容器网格（右侧）根据已装备容器动态生成。
- **物品贴图使用按高度适宜比例缩放**：
  - `InventoryGridPanel` 新增 `_fit_by_height_rect()` 方法，保持纵横比，缩放至格子高度，水平居中。
  - 物品图标绘制在网格上方，不受物品栏面板蒙版影响。
- **更新 `DemoGameRuntime`**：
  - 启动时创建 `EquipmentState`，默认配备背包 + 战术弹挂。
  - 同时将物品栏网格和装备状态绑定到 `InventoryMenu`。
  - HUD 绑定背包网格用于快捷栏显示。
- **更新国际化文本**：
  - 新增 `action_hotbar_next` 和 `action_hotbar_prev` 文本（英文 + 中文）。
- **新增文档**：
  - 新增 `EQUIPMENT_SYSTEM.md` / `EQUIPMENT_SYSTEM_ZH.md`。
  - 更新 `HUD_HOTBAR_DESIGN.md` / `HUD_HOTBAR_DESIGN_ZH.md`（v0.2）。
  - 更新 `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md`（v0.2）。
- **按键绑定已确认**：
  - `pe_inventory`（Tab）打开物品栏。
  - `pe_hotbar_1` 到 `pe_hotbar_9`（按键 1-9）选择快捷栏。
  - 全部通过 GUIDE 输入系统配置，支持完全重映射。

---

## 更新 14 — 中弹粒子特效 + 物品/背包/武器数据系统

### 变更内容

- **新增中弹粒子效果（不依赖额外精灵图）**：
  - 新场景：`scenes/vfx/hit_particle_effect.tscn`，仅使用 `CPUParticles2D`。
  - 新脚本：`scripts/game/vfx/hit_particle_effect.gd`。
  - 实现一次性喷溅粒子（短生命周期、重力、散射方向），用于子弹命中反馈。
  - 已在 `projectile.gd:on_hit` 中接入，命中时实例化并调用 `emit_hit(...)`。
- **实现物品系统（注册表驱动）**：
  - 新增 `ItemDefinition` 资源结构。
  - 新增 `ItemRegistry` + `ItemCatalog`，内置条目：
    - `game:item/weapon/pistol`
    - `game:item/weapon/creature`
    - `game:item/med/bandage`
    - `game:item/ammo/9x19`
- **实现背包系统（纯数据运行时结构）**：
  - 新增 `ItemStack` 与 `GridInventory`。
  - 更新 `InventoryState`：持有 `GridInventory`，支持 `add_item(...)`，并通过物品定义重量同步 `current_weight`。
- **基于物品系统实现武器系统**：
  - 新增 `WeaponDefinition`、`WeaponRegistry`、`WeaponCatalog`。
  - 武器条目从已装备物品 ID 映射到战斗参数（弹丸 ID、弹匣容量、散布、后坐、换弹时序）。
  - 新增 `WeaponCatalog.apply_to_combat_state(...)`，并已接入玩家/人类敌人/非人类敌人的运行时初始化逻辑。
  - `DemoGameRuntime` 启动时新增 item/weapon 注册表初始化。
- **同步更新设计文档**：
  - 扩展 `GDD_Version2.md` / `GDD_Version2_ZH.md`，补充物品→武器映射的运行时说明。
  - 新增 `ITEM_REGISTRY.md` / `ITEM_REGISTRY_ZH.md`。
  - 新增 `WEAPON_REGISTRY.md` / `WEAPON_REGISTRY_ZH.md`。

---

## 更新 13.4 — 人类受击箱隔离与子弹空中阻挡碰撞

### 变更内容

- **人类受击碰撞箱不再与地面/空中移动层发生碰撞**：
  - 将 `Player/HitCollision` 与 `HumanEnemy/HitCollision` 从直接 `CollisionShape2D` 改为 `Area2D`（`collision_layer = 1`，`collision_mask = 0`）并挂载子形状。
  - 将人类 `CharacterBody2D` 移动碰撞层收敛为地面层（`collision_layer = 2`），同时保留玩家交互层掩码。
- **子弹碰撞行为按文档与当前需求对齐**：
  - 保持对敌对目标的受击检测（语义对应第 1 层受击域）。
  - 在子弹运动系统中新增空中阻挡检测（物理射线查询）；命中空中阻挡体时子弹会过期销毁。
  - 在 `ProjectileData` 中显式补充子弹碰撞位字段（`layer=空中`、`mask=受击+空中`）以增强一致性与可维护性。
- **死亡态兼容性扩展**：
  - `BiologicalActor.on_death()` 现会同时关闭 `Area2D` 受击节点（`monitoring/monitorable=false`）并禁用其子 `CollisionShape2D`（若存在）。

---

## 更新 13.3 — 独立碰撞形状的层/掩码对齐修正

### 变更内容

- **按碰撞设计文档对齐实体 collision_layer / collision_mask**：
  - `Player`（`CharacterBody2D`）设置为 `collision_layer = 3`（受击+地面），`collision_mask = 10`（地面+交互）。
  - `HumanEnemy` 设置为 `collision_layer = 3`（受击+地面），`collision_mask = 2`（地面）。
  - `NonHumanEnemy` 设置为 `collision_layer = 5`（受击+空中），`collision_mask = 4`（空中）。
- **保留独立碰撞形状并确保职责分离**：
  - 人类实体继续使用独立的 `GroundCollision` 与 `HitCollision` 节点。
  - 地面移动碰撞与受击/交互域碰撞保持结构分离。
- **修正死亡时碰撞禁用兼容性**：
  - 更新 `BiologicalActor.on_death()`，在存在时禁用 `CollisionShape2D`、`GroundCollision`、`HitCollision`。
  - 同时兼容历史单碰撞体命名与当前分离碰撞体结构。
- **同步更新进度文档**。

---

## 更新 13.2 — 人类实体地面/受击碰撞分离与手部颜色同步

### 变更内容

- **确认人类实体使用分离的 Ground/Hit 碰撞形状**：
  - 已确认 `Player` 与 `HumanEnemy` 场景均使用独立的 `CollisionShape2D` 节点：
    - `GroundCollision` 用于与地面阻挡层的移动碰撞。
    - `HitCollision` 用于受击/交互域的重叠检测逻辑。
  - 地面碰撞与受击/交互职责不再共享同一个 `CollisionShape2D`。
- **实现人类实体替换体色时左右手同步换色**：
  - 更新 `HumanActor._apply_body_color()`，使 `LeftHand/HandSprite` 与 `RightHand/HandSprite` 使用与 `BodySprite` 相同的 `body_color` 着色。
  - 通过继承自动作用于 `Player` 与 `HumanEnemy`。
- **同步更新进度文档**。

---

## 更新 13.1 — 交互碰撞层、玩家颜色更新与物品翻转验证

### 变更内容

- **新增交互碰撞层（第 4 层）**：
  - 在碰撞层设计中新增第 4 层（`0x08`）作为**交互层**。
  - 用于物品拾取、战利品容器、交易终端等可交互对象。
  - 只有玩家掩码此层；可交互对象使用 `Area2D` 位于第 4 层进行重叠检测。
  - 同步更新 `COLLISION_LAYER_DESIGN.md` 和 `COLLISION_LAYER_DESIGN_ZH.md`，新增"可交互对象"章节并更新玩家掩码。
- **将玩家默认颜色更改为 `0xFFFF66`**：
  - 玩家 `_setup_runtime_state()` 中的 `body_color` 从 `Color(0.45, 0.65, 0.85)` 改为 `Color("ffff66")`。
- **验证瞄准翻转时手中物品是否正常翻转**：
  - 确认 AimPivot 中的物品节点（ItemPivot/ItemSprite、RightHand、LeftHand）作为 `AimPivot` 子节点，在朝左瞄准时正确继承 `scale.y = -1` 翻转。
  - 无需代码修改；`HumanActor` 中现有的 `_update_sprite_flip()` 对玩家和人类敌人场景均能正确处理。
- **同步更新进度文档**。

---

## 更新 13 — 精灵图翻转、人类体色、碰撞层设计文档与实体注册表文档

### 变更内容

- **根据瞄准方向翻转精灵图（以右方向为正方向）**：
  - 在 `HumanActor` 基类中新增 `_update_sprite_flip()` 方法。
  - 当瞄准方向朝左（`x < 0`）时，身体精灵水平翻转（`flip_h = true`），同时 `AimPivot` 的 Y 轴缩放取反（`scale.y = -1`），使手部和武器正确渲染。
  - 通过继承自动应用于玩家和人类敌人。
- **在人类角色基类中新增 `body_color` 变量**：
  - `HumanActor` 新增 `body_color: Color` 变量（默认 `Color.WHITE`）。
  - 在 `_ready()` 中通过 `_apply_body_color()` 将身体精灵的 `modulate` 设为 `body_color`。
  - 玩家在 `_setup_runtime_state()` 中设定预设蓝色色调（`Color(0.45, 0.65, 0.85)`）。
  - 未来的人类敌人或自定义皮肤可在 `super._ready()` 前覆盖 `body_color`。
- **碰撞层设计文档**：
  - 新增 `COLLISION_LAYER_DESIGN.md` 和 `COLLISION_LAYER_DESIGN_ZH.md`。
  - 第 1 层 = 受击碰撞（所有实体），第 2 层 = 地面碰撞（人类角色 + 地面 Tile），第 3 层 = 空中碰撞（非人类敌人、子弹、空中 Tile）。
  - Tile 可同时参与地面碰撞、空中碰撞或两者皆参与。
- **实体注册表文档**：
  - 新增 `ENTITY_REGISTRY.md`（英文，主版本）和 `ENTITY_REGISTRY_ZH.md`，遵循注册表设计模板。
  - 记录条目结构、校验规则、加载时机、运行时访问方式和当前条目。
- **同步更新进度文档**。

---

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

- 在实体场景和 Tile 地图中按 `COLLISION_LAYER_DESIGN.md` 实现碰撞层分配。
- 全局状态机重新设计（覆盖所有游戏流程和菜单）。
- 完善弹丸命中检测和伤害应用管道。
- 完整的敌人 AI 瞄准/射击集成。
- 背包 / 物品系统实现。
- 完整的关卡推进流程集成。
