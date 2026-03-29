class_name WeaponRegistry
extends RegistryBase

func _validate_entry(entry: Variant) -> bool:
	return entry is WeaponDefinition and not (entry as WeaponDefinition).id.is_empty()

func _get_expected_type_name() -> String:
	return "WeaponDefinition"

