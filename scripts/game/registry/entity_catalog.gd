class_name EntityCatalog
extends RefCounted

const REGISTRY_TYPE := "entity"
const ENTITIES_JSON_PATH := "res://resources/registries/entities/entities.json"
const PLAYER := "game:entity/player"
const HUMAN_ENEMY := "game:entity/human_enemy"
const NON_HUMAN_ENEMY := "game:entity/non_human_enemy"


static func ensure_registry() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, EntityRegistry.new())
	var registry := _get_entity_registry()
	if registry == null:
		push_error("[EntityCatalog] Unable to resolve entity registry.")
		return
	_load_entities_from_json(registry)


static func _load_entities_from_json(registry: EntityRegistry) -> void:
	if not FileAccess.file_exists(ENTITIES_JSON_PATH):
		push_warning("[EntityCatalog] Entity JSON not found: %s" % ENTITIES_JSON_PATH)
		return
	var file := FileAccess.open(ENTITIES_JSON_PATH, FileAccess.READ)
	if file == null:
		push_warning("[EntityCatalog] Failed to open entity JSON: %s" % ENTITIES_JSON_PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("[EntityCatalog] JSON parse error in %s: %s" % [ENTITIES_JSON_PATH, json.get_error_message()])
		return
	var data: Variant = json.data
	if not (data is Dictionary):
		push_error("[EntityCatalog] Entity JSON root must be a Dictionary.")
		return
	for entity_id in (data as Dictionary):
		var resource_location := ResourceLocation.from_string(entity_id)
		if resource_location == null or registry.has_entry(resource_location):
			continue
		var entry: Variant = (data as Dictionary)[entity_id]
		if entry is Dictionary:
			registry.register(resource_location, (entry as Dictionary).duplicate(true))


static func get_entity_definition(entity_id: String) -> Dictionary:
	ensure_registry()
	var resource_location := ResourceLocation.from_string(entity_id)
	if resource_location == null:
		return {}
	var registry := _get_entity_registry()
	if registry == null:
		return {}
	var entry : Dictionary = registry.get_entry(resource_location)
	return entry.duplicate(true) if entry is Dictionary else {}


static func instantiate_entity(entity_id: String, node_name: String = "") -> Node:
	var definition := get_entity_definition(entity_id)
	var scene_path := str(definition.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("[EntityCatalog] Missing scene for entity '%s': %s" % [entity_id, scene_path])
		return null
	var packed_scene := ResourceLoader.load(scene_path)
	if not (packed_scene is PackedScene):
		push_error("[EntityCatalog] Scene is not a PackedScene: %s" % scene_path)
		return null
	var instance : Node = packed_scene.instantiate()
	if instance != null and not node_name.is_empty():
		instance.name = node_name
	return instance


static func _get_entity_registry() -> EntityRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	if registry is EntityRegistry:
		return registry
	return null
