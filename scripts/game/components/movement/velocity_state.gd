class_name VelocityState
extends Resource

@export var velocity: Vector2 = Vector2.ZERO
@export var max_speed: float = 200.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0

func _init(max_spd: float = 200.0, accel: float = 800.0, frict: float = 600.0) -> void:
	max_speed = max_spd
	acceleration = accel
	friction = frict
