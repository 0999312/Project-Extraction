# Collision Layer Design

## 1. Goal

Unify runtime collision semantics with the following constraints:

1. All entities have a hit collision layer.
2. Humans (player + human enemies) have a ground collision layer.
3. Non-human enemies use an air collision layer while airborne.
4. Tiles can define ground collision and air collision separately (and both can coexist in one level).
5. Bullets are defined as air-collision projectiles and use air-collision rules for hit filtering.

## 2. Layer Mapping

Implementation file: `scripts/game/collision/collision_layers.gd`

| Bit Index (1-based) | Constant | Meaning |
|---|---|---|
| 1 | `ENTITY_HIT` | Entity hit layer |
| 2 | `ENTITY_GROUND` | Entity ground layer |
| 3 | `ENTITY_AIR` | Entity air layer |
| 4 | `TILE_GROUND` | Tile ground layer |
| 5 | `TILE_AIR` | Tile air layer |
| 6 | `PROJECTILE_AIR` | Projectile (air) layer |

## 3. Entity Configuration

### 3.1 Player / Human Enemy

- Scenes:
  - `scenes/entities/player.tscn`
  - `scenes/entities/human_enemy.tscn`
- Root `CharacterBody2D`:
  - `collision_layer = ENTITY_HIT | ENTITY_GROUND`
  - `collision_mask = TILE_GROUND | ENTITY_GROUND | ENTITY_AIR`

Notes: humans interact with ground tiles and do not participate in air-tile collision.

### 3.2 Non-Human Enemy

- Scene: `scenes/entities/non_human_enemy.tscn`
- Root `CharacterBody2D`:
  - `collision_layer = ENTITY_HIT | ENTITY_AIR`
  - `collision_mask = TILE_AIR | ENTITY_GROUND | ENTITY_AIR`

Notes: non-human enemies are treated as air entities while still interacting with other entity layers.

## 4. Tile Layer Configuration

- Scene: `scenes/game_scene/pe_scene/DemoGame.tscn`
- `ground` (`TileMapLayer`):
  - `collision_enabled = true`
  - `collision_layer = TILE_GROUND`
- `TileMapLayer` (`TileMapLayer`):
  - `collision_enabled = true`
  - `collision_layer = TILE_AIR`

Notes: ground and air tiles are split into separate layers so both can exist in the same map.

## 5. Bullet (Air Collision) Configuration

- Data: `scripts/game/components/combat/projectile_data.gd`
  - `collision_layer = PROJECTILE_AIR`
  - `collision_mask = ENTITY_HIT | TILE_AIR`

Current projectile hit logic is handled by lightweight runtime checks in `ProjectileMotionRuntime` instead of direct Godot physics body callbacks. These layer definitions keep semantics consistent and allow future migration to physics or hybrid queries.

## 6. Constraints and Extension Guidelines

1. New human entities should default to `ENTITY_HIT | ENTITY_GROUND`.
2. New flying enemies should default to `ENTITY_HIT | ENTITY_AIR`.
3. Tiles that block both ground and air can be authored in both `TileMapLayer`s, or extended later to support multi-collision in one layer.
4. If bullets should be blocked by ground geometry (for example, low-altitude projectiles), add `TILE_GROUND` to projectile mask.
