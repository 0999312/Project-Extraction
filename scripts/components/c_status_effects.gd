## C_StatusEffects
##
## ECS component tracking lightweight injury states for an entity (GDD §4.1).
## Bleed ticks deal damage over time (handled by a dedicated system).
## Pain and fracture apply gameplay penalties accessible via helper methods.
## Applied to: Player, Human Enemies, Non-Human Enemies.
class_name C_StatusEffects
extends Component

## Light bleeding: slow damage per second, stopped by a bandage item.
@export var bleed_light: bool = false
## Heavy bleeding: fast damage per second, requires a hemostat/tourniquet.
@export var bleed_heavy: bool = false
## Pain state: adds aim sway and slows interactions.
@export var pain: bool = false
## Fracture state (optional, unlocked after Milestone 1): reduces movement speed.
@export var fracture: bool = false

## Damage per second dealt by light bleed. Consumed by the BleedSystem.
@export var bleed_light_dps: float = 1.0
## Damage per second dealt by heavy bleed. Consumed by the BleedSystem.
@export var bleed_heavy_dps: float = 5.0

## Aim sway multiplier applied when [member pain] is true (>1 = worse accuracy).
@export var pain_aim_sway_mult: float = 1.5
## Interaction speed multiplier applied when [member pain] is true (<1 = slower).
@export var pain_interaction_speed_mult: float = 0.75
## Movement speed multiplier applied when [member fracture] is true (<1 = slower).
@export var fracture_move_speed_mult: float = 0.6


## Returns the combined movement speed multiplier from all active status effects.
func get_move_speed_multiplier() -> float:
	var mult := 1.0
	if fracture:
		mult *= fracture_move_speed_mult
	return mult


## Returns the aim sway multiplier (>1 means more sway/inaccuracy).
func get_aim_sway_multiplier() -> float:
	if pain:
		return pain_aim_sway_mult
	return 1.0


## Returns the interaction speed multiplier (<1 means slower looting/healing).
func get_interaction_speed_multiplier() -> float:
	if pain:
		return pain_interaction_speed_mult
	return 1.0


## True if any harmful status effect is currently active.
func has_any_status() -> bool:
	return bleed_light or bleed_heavy or pain or fracture
