class_name ProjectileCatalog
extends RefCounted

const REGISTRY_TYPE := "projectile"
const BULLET := "game:projectile/bullet"
const CREATURE_BOLT := "game:projectile/creature_bolt"

const PROJECTILE_DEFINITIONS := {
	BULLET: {
		"script_path": "res://scripts/game/projectiles/projectile.gd",
		"speed": 850.0,
		"damage": 20.0,
		"penetration": 0.0,
		"lifetime": 2.0,
		"max_distance": 1400.0,
		"sprite_path": "res://assets/game/textures/projectiles/bullet.png",
	},
	CREATURE_BOLT: {
		"script_path": "res://scripts/game/projectiles/projectile.gd",
		"speed": 720.0,
		"damage": 12.0,
		"penetration": 0.0,
		"lifetime": 2.0,
		"max_distance": 900.0,
		"sprite_path": "res://assets/game/textures/projectiles/bullet.png",
	},
}


static func ensure_registry() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, ProjectileRegistry.new())
	var registry := _get_projectile_registry()
	if registry == null:
		push_error("[ProjectileCatalog] Unable to resolve projectile registry.")
		return
	for projectile_id in PROJECTILE_DEFINITIONS:
		var resource_location := ResourceLocation.from_string(projectile_id)
		if resource_location == null or registry.has_entry(resource_location):
			continue
		registry.register(resource_location, PROJECTILE_DEFINITIONS[projectile_id].duplicate(true))


static func get_projectile_definition(projectile_id: String) -> Dictionary:
	ensure_registry()
	var resource_location := ResourceLocation.from_string(projectile_id)
	if resource_location == null:
		return {}
	var registry := _get_projectile_registry()
	if registry == null:
		return {}
	var entry : Dictionary = registry.get_entry(resource_location)
	return entry.duplicate(true) if entry is Dictionary else {}


static func instantiate_projectile(projectile_id: String, overrides: Dictionary = {}) -> Projectile:
	var definition := get_projectile_definition(projectile_id)
	var script_path := str(definition.get("script_path", ""))
	if script_path.is_empty() or not ResourceLoader.exists(script_path):
		push_error("[ProjectileCatalog] Missing script for projectile '%s': %s" % [projectile_id, script_path])
		return null
	var script_resource := ResourceLoader.load(script_path)
	if not (script_resource is GDScript):
		push_error("[ProjectileCatalog] Projectile script is invalid: %s" % script_path)
		return null
	var projectile : Projectile = (script_resource as GDScript).new()
	if not (projectile is Projectile):
		push_error("[ProjectileCatalog] Projectile script did not instantiate a Projectile: %s" % script_path)
		return null
	var projectile_data := ProjectileData.new(
		float(definition.get("speed", 600.0)),
		float(definition.get("damage", 20.0)),
		float(definition.get("penetration", 0.0)),
		float(definition.get("lifetime", 2.0)),
		float(definition.get("max_distance", 1400.0))
	)
	projectile_data.configure_sprite(str(definition.get("sprite_path", ProjectileData.DEFAULT_SPRITE_PATH)))
	for key in overrides:
		match key:
			"owner_faction":
				projectile.owner_faction = overrides[key]
			"position":
				projectile.global_position = overrides[key]
			_:
				projectile_data.set(key, overrides[key])
	projectile.projectile_data = projectile_data
	return projectile


static func _get_projectile_registry() -> ProjectileRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	if registry is ProjectileRegistry:
		return registry
	return null
