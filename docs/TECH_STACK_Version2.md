# Project Extraction — Tech Stack & Architecture v0.3 (EN)

**Date:** 2026-03-16  
**Goal:** Define the concrete technical stack and how MSF (registry/tags/events/i18n) + scene/node-driven gameplay + Maaack Template integrate, including gameplay-content-specific implementations, safehouse home system, and raid map generation workflow.

---

## 1) Repositories / Plugins (Scanned & Integrated)

### 1.1 Base Project
- **Maaack/Godot-Game-Template**
  - Provides scene/menu/options/pause patterns and a template-friendly project structure.

### 1.2 Content Framework (IDs, Registries, Tags, Events, I18n)
- **0999312/Minecraft-Style-Framework (MSF)**
  - **ResourceLocation** (`namespace:path`) is the core identifier.
  - **RegistryBase** stores entries keyed by ResourceLocation string.
  - **RegistryManager** autoload manages registries by type name.
  - **TagRegistry** manages `Tag` objects; each tag references a `registry_type: ResourceLocation` and contains entries of RLs.
  - **EventBus** for decoupled events (and cancellation / signal bridging).
  - **I18n** JSON-based localization.

### 1.3 Gameplay Runtime Pattern
- **Scene / Node-driven gameplay runtime**
  - Player, enemies, doors, and interaction points live as scene nodes with local state objects.
  - High-frequency logic (projectiles, combat updates, AI decisions) is handled by focused gameplay scripts and manager services.
  - Pooling and chunk activation remain the main performance tools.
  - The project no longer depends on GECS or gdUnit4.

### 1.4 Input
- **godotneers/G.U.I.D.E**
  - Context-driven input, rebinding support, device support.
  - Output must be converted into simulation commands (not direct node manipulation).

### 1.5 Camera
- **ramokz/phantom-camera**
  - Follow, smoothing, constraints, trauma/shake.
  - Controlled via a camera bridge from simulation events.

### 1.6 Scene Loading / Switching
- **Maaack Scene Loader** (preferred with Maaack template ecosystem)
  - Mandatory for large transitions (Safehouse ↔ Raid).
  - Standardizes loading screens and async resource loading.

### 1.7 Audio Management
- **@nathanhoad/godot_sound_manager** (recommended for ease of use)
  - Autoload playback for SFX/BGM.
  - Wrapped via Audio Bridge so replacement is painless later.
  - Project audio registry uses folder + filename configuration (`scripts/audio/audio_catalog.gd`).
  - Current initialization flow is scene-driven:
    - Startup groups are registered in `scenes/opening/opening.gd`.
    - Gameplay groups are registered in `scenes/loading_screen/loading_screen.gd`.

### 1.8 Localization
- JSON-based UI localization is initialized in `scenes/opening/opening.gd`
  via `I18NManager` (decoupled from audio registration).
- Current supported languages: `en`, `zh`.
- Active language is stored in `AppSettings.GAME_SECTION` with key `Language`
  and can be changed from `game_options`.

---

## 2) Project Architecture (Performance-First, Data-Driven Nodes)

### 2.1 Core Principle
**Gameplay logic is data-driven and registry-addressable; runtime actors remain scene/node-driven.**  
No gameplay system should rely on hardcoded strings; use `ResourceLocation` everywhere.

### 2.2 Layers
1. **Content Layer (MSF)**
   - Registries: items, tags, POIs, loot tables, quests, dialogues, tech, home modules, raid templates.
2. **Gameplay Logic Layer**
   - State objects, manager services, AI brains, and pooled runtime processors handle:
     - AI, projectiles, status effects, loot roll decisions, quest state transitions.
3. **Presentation Layer (Godot Nodes)**
   - Player body, enemy bodies, sprites, VFX, UI, camera, scene fragments.
4. **Service Bridge Layer**
   - InputBridge, AudioBridge, UIBridge, SceneFlowBridge, CameraBridge.
   - Bridges isolate plugin-specific APIs from the rest of gameplay code.

---

## 3) ResourceLocation (RL) Standards (Concrete)

### 3.1 Naming Conventions
- `game:*` for first-party content.
- `core:*` reserved for framework registry types.
- tags are also RLs, recommended pattern: `game:tag/<tag_name>`.

Examples:
- Registry types:
  - `core:item`, `core:poi`, `core:loot_table`, `core:quest`, `core:scene`, `core:tag`
- Content:
  - `game:item_weapon`, `game:item_med`
  - `game:poi_metro_station`
  - `game:loot_table_industrial`
  - `game:extract/edge_gate` *(if you implement extractions as registry entries)*

### 3.2 Tags (MSF TagRegistry)
- Each tag must declare which registry type it applies to:
  - e.g. `tag_id = game:tag/weapon_smg`
  - `registry_type = core:item`
- Tag entries are RLs (string-form inside `Tag`).

---

## 4) Data Definitions & Runtime Structures (Implementation Details)

### 4.1 Item Definitions (MSF Registry Entry)
MSF demo uses `ItemInfo` with `scene/script`. For this project:
- Store core item metadata in an `ItemInfo`-like Resource (extend or wrap).
- Keep inventory items as data, not Nodes.

**Inventory runtime:**
- `ItemStack { item_id: RL, count, durability?, custom_data }`
- `GridInventory { width, height, placements }`

**World drop runtime:**
- World pickup node carrying `item_id`, count, and optional display metadata.
- Optional lightweight prompt / highlight view for pickup feedback.

### 4.2 POI Definitions
POI registry entries include:
- fragment scene (PackedScene)
- placement footprint & rules
- loot profile RL
- spawn profile RL
- quest hooks RLs (optional)

