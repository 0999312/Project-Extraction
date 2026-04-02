# Project Manual Review Reference

> Minimal reference for manually reviewing the full project.

## 1. Review Order

1. Project configuration and plugin integration
2. Registry data and content definitions
3. Core gameplay state and runtime logic
4. Entities, scenes, and game flow
5. UI, input, and localization
6. Existing documentation consistency

## 2. Review Scope

| Step | Area | Review content | Key paths |
|---|---|---|---|
| 1 | Configuration | Confirm startup scene, autoloads, enabled plugins, input actions, and global theme are correct. | `project.godot`, `override.cfg`, `addons/` |
| 2 | Registry data | Check whether item, weapon, projectile, buff, entity, and tag definitions are complete and consistent with IDs and runtime usage. | `resources/registries/`, `scripts/game/registry/`, `addons/mc_game_framework/` |
| 3 | Gameplay systems | Review combat, movement, inventory, equipment, AI, and player-state logic for correctness, coupling, and missing edge cases. | `scripts/game/components/`, `scripts/game/systems/`, `scripts/game/projectiles/` |
| 4 | Runtime flow | Verify scene loading, player/enemy setup, level/state transitions, and runtime orchestration are aligned. | `scripts/game/gameplay/`, `scripts/game/entities/`, `scenes/game_scene/`, `prefabs/entity/` |
| 5 | UI / i18n | Review HUD, inventory, pause/menu flow, input mapping, and English/Chinese text consistency. | `scripts/game/ui/`, `scenes/`, `resources/i18n/` |
| 6 | Documentation | Check whether design and progress documents match the current implementation and bilingual files stay paired. | `docs/` |

## 3. Minimum Review Output

For each step, record only:

- **Status:** Pass / Issue / Needs follow-up
- **Main findings:** up to 3 items
- **Action:** fix now / defer / clarify requirement
