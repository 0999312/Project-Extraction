class_name AimState
extends Resource

@export var aim_direction: Vector2 = Vector2.RIGHT
@export var aim_target_id: String = ""
@export var precision_multiplier: float = 1.0

func _init(dir: Vector2 = Vector2.RIGHT) -> void:
	aim_direction = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
