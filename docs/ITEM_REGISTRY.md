# Item Registry

## 1. Registry Overview

- **Registry name:** `item`
- **Business purpose:** Data-driven definitions for all runtime items (weapons, meds, ammo, materials) used by inventory and combat mapping.
- **Primary owner:** Gameplay Runtime
- **Related gameplay/content areas:** Inventory, loot, equipment, combat weapon resolution

## 2. ResourceLocation Rules

- **Entry namespace(s):** `game`
- **Entry ID naming convention:** `game:item/<category>/<name>` (e.g. `game:item/weapon/pistol`)
- **Required tag naming convention:** optional string tags in entry payload (`weapon`, `med`, `ammo`, `caliber_9x19`)
- **Cross-registry references:** Weapon registry entries map back to item IDs (`WeaponDefinition.item_id`)

## 3. Load Timing and Lifecycle

- **When is the registry created?** On first `ItemCatalog.ensure_registry()` call.
- **When are entries registered?** During `ItemCatalog.ensure_registry()`.
- **Can entries be extended at runtime?** Yes.
- **Should the registry persist across scenes?** Yes (global `RegistryManager`).

## 4. Entry Schema

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | `String` (RL) | Yes | — | Item RL key |
| `display_name` | `String` | Yes | `""` | Display name |
| `category` | `String` | Yes | `""` | Item category |
| `size_w` | `int` | No | `1` | Grid width |
| `size_h` | `int` | No | `1` | Grid height |
| `weight` | `float` | No | `0.0` | Unit weight |
| `max_stack` | `int` | No | `1` | Max stack count |
| `tags` | `Array[String]` | No | `[]` | Category/behavior tags |

## 5. Validation Rules

- Entry must be `ItemDefinition` with non-empty `id`.
- Duplicate IDs are skipped (first registration wins).
- `size_w`, `size_h`, and `max_stack` should be positive.

## 6. Runtime Access Pattern

- **Lookup API:** `ItemCatalog.get_item_definition(item_id)`
- **Typical caller(s):** `InventoryState`, `GridInventory`, weapon mapping
- **Caching strategy:** registry lookup via `RegistryManager`
- **Failure behavior:** `null` return + error log on invalid registry state

## 7. Current Built-in Entries

- `game:item/weapon/pistol`
- `game:item/weapon/creature`
- `game:item/med/bandage`
- `game:item/ammo/9x19`

## 8. Source Files

- `scripts/game/components/gameplay/item_definition.gd`
- `scripts/game/registry/item_registry.gd`
- `scripts/game/registry/item_catalog.gd`

