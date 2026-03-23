class_name AudioRegistry
extends RegistryBase


func _validate_entry(entry: Variant) -> bool:
	return entry is Dictionary


func _get_expected_type_name() -> String:
	return "Dictionary"


func get_entries_for_phase(load_phase: String) -> Dictionary:
	var result: Dictionary = {}
	for key in _entries:
		var entry: Variant = _entries[key]
		if entry is Dictionary and entry.get("load_phase", "") == load_phase:
			result[key] = entry
	return result
