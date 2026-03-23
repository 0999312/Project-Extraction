class_name GuideInputRuntime
extends RefCounted

const REMAP_CONFIG_PATH := "user://pe_guide_remap.tres"

static var _context: PlayerInputContext
static var _remapper: GUIDERemapper
static var _remapping_config: GUIDERemappingConfig
static var _actions: Dictionary = {}


static func ensure_initialized() -> void:
	if _context != null:
		return
	_context = PlayerInputContext.new()
	_cache_actions()
	_remapping_config = _load_remapping_config()
	_remapper = GUIDERemapper.new()
	_remapper.initialize([_context], _remapping_config)
	apply_remapping_config(_remapping_config)


static func get_context() -> GUIDEMappingContext:
	ensure_initialized()
	return _context


static func get_action(name: StringName) -> GUIDEAction:
	ensure_initialized()
	return _actions.get(name)


static func get_actions() -> Dictionary:
	ensure_initialized()
	return _actions


static func get_remapper() -> GUIDERemapper:
	ensure_initialized()
	return _remapper


static func apply_remapping_config(config: GUIDERemappingConfig) -> void:
	_remapping_config = config if config != null else GUIDERemappingConfig.new()
	GUIDE.set_remapping_config(_remapping_config)
	_save_remapping_config(_remapping_config)


static func _cache_actions() -> void:
	_actions.clear()
	for mapping in _context.mappings:
		if mapping.action != null:
			_actions[mapping.action.name] = mapping.action


static func _load_remapping_config() -> GUIDERemappingConfig:
	if not ResourceLoader.exists(REMAP_CONFIG_PATH):
		return GUIDERemappingConfig.new()
	var loaded := ResourceLoader.load(REMAP_CONFIG_PATH)
	if loaded is GUIDERemappingConfig:
		return loaded
	return GUIDERemappingConfig.new()


static func _save_remapping_config(config: GUIDERemappingConfig) -> void:
	if config == null:
		return
	ResourceSaver.save(config, REMAP_CONFIG_PATH)
