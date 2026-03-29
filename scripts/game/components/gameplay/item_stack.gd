class_name ItemStack
extends Resource

@export var item_id: String = ""
@export var count: int = 1
@export var durability: float = 1.0
@export var custom_data: Dictionary = {}

func _init(id: String = "", initial_count: int = 1) -> void:
	item_id = id
	count = maxi(1, initial_count)
