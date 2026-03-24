# Project Extraction — Progress

## Update 8 — Node-Driven Runtime Rewrite, Plugin Removal, and Documentation Cleanup

### Changes

- **Rebuilt the playable DemoGame flow without ECS runtime dependencies**:
  - Reworked the player, biological actor base, human enemy, non-human enemy, projectile, combat-processing, and projectile-processing scripts to use node-owned runtime state instead of a world/entity/system framework.
  - `DemoGame.tscn` no longer depends on `World`, `World/Systems/*`, or GECS runtime nodes.
- **Preserved menu, loading, input, camera, and audio integration**:
  - Kept GUIDE input polling, pause-menu flow, phantom-camera aim offset, and audio playback wired into the rewritten runtime.
  - Updated the debug menu runtime counters to report actor/projectile counts without querying an ECS world.
- **Removed plugins and project configuration that are no longer used**:
  - Removed `addons/gecs` and its project/editor-plugin references.
  - Removed `addons/gdUnit4` and its project/editor-plugin references.
- **Synchronized docs with the new code reality**:
  - Updated progress/API/architecture notes so the documented runtime direction matches the current codebase after plugin removal.

---

## Update 7 — Documentation Replan, Audio Registry Docs, and Decision to Abandon ECS Architecture

### Changes

- **Current documentation direction is now scene/node + data-driven runtime**:
  - Reworked design and architecture documents to describe player, enemies, projectiles, containers, doors, and trader terminals without framework-bound entity simulation.
  - The progress record now formally states that the current project plan will abandon the previous ECS architecture direction.
- **Added audio registry reference documents**:
  - Added a current-state audio registry guide describing registry shape, load phases, categories, and runtime registration flow.
  - Added a reusable registry design document template for future item / POI / loot / trader / home-system registry planning.
- **Synchronized core docs**:
  - Updated GDD, tech stack notes, and API overview so they align with the current scene-driven runtime and content registry workflow.

---

## Update 6 — DemoGame Runtime Alignment, Biological Base Refactor, and Documentation Sync

### Changes

- **DemoGame scene/runtime alignment**:
  - `demo_game_runtime.gd` now reuses the existing runtime nodes already present in `DemoGame.tscn` instead of duplicating processing branches at runtime.
  - Runtime references stay inside the scene tree and initialization is idempotent when the same scene is entered repeatedly.
  - Files: `DemoGame.tscn`, `demo_game_runtime.gd`.
- **Biological actor base class unified for Player / HumanEnemy / NonHumanEnemy**:
  - Added `e_biological_body_base.gd` as a shared base for biological actor setup.
  - Centralized delayed runtime hookup and shared initialization so player / human enemy / non-human enemy body scripts follow the same setup path.
  - Files: `e_biological_body_base.gd`, `e_human_base.gd`, `e_player.gd`, `e_human_enemy_body.gd`, `e_non_human_enemy_body.gd`.
- **Demo scene now visibly includes all three biological categories**:
  - Added `HumanEnemyBody` and `NonHumanEnemyBody` instances to `DemoGame.tscn` so Player / Human Enemy / Non-Human Enemy are all present in the same playable scene flow.
- **Audio cleanup verification for removed files/calls**:
  - Audited repository audio path references and confirmed no stale calls to deleted audio assets remain.
  - Current combat audio references (`handgun_shoot`, `reload`, `mag_empty`) and registered gameplay audio files are present on disk.
- **Tech stack documentation synchronized**:
  - Updated architecture notes to reflect current audio/localization initialization flow and the biological base scene contract.

---

## Update 5 — Projectile Sprite Collision, Audio Runtime Wiring, Registry Debug

### Changes

- **Projectile sprite configurability and sprite-based collision radius**:
  - Added configurable projectile sprite path to combat/projectile data.
  - Default projectile sprite is now `res://assets/game/textures/projectiles/bullet.png`.
  - Projectile collision radius is derived from the configured sprite size at runtime.
  - Projectile motion now performs lightweight runtime collision checks against living hostile targets using segment-to-point distance with sprite-derived radius.
  - Files: `c_combat_state.gd`, `c_projectile_data.gd`, `s_combat_fire_system.gd`, `s_projectile_motion_system.gd`.
- **SoundManager runtime linkage with existing audio config**:
  - Added catalog helpers to fetch registered streams and play registered music directly from registry entries.
  - Opening scene now auto-plays main menu music from startup registry entries.
  - Loading screen now auto-plays gameplay music from gameplay registry entries before the game scene loads.
  - Menu UI sound controller is now wired to registry-configured UI streams so focused/select and pressed/click interactions play expected SFX.
  - Files: `audio_catalog.gd`, `opening.gd`, `loading_screen.gd`.
- **Fix for `Condition "found" is true. Returning: Ref()` path**:
  - Added defensive registry existence checks before `RegistryManager.get_registry(...)` access in audio catalog helpers.
  - Added explicit error logging when registry resolution fails.
  - File: `audio_catalog.gd`.
- **Registry debug output after load**:
  - After startup/gameplay registration, debug output now prints registry key and summarized entry content (category, phase, path, files, stream paths).
  - File: `audio_catalog.gd`.

---

## Update 4 — Video Settings & Anti-Aliasing Removal

### Changes

