# Buff Registry Design Document

**Date:** 2026-03-29  
**Status:** Active  

---

## 1. Registry Overview

- **Registry name:** `buff`
- **Business purpose:** Centralised definition and lookup of all temporary or persistent status modifiers (buffs and debuffs) that can be applied to any biological actor. Replaces hardcoded boolean flags in `StatusEffectsState` with a data-driven, extensible system.
- **Primary owner:** Gameplay Systems / Player & Enemy Combat
- **Related gameplay/content areas:** Player state, enemy state, medical items, combat damage, HUD display

---

## 2. ResourceLocation Rules

- **Entry namespace(s):** `game`
- **Entry ID naming convention:** `game:buff/<buff_name>` (e.g. `game:buff/bleed_light`)
- **Required tag naming convention:** Tags in `BuffDefinition.tags` are plain strings (e.g. `"bleed"`, `"debuff"`). At registration, they are added to MSF TagRegistry under `game:tag/buff/<tag_name>`. Query at runtime via `BuffCatalog.has_tag()`.
- **Cross-registry references:** Medical item effects (via `game:item_med` tag rules) reference buff IDs to apply/remove buffs. No other registry cross-references required at this stage.

---

## 3. Load Timing and Lifecycle

- **When is the registry created?** On first call to `BuffCatalog.ensure_registry()`, typically when the gameplay scene loads or a buff is first applied.
- **When are entries registered?** Built-in entries are loaded from `.tres` resource files in `resources/registries/buffs/`. Custom entries can be added via `BuffRegistry.register(rl, definition)`.
- **Can entries be extended at runtime?** Yes — mods or expansion content may register additional `BuffDefinition` entries before gameplay starts.
- **Should the registry persist across scenes?** Yes — lives in the global `RegistryManager` autoload.

---

## 4. Entry Schema

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | `String` (ResourceLocation) | Yes | — | Unique buff identifier, e.g. `game:buff/bleed_light` |
| `display_name` | `String` | Yes | `""` | Human-readable name shown in HUD/logs |
| `stackable` | `bool` | No | `false` | Whether multiple instances accumulate |
| `max_stacks` | `int` | No | `1` | Maximum stack count when `stackable = true`; `0` = unlimited |
| `base_duration` | `float` | No | `0.0` | Duration in seconds; `0.0` = permanent until removed |
| `damage_per_second` | `float` | No | `0.0` | Periodic damage (positive) or healing (negative) per second per stack |
| `move_speed_mult` | `float` | No | `1.0` | Multiplier applied to the actor's movement speed |
| `aim_sway_mult` | `float` | No | `1.0` | Multiplier applied to the actor's aim sway |
| `interaction_speed_mult` | `float` | No | `1.0` | Multiplier applied to interaction speed |
| `tags` | `Array[String]` | No | `[]` | Categorisation tags, e.g. `["bleed", "debuff"]` |

### 4.1 Runtime Structures

**`BuffInstance`** (one active application of a `BuffDefinition`):

| Field | Type | Description |
|---|---|---|
| `definition` | `BuffDefinition` | Reference to the registry entry |
| `remaining_duration` | `float` | Countdown in seconds; `-1.0` = permanent |
| `stack_count` | `int` | Current stack depth |

**`BuffComponent`** (node attached to an actor):
- Owns a `Dictionary` of active `BuffInstance` objects keyed by buff ID.
- Calls `tick(delta)` every physics frame to drain durations, apply periodic damage, and expire finished buffs.
- Rebuilds `StatusEffectsState` multipliers whenever the active set changes.

---

## 5. Validation Rules

- `id` must be a valid `ResourceLocation` string (`namespace:path`).
- Duplicate IDs are silently skipped (first-registered wins).
- `damage_per_second` has no enforced range — negative values represent healing.
- `max_stacks` must be `>= 0`; `0` means unlimited.
- `base_duration` must be `>= 0.0`.
- Multiplier fields (`move_speed_mult`, `aim_sway_mult`, `interaction_speed_mult`) must be `> 0.0`; values `<= 0.0` are clamped to a minimum of `0.01` at runtime.

