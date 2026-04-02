# Project Extraction — Progress

## Update 21 — Inventory Design Refactor (Remove Patterns, Hide Weapon Hotbar, Scene-ify Layout)

### Changes

- **Removed custom item patterns**:
  - Removed `pattern` field from `ItemDefinition`. All items are now strictly rectangular (`size_w × size_h`).
  - Simplified `_get_item_cells()` in `GridInventory` to always generate a filled rectangle.
  - Simplified rendering and drag preview in `InventoryGridPanel` — no more per-cell pattern-aware iteration.
- **Hidden weapon hotbar slots (0–2) in inventory menu**:
  - Only slots 3–8 are shown in the inventory menu hotbar strip.
  - Weapon slots are exclusively managed through the equipment panel.
  - `_refresh_hotbar_ui()` now properly maps UI indices to data indices.
- **Applied `minimal_vector.tres` theme to inventory menu**:
  - Theme applied via scene file (`inventory_menu.tscn`), not loaded at runtime.
  - All hotbar slot corners set to 0 px (was 8 px). Grid slot corners already 0 px.
- **Save/load interfaces retained (not called)**:
  - `save_to_dict()` / `load_from_dict()` exist on both `GridInventory` and `EquipmentState`.
  - These interfaces are not called at runtime — reserved for future persistence.
- **Converted static UI layout to scene file**:
  - The static layout (root control, background, scroll, center, HBoxMain, equipment panel, VBoxRight, title labels, grid container, hotbar container) is now defined in `inventory_menu.tscn`.
  - Dynamic parts (equipment slot rows, hotbar slot panels, grid panels) remain in code.
  - Script uses `@onready` references instead of `Control.new()` for static nodes.
- **Updated documentation**:
  - Updated `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md` to v0.5.
  - Updated `ITEM_REGISTRY.md` / `ITEM_REGISTRY_ZH.md` to remove pattern field.
  - Updated progress documents.

---

## Update 20 — Inventory System Enhancements (Patterns, Rarity, Stacking, Save/Load)

### Changes

- **Fixed item texture rendering in inventory slots**:
  - Item icons now render above grid lines and borders (draw order: grid lines → items → drag preview).
  - Replaced `fit_by_height_rect` with `fit_inside_rect` to ensure item icons never overflow slot boundaries (scales by both width and height, centres both axes).
  - Grid panels now use `clip_contents = false` so item textures are not clipped by PanelContainer borders.
- **Restricted hotbar weapon slots in inventory menu**:
  - Hotbar slots 0–2 (weapon slots) can no longer be assigned by dragging items from container grids. They are read-only in the inventory grid view and can only be managed through the equipment panel (primary/secondary/melee weapon).
  - Hotbar slots 3–8 continue to accept any item via grid drag.
- **Implemented item stacking and merging**:
  - Dropping a dragged item stack onto an existing stack of the same item merges counts up to `max_stack`.
  - Full merge ends the drag; partial merge leaves the remainder in the drag state.
  - Stack count (>1) is displayed in the bottom-right corner of the item rect with shadow for readability.
- **Added item rarity system**:
  - New `ItemDefinition.rarity` field (`int`, 0–5: none/common/uncommon/rare/epic/legendary).
  - Items render with rarity-coloured background tints: default gray-blue, green (uncommon), blue (rare), purple (epic), gold (legendary).
- **Added custom item patterns (irregular shapes)**:
  - New `ItemDefinition.pattern` field (`Array[Vector2i]`) for defining non-rectangular occupancy shapes.
  - `GridInventory.can_place()`, `place_item()`, `remove_item()`, `get_placement_at()` all use pattern-aware cell iteration.
  - Pattern rotation: right-click during drag rotates pattern cells 90° clockwise.
  - Grid panel renders per-cell backgrounds for pattern items; drag preview highlights individual cells.
- **Added inventory save/load API**:
  - `GridInventory.save_to_dict()` / `load_from_dict()` serializes/restores full inventory state including placements, hotbar, and ItemStack data.
  - `EquipmentState.save_to_dict()` / `load_from_dict()` serializes/restores equipment slots and all container grids.
