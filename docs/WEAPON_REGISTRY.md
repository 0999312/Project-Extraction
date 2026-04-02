# Weapon Registry

## 1. Registry Overview

- **Registry name:** `weapon`
- **Business purpose:** Define weapon behavior profiles decoupled from actor scripts and mapped from equipped item IDs.
- **Primary owner:** Combat Runtime
- **Related gameplay/content areas:** Shooting, reload timing, spread/recoil, projectile selection

## 2. ResourceLocation Rules

- **Entry namespace(s):** `game`
- **Entry ID naming convention:** `game:weapon/<name>` (e.g. `game:weapon/pistol`)
- **Required tag naming convention:** none
- **Cross-registry references:** `item_id` references `core:item`; `projectile_definition_id` references projectile registry IDs; held-item render mappings may reference weapon RLs as keys

## 3. Load Timing and Lifecycle

- **When is the registry created?** On first `WeaponCatalog.ensure_registry()` call.
- **When are entries registered?** During `WeaponCatalog.ensure_registry()` – loaded from `.tres` resource files in `resources/registries/weapons/`.
- **Can entries be extended at runtime?** Yes.
- **Should the registry persist across scenes?** Yes (global `RegistryManager`).

## 4. Entry Schema

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | `String` (RL) | Yes | — | Weapon RL key |
| `display_name` | `String` | Yes | `""` | Display name |
| `item_id` | `String` (RL) | Yes | `""` | Back-reference to item entry |
| `projectile_definition_id` | `String` (RL) | Yes | `game:projectile/bullet` | Projectile type |
| `ammo_capacity` | `int` | Yes | `0` | Magazine size |
| `fire_interval` | `float` | Yes | `0.14` | Time between shots |
| `reload_duration_sec` | `float` | Yes | `1.5` | Reload duration |
| `hipfire_spread_deg` | `float` | No | `6.0` | Hip-fire spread |
| `ads_spread_deg` | `float` | No | `1.5` | ADS spread |
| `recoil_per_shot` | `float` | No | `0.6` | Recoil gain per shot |
| `recoil_recovery_per_sec` | `float` | No | `2.0` | Recoil recovery |
| `pellets_per_shot` | `int` | No | `1` | Shot pellet count |
| `icon_path` | `String` | No | `""` | Path to weapon icon texture |

## 5. Runtime Access Pattern

- `WeaponCatalog.get_weapon_for_item(item_id)` resolves equipped item to weapon profile.
- `WeaponCatalog.apply_to_combat_state(combat_state)` applies profile fields to combat runtime.
- `HeldItemRenderCatalog.get_render_config_for(weapon_id, item_id)` resolves held-item visuals with weapon-first priority.

## 6. Current Built-in Entries

- `game:weapon/pistol` – loaded from `resources/registries/weapons/pistol.tres`
- `game:weapon/creature_organ` – loaded from `resources/registries/weapons/creature_organ.tres`

## 7. Source Files

- `scripts/game/components/combat/weapon_definition.gd`
- `scripts/game/registry/weapon_registry.gd`
- `scripts/game/registry/weapon_catalog.gd`
- `scripts/game/registry/held_item_render_catalog.gd`
- `resources/registries/weapons/*.tres`
- `resources/registries/held_item_render_configs/held_item_render_mappings.json`
