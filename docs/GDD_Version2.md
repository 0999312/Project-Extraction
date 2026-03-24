# Project Extraction (Working Title) — Game Design Document (GDD) v0.3 (EN)

**Date:** 2026-03-16  
**Primary Mode:** Single-player (offline, authoritative local simulation)  
**Future Mode:** Client–Server **Co-op PvE** (same content and rules as single-player)  
**Core Pillars:** Looting & inventory decisions → Risk management → Extraction → Safehouse progression (home system) → Tech unlocks (Intel)

---

## 1) High Concept

A 2D top-down extraction shooter with Tarkov-like looting and a strong “search & secure” loop. Each raid takes place on a large open map populated with POIs (Points of Interest). Players explore, fight, loot, and extract. Outside raids, players develop a **Safehouse Home System** (building, survival improvements, agriculture, light industry/automation, trading facilities, and map expansion), using materials and “Intel” recovered from raids.

**Character Style:** Humans are highly abstract and cute: effectively a “talking sphere with hands”. This reduces animation complexity and improves clarity/performance while preserving the depth of tactical gameplay.

---

## 2) Content IDs: ResourceLocation Everywhere (MSF Requirement)

All IDs in design and implementation use **Minecraft-Style-Framework `ResourceLocation`** (`namespace:path`) as the single source of truth for identification across:
- registry entries (items, POIs, entities, scenes, loot tables, quests, etc.)
- tags
- event bus events
- save data references
- runtime spawn instructions

**Example IDs:**
- `core:registry/item` (registry type RL reference)
- `game:item_weapon` (major item category definition)
- `game:poi_metro_station`
- `game:loot_table_city_crates`
- `game:quest_find_lab_notes`
- `game:tag/weapon_smg` (tag IDs as RL)
- `game:intel_lab_notes`

> **Important:** per your rule, weapons/meds/etc. are registered as major categories. Subtypes are expressed via **tags** and data fields.

---

## 3) Gameplay Loops

### 3.1 Raid Loop (Session)
1. Choose loadout from stash (risk vs reward).
2. Deploy to raid map (generated open area + POIs).
3. Explore POIs, loot containers, fight enemies.
4. Collect materials + Intel items + quest objectives.
5. Move to extraction point; survive extraction countdown/conditions.
6. Extract → transfer secured items to stash; apply quest progress and meta rewards.
7. Fail → lose unsecured items (safe container exceptions).

### 3.2 Safehouse Home System Loop (Meta)
- Manage stash (grid inventory).
- Build/upgrade home facilities: storage, crafting, med station, farm plots, workshops, power grid (light).
- Agriculture production → processing.
- Light industrial automation → stable production of key consumables/components.
- Trading facilities (fixed stations, not NPC entities).
- Expand accessible safehouse/map areas via upgrades/unlocks.
- Tech tree unlocked using Intel (raid-only knowledge items).

---

## 4) Key Systems (Tarkov-like Feature Checklist)

### 4.1 Player State (Lightweight Injury)
Focus on readable, gameplay-relevant states:
- `HP` (single pool)
- `Stamina`
- `Encumbrance` (weight affects speed, stamina regen, noise)
- `BleedLight` / `BleedHeavy`
- `Pain` (aim sway penalty / interaction speed penalty)
- Optional later: `Fracture` (movement penalty)

**Healing items:** registered as **one major category** `game:item_med`.  
Effects are tag-driven: `game:tag/med_bandage`, `game:tag/med_painkiller`, etc.

### 4.2 Combat (Ranged + Melee)
**Ranged weapons**
- Caliber + fire mode determined by tags (e.g. `game:tag/caliber_9x19`, `game:tag/firemode_auto`)
- Basic recoil/spread model
- Basic armor vs penetration model (lightweight)

**Melee**
- light/heavy attack
- short-range arc / box hit
- stamina cost

### 4.3 Looting & Containers (Primary Pillar)
- World containers: crates/drawers/safes/corpses/lockers
- **Deferred loot roll**: generate container contents on first open (or when player enters the chunk) for performance + replayability.
- Sound/risk: opening containers can emit noise events (optional).

### 4.4 Grid Inventory
- player inventory areas: pockets/rig/backpack/safe container
- item fields: `size_w`, `size_h`, `weight`, `max_stack`
- rotate items
- stack/split
- equipment slots + weapon mod slots (tag + slot rules)

