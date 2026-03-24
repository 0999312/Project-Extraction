# API Overview (Current Input, Runtime, and Audio Integration)

- The current playable runtime is scene/node-driven and no longer depends on GECS or gdUnit4.
- The current gameplay runtime script tree now lives under `scripts/game/`.

## `player_input_context.gd`

- `class_name PlayerInputContext : GUIDEMappingContext`
- Provides GUIDE action mappings:
  - `pe_move` (`AXIS_2D`)
  - `pe_aim_axis` (`AXIS_2D`)
  - `pe_fire` (`BOOL`)
  - `pe_aim_hold` (`BOOL`)
  - `pe_reload` (`BOOL`)
  - `pe_fire_mode_toggle` (`BOOL`)
  - `pe_sprint` (`BOOL`)

## `guide_input_runtime.gd`

- `class_name GuideInputRuntime`
- Static runtime API:
  - `ensure_initialized()`
  - `get_context() -> GUIDEMappingContext`
  - `get_action(name: StringName) -> GUIDEAction`
  - `get_action_axis_2d(name: StringName) -> Vector2`
  - `get_actions() -> Dictionary`
  - `get_remapper() -> GUIDERemapper`
  - `is_action_triggered(name: StringName) -> bool`
  - `apply_remapping_config(config: GUIDERemappingConfig) -> void`

## `guide_input_options_menu.gd`

- GUIDE-based remap UI controller used by `guide_input_options_menu.tscn`.
- Supports:
  - keybinding table view (`Action` rows × `Keyboard` / `Mouse` / `Gamepad` columns)
  - clear movement direction text rows (`Move Up` / `Move Down` / `Move Left` / `Move Right`)
  - select action binding per table cell
  - rebind with `GUIDEInputDetector`
  - clear binding
  - reset defaults

## `e_player.gd`

### Input-facing behavior

- Polls GUIDE actions each physics frame:
  - movement vector (`pe_move`)
  - sprint hold (`pe_sprint`)
  - aiming axis (`pe_aim_axis`)
  - fire + ADS flags pushed into current combat/runtime state

### Runtime-facing helpers

- Exposes player-alive checks and accessors for current health / inventory / combat-related state used by gameplay scripts.

## `c_combat_state.gd`

Fields include:

- `wants_fire: bool`
- `wants_reload: bool`
- `wants_fire_mode_toggle: bool`
- `recoil_accum: float`
- `hipfire_spread_deg: float`
- `ads_spread_deg: float`
- `recoil_spread_per_accum_deg: float`
- `recoil_per_shot: float`
- `recoil_recovery_per_sec: float`
- `fire_mode: FireMode` (`SAFE` / `SEMI` / `AUTO`)
- `pellets_per_shot: int`
- `projectile_speed: float`
- `projectile_max_distance: float`
- `ads_distance: float`
- `attack_damage: float`
- `ammo_max` / `ammo_current` + reload state (`is_reloading`, `reload_progress`, `reload_duration_sec`)

## `c_aim_state.gd`

Field includes:

- `precision_multiplier: float`

## `c_projectile_data.gd`

Fields include:

- `spread_deviation_rad: float`
- `max_distance: float`
- `remaining_distance: float`
- `base_damage` / `base_speed` for attenuation curve

## `e_base_projectile.gd`

- `setup(direction, dmg, pen, owner_id, wpn_id)` applies `spread_deviation_rad` rotation before velocity assignment.
- Intended as the node-driven projectile runtime setup entry point.

## `s_combat_fire_system.gd`

- Handles per-tick combat processing for actors with combat/aim/position/faction data.
- Responsibilities include:
  - cooldown + recoil recovery
  - fire-mode handling (`SAFE` / `SEMI` / `AUTO`)
  - manual reload trigger and non-player auto reload when magazine is empty
  - empty-mag reminder SFX
  - projectile spawn when fire is requested and ammo/cooldown rules allow it
  - hipfire vs ADS spread + recoil spread
  - per-shot pellet count support

## `s_projectile_motion_system.gd`

- Advances projectile age/position and removes expired projectiles.
- Applies distance-based attenuation using `remaining_distance / max_distance`:
  - gradual damage decay
  - gradual speed decay
  - projectile expiry when travel distance is exhausted

## `demo_game_runtime.gd`

- Coordinates demo-scene gameplay processing.
- Uses combat and projectile processing helpers directly from the scene runtime.
- Polls GUIDE `pe_pause` through `GuideInputRuntime` helpers and opens `PauseMenuController` in `DemoGame`.
- Applies ADS camera follow offset toward crosshair direction by writing `PhantomCamera2D.follow_offset` while aiming.

## `game_state.gd`

Game loop phase API:

- `enum GamePhase { HOMESTEAD, DEPLOY, RAID, EXTRACT }`
- `set_game_phase(phase: GamePhase) -> void`
- `get_game_phase() -> GamePhase`

## `audio_registry.gd`

- `class_name AudioRegistry : RegistryBase`
- Registry entry type: `Dictionary`
- Supports selecting entries by load phase:
  - `get_entries_for_phase(load_phase: String) -> Dictionary`

## `opening.gd`

- Extends the Maaacks template Opening scene.
- Handles localization initialization: loads i18n JSON translations, applies configured language.
- Handles startup audio registration: registers `AudioRegistry` via `RegistryManager`, loads startup audio groups from `AudioCatalog.STARTUP_AUDIO_GROUPS`.
- Configures menu UI sound players from registry-loaded streams.
- Auto-plays main menu music through `AudioCatalog.play_registered_music(...)`.

## `loading_screen.gd`

- Extends `LoadingScreen` (Maaacks template).
- Registers gameplay-phase audio groups on `_ready()`.
- Starts gameplay music before the game scene loads.

## `audio_catalog.gd`

- Defines startup/gameplay audio registration config.
- Uses folder + filename arrays per category.
- Provides helpers for:
  - ensuring the audio registry exists
  - registering startup/gameplay groups
  - resolving a registered stream by category / preferred filename
  - playing registered music through `SoundManager`

## `language_option_control.gd`

- `ListOptionControl` for language switching in `game_options`.
- Supported values: `en`, `zh`
- Calls `I18NManager.set_language(...)` and persists via `PlayerConfig` on change.
