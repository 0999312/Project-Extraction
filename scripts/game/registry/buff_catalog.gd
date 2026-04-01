class_name BuffCatalog
extends RefCounted

const REGISTRY_TYPE := "buff"
const TAG_REGISTRY_TYPE := "buff_tags"
const BUFFS_RESOURCE_DIR := "res://resources/registries/buffs"

# ── Built-in Buff IDs ──────────────────────────────────────────────────────────
const BLEED_LIGHT  := "game:buff/bleed_light"
const BLEED_HEAVY  := "game:buff/bleed_heavy"
const FRACTURE     := "game:buff/fracture"

# ── Registry helpers ──────────────────────────────────────────────────────────
static func ensure_registry() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, BuffRegistry.new())
	if not RegistryManager.has_registry(TAG_REGISTRY_TYPE):
		RegistryManager.register_registry(TAG_REGISTRY_TYPE, TagRegistry.new())
	var registry := _get_buff_registry()
	if registry == null:
		LocalizedText.error("logs.buff_catalog.registry_unresolved")
		return
	_load_buffs_from_resources(registry)

static func _load_buffs_from_resources(registry: BuffRegistry) -> void:
	var dir := DirAccess.open(BUFFS_RESOURCE_DIR)
	if dir == null:
		LocalizedText.warn("logs.buff_catalog.buffs_dir_missing", [BUFFS_RESOURCE_DIR])
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := "%s/%s" % [BUFFS_RESOURCE_DIR, file_name]
			var res := ResourceLoader.load(path)
			if res is BuffDefinition:
				var buff_def: BuffDefinition = res
				var rl := ResourceLocation.from_string(buff_def.id)
				if rl != null and not registry.has_entry(rl):
					registry.register(rl, buff_def)
					_register_tags_for_buff(buff_def)
		file_name = dir.get_next()
	dir.list_dir_end()

static func _register_tags_for_buff(buff_def: BuffDefinition) -> void:
	var tag_registry := _get_tag_registry()
	if tag_registry == null:
		return
	var buff_rl := ResourceLocation.from_string(buff_def.id)
	if buff_rl == null:
		return
	var registry_type_rl := ResourceLocation.new("core", REGISTRY_TYPE)
	for tag_name in buff_def.tags:
		var tag_rl := ResourceLocation.new("game", "tag/buff/%s" % tag_name)
		if not tag_registry.has_entry(tag_rl):
			tag_registry.register_tag(tag_rl, registry_type_rl)
		tag_registry.add_to_tag(tag_rl, buff_rl)

static func get_definition(buff_id: String) -> BuffDefinition:
	ensure_registry()
	var rl := ResourceLocation.from_string(buff_id)
	if rl == null:
		return null
	var registry := _get_buff_registry()
	if registry == null:
		return null
	var entry : BuffDefinition = registry.get_entry(rl)
	return entry if entry is BuffDefinition else null

static func has_tag(buff_id: String, tag_name: String) -> bool:
	var tag_registry := _get_tag_registry()
	if tag_registry == null:
		return false
	var tag_rl := ResourceLocation.new("game", "tag/buff/%s" % tag_name)
	var buff_rl := ResourceLocation.from_string(buff_id)
	if buff_rl == null:
		return false
	return tag_registry.has_entry_in_tag(tag_rl, buff_rl)

static func _get_buff_registry() -> BuffRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	return registry if registry is BuffRegistry else null

static func _get_tag_registry() -> TagRegistry:
	if not RegistryManager.has_registry(TAG_REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(TAG_REGISTRY_TYPE)
	return registry if registry is TagRegistry else null
