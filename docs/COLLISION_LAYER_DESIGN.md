# Collision Layer Design

This document describes the collision layer assignment for all physics objects in Project Extraction.

## Layer Assignments

| Layer | Bit | Purpose |
|---|---|---|
| 1 | `0x01` | **Hit Collision** — Damage hit-box present on every entity (player, human enemy, non-human enemy). Used by projectile hit-detection queries. |
| 2 | `0x02` | **Ground Collision** — Ground-level movement collision for human actors (player and human enemies) and tiles that block ground-level movement. |
| 3 | `0x04` | **Air Collision** — Airborne / elevated collision for non-human enemies, projectiles, and tiles that block airborne movement. |

## Per-Object Collision Setup

### Player (HumanActor)

| Property | Layers |
|---|---|
| `collision_layer` | 1 (Hit), 2 (Ground) |
| `collision_mask` | 2 (Ground) |

- **HitCollision** (CircleShape2D) — on layer 1, detectable by projectile queries.
- **GroundCollision** (CapsuleShape2D) — on layer 2, collides with ground-blocking tiles.

### Human Enemy (HumanActor)

| Property | Layers |
|---|---|
| `collision_layer` | 1 (Hit), 2 (Ground) |
| `collision_mask` | 2 (Ground) |

- Same layout as Player: HitCollision on layer 1, GroundCollision on layer 2.

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
4. Tiles can participate in ground collision, air collision, or both, providing level designers with fine-grained control over which objects can pass through which obstacles.
