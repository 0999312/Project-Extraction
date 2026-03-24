class_name C_Position
extends Resource

@export var world_position: Vector2 = Vector2.ZERO
@export var facing_angle: float = 0.0

func _init(pos: Vector2 = Vector2.ZERO, angle: float = 0.0) -> void:
	world_position = pos
	facing_angle = angle
