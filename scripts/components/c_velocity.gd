## C_Velocity
##
## ECS component storing movement velocity and locomotion parameters for
## an entity. Movement systems write the target velocity each frame;
## the result is applied to the physics body (Player) or used to move
## pure ECS entities via a transform system.
##
## Encumbrance and status-effect multipliers are applied externally by the
## movement system before writing to this component.
class_name C_Velocity
extends Component

## Current velocity vector in pixels per second.
@export var velocity: Vector2 = Vector2.ZERO
## Maximum movement speed in pixels per second (base, before modifiers).
@export var max_speed: float = 200.0
## Acceleration applied when moving (pixels per second squared).
@export var acceleration: float = 800.0
## Friction deceleration applied when no input is given (pixels per second squared).
@export var friction: float = 600.0
