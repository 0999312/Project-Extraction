class_name ItemRegistry
extends RegistryBase

func _validate_entry(entry: Variant) -> bool:
	return entry is ItemDefinition and not (entry as ItemDefinition).id.is_empty()

func _get_expected_type_name() -> String:
	return "ItemDefinition"