- **Updated documentation**:
  - Updated `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md` to v0.4.
  - Updated progress documents.

---

## Update 19 — MSF UIManager Integration / UI System Refactor

### Changes

- **Refactored all gameplay UI to use MSF `UIManager` stack-based panel management**:
  - `PlayerHUD` changed from `CanvasLayer` to `Control` and registered as a `UIManager.add_overlay()` on `UILayer.SCENE`.
  - `InventoryMenu` changed from `CanvasLayer` to `UIPanel`, opened/closed via `UIManager.open_panel()` / `UIManager.back()` on `UILayer.NORMAL`.
  - New `PauseMenuPanel` extends `UIPanel`, opened via `UIManager.open_panel()` on `UILayer.POPUP`.
  - Removed old Maaacks `PauseMenuController` dependency from `DemoGame.tscn`.
- **Fixed ESC key conflict between inventory and pause menu**:
  - `InventoryMenu._unhandled_input()` now consumes `ui_cancel` to close inventory via `UIManager.back(NORMAL)`.
  - `PauseMenuPanel._unhandled_input()` consumes `ui_cancel` to close pause via `UIManager.back(POPUP)`.
  - `DemoGameRuntime._poll_pause_input()` only opens pause menu when no other panels are open.
  - Stack-based layer ordering guarantees correct input priority.
- **Introduced `UICatalog` for registry-driven UI panel registration**:
  - Follows the same catalog pattern as `ItemCatalog`, `WeaponCatalog`, etc.
  - Registers `game:ui/pause_menu` (POPUP, CacheMode.NONE) and `game:ui/inventory` (NORMAL, CacheMode.CACHE).
- **Converted script-built UI to Godot scenes**:
  - New `scenes/game_scene/ui/pause_menu_panel.tscn` with full button layout and confirmation dialogs.
  - New `scenes/game_scene/ui/inventory_panel.tscn` as UIPanel root for inventory.
  - Updated `scenes/game_scene/player_hud.tscn` root from `CanvasLayer` to `Control`.
- **Structural improvements per MSF patterns**:
  - All HUD elements now use `mouse_filter = MOUSE_FILTER_IGNORE` to avoid blocking input.
  - Inventory data (grid, equipment) passed via `_on_open(data)` dictionary instead of direct method calls.
  - Panel lifecycle callbacks (`_on_init`, `_on_open`, `_on_close`, `_on_destroy`) replace manual open/close/toggle.
- **New documentation**:
  - Added `UI_SYSTEM_REFACTOR.md` / `UI_SYSTEM_REFACTOR_ZH.md`.
  - Updated progress documents.

---

## Update 18 — Minimal Vector Theme Design Documentation

### Changes

- **Extracted the current `minimal_vector` theme into a dedicated design document**:
  - Added `MINIMAL_VECTOR_THEME_DESIGN.md` and `MINIMAL_VECTOR_THEME_DESIGN_ZH.md`.
  - Documented the theme's scope, palette structure, control coverage, and editing guidelines.
  - Explicitly recorded the boundary between the global theme resource and gameplay-local UI style overrides (inventory slots, hotbar slots, equipment placeholders).
- **Kept implementation unchanged**:
  - This update is documentation-only and does not alter the existing theme resource or gameplay UI behaviour.

---

## Update 17 — Equipment Slot Drag/Unequip Flow + Minimal Vector Theme Palette Pass

### Changes

- **Equipment panel now supports drag-based equip / unequip**:
  - Inventory items can now be dragged from a container grid onto compatible equipment slots to equip them.
  - Equipped items can now be dragged back out of non-backpack equipment slots and dropped into a container grid to unequip them.
  - Dragging an equipped item between compatible equipment slots now rebinds the item to the new slot.
  - The backpack slot remains locked while it is the active storage source for the inventory UI, preventing the primary bound backpack grid from being detached accidentally.
- **Reused the existing inventory drag/drop flow with minimal code churn**:
  - `InventoryGridPanel` gained a lightweight external-drop hook for accepting items dragged out of equipment slots.
  - Equipment-slot interactions were added in `InventoryMenu` instead of rewriting the grid drag logic.
