class_name EquipmentRules
extends RefCounted

const WEAPON_ONLY_HOTBAR_SLOT_COUNT := 3


static func can_equip_item_to_slot(slot_key: String, item_id: String, equipment: EquipmentState = null) -> bool:
	if item_id.is_empty():
		return false
	if equipment != null and not equipment.get_equipped(slot_key).is_empty():
		return false
	var item_def := ItemCatalog.get_item_definition(item_id)
	match slot_key:
		"primary_weapon", "secondary_weapon", "melee_weapon":
			return ItemCatalog.has_tag(item_id, "weapon")
		"armor":
			return item_def != null and item_def.category == "armor"
		"headset":
			return item_def != null and item_def.category == "headset"
		"helmet":
			return item_def != null and item_def.category == "helmet"
		"tactical_vest":
			return item_def != null and item_def.category in ["vest", "tactical_vest"]
		"backpack":
			return item_def != null and item_def.category == "backpack"
		_:
			return false


static func can_assign_item_to_hotbar(slot_index: int, item_id: String) -> bool:
	if slot_index < 0 or item_id.is_empty():
		return false
	if slot_index >= WEAPON_ONLY_HOTBAR_SLOT_COUNT:
		return true
	return ItemCatalog.has_tag(item_id, "weapon")