### 4.3 Loot Tables
Loot table entries should be registry-driven:
- rules by biome/POI/container tags
- outputs are RL item IDs or item tags
- constraints: rarity, min/max count, weights

**Deferred roll policy (performance):**
- Only roll loot on:
  - container open
  - or chunk activation (player enters chunk)

---

## 5) Gameplay Content Implementations (Per Requirement)

### 5.1 Player (CharacterBody2D + Runtime State)
- Node: `CharacterBody2D` for movement/collision and animations.
- Local runtime state stores health, stamina, inventory reference, weapon state, and active effects.
- Input writes directly into player state; camera/UI/animation read from the same runtime data.

### 5.2 Enemies (Body Script + AI Brain)
- Enemy scenes own their movement, hit reactions, and interaction hooks.
- AI state, targeting, and weapon usage are managed by enemy-local brains or shared behavior helpers.
- Human enemies can keep the shared `HumanBase` aim-pivot rig; non-human enemies can keep full-body aiming while still following the same biological actor base contract.

### 5.3 Projectiles (Pooled Runtime Objects)
- Projectile manager updates positions, performs hit checks, and applies damage/results.
- Visual tracers and impact effects are pooled to avoid unnecessary scene churn.

### 5.4 Containers (Lazy Local State)
- Containers are POI fragment nodes for interaction triggers.
- Container state is created or hydrated on first interaction, keeping deferred loot behavior without preloading all container contents.

### 5.5 Traders (Fixed Interaction Points; Not roaming actors)
- Traders are safehouse **interaction terminals** (Nodes).
- Trader behavior is data-driven via `trader_id: RL` and registry definitions.
- No roaming merchant actor is required.

### 5.6 Biological Body Base Scene Contract
- Shared base script remains useful as a runtime contract for biological actors.
- Responsibilities:
  - centralize shared initialization
  - provide delayed setup when dependent runtime references are not ready yet
  - standardize health/damage/aim anchor behavior across derived bodies
- Derived bodies:
  - `HumanBase` (player + human enemy)
  - `NonHumanEnemyBody` (non-human enemy full-body rotation)

---

## 6) Safehouse Home System (Architecture)

### 6.1 Home Modules Registry
Create a registry `core:home_module`:
- each module: build costs (item tags), prerequisites (tech RLs), unlock effects (recipes, stash size, trader tiers, map expansions)

### 6.2 Automation Model
Use a graph-based logistics simulation:
- nodes: producer/processor/storage/power
- edges: transfer links
- tick-based processing with throughput caps

This is deterministic-friendly and scalable.

### 6.3 Map Expansion
Safehouse is segmented into areas:
- expansions unlock new rooms/plots/stations
- expansions also unlock new trader terminals / crafting stations

All expansions are RL-defined so saves remain stable.

---

## 7) Raid Map Generation (Concrete Pipeline)

### 7.1 Inputs
- `raid_template_id: RL`
- seed
- biome tags
- difficulty scalar

### 7.2 Steps
1. Generate base terrain TileMaps.
2. Partition into regions (city/industrial/fields/forest).
3. Place major POIs with distance constraints.
4. Scatter minor POIs by region density.
5. Validate connectivity between spawns, POIs, and extraction candidates.
6. Assign loot/spawn profiles per POI.
7. Select spawn zones.
8. Place extraction points:
   - 1–2 guaranteed always-available extractions, far from spawn
   - 1–4 conditional extractions (key/payment/power switch/time window)
9. Precompute chunk metadata for activation/deactivation.

### 7.3 Chunk Activation (Optimization)
- When chunk becomes active:
  - instantiate POI fragments if not loaded
  - activate enemy spawns
  - enable container interaction
- When chunk becomes inactive:
  - pause or simplify enemy brain updates outside the active radius
  - unload heavy visuals if safe

---

## 8) Save System (Multi-Slot, RL-safe)

### 8.1 Slot Structure
Each slot stores:
- stash grid inventories
- safehouse module states
- tech tree unlocks (Intel-driven)
- quests and trader progression
- references to content as RL strings

### 8.2 Versioning & Compatibility
Store:
- `save_version`
- `content_manifest_hash` based on RL keys
Missing RL fallback:
- convert to `game:item_unknown_salvage` or refund value

---

## 9) Bridges (Integration Contracts)

- **InputBridge:** G.U.I.D.E → runtime input commands / state updates for scene actors
- **AudioBridge:** UI/gameplay code → `AudioCatalog` / `SoundManager`
- **SceneFlowBridge:** extraction/death requests → Maaack Scene Loader transitions
- **UIBridge:** runtime state → UI updates (event-driven where appropriate)
- **CameraBridge:** hit/explosion/gameplay events → phantom-camera trauma/shake

---

## 10) Implementation Checklist (Backlog-Oriented)
- [ ] Define RL namespaces and registry type RLs
- [ ] Implement registry entries for items/POIs/loot/quests/tech/home modules
- [ ] Implement tag sets for weapon/med/ammo/intel/etc.
- [ ] Implement inventory data structures + grid placement logic
- [ ] Implement raid generation pipeline + extraction placement rules
- [ ] Implement container deferred loot roll system
- [ ] Implement safehouse home system modules + build/upgrade + automation graph
- [ ] Implement multi-slot save + versioning/migration
- [ ] Implement scene/node runtime pipelines and content-type-specific processing flows

---

## 11) Current Option & Input UX Adjustments

- `game_options` now includes language switching (English / 简体中文),
  persisted to `GameSettings.Language`.
- Keybinding UI is presented as a table:
  - Columns: `Keyboard` / `Mouse` / `Gamepad`
  - Rows: concrete actions
  - Movement directions are explicit rows:
    - `Move Up`, `Move Down`, `Move Left`, `Move Right`
