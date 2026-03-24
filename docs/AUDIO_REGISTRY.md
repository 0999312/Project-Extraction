# Audio Registry Guide

## 1. Purpose

The project uses a dedicated audio registry to keep UI sound effects, gameplay sound effects, and music organized by category and load phase. The current implementation is intentionally simple: audio is declared in a catalog, loaded into a registry, and then consumed through helper methods instead of scattering hardcoded `load(...)` calls across gameplay and UI scripts.

## 2. Source Files

- `scripts/audio/audio_registry.gd`
- `scripts/audio/audio_catalog.gd`
- `scenes/opening/opening.gd`
- `scenes/loading_screen/loading_screen.gd`

## 3. Runtime Flow

### 3.1 Startup Phase

`opening.gd` performs startup registration in `_ready()`:

1. ensure localization is initialized
2. call `AudioCatalog.ensure_registry_and_register(AudioCatalog.STARTUP_AUDIO_GROUPS)`
3. configure UI sound players from the registered UI streams
4. call `AudioCatalog.play_registered_music("music", "main_menu.mp3")`

### 3.2 Gameplay Load Phase

`loading_screen.gd` performs gameplay registration in `_ready()`:

1. call `AudioCatalog.register_gameplay_audio()`
2. call `AudioCatalog.play_registered_music("environment", "game_scene.mp3")`

This keeps startup assets lightweight while ensuring game-scene music and combat SFX are available before gameplay begins.

## 4. Registry Type and Keys

- Registry type name: `audio`
- Registry implementation: `AudioRegistry`
- Namespace used for entries: `game`
- ResourceLocation pattern: `game:audio/<category>`

Current categories:

- `game:audio/ui`
- `game:audio/music`
- `game:audio/game`
- `game:audio/environment`

## 5. Registry Entry Shape

Each registered audio category stores a `Dictionary` with the following fields:

| Field | Type | Meaning |
|---|---|---|
| `category` | `String` | Logical audio category, such as `ui` or `game` |
| `load_phase` | `String` | When the group should be registered (`startup`, `game_load`) |
| `path` | `String` | Folder path containing the audio files |
| `files` | `Array` | Declared file names for the group |
| `streams` | `Array` | Loaded stream metadata dictionaries |

Each `streams` entry contains:

| Field | Type | Meaning |
|---|---|---|
| `file_name` | `String` | Original file name |
| `path` | `String` | Full resource path |
| `stream` | `AudioStream` | Loaded stream resource |

## 6. Current Catalog Contents

### 6.1 Startup Groups

| Category | Folder | Files |
|---|---|---|
| `ui` | `res://assets/game/sounds/ui` | `cancel.mp3`, `click.mp3`, `equip.mp3`, `select.mp3`, `shopping_buy.mp3` |
| `music` | `res://assets/game/sounds/music` | `main_menu.mp3` |

### 6.2 Gameplay Groups

| Category | Folder | Files |
|---|---|---|
| `game` | `res://assets/game/sounds/sounds` | `entity_hurt.mp3`, `handgun_shoot.mp3`, `human_die.mp3`, `mob_die.mp3`, `mag_empty.mp3`, `reload.mp3` |
| `environment` | `res://assets/game/sounds/music` | `game_scene.mp3` |

## 7. Helper APIs in `AudioCatalog`

### 7.1 Registration Helpers

- `ensure_registry_and_register(audio_groups: Array) -> void`
- `register_gameplay_audio() -> void`

These helpers create the registry if needed, load the configured files, and register entries by category.

### 7.2 Lookup / Playback Helpers

- `get_registered_stream(category: String, preferred_file_name: String = "") -> AudioStream`
- `play_registered_music(category: String, preferred_file_name: String = "", crossfade: float = DEFAULT_MUSIC_CROSSFADE, force_restart: bool = false) -> void`

These helpers allow calling code to request audio by category and optional preferred filename instead of hardcoding a file load in every consumer.

## 8. Design Notes

- The registry is scene-driven, not autoload-bootstrap-driven.
- Missing folders, unsupported extensions, and nonexistent resources are skipped safely.
- Debug builds print registry contents after registration, which is useful when auditing audio loading problems.
- UI audio players are created from registry-loaded streams in `opening.gd`, so menu sound usage stays consistent with the configured catalog.

## 9. Recommended Workflow for Adding New Audio

1. Add the audio file under the correct folder in `assets/game/sounds/...`.
2. Add the filename to the correct group in `AudioCatalog`.
3. Decide whether it belongs to `startup` or `game_load`.
4. Consume it through `AudioCatalog.get_registered_stream(...)` or `AudioCatalog.play_registered_music(...)`.
5. Verify the category and filename are reflected in debug output when running a debug build.

## 10. When to Extend This Design

Consider splitting or extending the registry when one of the following happens:

- a category grows too large and needs sub-categories or priority rules
- different game phases need separate preload budgets
- you need per-entry metadata such as bus routing, volume defaults, looping hints, or localization-specific variants
