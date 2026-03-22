## BaseItem
##
## Base data resource for all items in Project Extraction (GDD §5.2).
##
## Items are pure data — no Nodes.  At runtime they are referenced by
## [code]ItemStack[/code] objects inside [code]GridInventory[/code]
## resources.  When an item is dropped into the world a separate
## "world pickup" ECS entity is spawned using [member world_drop_scene].
##
## All item IDs follow the ResourceLocation convention (GDD §2):
## e.g. [code]"game:item_weapon"[/code], [code]"game:item_med"[/code].
##
## Subtype differentiation (SMG vs rifle, bandage vs painkiller) is
## handled entirely through the MSF TagRegistry, not through subclasses.
class_name BaseItem
extends Resource

#region Identity

## ResourceLocation string uniquely identifying this item definition.
## Example: [code]"game:item_weapon"[/code], [code]"game:item_intel"[/code].
@export var item_id: String = ""

## I18n key used to look up the localised display name via I18nManager.
@export var display_name_key: String = ""

## Optional icon shown in inventory UI and pickup prompts.
@export var icon: Texture2D = null

#endregion Identity


#region Inventory Properties

## Grid width of this item in the player's inventory (GDD §4.4).
@export var size_w: int = 1
## Grid height of this item in the player's inventory (GDD §4.4).
@export var size_h: int = 1

## Item weight in kilograms; contributes to encumbrance (GDD §4.1).
@export var weight: float = 0.1

## Maximum number of identical items that can occupy a single stack.
## Set to 1 for weapons, armour and unique items.
@export var max_stack: int = 1

#endregion Inventory Properties


#region World Presence

## Optional PackedScene used when this item is dropped into the world.
## The spawned scene is expected to contain an ECS entity with a
## [code]C_ItemStack[/code] component referencing this item's ID.
@export var world_drop_scene: PackedScene = null

#endregion World Presence


#region Interaction

## ResourceLocation string for the use-action to invoke when the player
## activates this item (e.g. [code]"game:use/med_apply"[/code]).
## Empty string means the item has no direct use action.
@export var use_action: String = ""

## Category-specific extra fields stored as a freeform dictionary.
## Examples: ammo stats, durability, magazine capacity, craft recipe ID.
@export var data: Dictionary = {}

#endregion Interaction


#region Helpers

## Returns the localised display name.
## Full I18n resolution is delegated to I18nManager; this method returns
## the raw key as a fallback when the manager is unavailable.
func get_display_name() -> String:
	return display_name_key


## Returns true if [param other] is the same item type and stacking is
## permitted (max_stack > 1).
func can_stack_with(other: BaseItem) -> bool:
	if other == null:
		return false
	return item_id == other.item_id and max_stack > 1


## Returns the total grid cell count this item occupies.
func get_grid_area() -> int:
	return size_w * size_h

#endregion Helpers
