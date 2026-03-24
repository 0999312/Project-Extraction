class_name ProjectileRegistry
extends RegistryBase


func _validate_entry(entry: Variant) -> bool:
	if not (entry is Dictionary):
		return false
	var projectile_entry: Dictionary = entry
	return not str(projectile_entry.get("script_path", "")).is_empty()


func _get_expected_type_name() -> String:
	return "Dictionary with script_path"
