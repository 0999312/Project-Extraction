## NonHumanEnemyBody  (e_non_human_enemy_body.gd)
##
## [CharacterBody2D] physics shell for non-human enemy entities.
##
## Non-human enemies do NOT use separate hand/weapon pivots. Instead, the
## entire body rotates to face the target, giving them an alien or creature-
## like "whole-body aiming" feel. The rotation angle is read from the ECS
## entity's [C_AimState] component, which AISystem writes each frame.
##
## [b]Bridge pattern:[/b]
## Gameplay state lives in the child [NonHumanEnemy] ECS entity.
##
##   Node (NonHumanEnemyBody CharacterBody2D)  ECS Entity (NonHumanEnemy child)
##   ────────────────────────────────────────  ─────────────────────────────────
##   move_and_slide()                          C_Health, C_StatusEffects
##   Full-body rotation toward target          C_Position (synced from Node)
##   CollisionShape2D hitbox                   C_Velocity, C_Faction
##   Sprite2D body visual (rotates with self)  C_AIState, C_AimState, C_CombatState
##
## [b]Scene structure (expected):[/b]
## [codeblock]
## ┌─ NonHumanEnemyBody  (CharacterBody2D root, this script)
## │   ├─ CollisionShape2D    ← circle / capsule hitbox
## │   └─ BodySprite          ← Sprite2D; rotates with the parent body
## [/codeblock]
##
## The [member NonHumanEnemy.variant] property on the ECS entity child
## selects the archetype (SWARMER, CHARGER, DRONE, BLOB).
class_name NonHumanEnemyBody
extends CharacterBody2D


#region Constants

## Minimum squared vector length before treating a direction as valid.
## Matches [constant HumanBase.AIM_EPSILON] for consistency.
const AIM_EPSILON: float = 0.0001

#endregion Constants


#region Exports

## Variant to assign to the [NonHumanEnemy] ECS entity at spawn time.
## Must match [enum NonHumanEnemy.EnemyVariant].
@export var variant: NonHumanEnemy.EnemyVariant = NonHumanEnemy.EnemyVariant.SWARMER

#endregion Exports


#region Private Variables

## Child [NonHumanEnemy] ECS entity holding all authoritative gameplay state.
## Registered with the GECS World during [method _ready].
var _ecs_entity: NonHumanEnemy = null

#endregion Private Variables


#region Godot Lifecycle

func _ready() -> void:
	_setup_ecs_entity()


func _physics_process(_delta: float) -> void:
	_update_body_rotation()
	_apply_ecs_movement()

#endregion Godot Lifecycle


#region ECS Bridge Setup

## Creates and registers the child [NonHumanEnemy] ECS entity, applying the
## [member variant] selected in the Inspector. Called once from [method _ready].
func _setup_ecs_entity() -> void:
	_ecs_entity = NonHumanEnemy.new()
	_ecs_entity.variant = variant
	_ecs_entity.name = "NonHumanEnemyECSState"
	add_child(_ecs_entity)

	# Sync starting position into the ECS component.
	var pos_comp: C_Position = _ecs_entity.get_component(C_Position)
	if pos_comp:
		pos_comp.world_position = global_position

	# Register with the active GECS World.
	if ECS.world:
		ECS.world.add_entity(_ecs_entity)

#endregion ECS Bridge Setup


#region Body Rotation (Aim)

## Rotates the entire body ([code]self.rotation[/code]) to face the direction
## stored in [C_AimState.aim_direction].
##
## AISystem writes [C_AimState.aim_direction] toward the target entity
## whenever the enemy is in CHASE or ATTACK state, and toward the patrol
## direction or last-known-position vector otherwise.
func _update_body_rotation() -> void:
	if _ecs_entity == null:
		return
	var aim: C_AimState = _ecs_entity.get_component(C_AimState)
	if aim != null and aim.aim_direction.length_squared() > AIM_EPSILON:
		rotation = aim.aim_direction.angle()

#endregion Body Rotation


#region Physics Movement

## Reads [C_Velocity] from the ECS entity and drives [method CharacterBody2D.move_and_slide].
## Syncs the resulting position back into [C_Position].
func _apply_ecs_movement() -> void:
	if _ecs_entity == null:
		return
	var vel_comp: C_Velocity = _ecs_entity.get_component(C_Velocity)
	if vel_comp:
		velocity = vel_comp.velocity
	move_and_slide()
	# Write the updated physics position back to the ECS component.
	var pos_comp: C_Position = _ecs_entity.get_component(C_Position)
	if pos_comp:
		pos_comp.world_position = global_position

#endregion Physics Movement


#region Public API

## Returns the child [NonHumanEnemy] ECS entity holding gameplay state.
func get_ecs_entity() -> NonHumanEnemy:
	return _ecs_entity


## Returns [code]true[/code] if the enemy's HP > 0.
func is_alive() -> bool:
	if _ecs_entity == null:
		return false
	return _ecs_entity.is_alive()

#endregion Public API
