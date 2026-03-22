# Project Extraction — Tech Stack & Architecture v0.3 (EN)

**Date:** 2026-03-16  
**Goal:** Define the concrete technical stack and how MSF (registry/tags/events/I18n) + GECS (ECS) + Maaack Template integrate, including entity-type-specific implementations, safehouse home system, and raid map generation workflow.

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

### 1.3 ECS Runtime
- **csprance/gecs (GECS)**
  - Entities are Nodes holding component Resources; systems query + process entities.
  - QueryBuilder supports fluent queries, property filters, relationships, and `iterate()` fast paths.
  - CommandBuffer enables safe deferred structural changes.

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
- **Simple Audio Manager** (recommended for ease of use)
  - Autoload playback for SFX/BGM.
  - Wrapped via Audio Bridge so replacement is painless later.

---

## 2) Project Architecture (Performance-First, Hybrid ECS + Nodes)

### 2.1 Core Principle
**Simulation is data-driven and registry-addressable; presentation is node-driven.**  
No gameplay system should rely on hardcoded strings; use `ResourceLocation` everywhere.

### 2.2 Layers
1. **Content Layer (MSF)**
   - Registries: items, tags, POIs, loot tables, quests, dialogues, tech, home modules, raid templates.
2. **Simulation Layer (GECS)**
   - ECS world processes high-frequency and high-count logic:
     - AI, projectiles, status effects, loot roll decisions, quest state transitions.
3. **Presentation Layer (Godot Nodes)**
   - Player body, sprites, VFX, UI, camera, scene fragments.
4. **Bridge Layer (Autoload services)**
   - InputBridge, AudioBridge, UIBridge, SceneFlowBridge, CameraBridge
   - Bridges are the ONLY place allowed to call plugin APIs.

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
- ECS entity `E_ItemDrop` with component `C_ItemStack` referencing `item_id` and count.
- Optional Node view for sprite pickup prompt.

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

## 5) Entity Type Implementations (Per Requirement)

### 5.1 Player (Node + ECS Hybrid)
- Node: `CharacterBody2D` for movement/collision and animations.
- ECS: authoritative gameplay state and combat decisions.

**Sync path:**
- Node → ECS: position/aim
- ECS → Node: status effects, weapon state, camera shake events

### 5.2 Enemies (ECS-first)
- ECS handles AI state, targeting, weapon usage, health.
- Node view is minimal and can be chunk-activated/deactivated.

### 5.3 Projectiles (ECS-only)
- ECS updates positions, performs hit checks, applies damage events.
- Pool VFX and avoid per-projectile Nodes.

### 5.4 Containers (Lazy ECS state)
- Containers are POI fragment nodes for interaction triggers.
- ECS container-state entity created or activated on first interaction.

### 5.5 Traders (Fixed Interaction Points; Not Entities)
- Traders are safehouse **interaction terminals** (Nodes).
- Trader behavior is data-driven via `trader_id: RL` and registry definitions.
- No NPC merchant ECS entity exists.

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
  - sleep AI systems for entities outside radius
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

- **InputBridge:** G.U.I.D.E → MSF EventBus command events → ECS consumes
- **AudioBridge:** ECS `PlaySfxEvent` → Simple Audio Manager
- **SceneFlowBridge:** extraction/death requests → Maaack Scene Loader transitions
- **UIBridge:** ECS state → UI updates (event-driven)
- **CameraBridge:** ECS hit/explosion events → phantom-camera trauma/shake

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
- [ ] Implement ECS bridges and entity-type-specific pipelines