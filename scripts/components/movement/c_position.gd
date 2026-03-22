## C_Position
##
## [b]Pure-data[/b] ECS component holding authoritative world-space position and
## facing direction for an entity.
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## Position synchronisation is handled externally:
##   • For the Player: [Player] (CharacterBody2D) writes [member world_position]
##     after [method CharacterBody2D.move_and_slide] each physics frame.
##   • For pure-ECS enemies: MovementSystem writes [member world_position] directly.
##
## Applied to: Player ECS bridge, Human Enemies, Non-Human Enemies, Projectiles.
class_name C_Position
extends Component

## World-space position in pixels (Godot 2D coordinate space).
@export var world_position: Vector2 = Vector2.ZERO
## Facing direction as an angle in radians (0 = right, PI/2 = down).
@export var facing_angle: float = 0.0


## Convenience constructor.
## Usage: [code]C_Position.new(Vector2(100, 200), 0.0)[/code]
func _init(pos: Vector2 = Vector2.ZERO, angle: float = 0.0) -> void:
	world_position = pos
	facing_angle = angle
