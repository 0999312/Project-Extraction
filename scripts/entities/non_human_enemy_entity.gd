## NonHumanEnemyEntity
##
## ECS-first entity representing a non-human enemy with distinct locomotion
## and attack patterns (GDD §4.5, §6.2, Tech Stack §5.2).
##
## Four built-in variants cover the GDD's example non-human archetypes:
##   • SWARMER  — fast, fragile; rushes in groups; short melee range.
##   • CHARGER  — slow, tanky; telegraphs a straight-line charge attack.
##   • DRONE    — airborne; keeps at range; uses projectile attacks.
##   • BLOB     — very slow; melee AOE; splits into Swarmers on death.
##
## Like [HumanEnemyEntity], this is ECS-first:
##   • AI state machine lives in [C_AIState].
##   • Combat (ranged or melee) lives in [C_CombatState].
##   • Variant-specific stats are set in [method _configure_by_variant].
##
## [member archetype_id] can point to a [code]core:entity_archetype[/code]
## registry entry to override stats without subclassing.
class_name NonHumanEnemyEntity
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

## Determines default stats and AI parameters.  Can be changed in the
## editor or via the archetype registry at spawn time.
@export var variant: EnemyVariant = EnemyVariant.SWARMER

## ResourceLocation string of the entity archetype registry entry.
## When non-empty the archetype system may override component values
## set by [method _configure_by_variant].
@export var archetype_id: String = ""

#endregion Configuration


#region GECS Component Declaration

## Declares the default ECS components, then calls
## [method _configure_by_variant] to apply variant-specific stats.
func define_components() -> Array:
	var health := C_Health.new()
	var vel := C_Velocity.new()
	var ai := C_AIState.new()

	var faction := C_Faction.new()
	faction.faction = C_Faction.FactionType.NON_HUMAN_ENEMY

	_configure_by_variant(health, vel, ai)

	return [
		health,
		C_StatusEffects.new(),
		C_Position.new(),
		vel,
		C_CombatState.new(),
		faction,
		ai,
	]


## Applies variant-specific default stats to the provided components.
## Systems may further override these values via the archetype registry.
func _configure_by_variant(
	health: C_Health,
	vel: C_Velocity,
	ai: C_AIState
) -> void:
	match variant:
		EnemyVariant.SWARMER:
			health.max_hp = 25.0
			health.current_hp = 25.0
			vel.max_speed = 280.0
			vel.acceleration = 1200.0
			ai.detection_radius = 350.0
			ai.attack_radius = 60.0

		EnemyVariant.CHARGER:
			health.max_hp = 200.0
			health.current_hp = 200.0
			vel.max_speed = 180.0
			vel.acceleration = 400.0
			ai.detection_radius = 250.0
			ai.attack_radius = 80.0

		EnemyVariant.DRONE:
			health.max_hp = 50.0
			health.current_hp = 50.0
			vel.max_speed = 240.0
			vel.acceleration = 700.0
			ai.detection_radius = 450.0
			ai.attack_radius = 300.0

		EnemyVariant.BLOB:
			health.max_hp = 150.0
			health.current_hp = 150.0
			vel.max_speed = 80.0
			vel.acceleration = 200.0
			ai.detection_radius = 200.0
			ai.attack_radius = 100.0

#endregion GECS Component Declaration


#region Lifecycle Overrides

## Called when this enemy's HP reaches zero.
## Sets AI state to DEAD, disables the entity, and triggers the
## variant-specific death effect (e.g. Blob split).
func on_death(killer_id: String = "") -> void:
	var ai: C_AIState = get_component(C_AIState)
	if ai:
		ai.behavior = C_AIState.AIBehavior.DEAD

	if variant == EnemyVariant.BLOB:
		_request_blob_split()

	enabled = false


## Emits a blob-split request so a system can spawn child Swarmers.
## Kept as a stub here; the actual spawn logic belongs in a dedicated
## system (or EventBus event handler) to respect the ECS boundary.
func _request_blob_split() -> void:
	pass  # TODO: emit EventBus event e.g. "game:event/blob_split" with position payload.

#endregion Lifecycle Overrides
