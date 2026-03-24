class_name C_AIState
extends Resource

enum AIBehavior {
	IDLE,
	PATROL,
	ALERT,
	CHASE,
	ATTACK,
	FLEE,
	DEAD,
}

@export var behavior: AIBehavior = AIBehavior.IDLE
@export var last_known_target_position: Vector2 = Vector2.ZERO
@export var detection_radius: float = 300.0
@export var attack_radius: float = 150.0
@export var patrol_point_index: int = 0
@export var state_timer: float = 0.0
@export var alert_level: float = 0.0
@export var path_points: Array[Vector2] = []
@export var path_index: int = 0

func _init(detect_radius: float = 300.0, atk_radius: float = 150.0) -> void:
	detection_radius = detect_radius
	attack_radius = atk_radius
