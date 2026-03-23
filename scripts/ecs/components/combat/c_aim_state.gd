## C_AimState
##
## [b]Pure-data[/b] ECS component holding the current aim direction for an entity.
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## This component is written by:
##   • [Player] body      — from [method Node2D.get_global_mouse_position] each frame
##   • AISystem           — from target entity's world position stored in [C_AIState]
## And read by:
##   • [HumanBase]        — rotates the AimPivot rig (hands + held weapon)
##   • [NonHumanEnemyBody] — rotates the entire body toward the target
##   • CombatSystem       — spawn direction for projectiles
##
## Applied to: Player ECS bridge, Human Enemies, Non-Human Enemies.
class_name C_AimState
extends Component

## Normalised world-space direction this entity is currently aiming.
## [code]Vector2.RIGHT[/code] when no aim input or target is present.
@export var aim_direction: Vector2 = Vector2.RIGHT

## Entity ID string of the current aim target (AI enemies only).
## Written by AISystem when a valid attack target exists.
## Empty string = free-aim (patrol look-around, line-of-sight sweep, etc.).
@export var aim_target_id: String = ""

## Optional precision multiplier for this entity (1.0 = default spread).
@export var precision_multiplier: float = 1.0


## Convenience constructor.
## Usage: [code]C_AimState.new(Vector2.RIGHT)[/code]
func _init(dir: Vector2 = Vector2.RIGHT) -> void:
	# Use an epsilon threshold to avoid normalising a near-zero vector,
	# which would produce NaN or an invalid unit vector.
	aim_direction = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
