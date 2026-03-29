class_name EnergyState
extends Resource

@export var current_energy: float = 100.0
@export var max_energy: float = 100.0
@export var regen_rate: float = 2.0
@export var is_depleted: bool = false
@export var depletion_threshold: float = 10.0

func _init(max_e: float = 100.0, regen: float = 2.0) -> void:
	max_energy = max_e
	current_energy = max_e
	regen_rate = regen
