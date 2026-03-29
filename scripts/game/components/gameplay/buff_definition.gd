class_name BuffDefinition
extends Resource

# Describes a reusable buff/debuff type registered in the buff registry.
# Each entry in the buff registry is an instance of this resource.

## Unique ResourceLocation ID, e.g. "game:buff/bleed_light"
@export var id: String = ""

## Human-readable display name (use an I18n key in production)
@export var display_name: String = ""

## Whether this buff stacks (multiple instances can be active simultaneously)
@export var stackable: bool = false

## Maximum stack count when stackable = true (0 = unlimited)
@export var max_stacks: int = 1

## Duration in seconds. 0.0 = permanent until explicitly removed.
@export var base_duration: float = 0.0

## Periodic damage applied per second (positive = damage, negative = healing)
@export var damage_per_second: float = 0.0

## Multiplier applied to the actor's move speed (1.0 = no change)
@export var move_speed_mult: float = 1.0

## Multiplier applied to the actor's aim sway (1.0 = no change)
@export var aim_sway_mult: float = 1.0

## Multiplier applied to the actor's interaction speed (1.0 = no change)
@export var interaction_speed_mult: float = 1.0

## Tags for categorisation / query, e.g. ["bleed", "debuff"]
@export var tags: Array[String] = []
