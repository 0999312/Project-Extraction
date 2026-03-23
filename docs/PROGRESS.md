# Project Extraction - Current Progress

## Completed in this update

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

## Remaining (not fully covered yet)

- Deep cleanup/removal of all unused folders/resources in non-ECS domains.
- Full global state machine redesign across all game flows and menus.
- More complete projectile hit detection and damage application pipeline.
- Full enemy AI-driven aiming/shooting integration.
