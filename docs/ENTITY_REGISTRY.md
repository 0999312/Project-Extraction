# Entity Registry

## 1. Registry Overview

- **Registry name:** `entity`
- **Business purpose:** Centralized definition and instantiation of all runtime actors (player, human enemies, non-human enemies) so gameplay code never hardcodes scene paths.
- **Primary owner:** Gameplay Runtime
- **Related gameplay/content areas:** Player spawning, enemy spawning, demo scene setup

## 2. ResourceLocation Rules

- **Entry namespace(s):** `game`
- **Entry ID naming convention:** `game:entity/<entity_name>` (e.g. `game:entity/player`)
- **Required tag naming convention:** None
- **Cross-registry references:** Entity combat state references projectile definition IDs from the **projectile** registry (e.g. `game:projectile/bullet`)

## 3. Load Timing and Lifecycle

- **When is the registry created?** At gameplay load time, when `EntityCatalog.ensure_registry()` is first called (typically from `DemoGameRuntime`).
- **When are entries registered?** During `EntityCatalog.ensure_registry()`, all entries in `ENTITY_DEFINITIONS` are registered if not already present.
- **Can entries be extended at runtime?** Yes — additional entries may be registered via `EntityRegistry.register(...)` after the initial batch.
- **Should the registry persist across scenes?** Yes — the registry lives in the global `RegistryManager` autoload and survives scene transitions.

## 4. Entry Schema

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `scene_path` | `String` | Yes | — | Full `res://` path to the entity's `.tscn` scene file. Must be a valid `PackedScene`. |
| `class_name` | `String` | No | `""` | Human-readable class name for debug/log output. Not used for instantiation. |

## 5. Validation Rules

- Entries must be a `Dictionary` with a non-empty `scene_path` field.
- `scene_path` must point to an existing `PackedScene` resource at instantiation time.
- Duplicate `ResourceLocation` IDs are silently skipped (first-registered wins).

## 6. Runtime Access Pattern

- **Lookup API:** `EntityCatalog.get_entity_definition(entity_id)` returns a copy of the definition dictionary.
- **Instantiation API:** `EntityCatalog.instantiate_entity(entity_id, node_name)` loads the packed scene and returns a new node instance.
- **Typical caller(s):** `DemoGameRuntime` (actor spawning), future level generation systems.
- **Caching strategy:** Scene resources are loaded via `ResourceLoader` which handles caching internally.
- **Failure behavior:** `push_error(...)` log message + return `null` on missing scene or invalid definition.

## 7. Authoring Workflow

1. Create the entity scene (`.tscn`) under `scenes/entities/` and attach the corresponding GDScript.
2. Add a new constant and definition entry in `EntityCatalog.ENTITY_DEFINITIONS`.
3. The entry is auto-registered when `EntityCatalog.ensure_registry()` runs.
4. Instantiate via `EntityCatalog.instantiate_entity(EntityCatalog.NEW_ENTITY_ID)`.

## 8. Save / Migration Notes

- **Are entry IDs saved directly?** Not currently — the save system is not yet implemented.
- **Compatibility strategy for removed entries:** Undefined until save system is designed.
- **Version field needed?** No — not needed at this stage.

## 9. Current Entries

| ID | Scene Path | Class |
|---|---|---|
| `game:entity/player` | `res://scenes/entities/player.tscn` | `Player` |
| `game:entity/human_enemy` | `res://scenes/entities/human_enemy.tscn` | `HumanEnemy` |
| `game:entity/non_human_enemy` | `res://scenes/entities/non_human_enemy.tscn` | `NonHumanEnemy` |

## 10. Example Entry

```json
{
  "scene_path": "res://scenes/entities/player.tscn",
  "class_name": "Player"
}
```

## 11. Source Files

- `scripts/game/registry/entity_registry.gd` — Registry implementation (extends `RegistryBase`).
- `scripts/game/registry/entity_catalog.gd` — Static catalog with definition constants and helper methods.

## 12. Implementation Checklist

- [x] Registry type name confirmed (`entity`)
- [x] ResourceLocation naming rules confirmed (`game:entity/<name>`)
- [x] Entry schema finalized
- [x] Validation rules documented
- [x] Runtime load timing documented
- [x] Save/migration behavior documented (deferred)
- [x] Example entry reviewed
