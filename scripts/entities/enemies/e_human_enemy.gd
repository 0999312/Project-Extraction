## HumanEnemy  (e_human_enemy.gd)
##
## ECS-first entity representing a human enemy: an abstract "sphere person"
## armed with a ranged weapon (GDD §4.5, §6.2, Tech Stack §5.2).
##
## [b]GECS Best Practice — ECS-first:[/b]
## Human enemies are pure [Entity] nodes. All AI, combat and status logic
## lives in Systems that query for the required [Component]s:
##   • AISystem        — reads/writes [C_AIState]
##   • CombatSystem    — reads/writes [C_CombatState]
##   • DamageSystem    — modifies [C_Health.current_hp]
##   • BleedSystem     — applies [C_StatusEffects] DPS
##   • MovementSystem  — writes [C_Velocity.velocity], advances [C_Position]
##
## Navigation requests are batched through a service node; no per-enemy
## NavigationAgent2D is needed at this stage.
##
## A lightweight Node "view" (sprite + hit-flash) is optional and can be
## attached as a sibling; it is activated/deactivated per chunk by the
## ChunkActivationSystem.
##
## [member archetype_id] is a ResourceLocation string pointing to a
## [code]core:entity_archetype[/code] registry entry that can override the
## default component values set in [method define_components].
class_name HumanEnemy
extends BaseEntity


#region Configuration

## ResourceLocation string of the entity archetype registry entry used to
## override default stats (e.g. [code]"game:entity/human_guard"[/code]).
## When empty the default values defined below are used.
@export var archetype_id: String = ""

#endregion Configuration


#region GECS Lifecycle

## Add this entity to named groups for non-ECS scene-tree operations.
## [b]Note:[/b] ECS queries should use [code]q.with_all([C_AIState])[/code]
## (component-based), not [code]q.with_group("enemies")[/code] (slow).
func on_ready() -> void:
	add_to_group("enemies")
	add_to_group("human_enemies")


## Declares the default [Component] set using [code]_init()[/code] constructors
## for compact, readable configuration (GECS Best Practice).
## Stats can be overridden at spawn time via the archetype registry.
func define_components() -> Array:
	return [
		C_Health.new(80.0),
		C_Stamina.new(80.0, 5.0),
		C_StatusEffects.new(),
		C_Position.new(),
		C_Velocity.new(160.0, 600.0, 500.0),
		C_CombatState.new(),
		# Human enemies carry a ranged weapon; CombatSystem fills in the weapon ID.
		C_Faction.new(C_Faction.FactionType.HUMAN_ENEMY),
		C_AIState.new(280.0, 200.0),
	]

#endregion GECS Lifecycle


#region Death

## Called when this enemy's HP reaches zero.
## Transitions AI to DEAD and disables the entity so it no longer matches
## ECS queries. Extend to emit loot-drop events via EventBus.
func on_death(killer_id: String = "") -> void:
	var ai: C_AIState = get_component(C_AIState)
	if ai:
		ai.behavior = C_AIState.AIBehavior.DEAD
	# Disable via GECS property — entity leaves all archetype queries.
	enabled = false

#endregion Death
