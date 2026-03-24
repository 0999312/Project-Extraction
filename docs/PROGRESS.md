# Project Extraction — Progress

## Update 3 — Bootstrap Removal & Cleanup

### Changes

- **Removed bootstrap autoload scripts**, moving their responsibilities into the game flow scenes:
  - `scenes/opening/opening.gd` — now handles localization init (loading i18n JSON translations, applying configured language) and startup audio registration. Extends the Maaacks template Opening scene.
  - `scenes/loading_screen/loading_screen.gd` — now registers gameplay-phase audio groups on `_ready()`, so audio is available before the game scene loads.
  - `scenes/menus/options_menu/game/language_option_control.gd` — language switching now calls `I18NManager` + `PlayerConfig` directly, no longer depends on `LocalizationBootstrap`.
  - `scripts/ecs/gameplay/demo_game_runtime.gd` — removed `AudioRegistryBootstrap.register_gameplay_audio()` call.
  - `scripts/ecs/level_and_state_manager.gd` — removed `AudioRegistryBootstrap.register_gameplay_audio()` call.
  - `project.godot` — removed `LocalizationBootstrap` and `AudioRegistryBootstrap` autoload entries.
- **Added localized tab titles** for options menu tabs via `localized_options_tab_container.gd`.
- **Added Chinese translations** for all template menu strings (New Game, Options, Audio/Video labels, etc.) in `resources/i18n/ui_text.zh.json`.
- **Combat SFX pipeline**: shoot/reload/empty-magazine sounds now play correctly through `SoundManager.play_sound()` with cached audio streams.
- **Player input processing order**: `process_physics_priority = 100` on DemoGame ensures player input is polled before ECS systems run.
- **DEBUG logging**: comprehensive `[DEBUG]` prefixed logs for player movement, aiming, firing, reload, sprint, and fire mode changes.

### Deletions (Update 3)

| Deleted File | Reason |
|---|---|
| `scripts/localization/localization_bootstrap.gd` (+.uid) | Replaced by `scenes/opening/opening.gd` — localization init moved into the opening scene |
| `scripts/audio/audio_registry_bootstrap.gd` (+.uid) | Replaced by `scenes/opening/opening.gd` (startup audio) and `scenes/loading_screen/loading_screen.gd` (gameplay audio) |
| `scenes/menus/options_menu/mini_options_menu.tscn` | Unreferenced options menu variant; active flow uses `master_options_menu_with_tabs.tscn` |
| `scenes/menus/options_menu/input/input_options_menu.tscn` | Superseded by `guide_input_options_menu.tscn` (GUIDE-based keybinding table) |
| `scenes/menus/options_menu/input/input_options_menu_with_mouse_sensitivity.tscn` | Superseded by `guide_input_options_menu.tscn` + `input_extras_menu.tscn` |
| `scenes/menus/options_menu/input/input_icon_mapper.tscn` | Only referenced by deleted `input_options_menu.tscn` |
| `scenes/menus/options_menu/video/video_options_menu.tscn` | Superseded by `video_options_menu_with_extras.tscn` |
| `scenes/game_scene/input_display_label.gd` (+.uid) | Unreferenced template leftover — no runtime or scene usage |
| `scenes/game_scene/tutorial_manager.gd` (+.uid) | Unreferenced template leftover — no runtime or scene usage |
| `scenes/game_scene/tutorials/tutorial_1.tscn` | Unreferenced template tutorial — not part of current game flow |
| `scenes/game_scene/tutorials/tutorial_2.tscn` | Unreferenced template tutorial — not part of current game flow |
| `scenes/game_scene/tutorials/tutorial_3.tscn` | Unreferenced template tutorial — not part of current game flow |

---

## Update 2 — Combat, Input & Audio Systems

### Changes

- Implemented shooting-system expansion for aim/fire/reload workflow:
  - Projectile spawn supports multi-pellet shots and weaponized projectile attributes
  - Added fire mode model (`SAFE/SEMI/AUTO`) and runtime mode switching
  - Added player reload input and reload processing state
  - Added non-player auto reload behavior on empty magazine
  - Added empty magazine reminder SFX playback
  - Files: `s_combat_fire_system.gd`, `c_combat_state.gd`, `player_input_context.gd`, `e_player.gd`
- Implemented projectile distance attenuation and distance-based expiry:
  - `c_projectile_data.gd`, `s_projectile_motion_system.gd`
- Added aiming camera follow offset (crosshair-follow style while ADS):
  - `demo_game_runtime.gd`
- Extended input/keybinding/i18n for combat controls:
  - Added Reload and Toggle Fire Mode actions to input context and keybinding table
  - Updated `ui_text.en.json`, `ui_text.zh.json`
- Updated API docs for shooting/reload/firemode/attenuation/camera behavior
- Decoupled localization bootstrap from audio registry bootstrap:
  - Added `localization_bootstrap.gd` (later removed in Update 3)
- Added folder + filename based audio registration config:
  - `audio_catalog.gd`, `audio_registry_bootstrap.gd`
- Added language option in game core options:
  - `language_option_control.gd`, `language_option_control.tscn` → `game_options_menu.tscn`
- Reorganized keybinding menu into table format:
  - Columns by input method (Keyboard / Mouse / Gamepad), rows by concrete actions
  - `guide_input_options_menu.gd`
- Moved ECS-related gameplay code to `scripts/ecs` and updated scene script paths
- Added GUIDE-driven player input context and runtime remap persistence:
  - `player_input_context.gd`, `guide_input_runtime.gd`
- Added GUIDE-based options keybinding panel:
  - `guide_input_options_menu.tscn`, `guide_input_options_menu.gd`, `master_options_menu_with_tabs.tscn`
- Implemented player input flow (movement / aiming / shooting):
  - `e_player.gd`
- Implemented aiming + shooting systems with recoil and hipfire/ADS precision:
  - `s_combat_fire_system.gd`, `s_projectile_motion_system.gd`, `e_base_projectile.gd`
  - `c_combat_state.gd`, `c_projectile_data.gd`, `c_aim_state.gd`
- Added Demo runtime ECS world bootstrap and system processing:
  - `demo_game_runtime.gd`, `DemoGame.tscn`
- Added lightweight game global phase state:
  - `game_state.gd`, `level_and_state_manager.gd`

### Deletions (Update 2)

| Deleted File | Reason |
|---|---|
| `scenes/menus/options_menu/mini_options_menu_with_reset.gd` (+.uid, +.tscn) | Unused duplicate menu variant |
| `scripts/items/base_item.gd` (+.uid) | Unused foundational script with no references |

---

## Remaining Work

- Full global state machine redesign across all game flows and menus.
- Complete projectile hit detection and damage application pipeline.
- Full enemy AI-driven aiming/shooting integration.
- Inventory / item system implementation.
- Full level progression flow integration.
