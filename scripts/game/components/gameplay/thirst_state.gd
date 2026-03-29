class_name ThirstState
extends Resource

# Represents the player's hydration level.
# current_thirst decreases over time; reaching 0 triggers dehydration penalties.
@export var current_thirst: float = 100.0
@export var max_thirst: float = 100.0
@export var drain_rate: float = 1.0
@export var is_dehydrated: bool = false
@export var dehydration_threshold: float = 10.0

func _init(max_t: float = 100.0, drain: float = 1.0) -> void:
	max_thirst = max_t
	current_thirst = max_t
	drain_rate = drain
