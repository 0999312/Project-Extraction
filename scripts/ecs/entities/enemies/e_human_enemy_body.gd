## HumanEnemyBody  (e_human_enemy_body.gd)
##
## [CharacterBody2D] physics shell for human enemy entities.
##
## Extends [HumanBase] to share the AimPivot rig (left/right hands + weapon
## 360° rotation). Overrides [method HumanBase._get_aim_direction] to read
## the aim direction from the ECS entity's [C_AimState] component — written
## each frame by AISystem from [C_AIState.last_known_target_position].
##
## [b]Bridge pattern:[/b]
## Gameplay state lives in the child [HumanEnemy] ECS entity. This body node
## is responsible only for physics movement and scene-tree presentation.
##
##   Node (HumanEnemyBody CharacterBody2D)   ECS Entity (HumanEnemy child)
##   ──────────────────────────────────      ─────────────────────────────
##   move_and_slide()                        C_Health, C_Stamina
##   AimPivot → hand / weapon rotation       C_StatusEffects, C_CombatState
##   CollisionShape2D hitbox                 C_Position (synced from Node)
##   Sprite2D body visual                    C_Velocity, C_Faction
##                                           C_AIState, C_AimState
##
## [b]Scene structure (expected):[/b]
## [codeblock]
## ┌─ HumanEnemyBody  (CharacterBody2D root, this script)
## │   ├─ CollisionShape2D      ← capsule hitbox
## │   ├─ BodySprite            ← Sprite2D body visual
## │   └─ AimPivot              ← Node2D; rotated by HumanBase
## │       ├─ RightHand         ← Node2D (16, 0)
## │       │   └─ HandSprite
## │       └─ LeftHand          ← Node2D (10, -6)
## │           └─ HandSprite
## [/codeblock]
class_name HumanEnemyBody
extends HumanBase


#region Private Variables

## Child [HumanEnemy] ECS entity holding all authoritative gameplay state.
## Registered with the GECS World during [method _ready].
var _ecs_entity: HumanEnemy = null

#endregion Private Variables


#region Godot Lifecycle

func _ready() -> void:
	_setup_ecs_entity()


## Updates aim pivot (via [HumanBase]), then applies ECS-driven movement.
func _physics_process(delta: float) -> void:
	super(delta)  # HumanBase: rotates _aim_pivot from _get_aim_direction()
	_apply_ecs_movement()

#endregion Godot Lifecycle


#region ECS Bridge Setup

## Creates and registers the child [HumanEnemy] ECS entity.
## Called once from [method _ready].
func _setup_ecs_entity() -> void:
	_ecs_entity = HumanEnemy.new()
	_ecs_entity.name = "HumanEnemyECSState"
	add_child(_ecs_entity)

	# Sync starting position into the ECS component.
	var pos_comp: C_Position = _ecs_entity.get_component(C_Position)
	if pos_comp:
		pos_comp.world_position = global_position

	# Register with the active GECS World.
	if ECS.world:
		ECS.world.add_entity(_ecs_entity)

#endregion ECS Bridge Setup


#region Aim Direction Override

## Returns the aim direction from the ECS entity's [C_AimState] component.
##
## AISystem writes [C_AimState.aim_direction] each frame based on
## [C_AIState.last_known_target_position] when a target is being chased or
## attacked, or along the current patrol / line-of-sight direction otherwise.
func _get_aim_direction() -> Vector2:
	if _ecs_entity == null:
		return Vector2.RIGHT
	var aim: C_AimState = _ecs_entity.get_component(C_AimState)
	if aim != null and aim.aim_direction.length_squared() > AIM_EPSILON:
		return aim.aim_direction
	return Vector2.RIGHT

#endregion Aim Direction Override


#region Physics Movement

## Reads [C_Velocity] from the ECS entity and drives [method CharacterBody2D.move_and_slide].
## Syncs the resulting position and facing angle back into [C_Position].
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
		pos_comp.facing_angle = _get_aim_direction().angle()

#endregion Physics Movement


#region Public API

## Returns the child [HumanEnemy] ECS entity holding gameplay state.
func get_ecs_entity() -> HumanEnemy:
	return _ecs_entity


## Returns [code]true[/code] if the enemy's HP > 0.
func is_alive() -> bool:
	if _ecs_entity == null:
		return false
	return _ecs_entity.is_alive()

#endregion Public API
