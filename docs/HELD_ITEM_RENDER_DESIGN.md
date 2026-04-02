# Held Item Render Design

## 1. Scope

- Defines how human actors resolve the sprite shown in `AimPivot/Item/ItemPivot/ItemSprite`.
- Keeps render data separate from item and weapon registries through an ID mapping layer.
- Applies to player and human enemies; non-human enemies continue to use their own scene visuals.

## 2. Render Config Resource

- **Resource type:** `HeldItemRenderConfig`
- **Resource directory:** `res://resources/registries/held_item_render_configs/`
- **Current fields:**
  - `id` — render config RL
  - `sprite_path` — sprite texture path
  - `sprite_offset` — local offset on `ItemSprite`
  - `sprite_scale` — local scale on `ItemSprite`
  - `sprite_rotation_deg` — local rotation on `ItemSprite`

## 3. Mapping Table

- **Chosen implementation:** JSON
- **Mapping file:** `res://resources/registries/held_item_render_configs/held_item_render_mappings.json`
- **Key format:** registry key / `ResourceLocation` string
- **Supported layers:**
  - `weapon_render_configs`: `Weapon RL -> Render Config RL`
  - `item_render_configs`: `Item RL -> Render Config RL`
- **Default fallback:** `default_render_config_id`

The mapping table format remains an implementation choice between JSON and Dictionary Resource at design level. This implementation uses JSON and keeps RL-string keys.

## 4. Resolution Priority

1. Resolve by weapon RL.
2. If not found, resolve by item RL.
3. If still not found, use the default render config.
4. If the resolved sprite texture is unavailable, fall back to the default render config sprite.

## 5. Runtime Responsibility Split

- `HeldItemRenderCatalog` owns render-config loading and mapping resolution.
- `HumanActor` applies the resolved render config to the held-item sprite.
- `DemoGameRuntime` is responsible for short-circuiting fire requests when no usable weapon is selected.
- `CombatFireRuntime` does **not** own the no-weapon short-circuit logic and only processes already-filtered fire requests.

## 6. Missing Resource Rule

- “Material missing” and “texture missing” are treated as one issue in this flow:
  - **Sprite missing texture**
- When a held-item render config references a missing sprite, runtime and validation fall back to the default render config.

## 7. Source Files

- `scripts/game/components/rendering/held_item_render_config.gd`
- `scripts/game/registry/held_item_render_catalog.gd`
- `resources/registries/held_item_render_configs/*.tres`
- `resources/registries/held_item_render_configs/held_item_render_mappings.json`
- `scripts/game/entities/gameplay/human_actor.gd`
- `scripts/game/gameplay/demo_game_runtime.gd`
