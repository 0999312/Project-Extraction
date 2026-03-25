# Entity Registry Guide

## 1. Purpose

The entity registry centralizes the mapping from entity IDs to scene resources. This provides a single runtime instantiation entry point for player and enemy actors, and avoids hardcoding scene paths in gameplay scripts.

## 2. Source Files

- `scripts/game/registry/entity_registry.gd`
- `scripts/game/registry/entity_catalog.gd`
- `scripts/game/gameplay/demo_game_runtime.gd`

## 3. Registry Type and Key Format

- Registry type name: `entity`
- Registry implementation: `EntityRegistry`
- Namespace: `game`
- ResourceLocation pattern: `game:entity/<name>`

Current entity keys:

- `game:entity/player`
- `game:entity/human_enemy`
- `game:entity/non_human_enemy`

## 4. Entry Schema

Each entry is a `Dictionary` with the following fields:

| Field | Type | Required | Meaning |
|---|---|---|---|
| `scene_path` | `String` | Yes | Scene path (`PackedScene`) for the runtime entity |
| `class_name` | `String` | No | Expected script class name (for documentation/debugging) |

Example:

```json
{
  "scene_path": "res://scenes/entities/player.tscn",
  "class_name": "Player"
}
```

## 5. Load Timing and Lifecycle

`EntityCatalog.ensure_registry()` is responsible for:

1. Creating and registering `EntityRegistry` if `entity` registry does not exist.
2. Registering entries declared in `ENTITY_DEFINITIONS` (skipping duplicates).

Call site:

- `DemoGameRuntime._ready()` calls it before spawning runtime actors.

The registry is managed by `RegistryManager` and can be reused across scenes during the app lifecycle.

## 6. Runtime Access Pattern

### 6.1 Lookup

- `EntityCatalog.get_entity_definition(entity_id: String) -> Dictionary`

### 6.2 Instantiation

- `EntityCatalog.instantiate_entity(entity_id: String, node_name: String = "") -> Node`

Behavior:

1. Resolve definition by `entity_id`.
2. Validate that `scene_path` exists.
3. Load and instantiate `PackedScene`.
4. Optionally override the instance node name.

## 7. Validation and Failure Behavior

Current `EntityRegistry._validate_entry(entry)` rules:

- Entry must be a `Dictionary`.
- `scene_path` must not be empty.

Failure behavior:

- Catalog-level APIs use `push_error(...)` and return `null` / empty dictionary.

## 8. Current Authoring Workflow

1. Add or update definitions in `EntityCatalog.ENTITY_DEFINITIONS`.
2. Consume runtime entities through `EntityCatalog.instantiate_entity(...)`.
3. Keep gameplay scenes (such as DemoGame) dependent on entity IDs rather than direct scene paths.

## 9. Save and Migration Notes

- Save systems should persist `entity_id` (ResourceLocation string) instead of direct scene paths.
- When removing an entity entry, provide fallback or migration mapping to keep old saves loadable.

## 10. Implementation Checklist

- [x] Registry type name confirmed (`entity`)
- [x] ResourceLocation naming rules confirmed
- [x] Entry schema documented
- [x] Validation rules documented
- [x] Runtime load timing documented
- [x] Runtime access APIs documented
