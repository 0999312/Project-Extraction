# Collision Removal Notice (Entity Layer)

## Scope

This change removes entity-side collision configuration and collision shape nodes from current gameplay entities so collision implementation can be completed manually by editors/designers.

Affected files:

- `scenes/entities/player.tscn`
- `scenes/entities/human_enemy.tscn`
- `scenes/entities/non_human_enemy.tscn`
- `scripts/game/entities/gameplay/biological_actor.gd`

## Removed Content

### 1. Scene-level collision configuration removed

From entity root nodes (`CharacterBody2D`):

- `collision_layer`
- `collision_mask`

From entity scenes:

- `CollisionShape2D` nodes such as `GroundCollision` and `HitCollision`
- Shape sub-resources used only by removed collision nodes (`CapsuleShape2D`, `CircleShape2D`)

### 2. Runtime collision disable logic removed

From `BiologicalActor.on_death(...)`:

- Removed `CollisionShape2D` lookup and `shape.disabled = true` branch.

## Editor Action Required (Manual Re-implementation)

Editors must manually re-apply collision behavior in scenes as needed:

1. Add required `CollisionShape2D` nodes back to each entity scene.
2. Reconfigure `collision_layer` / `collision_mask` on entity root nodes.
3. Ensure death-state behavior is handled consistently if collision disabling is desired.
4. Verify projectile hit filtering and movement blocking after manual setup.

## Reminder

After manual collision restoration, update and keep these design docs consistent:

- `docs/COLLISION_LAYER_DESIGN.md`
- `docs/COLLISION_LAYER_DESIGN_ZH.md`
