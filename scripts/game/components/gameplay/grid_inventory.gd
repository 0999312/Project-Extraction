class_name GridInventory
extends Resource

@export var width: int = 6
@export var height: int = 8
@export var stacks: Array[ItemStack] = []

func _init(w: int = 6, h: int = 8) -> void:
	width = maxi(1, w)
	height = maxi(1, h)

func add_stack(stack: ItemStack) -> void:
	if stack == null:
		return
	stacks.append(stack)

func remove_stack_at(index: int) -> void:
	if index < 0 or index >= stacks.size():
		return
	stacks.remove_at(index)

func compute_total_weight() -> float:
	var total := 0.0
	for stack in stacks:
		if stack == null:
			continue
		var def := ItemCatalog.get_item_definition(stack.item_id)
		if def == null:
			continue
		total += def.weight * float(maxi(1, stack.count))
	return total