- **Updated `minimal_vector.tres` palette without touching finalized button colors**:
  - Kept `Button` normal / hover / pressed / focus colors unchanged.
  - Updated non-button theme elements such as panel backgrounds, tab surfaces, scrollbar colors, progress-bar background, and line-edit selection/fill colors.
  - The revised palette pulls closer to the supplied reference image: brighter cyan blues, vivid greens, warm orange-browns, and saturated yellow tab accents.
- **Updated documentation**:
  - Updated `EQUIPMENT_SYSTEM.md` / `EQUIPMENT_SYSTEM_ZH.md`.
  - Updated `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md`.
  - Updated progress documents.

---

## Update 16 — Hotbar Square Layout + Inventory Scene/Player Inventory Binding

### Changes

- **Hotbar visuals updated to fixed-size squares**:
  - HUD hotbar slots now remain `56 × 56` in both normal and selected states.
  - Selected hotbar slots now change only their fill colour to semi-transparent green (`alpha = 64`); they no longer grow in size.
  - Inventory-menu hotbar styling was updated to match the HUD.
- **Inventory scene is now bound to the player's real inventory**:
  - `DemoGameRuntime` now instantiates `scenes/game_scene/inventory_menu.tscn` instead of constructing the menu purely via `InventoryMenu.new()`.
  - The player's `InventoryState.inventory` is now used as the backpack grid, so the player runtime, HUD, and inventory menu all share the same inventory data.
  - Player startup inventory was normalized to the documented default backpack size of `6 × 6`.
- **Equipment panel now mirrors live equipment state**:
  - The inventory menu's equipment panel now shows the currently bound item name / fallback label for each visible equipment slot.
  - Backpack and vest grid sections now display the equipped container name alongside grid dimensions.
  - Hotbar slot assignments are mirrored back into `EquipmentState`, keeping weapon / usable-slot state aligned with the inventory UI.
- **Hotbar reservation rules tightened**:
  - Hotbar slots `0–2` now only accept items tagged as `weapon`, matching the equipment-system design.
  - Selecting a non-weapon hotbar item no longer overwrites `combat_state.equipped_weapon_id`.
- **Updated documentation**:
  - Updated `HUD_HOTBAR_DESIGN.md` / `HUD_HOTBAR_DESIGN_ZH.md`.
  - Updated `EQUIPMENT_SYSTEM.md` / `EQUIPMENT_SYSTEM_ZH.md`.
  - Updated `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md`.
  - Updated progress documents.

---

## Update 15 — Equipment System + UI Overhaul (No Textures)

### Changes

- **Introduced Equipment System (`EquipmentState`)**:
  - New component: `scripts/game/components/gameplay/equipment_state.gd`.
  - Defines 14 equipment slots: primary/secondary/melee weapons, 6 usable hotbar slots, armor, headset, helmet, backpack, tactical vest.
  - Container slots (backpack, vest) own their own `GridInventory` instances.
  - Designed for extensibility — new slots can be added to `SLOT_KEYS` without breaking existing code/saves.
  - `sync_weapons_to_hotbar()` pushes equipped weapons to hotbar slots 0-2.
- **Rewrote hotbar UI to use StyleBoxFlat (no texture/material)**:
  - Each hotbar slot is now a `PanelContainer` + `StyleBoxFlat` (was `TextureRect` + `hud_item.png`).
  - Theme: 6 px pure-black border, 8 px corner radius, background alpha = 64.
  - Selected slot: slightly enlarged (56→64 px) with deep-blue fill.
- **Rewrote inventory grid cells to use StyleBoxFlat (no texture/material)**:
  - `InventorySlot` changed from `TextureRect` to `PanelContainer` + `StyleBoxFlat`.
  - Theme: 6 px pure-black border, 0 px corner radius (no rounding), background alpha = 64.
- **Inventory menu now generates equipment-based grids**:
  - Default player has backpack (6×6) and tactical vest (3×2).
  - Equipment panel (left side) shows placeholder slots for all gear categories.
  - Container grids (right side) are dynamically generated per equipped container.
