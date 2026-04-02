# Item Registry

## 1. Registry Overview

- **Registry name:** `item`
- **Business purpose:** Data-driven definitions for all runtime items (weapons, meds, ammo, materials) used by inventory and combat mapping.
- **Primary owner:** Gameplay Runtime
- **Related gameplay/content areas:** Inventory, loot, equipment, combat weapon resolution

## 2. ResourceLocation Rules

- **Entry namespace(s):** `game`
- **Entry ID naming convention:** `game:item/<category>/<name>` (e.g. `game:item/weapon/pistol`)
- **Tag naming convention:** Tags are managed via MSF TagRegistry under `game:tag/item/<tag_name>`. Tags are defined in standalone JSON files in `resources/registries/tags/items/`, loaded after items are registered. At runtime use `ItemCatalog.has_tag()` and `ItemCatalog.get_items_with_tag()`.
- **Cross-registry references:** Weapon registry entries reference item IDs (`WeaponDefinition.item_id`)

## 3. Load Timing and Lifecycle

- **When is the registry created?** On first `ItemCatalog.ensure_registry()` call.
- **When are entries registered?** During `ItemCatalog.ensure_registry()` – loaded from `.tres` resource files in `resources/registries/items/`.
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
| `icon_path` | `String` | No | `""` | Path to the item icon texture |
| `rarity` | `int` | No | `0` | Rarity level (0 = none, 1–5 = common → legendary) |

## 5. Validation Rules

- Entry must be `ItemDefinition` with non-empty `id`.
- Duplicate IDs are skipped (first registration wins).
- `size_w`, `size_h`, and `max_stack` should be positive.
- `rarity` must be in range 0–5.

## 6. Runtime Access Pattern

- **Lookup API:** `ItemCatalog.get_item_definition(item_id)`
- **Tag queries:** `ItemCatalog.has_tag(item_id, tag_name)`, `ItemCatalog.get_items_with_tag(tag_name)`
- **Typical caller(s):** `InventoryState`, `GridInventory`, weapon mapping
- **Caching strategy:** registry lookup via `RegistryManager`
- **Failure behavior:** `null` return + error log on invalid registry state

## 7. Current Built-in Entries

- `game:item/weapon/pistol` – loaded from `resources/registries/items/pistol.tres`
- `game:item/weapon/creature` – loaded from `resources/registries/items/creature_weapon.tres`
- `game:item/med/bandage` – loaded from `resources/registries/items/bandage.tres`
- `game:item/ammo/9x19` – loaded from `resources/registries/items/ammo_9x19.tres`

## 8. Source Files

- `scripts/game/components/gameplay/item_definition.gd`
- `scripts/game/registry/item_registry.gd`
- `scripts/game/registry/item_catalog.gd`
- `resources/registries/items/*.tres`
- `resources/registries/tags/items/*.json` – tag definition files (each JSON maps a tag to item entries)

