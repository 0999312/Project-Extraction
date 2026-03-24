# 音频注册表说明

## 1. 目的

项目使用独立的音频注册表来管理 UI 音效、游戏内音效和音乐，并按分类与加载阶段组织资源。当前实现保持简单：先在目录配置中声明音频，再统一加载进注册表，最后通过辅助方法消费，避免在 UI 或玩法脚本中到处散落硬编码的 `load(...)` 调用。

## 2. 相关文件

- `scripts/audio/audio_registry.gd`
- `scripts/audio/audio_catalog.gd`
- `scenes/opening/opening.gd`
- `scenes/loading_screen/loading_screen.gd`

## 3. 运行时流程

### 3.1 启动阶段

`opening.gd` 在 `_ready()` 中执行启动阶段注册：

1. 先确保本地化初始化完成
2. 调用 `AudioCatalog.ensure_registry_and_register(AudioCatalog.STARTUP_AUDIO_GROUPS)`
3. 使用注册好的 UI 音频流配置菜单音效播放器
4. 调用 `AudioCatalog.play_registered_music("music", "main_menu.mp3")`

### 3.2 游戏加载阶段

`loading_screen.gd` 在 `_ready()` 中执行游戏阶段注册：

1. 调用 `AudioCatalog.register_gameplay_audio()`
2. 调用 `AudioCatalog.play_registered_music("environment", "game_scene.mp3")`

这样可以在启动时只加载轻量资源，并在真正进入游戏前补齐游戏场景音乐和战斗音效。

## 4. 注册表类型与键格式

- 注册表类型名：`audio`
- 注册表实现：`AudioRegistry`
- 条目命名空间：`game`
- ResourceLocation 形式：`game:audio/<category>`

当前分类如下：

- `game:audio/ui`
- `game:audio/music`
- `game:audio/game`
- `game:audio/environment`

## 5. 条目结构

每个音频分类在注册表中存储一个 `Dictionary`，字段如下：

| 字段 | 类型 | 含义 |
|---|---|---|
| `category` | `String` | 逻辑分类，例如 `ui`、`game` |
| `load_phase` | `String` | 注册阶段（`startup`、`game_load`） |
| `path` | `String` | 音频文件所在目录 |
| `files` | `Array` | 配置中声明的文件名列表 |
| `streams` | `Array` | 已加载的音频流元数据字典列表 |

其中 `streams` 内部每项结构如下：

| 字段 | 类型 | 含义 |
|---|---|---|
| `file_name` | `String` | 原始文件名 |
| `path` | `String` | 完整资源路径 |
| `stream` | `AudioStream` | 已加载的音频资源 |

## 6. 当前目录配置内容

### 6.1 启动阶段分组

| 分类 | 目录 | 文件 |
|---|---|---|
| `ui` | `res://assets/game/sounds/ui` | `cancel.mp3`、`click.mp3`、`equip.mp3`、`select.mp3`、`shopping_buy.mp3` |
| `music` | `res://assets/game/sounds/music` | `main_menu.mp3` |

### 6.2 游戏阶段分组

| 分类 | 目录 | 文件 |
|---|---|---|
| `game` | `res://assets/game/sounds/sounds` | `entity_hurt.mp3`、`handgun_shoot.mp3`、`human_die.mp3`、`mob_die.mp3`、`mag_empty.mp3`、`reload.mp3` |
| `environment` | `res://assets/game/sounds/music` | `game_scene.mp3` |

## 7. `AudioCatalog` 提供的辅助接口

### 7.1 注册辅助方法

- `ensure_registry_and_register(audio_groups: Array) -> void`
- `register_gameplay_audio() -> void`

这些方法会在需要时创建注册表、加载配置中的文件，并按分类注册条目。

### 7.2 查询 / 播放辅助方法

- `get_registered_stream(category: String, preferred_file_name: String = "") -> AudioStream`
- `play_registered_music(category: String, preferred_file_name: String = "", crossfade: float = DEFAULT_MUSIC_CROSSFADE, force_restart: bool = false) -> void`

调用方可以通过“分类 + 可选文件名”获取音频，而不必在每个使用处直接写文件加载逻辑。

## 8. 当前设计要点

- 当前注册流程由场景驱动，而不是通过自动加载引导脚本统一启动。
- 缺失目录、不支持的扩展名和不存在的资源都会被安全跳过。
- Debug 构建下，注册完成后会打印注册表内容，便于排查音频加载问题。
- `opening.gd` 会基于注册表中的 UI 音频流创建菜单音效播放器，从而保证菜单音频行为与目录配置一致。

## 9. 新增音频时的建议流程

1. 将音频文件放到 `assets/game/sounds/...` 下的正确目录。
2. 在 `AudioCatalog` 中把文件名加入对应分组。
3. 判断该资源属于 `startup` 还是 `game_load`。
4. 在使用处通过 `AudioCatalog.get_registered_stream(...)` 或 `AudioCatalog.play_registered_music(...)` 消费。
5. 在 Debug 构建中确认调试输出里出现了对应分类和文件名。

## 10. 何时需要扩展当前设计

当出现以下情况时，可以考虑拆分或扩展现有方案：

- 某个分类过大，需要子分类或优先级规则
- 不同游戏阶段需要更严格的预加载预算控制
- 需要为单个条目补充总线、默认音量、循环提示、语言变体等额外元数据
