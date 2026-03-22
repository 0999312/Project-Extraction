## BaseEntity
##
## Base class for all gameplay ECS entities in Project Extraction
## (GDD §6, Tech Stack §5).
##
## Extends the GECS [Entity] class with helpers that are shared across
## enemies and the player's ECS state node.  Subclasses override
## [method define_components] to declare their default component set and
## [method on_death] to implement type-specific death behaviour.
##
## The Player does NOT extend this class directly — it uses a
## [CharacterBody2D] body node that owns a [BaseEntity] child as its
## ECS bridge (see [PlayerEntity]).
class_name BaseEntity
extends Entity


#region Damage & Death

## Apply [param amount] of damage to this entity.
## Reads [C_Health]; does nothing if the entity is already dead.
## Calls [method on_death] when HP reaches zero.
## [param source_id] is the entity ID string of the damage source
## (used for kill credit / quest tracking).
func apply_damage(amount: float, source_id: String = "") -> void:
	var health: C_Health = get_component(C_Health)
	if health == null or health.is_dead:
		return
	health.take_damage(amount)
	if health.is_dead:
		on_death(source_id)


## Called once when this entity's HP reaches zero.
## Override in subclasses to trigger death animations, drop loot,
## emit ECS events, etc.
## [param killer_id] is the entity ID string of the killing entity.
func on_death(killer_id: String = "") -> void:
	pass


## Returns true if this entity is currently alive (has [C_Health] and is not dead).
func is_alive() -> bool:
	var health: C_Health = get_component(C_Health)
	if health == null:
		return false
	return not health.is_dead

#endregion Damage & Death


#region Position Helpers

## Returns the entity's current world position.
## Reads [C_Position] when present; falls back to the node's
## global_position if it is a [Node2D].
func get_world_position() -> Vector2:
	var pos_comp: C_Position = get_component(C_Position)
	if pos_comp:
		return pos_comp.world_position
	if self is Node2D:
		return (self as Node2D).global_position
	return Vector2.ZERO

#endregion Position Helpers


#region Faction Helpers

## Returns true if this entity is hostile towards [param other_entity].
## Requires both entities to have a [C_Faction] component.
func is_hostile_to(other_entity: Entity) -> bool:
	var my_faction: C_Faction = get_component(C_Faction)
	var their_faction: C_Faction = other_entity.get_component(C_Faction)
	if my_faction == null or their_faction == null:
		return false
	return my_faction.is_hostile_to(their_faction)

#endregion Faction Helpers