- **Item textures use fit-by-height scaling**:
  - New `_fit_by_height_rect()` in `InventoryGridPanel` maintains aspect ratio, scales to cell height, centres horizontally.
  - Item icons rendered above grid, not affected by inventory panel mask.
- **Updated `DemoGameRuntime`**:
  - Creates `EquipmentState` with default backpack + tactical vest at startup.
  - Binds both inventory grid and equipment state to `InventoryMenu`.
  - HUD binds to backpack grid for hotbar display.
- **Updated i18n**:
  - Added `action_hotbar_next` and `action_hotbar_prev` strings (EN + ZH).
- **New documentation**:
  - Added `EQUIPMENT_SYSTEM.md` / `EQUIPMENT_SYSTEM_ZH.md`.
  - Updated `HUD_HOTBAR_DESIGN.md` / `HUD_HOTBAR_DESIGN_ZH.md` (v0.2).
  - Updated `INVENTORY_SYSTEM.md` / `INVENTORY_SYSTEM_ZH.md` (v0.2).
- **Key bindings verified**:
  - `pe_inventory` (Tab) for opening inventory.
  - `pe_hotbar_1` through `pe_hotbar_9` (keys 1-9) for hotbar selection.
  - All via GUIDE input system, fully remappable.

---

## Update 14 — Hit Particle VFX + Item/Inventory/Weapon Data Systems

### Changes

- **Added hit particle effect for projectile impact without extra sprite assets**:
  - New scene: `scenes/vfx/hit_particle_effect.tscn` using `CPUParticles2D` only.
  - New script: `scripts/game/vfx/hit_particle_effect.gd`.
  - Emits one-shot blood-like impact particles with gravity, spread, and short lifetime.
  - Spawn integrated in projectile hit flow (`projectile.gd:on_hit`) via preloaded scene and runtime `emit_hit(...)`.
- **Implemented item system (registry-driven)**:
  - Added `ItemDefinition` resource schema.
  - Added `ItemRegistry` + `ItemCatalog` with built-in entries:
    - `game:item/weapon/pistol`
    - `game:item/weapon/creature`
    - `game:item/med/bandage`
    - `game:item/ammo/9x19`
- **Implemented inventory system (data-only runtime structures)**:
  - Added `ItemStack` and `GridInventory`.
  - Updated `InventoryState` to own `GridInventory`, support `add_item(...)`, and keep `current_weight` synchronized via computed item weights.
- **Implemented weapon system based on item system**:
  - Added `WeaponDefinition`, `WeaponRegistry`, and `WeaponCatalog`.
  - Weapon entries map from equipped item IDs to combat parameters (projectile ID, ammo capacity, spread, recoil, reload timing).
  - Added `WeaponCatalog.apply_to_combat_state(...)` and integrated into player/human enemy/non-human enemy runtime setup.
  - `DemoGameRuntime` now ensures item/weapon registries are initialized at startup.
- **Updated design docs**:
  - Expanded `GDD_Version2.md` / `GDD_Version2_ZH.md` with item→weapon mapping runtime notes.
  - Added `ITEM_REGISTRY.md` / `ITEM_REGISTRY_ZH.md`.
  - Added `WEAPON_REGISTRY.md` / `WEAPON_REGISTRY_ZH.md`.

---

## Update 13.4 — Human Hitbox Isolation and Projectile Air Blocking

### Changes

- **Human hitbox no longer collides with ground/air movement layers**:
  - Converted `Player/HitCollision` and `HumanEnemy/HitCollision` from direct `CollisionShape2D` to `Area2D` (`collision_layer = 1`, `collision_mask = 0`) with a child shape.
  - Set human `CharacterBody2D` movement collision to ground-only layer (`collision_layer = 2`), preserving interaction mask for player.
- **Projectile collision behavior aligned to docs and current requirement**:
  - Kept hostile actor hit-detection on hit domain (layer-1 semantics via runtime actor targeting).
  - Added air-layer blocker check in projectile motion using physics ray query; projectiles now expire when they hit air-blocking colliders.
  - Added explicit projectile collision bit fields in `ProjectileData` (`layer=Air`, `mask=Hit+Air`) for alignment and maintainability.
