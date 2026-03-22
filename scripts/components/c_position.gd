## C_Position
##
## ECS component that holds the authoritative world-space position and
## facing direction for an entity.
##
## For the Player (hybrid entity), the CharacterBody2D node writes its
## global_position here each physics frame so ECS systems always have
## an up-to-date position without accessing the scene tree directly.
## For pure ECS enemies this is the canonical position used by AI and
## combat systems.
class_name C_Position
extends Component

## World-space position in pixels (Godot 2D coordinate space).
@export var world_position: Vector2 = Vector2.ZERO
## Facing direction expressed as an angle in radians (0 = right).
@export var facing_angle: float = 0.0


## Convenience helper: returns a unit vector in the facing direction.
func get_facing_vector() -> Vector2:
	return Vector2.RIGHT.rotated(facing_angle)
