class_name EntityRegistry
extends RegistryBase


func _validate_entry(entry: Variant) -> bool:
	return entry is Dictionary and not str((entry as Dictionary).get("scene_path", "")).is_empty()


func _get_expected_type_name() -> String:
	return "Dictionary with scene_path"
