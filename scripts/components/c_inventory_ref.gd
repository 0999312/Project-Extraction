## C_InventoryRef
##
## ECS component that links an entity to its inventory data and tracks
## carried weight for encumbrance calculations (GDD §4.1 & §4.4).
##
## The actual GridInventory (grid placement data) and ItemStack list are
## pure Resource objects held by [member inventory]; this component is the
## ECS-side handle.  Weight is aggregated by the InventorySystem whenever
## items are added or removed.
class_name C_InventoryRef
extends Component

## The GridInventory resource holding the entity's carried items.
## Null until the inventory system initialises it.
@export var inventory: Resource = null

## ResourceLocation string of the currently equipped armour piece.
@export var equipped_armor_id: String = ""

## Current total carry weight in kilograms (updated by InventorySystem).
@export var current_weight: float = 0.0
## Maximum carry weight before heavy encumbrance penalties kick in.
@export var max_weight: float = 50.0


## Returns current encumbrance as a 0–1 ratio (>1 means over-encumbered).
func get_encumbrance_ratio() -> float:
	if max_weight <= 0.0:
		return 0.0
	return current_weight / max_weight


## Returns a movement speed multiplier based on encumbrance (GDD §4.1).
## At 0 % weight the multiplier is 1.0; at 100 % it drops to 0.5.
## Hard floor of 0.3 prevents entities from becoming completely immobile.
func get_speed_multiplier() -> float:
	var ratio := get_encumbrance_ratio()
	return clampf(1.0 - ratio * 0.5, 0.3, 1.0)


## Returns true if the entity is carrying more than its maximum weight.
func is_over_encumbered() -> bool:
	return current_weight > max_weight
