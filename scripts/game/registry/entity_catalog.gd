class_name EntityCatalog
extends RefCounted

const REGISTRY_TYPE := "entity"
const PLAYER := "game:entity/player"
const HUMAN_ENEMY := "game:entity/human_enemy"
const NON_HUMAN_ENEMY := "game:entity/non_human_enemy"

const ENTITY_DEFINITIONS := {
	PLAYER: {
		"scene_path": "res://scenes/entities/player.tscn",
		"class_name": "Player",
	},
	HUMAN_ENEMY: {
		"scene_path": "res://scenes/entities/human_enemy.tscn",
		"class_name": "HumanEnemy",
	},
	NON_HUMAN_ENEMY: {
		"scene_path": "res://scenes/entities/non_human_enemy.tscn",
		"class_name": "NonHumanEnemy",
	},
}


static func ensure_registry() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, EntityRegistry.new())
	var registry := _get_entity_registry()
	if registry == null:
		push_error("[EntityCatalog] Unable to resolve entity registry.")
		return
	for entity_id in ENTITY_DEFINITIONS:
		var resource_location := ResourceLocation.from_string(entity_id)
		if resource_location == null or registry.has_entry(resource_location):
			continue
		registry.register(resource_location, ENTITY_DEFINITIONS[entity_id].duplicate(true))


static func get_entity_definition(entity_id: String) -> Dictionary:
	ensure_registry()
	var resource_location := ResourceLocation.from_string(entity_id)
	if resource_location == null:
		return {}
	var registry := _get_entity_registry()
	if registry == null:
		return {}
	var entry := registry.get_entry(resource_location)
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
	var instance := packed_scene.instantiate()
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
