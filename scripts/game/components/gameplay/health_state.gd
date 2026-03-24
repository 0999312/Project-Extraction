class_name HealthState
extends Resource

@export var current_hp: float = 100.0
@export var max_hp: float = 100.0
@export var regen_rate: float = 0.0
@export var is_dead: bool = false

func _init(max_health: float = 100.0) -> void:
	max_hp = max_health
	current_hp = max_health
