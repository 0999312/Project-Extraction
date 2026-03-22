## C_InventoryRef
##
## [b]Pure-data[/b] ECS component linking an entity to its inventory resource
## and tracking carried weight for encumbrance (GDD §4.1 & §4.4).
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## Encumbrance multiplier derivation belongs in MovementSystem:
## [codeblock]
## # In MovementSystem:
## var ratio    = inv.current_weight / inv.max_weight
## var spd_mult = clampf(1.0 - ratio * 0.5, 0.3, 1.0)
## [/codeblock]
##
## Applied to: Player ECS bridge, Human Enemies (optional).
class_name C_InventoryRef
extends Component

## The GridInventory resource holding the entity's carried items.
## Null until initialised by InventorySystem.
@export var inventory: Resource = null

## ResourceLocation string of the currently equipped armour piece.
@export var equipped_armor_id: String = ""

## Current total carry weight in kilograms.
## Updated by InventorySystem whenever items are added or removed.
@export var current_weight: float = 0.0
## Maximum carry weight before encumbrance penalties apply.
@export var max_weight: float = 50.0


## Convenience constructor.
## [param max_w] Maximum carry weight in kilograms.
## Usage: [code]C_InventoryRef.new(60.0)[/code]
func _init(max_w: float = 50.0) -> void:
	max_weight = max_w
