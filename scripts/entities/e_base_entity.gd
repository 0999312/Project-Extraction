## BaseEntity
##
## Thin base class for all gameplay ECS entities in Project Extraction
## (GDD §6, Tech Stack §5).
##
## [b]GECS Best Practice — Composition over Inheritance:[/b]
## Keep this class small. Prefer combining [Component]s rather than growing
## the inheritance hierarchy. All game logic belongs in dedicated [System]s;
## the helpers below are convenience bridges for ad-hoc code paths only.
##
## Subclasses override [method Entity.define_components] to declare their
## default [Component] set and [method on_death] for type-specific cleanup.
##
## The Player does NOT extend this class directly — it uses a [CharacterBody2D]
## body node that owns a [BaseEntity] child as its ECS bridge (see [Player]).
class_name BaseEntity
extends Entity


#region Damage & Death

## Apply [param amount] damage to this entity.
##
## Directly modifies [C_Health.current_hp] without delegating to the
## component. Calls [method on_death] once when HP reaches zero.
## [param source_id] is the attacker's [member Entity.id] string (for
## kill-credit and quest tracking).
##
## [b]Note:[/b] In the full ECS implementation, damage is handled entirely
## by a DamageSystem using [Relationship]s or EventBus events so that the
## system can batch-process all damage in one pass. This helper is provided
## until those systems are written.
func apply_damage(amount: float, source_id: String = "") -> void:
	var health: C_Health = get_component(C_Health)
	if health == null or health.is_dead:
		return
	# Directly modify component data — logic stays out of the component.
	health.current_hp = maxf(0.0, health.current_hp - amount)
	if health.current_hp <= 0.0:
		health.is_dead = true
		on_death(source_id)


## Called once when this entity's HP reaches zero.
## Override in subclasses to disable the entity, drop loot, or emit events.
## [param killer_id] is the [member Entity.id] string of the killing entity.
func on_death(killer_id: String = "") -> void:
	pass


## Returns [code]true[/code] if this entity has [C_Health] and is not yet dead.
func is_alive() -> bool:
	var health: C_Health = get_component(C_Health)
	return health != null and not health.is_dead

#endregion Damage & Death


#region Position Helpers

## Returns the entity's current world position.
## Reads [C_Position] when present; falls back to [member Node2D.global_position].
func get_world_position() -> Vector2:
	var pos_comp: C_Position = get_component(C_Position)
	if pos_comp:
		return pos_comp.world_position
	if self is Node2D:
		return (self as Node2D).global_position
	return Vector2.ZERO

#endregion Position Helpers


#region Faction Helpers

## Returns [code]true[/code] if this entity is hostile toward [param other_entity].
##
## Hostility table (GDD §4.5):
##   • PLAYER       → hostile to HUMAN_ENEMY and NON_HUMAN_ENEMY
##   • HUMAN_ENEMY  → hostile to PLAYER only
##   • NON_HUMAN    → hostile to PLAYER and HUMAN_ENEMY
##   • NEUTRAL      → never hostile
##
## [b]Note:[/b] Targeting logic in the full game belongs in AITargetingSystem.
## This helper is for ad-hoc checks outside a system loop.
func is_hostile_to(other_entity: Entity) -> bool:
	var my_faction: C_Faction = get_component(C_Faction)
	var their_faction: C_Faction = other_entity.get_component(C_Faction)
	if my_faction == null or their_faction == null:
		return false
	# Direct field comparison — no logic methods on the component.
	match my_faction.faction:
		C_Faction.FactionType.PLAYER:
			return their_faction.faction == C_Faction.FactionType.HUMAN_ENEMY \
				or their_faction.faction == C_Faction.FactionType.NON_HUMAN_ENEMY
		C_Faction.FactionType.HUMAN_ENEMY:
			return their_faction.faction == C_Faction.FactionType.PLAYER
		C_Faction.FactionType.NON_HUMAN_ENEMY:
			return their_faction.faction == C_Faction.FactionType.PLAYER \
				or their_faction.faction == C_Faction.FactionType.HUMAN_ENEMY
		_:
			return false

#endregion Faction Helpers
