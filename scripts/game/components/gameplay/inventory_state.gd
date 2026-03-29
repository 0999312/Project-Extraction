class_name InventoryState
extends Resource

@export var inventory: GridInventory = null
@export var equipped_armor_id: String = ""
@export var current_weight: float = 0.0
@export var max_weight: float = 50.0

func _init(max_w: float = 50.0) -> void:
	max_weight = max_w
	if inventory == null:
		inventory = GridInventory.new()
	recompute_weight()

func add_item(item_id: String, count: int = 1) -> void:
	if inventory == null:
		inventory = GridInventory.new()
	inventory.add_stack(ItemStack.new(item_id, count))
	recompute_weight()

func recompute_weight() -> void:
	if inventory == null:
		current_weight = 0.0
		return
	current_weight = inventory.compute_total_weight()
