## C_Velocity
##
## [b]Pure-data[/b] ECS component storing movement velocity and locomotion
## parameters for an entity.
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## MovementSystem writes [member velocity] each frame after applying input,
## encumbrance and status-effect multipliers. The result is then either applied
## to the CharacterBody2D (Player) or used to advance [C_Position] directly
## (pure-ECS enemies).
##
## Applied to: Player ECS bridge, Human Enemies, Non-Human Enemies.
class_name C_Velocity
extends Component

## Current velocity vector in pixels per second. Written by MovementSystem.
@export var velocity: Vector2 = Vector2.ZERO
## Maximum movement speed in pixels per second (base value, before modifiers).
@export var max_speed: float = 200.0
## Acceleration applied when a direction input is present (pixels per second²).
@export var acceleration: float = 800.0
## Friction deceleration applied when no direction input is given (pixels per second²).
@export var friction: float = 600.0


## Convenience constructor.
## Usage: [code]C_Velocity.new(160.0, 600.0, 500.0)[/code]
func _init(max_spd: float = 200.0, accel: float = 800.0, frict: float = 600.0) -> void:
	max_speed = max_spd
	acceleration = accel
	friction = frict
