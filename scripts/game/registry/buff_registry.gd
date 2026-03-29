class_name BuffRegistry
extends RegistryBase

func _validate_entry(entry: Variant) -> bool:
	return entry is BuffDefinition and not (entry as BuffDefinition).id.is_empty()

func _get_expected_type_name() -> String:
	return "BuffDefinition"
