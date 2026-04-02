class_name RegistryValidator
extends RefCounted


static func validate_all() -> bool:
	ItemCatalog.ensure_registry()
	WeaponCatalog.ensure_registry()
	EntityCatalog.ensure_registry()
	ProjectileCatalog.ensure_registry()
	HeldItemRenderCatalog.ensure_loaded()
	BuffCatalog.ensure_registry()

	var is_valid := true
	is_valid = _validate_items() and is_valid
	is_valid = _validate_weapons() and is_valid
	is_valid = _validate_entities() and is_valid
	is_valid = _validate_projectiles() and is_valid
	is_valid = _validate_held_item_render_configs() and is_valid
	is_valid = _validate_buffs() and is_valid
	return is_valid


static func _validate_items() -> bool:
	var registry := RegistryManager.get_registry(ItemCatalog.REGISTRY_TYPE) as ItemRegistry
	if registry == null:
		LocalizedText.error("logs.registry.validator.item_registry_missing")
		return false
	var is_valid := true
	for key in registry.get_all_keys():
		var rl := ResourceLocation.from_string(key)
		var item_def := registry.get_entry(rl) as ItemDefinition
		if item_def == null:
			LocalizedText.error("logs.registry.validator.item_entry_invalid", [key])
			is_valid = false
			continue
		if item_def.id.is_empty():
			LocalizedText.error("logs.registry.validator.item_id_missing", [key])
			is_valid = false
		if not item_def.icon_path.is_empty() and not _resource_exists(item_def.icon_path):
			LocalizedText.warn("logs.registry.validator.item_icon_missing", [item_def.id, item_def.icon_path])
	return is_valid


static func _validate_weapons() -> bool:
	var registry := RegistryManager.get_registry(WeaponCatalog.REGISTRY_TYPE) as WeaponRegistry
	if registry == null:
		LocalizedText.error("logs.registry.validator.weapon_registry_missing")
		return false
	var is_valid := true
	for key in registry.get_all_keys():
		var rl := ResourceLocation.from_string(key)
		var weapon_def := registry.get_entry(rl) as WeaponDefinition
		if weapon_def == null:
			LocalizedText.error("logs.registry.validator.weapon_entry_invalid", [key])
			is_valid = false
			continue
		if ItemCatalog.get_item_definition(weapon_def.item_id) == null:
			LocalizedText.error("logs.registry.validator.weapon_item_missing", [weapon_def.id, weapon_def.item_id])
			is_valid = false
		var projectile_def := ProjectileCatalog.get_projectile_definition(weapon_def.projectile_definition_id)
		if projectile_def.size() == 0:
			LocalizedText.error("logs.registry.validator.weapon_projectile_missing", [weapon_def.id, weapon_def.projectile_definition_id])
			is_valid = false
		if not weapon_def.icon_path.is_empty() and not _resource_exists(weapon_def.icon_path):
			LocalizedText.warn("logs.registry.validator.weapon_icon_missing", [weapon_def.id, weapon_def.icon_path])
	return is_valid


static func _validate_entities() -> bool:
	var registry := RegistryManager.get_registry(EntityCatalog.REGISTRY_TYPE) as EntityRegistry
	if registry == null:
		LocalizedText.error("logs.registry.validator.entity_registry_missing")
		return false
	var is_valid := true
	for key in registry.get_all_keys():
		var rl := ResourceLocation.from_string(key)
		var entry : Dictionary = registry.get_entry(rl)
		if not (entry is Dictionary):
			LocalizedText.error("logs.registry.validator.entity_entry_invalid", [key])
			is_valid = false
			continue
		var scene_path := str((entry as Dictionary).get("scene_path", ""))
		if scene_path.is_empty() or not _resource_exists(scene_path):
			LocalizedText.error("logs.registry.validator.entity_scene_missing", [key, scene_path])
			is_valid = false
			continue
		var scene_res := ResourceLoader.load(scene_path)
		if not (scene_res is PackedScene):
			LocalizedText.error("logs.registry.validator.entity_scene_invalid", [key, scene_path])
			is_valid = false
	return is_valid


static func _validate_projectiles() -> bool:
	var registry := RegistryManager.get_registry(ProjectileCatalog.REGISTRY_TYPE) as ProjectileRegistry
	if registry == null:
		LocalizedText.error("logs.registry.validator.projectile_registry_missing")
		return false
	var is_valid := true
	for key in registry.get_all_keys():
		var rl := ResourceLocation.from_string(key)
		var entry : Dictionary = registry.get_entry(rl)
		if not (entry is Dictionary):
			LocalizedText.error("logs.registry.validator.projectile_entry_invalid", [key])
			is_valid = false
			continue
		var projectile_entry := entry as Dictionary
		var script_path := str(projectile_entry.get("script_path", ""))
		if script_path.is_empty() or not _resource_exists(script_path):
			LocalizedText.error("logs.registry.validator.projectile_script_missing", [key, script_path])
			is_valid = false
		elif not (ResourceLoader.load(script_path) is GDScript):
			LocalizedText.error("logs.registry.validator.projectile_script_invalid", [key, script_path])
			is_valid = false
		var sprite_path := str(projectile_entry.get("sprite_path", ""))
		if not sprite_path.is_empty() and not _resource_exists(sprite_path):
			LocalizedText.warn("logs.registry.validator.projectile_sprite_missing", [key, sprite_path])
	return is_valid


static func _validate_held_item_render_configs() -> bool:
	var is_valid := true
	var default_config_id := HeldItemRenderCatalog.get_default_render_config_id()
	if HeldItemRenderCatalog.get_default_render_config() == null:
		LocalizedText.error("logs.registry.validator.held_item_render_default_missing", [default_config_id])
		is_valid = false
	for config_id in HeldItemRenderCatalog.get_registered_config_ids():
		var render_config := HeldItemRenderCatalog.get_render_config_by_id(config_id)
		if render_config == null:
			continue
		if not _resource_exists(render_config.sprite_path):
			LocalizedText.warn("logs.registry.validator.held_item_render_sprite_missing", [config_id, render_config.sprite_path])
	for weapon_id_variant in HeldItemRenderCatalog.get_weapon_mappings().keys():
		var weapon_id := str(weapon_id_variant)
		if WeaponCatalog.get_weapon_definition(weapon_id) == null:
			LocalizedText.error("logs.registry.validator.held_item_render_weapon_missing", [weapon_id])
			is_valid = false
	for item_id_variant in HeldItemRenderCatalog.get_item_mappings().keys():
		var item_id := str(item_id_variant)
		if ItemCatalog.get_item_definition(item_id) == null:
			LocalizedText.error("logs.registry.validator.held_item_render_item_missing", [item_id])
			is_valid = false
	return is_valid


static func _validate_buffs() -> bool:
	var registry := RegistryManager.get_registry(BuffCatalog.REGISTRY_TYPE) as BuffRegistry
	if registry == null:
		LocalizedText.error("logs.registry.validator.buff_registry_missing")
		return false
	var is_valid := true
	for key in registry.get_all_keys():
		var rl := ResourceLocation.from_string(key)
		var buff_def := registry.get_entry(rl) as BuffDefinition
		if buff_def == null:
			LocalizedText.error("logs.registry.validator.buff_entry_invalid", [key])
			is_valid = false
			continue
		if buff_def.id.is_empty():
			LocalizedText.error("logs.registry.validator.buff_id_missing", [key])
			is_valid = false
	return is_valid


static func _resource_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if path.begins_with("uid://"):
		return ResourceLoader.load(path) != null
	return ResourceLoader.exists(path)
