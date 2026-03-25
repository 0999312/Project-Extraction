# Collision Layer Design

This document describes the collision layer assignment for all physics objects in Project Extraction.

## Layer Assignments

| Layer | Bit | Purpose |
|---|---|---|
| 1 | `0x01` | **Hit Collision** — Damage hit-box present on every entity (player, human enemy, non-human enemy). Used by projectile hit-detection queries. |
| 2 | `0x02` | **Ground Collision** — Ground-level movement collision for human actors (player and human enemies) and tiles that block ground-level movement. |
| 3 | `0x04` | **Air Collision** — Airborne / elevated collision for non-human enemies, projectiles, and tiles that block airborne movement. |
| 4 | `0x08` | **Interaction** — Interaction trigger areas for items, loot containers, terminals, and other interactable objects. Only the player masks this layer to detect nearby interactables. |

## Per-Object Collision Setup

### Player (HumanActor)

| Property | Layers |
|---|---|
| `collision_layer` | 2 (Ground) |
| `collision_mask` | 2 (Ground), 4 (Interaction) |

- **HitCollision** (`Area2D` + CircleShape2D child) — on layer 1 with mask 0, used as a hit-domain only; it does not collide with ground or air movement layers.
- **GroundCollision** (CapsuleShape2D) — on layer 2, collides with ground-blocking tiles.
- Player masks layer 4 so it can detect interactable objects (item pickup, terminals, etc.).

### Human Enemy (HumanActor)

| Property | Layers |
|---|---|
| `collision_layer` | 2 (Ground) |
| `collision_mask` | 2 (Ground) |

- Same split as Player: movement on ground layer, and `HitCollision` as layer-1 hit-domain only (`Area2D`, mask 0). Human enemies do not mask the interaction layer.

### Non-Human Enemy (BiologicalActor)

| Property | Layers |
|---|---|
| `collision_layer` | 1 (Hit), 3 (Air) |
| `collision_mask` | 3 (Air) |

- **HitCollision** (CircleShape2D) — on layer 1, detectable by projectile queries.
- Non-human enemies exist in the air layer only; they do not collide with ground-only obstacles.

### Projectile

| Property | Layers |
|---|---|
| `collision_layer` | 3 (Air) |
| `collision_mask` | 1 (Hit), 3 (Air) |

- Projectiles travel through the air collision layer.
- Projectile hit-detection queries check layer 1 (Hit) to damage entities and layer 3 (Air) to collide with air-blocking tiles.

### Interactable Object (Item / Container / Terminal)

| Property | Layers |
|---|---|
| `collision_layer` | 4 (Interaction) |
| `collision_mask` | — |

- Exists only on the interaction layer.
- Does not actively detect anything; the player's mask on layer 4 detects it.
- Typically implemented as an `Area2D` with a trigger shape.

### Tile (Ground-only)

| Property | Layers |
|---|---|
| `collision_layer` | 2 (Ground) |
| `collision_mask` | — |

- Blocks human actors that move on the ground layer.
- Does not block airborne entities or projectiles.

### Tile (Air-only)

| Property | Layers |
|---|---|
| `collision_layer` | 3 (Air) |
| `collision_mask` | — |

- Blocks non-human enemies and projectiles in the air layer.
- Does not block ground-level human actors.

### Tile (Ground + Air)

| Property | Layers |
|---|---|
| `collision_layer` | 2 (Ground), 3 (Air) |
| `collision_mask` | — |

- Blocks both ground-level human actors and airborne entities / projectiles.

## Design Rationale

1. **Layer 1 (Hit Collision)** is shared by all entities so projectile hit-detection has a single mask bit to query regardless of entity type.
2. **Layer 2 (Ground Collision)** separates ground-level movement from airborne movement. Only human actors and ground-blocking tiles participate.
3. **Layer 3 (Air Collision)** covers airborne movement. Non-human enemies, projectiles, and air-blocking tiles participate. This allows non-human enemies to fly over ground-only obstacles while still being stopped by structures marked as air-blocking.
4. **Layer 4 (Interaction)** is dedicated to interactive gameplay objects such as loot drops, containers, and trader terminals. Only the player masks this layer, keeping interaction detection isolated from combat and movement collision. Interactable objects use `Area2D` on layer 4 so the player can detect overlap without affecting physics movement.
5. Tiles can participate in ground collision, air collision, or both, providing level designers with fine-grained control over which objects can pass through which obstacles.
