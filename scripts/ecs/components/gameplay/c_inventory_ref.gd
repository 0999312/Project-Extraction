class_name C_InventoryRef
extends Resource

@export var inventory: Resource = null
@export var equipped_armor_id: String = ""
@export var current_weight: float = 0.0
@export var max_weight: float = 50.0

func _init(max_w: float = 50.0) -> void:
	max_weight = max_w