### 4.5 Enemies (Human + Non-Human)
- Human enemies: abstract “sphere people” with ranged weapons, simple tactics.
- Non-human enemies: distinct locomotion/attacks (swarmers, chargers, drones, infected blobs).
- Elites/bosses optional after core loop.

### 4.6 Quests, Dialogue, Trading
- Quests: kill/fetch/place/scout/extract-with-item
- Dialogue: branching options, quest gates
- **No merchant entities**: traders are **fixed interaction points** in safehouse (and optionally in-raid kiosks).
- Trading: buy/sell/barter, reputation/tech gates

---

## 5) Data & Content Implementation (Concrete)

This section describes how “items, actors, POIs, etc.” exist in the game in a way compatible with MSF registries and a scene/node-driven runtime.

### 5.1 Registries (ResourceLocation-driven)
Recommended registry types (retrieved via `RegistryManager.get_registry(type_name)` in MSF):
- `core:item` → **Item definitions** (major categories only)
- `core:tag` → Tags pointing to a registry type (MSF `TagRegistry` expects registry type RL)
- `core:poi` → POI definitions
- `core:loot_table` → Loot table definitions
- `core:quest` → Quest definitions
- `core:dialogue` → Dialogue definitions
- `core:scene` → Scene template definitions (safehouse/raid templates)
- `core:spawn_profile` → runtime spawn definitions for actors, loot markers, and encounter presets

> Note: MSF `Tag` stores `registry_type: ResourceLocation` and entries as RL strings. Tags must point to the correct registry type RL (e.g., `core:item`).

### 5.2 Item Data Model (Major Category + Tags)
**Registry entry:** `ItemInfo` (MSF demo shows `ItemInfo` holds `scene` or `script` and display name).  
For this game, extend or wrap with a richer data resource (example concept):
- `id: ResourceLocation`
- `display_name_key: String` (for I18n)
- `icon: Texture2D`
- `world_drop_scene: PackedScene` (optional: used when item is dropped into world)
- `size_w: int`, `size_h: int`
- `weight: float`
- `max_stack: int`
- `use_action: ResourceLocation` (e.g. `game:use/med_apply`)
- `data: Dictionary` for category-specific fields (ammo stats, durability, etc.)
- tags: stored in TagRegistry (not inside the item entry)

**Major category IDs (examples):**
- `game:item_weapon` (ALL guns + melee weapons share this major registry entry type; subtypes via tags)
- `game:item_med`
- `game:item_ammo`
- `game:item_armor`
- `game:item_material`
- `game:item_tool`
- `game:item_food`
- `game:item_intel`
- `game:item_quest`

**Subtype tags (examples):**
- `game:tag/weapon_smg`, `game:tag/weapon_rifle`, `game:tag/weapon_melee`
- `game:tag/caliber_9x19`, `game:tag/caliber_12g`
- `game:tag/med_bandage`, `game:tag/med_hemostat`, `game:tag/med_painkiller`
- `game:tag/intel_tier1`, `game:tag/intel_lab`

### 5.3 Inventory Implementation (How items exist at runtime)
Items in inventory should be **pure data**, not Nodes, for performance and save simplicity.

**Suggested runtime structures:**
- `ItemStack`:
  - `item_id: ResourceLocation`
  - `count: int`
  - `durability: float` (optional)
  - `custom_data: Dictionary` (ammo remaining, attachments list RLs, etc.)
  - `tags_cache: Array[ResourceLocation]` (optional optimization)
- `GridInventory`:
  - `width`, `height`
  - occupied cells map → stack id/index
  - per-stack placement (`x`, `y`, `rotated`)

**World drops:** when an item is dropped, spawn a **world pickup node** referencing `item_id` and display data.

### 5.4 POI Data Model (Open World + Fragments)
POI registry entries include:
- `poi_id: ResourceLocation`
- `scene_fragment: PackedScene` (visuals + collision + markers)
- `footprint: Rect2i` or polygon definition (for placement checks)
- `biome_tags: Array[ResourceLocation]`
- `loot_profile_id: ResourceLocation` (loot table RL)
- `spawn_profile_id: ResourceLocation` (enemy spawn preset RL)
- `special_rules: Dictionary` (locked doors, keycard requirements, quest hooks)

---

## 6) Gameplay Content: Different Runtime Implementations (Per Requirement)

We explicitly separate gameplay content by how it should be implemented for performance, readability, and development speed.

