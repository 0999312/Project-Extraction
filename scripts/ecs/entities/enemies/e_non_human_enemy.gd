## NonHumanEnemy  (e_non_human_enemy.gd)
##
## ECS-first entity representing a non-human enemy with distinct locomotion
## and attack patterns (GDD §4.5, §6.2, Tech Stack §5.2).
##
## [b]GECS Best Practice — ECS-first + Composition:[/b]
## All AI, combat, movement and damage logic lives in shared Systems.
## Variant-specific behaviour is expressed through data in [Component]s,
## not through subclasses. The [member variant] export selects a preset
## [Component] configuration; the archetype registry can further override it.
##
## Built-in variants (GDD §4.5):
##   • SWARMER  — fast, fragile; rush melee in groups.
##   • CHARGER  — slow, tanky; telegraphs a straight-line charge.
##   • DRONE    — airborne; keeps range; projectile attacks.
##   • BLOB     — very slow; melee AOE; spawns Swarmers on death.
##
## [member archetype_id] can point to a [code]core:entity_archetype[/code]
## registry entry to override stats without subclassing.
class_name NonHumanEnemy
extends BaseEntity


#region Enums

## Built-in non-human enemy archetypes (GDD §4.5).
enum EnemyVariant {
	SWARMER,  ## Fast, low HP; rushes the player in groups.
	CHARGER,  ## High HP, slow; charges in a straight line.
	DRONE,    ## Airborne; keeps distance; uses projectile attacks.
	BLOB,     ## Very slow; melee AOE; splits into Swarmers on death.
}

#endregion Enums


#region Configuration

## Determines the default [Component] configuration via [method define_components].
## Can be changed in the editor or overridden at spawn time via the archetype registry.
@export var variant: EnemyVariant = EnemyVariant.SWARMER

## ResourceLocation string of the entity archetype registry entry.
## When non-empty the archetype system may override component values.
@export var archetype_id: String = ""

#endregion Configuration


#region GECS Lifecycle

## Add this entity to named groups for non-ECS scene-tree operations.
## [b]Note:[/b] ECS queries should use [code]q.with_all([C_AIState])[/code]
## (component-based), not [code]q.with_group("enemies")[/code] (slow).
func on_ready() -> void:
	add_to_group("enemies")
	add_to_group("non_human_enemies")


## Returns the [Component] array for this entity based on [member variant].
## Uses [code]_init()[/code] constructors for compact, readable configuration.
func define_components() -> Array:
	# Shared components are appended; variant-specific stats differ only in
	# the _init() arguments — no branching code after construction.
	match variant:
		EnemyVariant.SWARMER:
			return [
				C_Health.new(25.0),
				C_StatusEffects.new(),
				C_Position.new(),
				C_Velocity.new(280.0, 1200.0),
				C_CombatState.new(),
				C_Faction.new(C_Faction.FactionType.NON_HUMAN_ENEMY),
				C_AIState.new(350.0, 60.0),
				# NonHumanEnemyBody reads this to rotate the whole body toward the target.
				C_AimState.new(),
			]
		EnemyVariant.CHARGER:
			return [
				C_Health.new(200.0),
				C_StatusEffects.new(),
				C_Position.new(),
				C_Velocity.new(180.0, 400.0),
				C_CombatState.new(),
				C_Faction.new(C_Faction.FactionType.NON_HUMAN_ENEMY),
				C_AIState.new(250.0, 80.0),
				C_AimState.new(),
			]
		EnemyVariant.DRONE:
			return [
				C_Health.new(50.0),
				C_StatusEffects.new(),
				C_Position.new(),
				C_Velocity.new(240.0, 700.0),
				C_CombatState.new(),
				C_Faction.new(C_Faction.FactionType.NON_HUMAN_ENEMY),
				C_AIState.new(450.0, 300.0),
				C_AimState.new(),
			]
		EnemyVariant.BLOB:
			return [
				C_Health.new(150.0),
				C_StatusEffects.new(),
				C_Position.new(),
				C_Velocity.new(80.0, 200.0),
				C_CombatState.new(),
				C_Faction.new(C_Faction.FactionType.NON_HUMAN_ENEMY),
				C_AIState.new(200.0, 100.0),
				C_AimState.new(),
			]
	# Fallback — should not be reached with a valid variant value.
	return []

#endregion GECS Lifecycle


#region Death

## Called when this enemy's HP reaches zero.
## Sets AI state to DEAD, disables the entity, and requests a blob split
## for the BLOB variant.
func on_death(killer_id: String = "") -> void:
	var ai: C_AIState = get_component(C_AIState)
	if ai:
		ai.behavior = C_AIState.AIBehavior.DEAD

	if variant == EnemyVariant.BLOB:
		_request_blob_split()

	enabled = false


## Emits a blob-split request so a System can spawn child Swarmers.
## Actual spawn logic belongs in a System (e.g. via EventBus) to respect
## the ECS boundary; this stub is the entity-side trigger point.
## TODO: emit EventBus event [code]"game:event/blob_split"[/code] with position payload.
func _request_blob_split() -> void:
	pass

#endregion Death