- **Death handling compatibility expanded**:
  - `BiologicalActor.on_death()` now also disables `Area2D`-based hit nodes (`monitoring/monitorable=false`) and child `CollisionShape2D` if present.

---

## Update 13.3 — Collision Layer/Mask Alignment for Independent Shapes

### Changes

- **Aligned entity collision layer/mask with collision design doc**:
  - `Player` (`CharacterBody2D`) set to `collision_layer = 3` (Hit + Ground), `collision_mask = 10` (Ground + Interaction).
  - `HumanEnemy` set to `collision_layer = 3` (Hit + Ground), `collision_mask = 2` (Ground).
  - `NonHumanEnemy` set to `collision_layer = 5` (Hit + Air), `collision_mask = 4` (Air).
- **Kept independent collision shapes and matched responsibilities**:
  - Human entities continue using separate `GroundCollision` and `HitCollision` nodes.
  - Ground movement collision and hit/interaction-domain collision remain structurally split.
- **Death-time collision disable compatibility fix**:
  - Updated `BiologicalActor.on_death()` to disable `CollisionShape2D`, `GroundCollision`, and `HitCollision` if present.
  - Preserves behavior for both legacy single-shape nodes and current split-shape setup.
- **Updated progress documents**.

---

## Update 13.2 — Human Ground/Hit Collision Split and Hand Color Sync

### Changes

- **Verified human entities use separate Ground/Hit collision shapes**:
  - Confirmed both `Player` and `HumanEnemy` scenes use distinct `CollisionShape2D` nodes:
    - `GroundCollision` for movement collision against ground-layer blockers.
    - `HitCollision` for hit/interaction-domain overlap logic.
  - Ground and hit/interaction responsibilities no longer share one `CollisionShape2D`.
- **Applied body color tint to both hands for human entities**:
  - Updated `HumanActor._apply_body_color()` so `LeftHand/HandSprite` and `RightHand/HandSprite` are tinted with the same `body_color` as `BodySprite`.
  - This automatically affects both `Player` and `HumanEnemy` through inheritance.
- **Updated progress documents**.

---

## Update 13.1 — Interaction Layer, Player Color Update, and Item Flip Verification

### Changes

- **Added Interaction collision layer (Layer 4)**:
  - Added Layer 4 (`0x08`) to the collision layer design as the **Interaction** layer.
  - Intended for item pickups, loot containers, trader terminals, and other interactable objects.
  - Only the player masks this layer; interactable objects use `Area2D` on layer 4 for overlap detection.
  - Updated `COLLISION_LAYER_DESIGN.md` and `COLLISION_LAYER_DESIGN_ZH.md` with the new layer, a new "Interactable Object" section, and updated player mask.
- **Changed player default color to `0xFFFF66`**:
  - Player `body_color` in `_setup_runtime_state()` changed from `Color(0.45, 0.65, 0.85)` to `Color("ffff66")`.
- **Verified held-item flipping during aim direction change**:
  - Confirmed that items held in AimPivot (ItemPivot/ItemSprite, RightHand, LeftHand) are children of `AimPivot` and correctly inherit the `scale.y = -1` flip when aiming left.
  - No code change required; the existing `_update_sprite_flip()` in `HumanActor` handles this correctly for both player and human enemy scenes.
- **Updated progress documents**.

---

## Update 13 — Sprite Flip, Body Color, Collision Layer Design, and Entity Registry Docs

### Changes

- **Sprite flipping based on aim direction (right = positive)**:
  - Added `_update_sprite_flip()` to `HumanActor` base class.
  - When the aim direction faces left (`x < 0`), the body sprite is flipped horizontally (`flip_h = true`) and the `AimPivot` scale is inverted on the Y axis (`scale.y = -1`) so hands and weapon render correctly.
  - Applies automatically to both Player and HumanEnemy through inheritance.
