# Project Extraction - Current Progress

## Completed in this update

- Implemented shooting-system expansion for aim/fire/reload workflow:
  - Projectile spawn supports multi-pellet shots and weaponized projectile attributes
  - Added fire mode model (`SAFE/SEMI/AUTO`) and runtime mode switching
  - Added player reload input and reload processing state
  - Added non-player auto reload behavior on empty magazine
  - Added empty magazine reminder SFX playback
  - Files:
    - `scripts/ecs/systems/s_combat_fire_system.gd`
    - `scripts/ecs/components/combat/c_combat_state.gd`
    - `scripts/ecs/input/player_input_context.gd`
    - `scripts/ecs/entities/gameplay/e_player.gd`
- Implemented projectile distance attenuation and distance-based expiry:
  - `scripts/ecs/components/combat/c_projectile_data.gd`
  - `scripts/ecs/systems/s_projectile_motion_system.gd`
- Added aiming camera follow offset (crosshair-follow style while ADS):
  - `scripts/ecs/gameplay/demo_game_runtime.gd`
- Extended input/keybinding/i18n for combat controls:
  - Added `Reload` and `Toggle Fire Mode` actions to input context and keybinding table
  - Updated translation resources:
    - `resources/i18n/ui_text.en.json`
    - `resources/i18n/ui_text.zh.json`
- Updated API docs for shooting/reload/firemode/attenuation/camera behavior:
  - `docs/API.md`
- Decoupled localization bootstrap from audio registry bootstrap:
  - Added `scripts/localization/localization_bootstrap.gd`
  - `AudioRegistryBootstrap` now handles audio registration only
- Added folder + filename based audio registration config:
  - `scripts/audio/audio_catalog.gd`
  - Updated `scripts/audio/audio_registry_bootstrap.gd` to register entries from catalog
- Added language option in game core options (`game_options`):
  - `scenes/menus/options_menu/game/language_option_control.gd`
  - `scenes/menus/options_menu/game/language_option_control.tscn`
  - Wired into `scenes/menus/options_menu/game/game_options_menu.tscn`
  - Saved under `GameSettings.Language`
- Reorganized keybinding menu into table format:
  - Columns by input method (`Keyboard` / `Mouse` / `Gamepad`)
  - Rows by concrete actions
  - Movement directions split into explicit rows (`Move Up/Down/Left/Right`)
  - Updated in `scripts/ecs/input/guide_input_options_menu.gd`
- Updated localization text resources for new options/input labels:
  - `resources/i18n/ui_text.en.json`
  - `resources/i18n/ui_text.zh.json`
- Moved ECS-related gameplay code to `scripts/ecs` and updated scene script paths.
- Added GUIDE-driven player input context and runtime remap persistence:
  - `scripts/ecs/input/player_input_context.gd`
  - `scripts/ecs/input/guide_input_runtime.gd`
- Added GUIDE-based options keybinding panel and wired it into the existing Maaack options tabs:
  - `scenes/menus/options_menu/input/guide_input_options_menu.tscn`
  - `scripts/ecs/input/guide_input_options_menu.gd`
  - `scenes/menus/options_menu/master_options_menu_with_tabs.tscn`
- Implemented player操作系统基础流程（移动/瞄准/射击输入接入）:
  - `scripts/ecs/entities/gameplay/e_player.gd`
- Implemented aiming + shooting systems with recoil and hipfire/ADS precision difference:
  - `scripts/ecs/systems/s_combat_fire_system.gd`
  - `scripts/ecs/systems/s_projectile_motion_system.gd`
  - `scripts/ecs/projectiles/e_base_projectile.gd`
  - `scripts/ecs/components/combat/c_combat_state.gd`
  - `scripts/ecs/components/combat/c_projectile_data.gd`
  - `scripts/ecs/components/combat/c_aim_state.gd`
- Added Demo runtime ECS world bootstrap and system processing:
  - `scripts/ecs/gameplay/demo_game_runtime.gd`
  - `scenes/game_scene/pe_scene/DemoGame.tscn`
- Added a lightweight game global phase state extension to support GDD loop semantics:
  - `scripts/ecs/game_state.gd`
  - `scripts/ecs/level_and_state_manager.gd`

## Deletions in this update (and reasons)

- `scenes/menus/options_menu/mini_options_menu_with_reset.gd`
- `scenes/menus/options_menu/mini_options_menu_with_reset.gd.uid`
- `scenes/menus/options_menu/mini_options_menu_with_reset.tscn`
  - Reason: Unused duplicate menu variant; active options flow uses
    `master_options_menu_with_tabs.tscn`.
- `scripts/items/base_item.gd`
- `scripts/items/base_item.gd.uid`
  - Reason: Currently unused script with no references in runtime/docs/API flow.
    Keeping unused foundational script increases maintenance noise.

## Remaining (not fully covered yet)

- Deep cleanup/removal of all unused folders/resources in non-ECS domains.
- Full global state machine redesign across all game flows and menus.
- More complete projectile hit detection and damage application pipeline.
- Full enemy AI-driven aiming/shooting integration.