---

## 6. Runtime Access Pattern

- **Lookup API:** `BuffCatalog.get_definition(buff_id: String) -> BuffDefinition`
- **Apply API:** `buff_component.apply_buff(buff_id: String)`
- **Remove API:** `buff_component.remove_buff(buff_id: String)`
- **Query API:** `buff_component.has_buff(buff_id: String) -> bool`
- **Typical caller(s):** Medical item use handler, damage resolution, combat hit effects, HUD display.
- **Caching strategy:** `RegistryManager` caches entries after first lookup.
- **Failure behavior:** `push_error(...)` + return `null` on unknown buff ID.

---

## 7. Authoring Workflow

1. Decide on a buff ID following `game:buff/<name>` convention.
2. Create a `BuffDefinition` `.tres` resource file in `resources/registries/buffs/`.
3. The entry is auto-registered when `BuffCatalog.ensure_registry()` runs.
4. Apply from gameplay code via `actor.get_node("BuffComponent").apply_buff(BuffCatalog.BLEED_LIGHT)`.
5. Treat and remove via the same API: `actor.get_node("BuffComponent").remove_buff(...)`.

---

## 8. Save / Migration Notes

- **Are entry IDs saved directly?** Yes — active buff IDs and remaining durations should be serialised in the player save state when the save system is implemented.
- **Compatibility strategy for removed entries:** Unknown buff IDs are skipped on load with a warning. No refund mechanism needed.
- **Version field needed?** No — not required at this stage.

---

## 9. Built-in Entries

| ID | Display Name | DPS | move_speed_mult | aim_sway_mult | Duration | Resource File |
|---|---|---|---|---|---|---|
| `game:buff/bleed_light` | Light Bleed | 1.0 | 1.0 | 1.0 | Permanent | `resources/registries/buffs/bleed_light.tres` |
| `game:buff/bleed_heavy` | Heavy Bleed | 5.0 | 1.0 | 1.0 | Permanent | `resources/registries/buffs/bleed_heavy.tres` |
| `game:buff/fracture` | Fracture | 0.0 | 0.6 | 1.0 | Permanent | `resources/registries/buffs/fracture.tres` |

---

## 10. Example Entry (GDScript factory)

```gdscript
static func _make_bleed_light() -> BuffDefinition:
    var d := BuffDefinition.new()
    d.id = "game:buff/bleed_light"
    d.display_name = "Light Bleed"
    d.stackable = false
    d.base_duration = 0.0       # permanent
    d.damage_per_second = 1.0
    d.tags = ["bleed", "debuff"]
    return d
```

---

## 11. Source Files

- `scripts/game/components/gameplay/buff_definition.gd` — Data resource describing a buff type.
- `scripts/game/components/gameplay/buff_instance.gd` — Runtime instance of an active buff.
- `scripts/game/components/gameplay/buff_component.gd` — Node component managing active buffs on an actor.
- `scripts/game/registry/buff_registry.gd` — Registry implementation (`extends RegistryBase`).
- `scripts/game/registry/buff_catalog.gd` — Static catalog that loads definitions from resource files.
- `resources/registries/buffs/*.tres` — Buff definition resource files.

---

## 12. Open Questions

- Should buff stacking use additive or multiplicative aggregation for multipliers?
- Should HUD display active buff icons, or just the net effect on stat bars?
- Is a cooldown system needed (debuff immunity after cure)?

---

## 13. Implementation Checklist

- [x] Registry type name confirmed (`buff`)
- [x] ResourceLocation naming rules confirmed (`game:buff/<name>`)
- [x] Entry schema (`BuffDefinition`) finalized
- [x] Validation rules documented
- [x] Runtime load timing documented
- [x] Runtime component (`BuffComponent`) implemented
- [x] Save/migration behavior documented (deferred)
- [x] Built-in entries reviewed (`bleed_light`, `bleed_heavy`, `fracture`)