- **Added `body_color` variable to human actor base class**:
  - `HumanActor` now holds a `body_color: Color` variable (default `Color.WHITE`).
  - On `_ready()`, the body sprite's `modulate` is set to `body_color` via `_apply_body_color()`.
  - Player sets a preset blue tint (`Color(0.45, 0.65, 0.85)`) in `_setup_runtime_state()`.
  - Future human enemies or custom skins can override `body_color` before `super._ready()`.
- **Collision layer design document**:
  - Added `COLLISION_LAYER_DESIGN.md` and `COLLISION_LAYER_DESIGN_ZH.md`.
  - Layer 1 = Hit Collision (all entities), Layer 2 = Ground Collision (human actors + ground tiles), Layer 3 = Air Collision (non-human enemies, projectiles, air tiles).
  - Tiles can participate in ground, air, or both layers.
- **Entity registry documentation**:
  - Added `ENTITY_REGISTRY.md` (English, primary) and `ENTITY_REGISTRY_ZH.md` following the registry design template.
  - Documents the entry schema, validation rules, load timing, runtime access pattern, and current entries.
- **Updated progress documents**.

---

## Update 12 — Crosshair Relaxed-State Hidden, Free-Mouse ADS, ADS Vignette, and UI Button SFX Fix

### Changes

- **Crosshair relaxed state now hides the node instead of swapping texture**:
  - Relaxed (paused / UI) state sets `visible = false` on the crosshair sprite.
  - Removed the `mouse.png` texture swap; the system cursor takes over when the pause menu makes it visible.
- **Crosshair follows the mouse freely during ADS**:
  - Removed the `ads_distance` clamping from crosshair position; crosshair always tracks the mouse in both hip-fire and ADS.
  - Introduced a separate invisible `CameraAimTarget` node whose position is clamped by `CombatState.ads_distance`.
  - Phantom-camera follow target now switches to `CameraAimTarget` (not the crosshair) during ADS, so the camera is distance-limited while the crosshair is not.
- **Added ADS vignette darkening overlay**:
  - New `AdsVignetteOverlay` (CanvasLayer) with a shader-driven full-screen `ColorRect`.
  - A circular transparent hole (default 32 px radius, matching the 64 × 64 crosshair sprite) follows the crosshair screen position.
  - Area outside the circle is dimmed (default 50 % black); configurable via `enabled`, `radius_px`, `darkness`, and `softness_px` properties.
  - Effect is enabled by default and automatically activates during ADS.
  - Shader file: `resources/shaders/ads_vignette.gdshader`.
- **UI button press now plays `select.mp3` instead of `click.mp3`**:
  - `opening.gd` wires `button_pressed_player` to `select.mp3`, matching `button_focused_player`.
  - `cancel.mp3` remains registered in the audio catalog as a placeholder; the registry contents are unchanged.
- **Updated docs to match the new crosshair/camera/vignette/audio behavior**.

---

## Update 11 — Crosshair Node, Relaxed Mouse Cursor, and ADS Camera Follow-Target Switch

### Changes

- **Added runtime crosshair/mouse node with three visual states**:
  - relaxed state (UI interaction): `assets/game/textures/ui/mouse.png`
  - hip-fire state: `assets/game/textures/ui/crosshair_normal.png`
  - ADS state: `assets/game/textures/ui/crosshair_aiming.png`
- **Applied origin/centering rules by state**:
  - relaxed mouse sprite is not centered (top-left origin)
  - hip-fire / ADS crosshair sprites are centered
- **Reworked camera follow behavior around ADS**:
  - ADS now switches phantom-camera follow target to crosshair instead of player.
  - Crosshair ADS position is clamped by `CombatState.ads_distance`; camera no longer follows beyond that range.
  - Leaving ADS switches follow target back to player.
- **Added weapon aiming-time parameter for smooth follow-target switching**:
  - Added `CombatState.aim_transition_sec`.
  - Camera follow-target transition smoothing now uses this parameter through phantom-camera damping.
- **Updated docs to match the new crosshair/camera runtime behavior**.

---

## Update 10 — Runtime Naming Cleanup, Entity Registry, and Projectile Registry

### Changes

