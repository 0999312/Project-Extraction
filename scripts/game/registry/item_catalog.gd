class_name ItemCatalog
extends RefCounted

const REGISTRY_TYPE := "item"
const TAG_REGISTRY_TYPE := "item_tags"
const ITEMS_RESOURCE_DIR := "res://resources/registries/items"
const ITEM_TAGS_DIR := "res://resources/registries/tags/items"

const ITEM_WEAPON_PISTOL := "game:item/weapon/pistol"
const ITEM_WEAPON_CREATURE := "game:item/weapon/creature"
const ITEM_MED_BANDAGE := "game:item/med/bandage"
const ITEM_AMMO_9MM := "game:item/ammo/9x19"

static func ensure_registry() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, ItemRegistry.new())
	if not RegistryManager.has_registry(TAG_REGISTRY_TYPE):
		RegistryManager.register_registry(TAG_REGISTRY_TYPE, TagRegistry.new())
	var registry := _get_registry()
	if registry == null:
		push_error("[ItemCatalog] Unable to resolve item registry.")
		return
	_load_items_from_resources(registry)
	_load_tags_from_json()

static func _load_items_from_resources(registry: ItemRegistry) -> void:
	var dir := DirAccess.open(ITEMS_RESOURCE_DIR)
	if dir == null:
		push_warning("[ItemCatalog] Item resource directory not found: %s" % ITEMS_RESOURCE_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := "%s/%s" % [ITEMS_RESOURCE_DIR, file_name]
			var res := ResourceLoader.load(path)
			if res is ItemDefinition:
				var item_def: ItemDefinition = res
				var rl := ResourceLocation.from_string(item_def.id)
				if rl != null and not registry.has_entry(rl):
					registry.register(rl, item_def)
		file_name = dir.get_next()
	dir.list_dir_end()

static func _load_tags_from_json() -> void:
	var tag_registry := _get_tag_registry()
	if tag_registry == null:
		return
	var registry_type_rl := ResourceLocation.new("core", REGISTRY_TYPE)
	var dir := DirAccess.open(ITEM_TAGS_DIR)
	if dir == null:
		push_warning("[ItemCatalog] Item tags directory not found: %s" % ITEM_TAGS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var tag_name := file_name.get_basename()
			var tag_rl := ResourceLocation.new("game", "tag/item/%s" % tag_name)
			var path := "%s/%s" % [ITEM_TAGS_DIR, file_name]
			_load_single_tag(tag_registry, registry_type_rl, tag_rl, path)
		file_name = dir.get_next()
	dir.list_dir_end()

static func _load_single_tag(tag_registry: TagRegistry, registry_type_rl: ResourceLocation, tag_rl: ResourceLocation, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[ItemCatalog] Failed to open tag file: %s" % path)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("[ItemCatalog] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return
	var data: Variant = json.data
	if not (data is Dictionary):
		push_error("[ItemCatalog] Tag file root must be a Dictionary: %s" % path)
		return
	var values: Variant = (data as Dictionary).get("values", [])
	if not (values is Array):
		push_error("[ItemCatalog] Tag 'values' must be an Array: %s" % path)
		return
	if not tag_registry.has_entry(tag_rl):
		tag_registry.register_tag(tag_rl, registry_type_rl)
	for entry in (values as Array):
		var entry_rl := ResourceLocation.from_string(str(entry))
		if entry_rl != null:
			tag_registry.add_to_tag(tag_rl, entry_rl)

static func get_item_definition(item_id: String) -> ItemDefinition:
	ensure_registry()
	var rl := ResourceLocation.from_string(item_id)
	if rl == null:
		return null
	var registry := _get_registry()
	if registry == null:
		return null
	var entry : ItemDefinition = registry.get_entry(rl)
	return entry if entry is ItemDefinition else null

static func has_tag(item_id: String, tag_name: String) -> bool:
	var tag_registry := _get_tag_registry()
	if tag_registry == null:
		return false
	var tag_rl := ResourceLocation.new("game", "tag/item/%s" % tag_name)
	var item_rl := ResourceLocation.from_string(item_id)
	if item_rl == null:
		return false
	return tag_registry.has_entry_in_tag(tag_rl, item_rl)

static func get_items_with_tag(tag_name: String) -> Array[ResourceLocation]:
	var tag_registry := _get_tag_registry()
	if tag_registry == null:
		return []
	var tag_rl := ResourceLocation.new("game", "tag/item/%s" % tag_name)
	return tag_registry.get_all_entries_of_tag(tag_rl)

static func _get_registry() -> ItemRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	return registry if registry is ItemRegistry else null

static func _get_tag_registry() -> TagRegistry:
	if not RegistryManager.has_registry(TAG_REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(TAG_REGISTRY_TYPE)
	return registry if registry is TagRegistry else null
