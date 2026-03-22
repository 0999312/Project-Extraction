## HumanEnemyEntity
##
## ECS-first entity representing a human enemy: an abstract "sphere person"
## armed with a ranged weapon (GDD §4.5, §6.2, Tech Stack §5.2).
##
## Human enemies use the GECS Entity architecture (ECS-first):
##   • AI behaviour driven by AISystem reading [C_AIState].
##   • Ranged combat driven by CombatSystem reading [C_CombatState].
##   • Health / status managed by the shared damage / bleed systems.
##   • Navigation requests are batched through a navigation service; no
##     per-enemy NavigationAgent2D node is required at this stage.
##
## A lightweight Node "view" (sprite + hit-flash) is optional and can be
## attached as a sibling in the scene; it is activated / deactivated per
## chunk by the ChunkActivationSystem.
##
## [member archetype_id] is a ResourceLocation string pointing to a registry
## entry in [code]core:entity_archetype[/code] that can override the default
## component values set in [method define_components].
class_name HumanEnemyEntity
extends BaseEntity

#region Configuration

## ResourceLocation string of the entity archetype registry entry used to
## override default stats (e.g. [code]"game:entity/human_guard"[/code]).
## When empty the default component values defined below are used.
@export var archetype_id: String = ""

#endregion Configuration


#region GECS Component Declaration

## Declares the default ECS components for all human enemies.
## Stats can be overridden at spawn time via the archetype registry.
func define_components() -> Array:
	var health := C_Health.new()
	health.max_hp = 80.0
	health.current_hp = 80.0

	var stamina := C_Stamina.new()
	stamina.max_stamina = 80.0
	stamina.current_stamina = 80.0
	stamina.regen_rate = 5.0

	var vel := C_Velocity.new()
	vel.max_speed = 160.0
	vel.acceleration = 600.0
	vel.friction = 500.0

	var faction := C_Faction.new()
	faction.faction = C_Faction.FactionType.HUMAN_ENEMY

	var ai := C_AIState.new()
	ai.detection_radius = 280.0
	ai.attack_radius = 200.0

	# Human enemies carry a ranged weapon by default.
	# The CombatSystem and archetype data will fill in the actual weapon ID.
	var combat := C_CombatState.new()

	return [
		health,
		stamina,
		C_StatusEffects.new(),
		C_Position.new(),
		vel,
		combat,
		faction,
		ai,
	]

#endregion GECS Component Declaration


#region Lifecycle Overrides

## Called when this enemy's HP reaches zero.
## Transitions AI to DEAD, disables the entity so it no longer appears
## in ECS queries, and can be extended to emit a loot-drop event.
func on_death(killer_id: String = "") -> void:
	var ai: C_AIState = get_component(C_AIState)
	if ai:
		ai.behavior = C_AIState.AIBehavior.DEAD

	# Disable so the AISystem and CombatSystem skip this entity.
	enabled = false

#endregion Lifecycle Overrides