- **Removed the most visible ECS-era naming from the active gameplay runtime**:
  - Renamed runtime state/resources away from `C_*` naming to neutral names such as `CombatState`, `ProjectileData`, `HealthState`, `FactionState`, and `AIState`.
  - Renamed runtime processors away from `S_*` naming to `CombatFireRuntime` and `ProjectileMotionRuntime`.
  - Renamed actor / projectile files and scene definitions away from `e_*` naming (`player.gd`, `human_enemy.gd`, `non_human_enemy.gd`, `projectile.gd`, `player.tscn`, etc.).
- **Added an entity registry for runtime actor definitions and instantiation**:
  - Added `EntityRegistry` + `EntityCatalog` to register current entity definitions (`player`, `human_enemy`, `non_human_enemy`).
  - Updated `DemoGame` to instantiate its runtime actors from the entity registry instead of placing the actor scenes directly in `DemoGame.tscn`.
- **Added a projectile registry for projectile definitions and firing flow**:
  - Added `ProjectileRegistry` + `ProjectileCatalog` to register projectile definitions such as the standard bullet and creature projectile.
  - Reworked combat firing so projectile spawning now goes through `ProjectileCatalog.instantiate_projectile(...)`.
  - Simplified `CombatState` so projectile configuration is addressed by `projectile_definition_id` rather than duplicating projectile stat fields per actor.
- **Updated documentation to match the registry-based runtime flow**:
  - Synchronized API / architecture / progress docs with the new naming, entity registry, projectile registry, and runtime instantiation flow.

---

## Update 9 — Script Layout Cleanup, Runtime Helper Reuse, and Documentation Sync

### Changes

- **Reorganized runtime scripts to match the post-ECS architecture**:
  - Renamed the stale `scripts/ecs/` tree to `scripts/game/` so the directory structure now reflects the current node-driven gameplay runtime.
  - Updated scene/script references to the new runtime paths.
- **Applied low-risk code-design cleanup in the active runtime**:
  - Moved repeated actor movement and target-resolution helpers into `BiologicalActor`.
  - Added reusable GUIDE polling helpers in `guide_input_runtime.gd`.
  - Simplified `Player`, enemy body scripts, demo runtime pause polling, and the GUIDE options menu to reuse those helpers instead of duplicating the same logic.
- **Synchronized docs with the new script layout**:
  - Updated architecture/API/progress notes so the documented script organization and helper responsibilities match the current codebase.

---

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
  - Added `biological_actor.gd` as a shared base for biological actor setup.
  - Centralized delayed runtime hookup and shared initialization so player / human enemy / non-human enemy body scripts follow the same setup path.
  - Files: `biological_actor.gd`, `human_actor.gd`, `player.gd`, `human_enemy.gd`, `non_human_enemy.gd`.
- **Demo scene now visibly includes all three biological categories**:
  - Added `HumanEnemy` and `NonHumanEnemy` instances to `DemoGame.tscn` so Player / Human Enemy / Non-Human Enemy are all present in the same playable scene flow.
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
  - Files: `combat_state.gd`, `projectile_data.gd`, `combat_fire_runtime.gd`, `projectile_motion_runtime.gd`.
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
  - Files: `combat_fire_runtime.gd`, `combat_state.gd`, `player_input_context.gd`, `player.gd`.
- Implemented projectile distance attenuation and distance-based expiry:
  - `projectile_data.gd`, `projectile_motion_runtime.gd`.
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
  - `player.gd`.
- Implemented aiming + shooting processing with recoil and hipfire/ADS precision:
  - `combat_fire_runtime.gd`, `projectile_motion_runtime.gd`, `projectile.gd`.
  - `combat_state.gd`, `projectile_data.gd`, `aim_state.gd`.
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

- Implement collision layer assignments in entity scenes and tile maps per `COLLISION_LAYER_DESIGN.md`.
- Full global state machine redesign across all game flows and menus.
- Complete projectile hit detection and damage application pipeline.
- Full enemy AI-driven aiming/shooting integration.
- Inventory / item system implementation.
- Full level progression flow integration.