### 6.1 Player (CharacterBody2D + Local State Object)
**Implementation:**
- Godot Node: `CharacterBody2D` (movement, collision, animation, interaction origin).
- Runtime state: a `PlayerState` data object or Resource stored on the player script:
  - health / stamina / bleed / pain
  - inventory reference
  - weapon state
  - quest state reference
- Input is written directly into the player runtime state each physics frame.
- Animation / VFX / camera offset read the same state locally.
- In the current project layout, these runtime scripts live under `scripts/game/`.

**Why this approach?**
- Keeps moment-to-moment control responsive.
- Avoids a second gameplay abstraction layer for the only actor the player directly owns.

### 6.2 Enemies (Node-driven Bodies + Data-driven AI Brains)
**Implementation:**
- Enemy scenes remain visible gameplay actors with their own body scripts.
- Each enemy owns an `EnemyState` structure:
  - health / alertness / target reference / weapon state / current tactic
- Decision-making is handled by a lightweight AI brain/state machine per enemy type.
- Pathfinding can still be centralized through a shared navigation service:
  - enemy requests path updates
  - service returns path points
  - enemy script follows those points
- Shared runtime helpers should be reused for repeated movement/target-resolution behavior instead of re-implementing them per actor script.

**Why this approach?**
- Easier to iterate on enemy feel, animation, and hit reactions.
- Still supports chunk activation and AI LOD by enabling/disabling enemy brains or reducing update frequency.

### 6.3 Projectiles (Pooled Runtime Objects)
**Implementation:**
- Projectiles are spawned from a pooled manager or lightweight projectile scene list.
- Each projectile stores:
  - position
  - velocity
  - lifetime / remaining distance
  - damage / penetration
  - owner reference or faction marker
- A projectile manager updates active projectiles each frame and performs collision checks.
- Visual tracers remain optional and should also be pooled.

**Why this approach?**
- Maintains high projectile throughput without requiring a separate gameplay framework.
- Fits the current game scale and keeps debugging straightforward.

### 6.4 Loot Containers (Scene Markers + Lazy State)
**Implementation options:**
- Static container Node in POI scene (`Area2D` + sprite + interaction prompt) with `container_id`.
- On first interaction, create or initialize local container state:
  - rolled flag
  - generated item list
  - lock state
- Generated contents remain attached to the container node or a local save payload.

**Why this approach?**
- Preserves deferred loot generation for performance.
- Avoids creating thousands of runtime objects before the player interacts with them.

### 6.5 Doors / Locks (Animated Nodes + State Records)
**Implementation:**
- Doors in POI fragments are Nodes for collision toggling and animation.
- Each door stores local state:
  - `is_locked`
  - `required_key_tag` or `required_key_item_id`
  - `is_open`
- Interaction validates inventory requirements, then updates animation and collision state directly.

### 6.6 Traders (Fixed Interaction Points; not roaming actors)
As requested: **no merchant actors**.
- Traders are **interaction stations** in safehouse:
  - Node: `TraderTerminal` / `ShopCounter`
  - Data: `trader_id: ResourceLocation`
- Trading UI pulls from registry-defined trader inventory rules:
  - inventory lists by tags + refresh timers
  - barter rules referencing item IDs/tags

### 6.7 Shared Biological Actor Base
A shared biological actor base is still useful, but only as a scene/runtime contract:
- common health / death / damage response hooks
- delayed setup when runtime references are not ready yet
- shared aiming anchor conventions for player / human enemy / non-human enemy bodies

---

## 7) Safehouse “Home System” (Expanded Requirement)

Safehouse is a persistent meta-map with:
- Building & upgrades
- Survival improvements
- Agriculture & industry
- Trading venues
- Map expansion

### 7.1 Home Modules (Registry-driven)
Each home module is defined via RL and data:
- `game:home/storage_upgrade_1`
- `game:home/med_station_1`
- `game:home/farm_plot_1`
- `game:home/workshop_1`
- `game:home/power_node_1`
- `game:home/trader_counter_1`
- `game:home/map_expansion_north_gate`

Module data fields:
- build cost: item tag requirements + counts
- prerequisites: tech node RLs
- provides:
  - new crafting recipes
  - new trader stock tiers
  - larger stash size
  - new safehouse rooms/areas
  - production capacity changes

