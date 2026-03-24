class_name C_Stamina
extends Resource

@export var max_stamina: float = 100.0
@export var current_stamina: float = 100.0
@export var regen_rate: float = 10.0
@export var exhaustion_threshold: float = 10.0
@export var is_exhausted: bool = false

func _init(max_stam: float = 100.0, regen: float = 10.0) -> void:
	max_stamina = max_stam
	current_stamina = max_stam
	regen_rate = regen