- **Configured `video_options_menu_with_extras`** for correct video settings application:
  - Fullscreen, Resolution, and V-Sync settings already correctly applied at startup via `AppConfig` → `AppSettings.set_video_from_config()` and at runtime via signal-connected handlers in the base `video_options_menu.gd`.
  - CameraShake option preserved (hidden) for future feature activation.
- **Removed Anti-Aliasing (MSAA) configuration**: The project uses the `gl_compatibility` renderer where MSAA support is limited; removed the option and its runtime application logic.
- **Fixed video settings localization**:
  - Added missing `"V-Sync :"` translation key to both `ui_text.en.json` and `ui_text.zh.json`.
  - Added V-Sync dropdown option title translations: Disabled / Enabled / Adaptive / Mailbox.
  - Added Camera Shake dropdown option title translations: Normal / Reduced / Minimal / None (for future use).
  - Removed obsolete `"Anti-Aliasing :"` translation entries.

### Deletions (Update 4)

| Deleted File | Reason |
|---|---|
| `scenes/game_scene/configurable_sub_viewport.gd` (+.uid) | Applied MSAA anti-aliasing settings to SubViewport; removed with Anti-Aliasing option since project uses `gl_compatibility` renderer |
| AntiAliasingControl node in `video_options_menu_with_extras.tscn` | Anti-Aliasing UI control removed per requirements |

---

## Update 3 — Bootstrap Removal & Cleanup

### Changes

- **Removed bootstrap autoload scripts**, moving their responsibilities into the game flow scenes:
  - `scenes/opening/opening.gd` — now handles localization init (loading i18n JSON translations, applying configured language) and startup audio registration. Extends the Maaacks template Opening scene.
  - `scenes/loading_screen/loading_screen.gd` — now registers gameplay-phase audio groups on `_ready()`, so audio is available before the game scene loads.
  - `scenes/menus/options_menu/game/language_option_control.gd` — language switching now calls `I18NManager` + `PlayerConfig` directly, no longer depends on `LocalizationBootstrap`.
  - `demo_game_runtime.gd` — removed old gameplay audio registration bootstrap call.
  - `level_and_state_manager.gd` — removed old gameplay audio registration bootstrap call.
  - `project.godot` — removed `LocalizationBootstrap` and `AudioRegistryBootstrap` autoload entries.
- **Added localized tab titles** for options menu tabs via `localized_options_tab_container.gd`.
- **Added Chinese translations** for all template menu strings (New Game, Options, Audio/Video labels, etc.) in `resources/i18n/ui_text.zh.json`.
- **Combat SFX pipeline**: shoot/reload/empty-magazine sounds now play correctly through `SoundManager.play_sound()` with cached audio streams.
- **Player input processing order**: `process_physics_priority = 100` on DemoGame ensures player input is polled before gameplay processing runs each physics frame.
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
  - Projectile spawn supports multi-pellet shots and weaponized projectile attributes.
  - Added fire mode model (`SAFE/SEMI/AUTO`) and runtime mode switching.
  - Added player reload input and reload processing state.
  - Added non-player auto reload behavior on empty magazine.
  - Added empty magazine reminder SFX playback.
  - Files: `s_combat_fire_system.gd`, `c_combat_state.gd`, `player_input_context.gd`, `e_player.gd`.
- Implemented projectile distance attenuation and distance-based expiry:
  - `c_projectile_data.gd`, `s_projectile_motion_system.gd`.
- Added aiming camera follow offset (crosshair-follow style while ADS):
  - `demo_game_runtime.gd`.
- Extended input/keybinding/i18n for combat controls:
  - Added Reload and Toggle Fire Mode actions to input context and keybinding table.
  - Updated `ui_text.en.json`, `ui_text.zh.json`.
- Updated API docs for shooting/reload/firemode/attenuation/camera behavior.
- Decoupled localization bootstrap from audio registration bootstrap:
  - Added `localization_bootstrap.gd` (later removed in Update 3).
- Added folder + filename based audio registration config:
  - `audio_catalog.gd`, `audio_registry_bootstrap.gd`.
- Added language option in game core options:
  - `language_option_control.gd`, `language_option_control.tscn` → `game_options_menu.tscn`.
- Reorganized keybinding menu into table format:
  - Columns by input method (Keyboard / Mouse / Gamepad), rows by concrete actions.
  - `guide_input_options_menu.gd`.
- Moved gameplay runtime scripts into a dedicated gameplay directory and updated scene script paths.
- Added GUIDE-driven player input context and runtime remap persistence:
  - `player_input_context.gd`, `guide_input_runtime.gd`.
- Added GUIDE-based options keybinding panel:
  - `guide_input_options_menu.tscn`, `guide_input_options_menu.gd`, `master_options_menu_with_tabs.tscn`.
- Implemented player input flow (movement / aiming / shooting):
  - `e_player.gd`.
- Implemented aiming + shooting processing with recoil and hipfire/ADS precision:
  - `s_combat_fire_system.gd`, `s_projectile_motion_system.gd`, `e_base_projectile.gd`.
  - `c_combat_state.gd`, `c_projectile_data.gd`, `c_aim_state.gd`.
- Added Demo runtime gameplay bootstrap and per-frame processing:
  - `demo_game_runtime.gd`, `DemoGame.tscn`.
- Added lightweight game global phase state:
  - `game_state.gd`, `level_and_state_manager.gd`.

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