### 7.2 Agriculture (Simple, scalable)
- Farm plots produce “raw” resources over time.
- Processing stations convert raw → useful crafting inputs.
- Outputs feed crafting and barter economy.

### 7.3 Industrial Automation (Lightweight Network, not physics conveyors)
Implement as a graph:
- Nodes: producers / processors / storage / power sources
- Edges: transport links
- Each tick:
  - pull inputs from upstream buffers
  - process recipe
  - push outputs downstream
This keeps automation fun but feasible in 2D without heavy physics.

### 7.4 Trading Locations
Trading is done at:
- `TraderTerminal` stations
- `MarketStall` stations unlocked via expansions

---

## 8) Raid Map Generation (Concrete Mechanism)

### 8.1 Inputs
- `raid_template_id: ResourceLocation` (base TileMap set, biome tags, size, difficulty)
- random seed
- POI pool filtered by biome/difficulty tags
- spawn preset pool for enemies and containers

### 8.2 Generation Steps (Recommended)
1. **Generate base terrain**
   - Place roads/rivers/impassable areas using noise + template masks.
2. **Define candidate zones**
   - Partition the map into regions (city/industrial/fields/forest).
3. **Place major POIs**
   - Pick 3–7 major POIs (metro station, lab, warehouse, farm, checkpoint).
   - Enforce minimum distance between major POIs.
   - Ensure at least 1 “high risk high reward” POI.
4. **Place minor POIs**
   - Scatter 10–30 small POIs (shacks, cars, small depots) with density based on region.
5. **Connect traversal**
   - Ensure walkable connectivity between:
     - player spawn zones
     - at least 2 extraction points
     - major POIs
6. **Assign loot + enemy profiles**
   - Each POI gets:
     - `loot_profile_id` (loot table RL)
     - `spawn_profile_id` (encounter RL)
7. **Place player spawn**
   - Choose among spawn zones on map edge or low-risk region.
   - Prefer far from the highest-value POI to create travel decisions.
8. **Place extraction points (critical)**
   - Generate 3–6 extraction candidates:
     - **Guaranteed extraction:** 1–2 always available, positioned far from spawn and preferably near map edges.
     - **Conditional extractions:** require item tag, switch activation, payment, or time window.
   - Rules:
     - At least one extraction must be within ~60–75% travel distance from spawn (not too close).
     - At least one extraction must be on the opposite side of the map to force route planning.
     - Conditional extractions can be closer but have requirements.
9. **Place quest markers**
   - If active quests require special objects:
     - spawn them in specific POIs or designated marker points inside POI scenes.
10. **Chunk activation setup**
   - Precompute chunk metadata:
     - which POIs intersect chunk
     - which spawn/loot profiles to activate on entry

### 8.3 Example Extraction Types (Data-driven)
Extraction definitions are registry entries:
- `game:extract/edge_gate` (always on, countdown 8s)
- `game:extract/paid_boat` (requires currency tag `game:tag/currency`, countdown 5s)
- `game:extract/keycard_door` (requires key item tag)
- `game:extract/power_switch` (requires powering a POI switch first)

---

## 9) Save System (Multi-Slot)

### 9.1 Slots
Multiple profile slots: `slot_01`, `slot_02`, etc.
Each stores:
- safehouse build state
- stash inventory (grid)
- tech tree unlocks
- trader reputation/progression
- quest progression state
- settings overrides per slot (optional)

All saved references to content use **ResourceLocation strings**.

### 9.2 Content manifest compatibility
Save metadata includes:
- `save_version`
- `content_manifest_hash` (based on registered RL keys + versions)
Missing RL fallback:
- replace missing items with `game:item_unknown_salvage` or refund value.

---

## 10) Milestones (Revised)

### Milestone 1 — Minimal Raid Loop (Loot/Extract)
- RL-based registries for items/tags/POIs/loot tables
- open area + POI placement + extraction placement
- container open → deferred loot roll → grid inventory moves
- 1 weapon archetype via tags + 1 enemy type
- extract/death → stash update
- multi-slot save create/load/delete

### Milestone 2 — Safehouse Home System
- build/upgrade core modules (storage, crafting, farm plot, trader terminal)
- tech tree consumes Intel items
- basic crafting + basic agriculture + first automation node

### Milestone 3 — Scaling & Optimization
- chunk activation and AI LOD tiers
- more POIs and loot tables
- more enemy types (human + non-human)
- more extraction types and quest hooks
