# API Overview (Current ECS + Input Integration)

## scripts/ecs/input/player_input_context.gd

- `class_name PlayerInputContext : GUIDEMappingContext`
- Provides GUIDE action mappings:
  - `pe_move` (`AXIS_2D`)
  - `pe_aim_axis` (`AXIS_2D`)
  - `pe_fire` (`BOOL`)
  - `pe_aim_hold` (`BOOL`)
  - `pe_sprint` (`BOOL`)

## scripts/ecs/input/guide_input_runtime.gd

- `class_name GuideInputRuntime`
- Static runtime API:
  - `ensure_initialized()`
  - `get_context() -> GUIDEMappingContext`
  - `get_action(name: StringName) -> GUIDEAction`
  - `get_actions() -> Dictionary`
  - `get_remapper() -> GUIDERemapper`
  - `apply_remapping_config(config: GUIDERemappingConfig) -> void`

## scripts/ecs/input/guide_input_options_menu.gd

- GUIDE-based remap UI controller used by:
  - `scenes/menus/options_menu/input/guide_input_options_menu.tscn`
- Supports:
  - select action binding
  - rebind with `GUIDEInputDetector`
  - clear binding
  - reset defaults

## scripts/ecs/entities/gameplay/e_player.gd

### Input-facing behavior

- Polls GUIDE actions each physics frame:
  - movement vector (`pe_move`)
  - sprint hold (`pe_sprint`)
  - aiming axis (`pe_aim_axis`)
  - fire + ADS flags pushed to `C_CombatState`

### ECS bridge methods

- `get_ecs_entity() -> BaseEntity`
- `is_alive() -> bool`
- `get_health() -> C_Health`
- `get_inventory_ref() -> C_InventoryRef`

## scripts/ecs/components/combat/c_combat_state.gd

Added fields:

- `wants_fire: bool`
- `recoil_accum: float`
- `hipfire_spread_deg: float`
- `ads_spread_deg: float`
- `recoil_spread_per_accum_deg: float`
- `recoil_per_shot: float`
- `recoil_recovery_per_sec: float`

## scripts/ecs/components/combat/c_aim_state.gd

Added field:

- `precision_multiplier: float`

## scripts/ecs/components/combat/c_projectile_data.gd

Added field:

- `spread_deviation_rad: float`

## scripts/ecs/projectiles/e_base_projectile.gd

- `setup(direction, dmg, pen, owner_id, wpn_id)` now applies `spread_deviation_rad` rotation before velocity assignment.

## scripts/ecs/systems/s_combat_fire_system.gd

- `class_name S_CombatFireSystem : System`
- Query: entities with `C_CombatState`, `C_AimState`, `C_Position`
- Per tick:
  - cooldown + recoil recovery
  - if fire requested and available ammo/cooldown, spawn projectile
  - apply hipfire vs ADS spread + recoil spread
  - decrement ammo, set cooldown, add recoil

## scripts/ecs/systems/s_projectile_motion_system.gd

- `class_name S_ProjectileMotionSystem : System`
- Query: entities with `C_ProjectileData`, `C_Position`
- Advances projectile age/position and removes expired projectiles.

## scripts/ecs/gameplay/demo_game_runtime.gd

- Bootstraps runtime `World` under demo scene.
- Assigns `ECS.world`.
- Registers and processes:
  - `S_CombatFireSystem`
  - `S_ProjectileMotionSystem`
- Polls GUIDE `pe_pause` action and opens `PauseMenuController` in `DemoGame`.

## scripts/ecs/game_state.gd

Added game loop phase API:

- `enum GamePhase { HOMESTEAD, DEPLOY, RAID, EXTRACT }`
- `set_game_phase(phase: GamePhase) -> void`
- `get_game_phase() -> GamePhase`

## scripts/audio/audio_registry.gd

- `class_name AudioRegistry : RegistryBase`
- Registry entry type: `Dictionary`
- Supports selecting entries by load phase:
  - `get_entries_for_phase(load_phase: String) -> Dictionary`

## scripts/audio/audio_registry_bootstrap.gd

- Autoload bootstrap for project audio/i18n initialization.
- Registers `core:audio` registry via `RegistryManager`.
- Registers and preloads audio categories:
  - Startup: `game:audio/ui`, `game:audio/music`
  - Game load: `game:audio/game`, `game:audio/environment`
- Loads and applies UI translations:
  - `res://resources/i18n/ui_text.en.json`
  - `res://resources/i18n/ui_text.zh.json`
