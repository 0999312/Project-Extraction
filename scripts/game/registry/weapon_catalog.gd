class_name WeaponCatalog
extends RefCounted

const REGISTRY_TYPE := "weapon"
const WEAPONS_RESOURCE_DIR := "res://resources/registries/weapons"

const WEAPON_PISTOL := "game:weapon/pistol"
const WEAPON_CREATURE_ORGAN := "game:weapon/creature_organ"

static func ensure_registry() -> void:
	ItemCatalog.ensure_registry()
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, WeaponRegistry.new())
	var registry := _get_registry()
	if registry == null:
		LocalizedText.error("logs.weapon_catalog.registry_unresolved")
		return
	_load_weapons_from_resources(registry)

static func _load_weapons_from_resources(registry: WeaponRegistry) -> void:
	var dir := DirAccess.open(WEAPONS_RESOURCE_DIR)
	if dir == null:
		LocalizedText.warn("logs.weapon_catalog.weapons_dir_missing", [WEAPONS_RESOURCE_DIR])
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := "%s/%s" % [WEAPONS_RESOURCE_DIR, file_name]
			var res := ResourceLoader.load(path)
			if res is WeaponDefinition:
				var weapon_def: WeaponDefinition = res
				var rl := ResourceLocation.from_string(weapon_def.id)
				if rl != null and not registry.has_entry(rl):
					registry.register(rl, weapon_def)
		file_name = dir.get_next()
	dir.list_dir_end()

static func get_weapon_definition(weapon_id: String) -> WeaponDefinition:
	ensure_registry()
	var rl := ResourceLocation.from_string(weapon_id)
	if rl == null:
		return null
	var registry := _get_registry()
	if registry == null:
		return null
	var entry : WeaponDefinition = registry.get_entry(rl)
	return entry if entry is WeaponDefinition else null

static func get_weapon_for_item(item_id: String) -> WeaponDefinition:
	ensure_registry()
	var registry := _get_registry()
	if registry == null:
		return null
	for key in registry.get_all_keys():
		var entry : WeaponDefinition = registry.get_entry(ResourceLocation.from_string(key))
		if entry is WeaponDefinition and (entry as WeaponDefinition).item_id == item_id:
			return entry
	return null

static func apply_to_combat_state(combat: CombatState) -> void:
	if combat == null:
		return
	var weapon := get_weapon_for_item(combat.equipped_weapon_id)
	if weapon == null:
		return
	combat.projectile_definition_id = weapon.projectile_definition_id
	combat.ammo_max = weapon.ammo_capacity
	if combat.ammo_current <= 0:
		combat.ammo_current = weapon.ammo_capacity
	combat.fire_interval = weapon.fire_interval
	combat.reload_duration_sec = weapon.reload_duration_sec
	combat.hipfire_spread_deg = weapon.hipfire_spread_deg
	combat.ads_spread_deg = weapon.ads_spread_deg
	combat.recoil_per_shot = weapon.recoil_per_shot
	combat.recoil_recovery_per_sec = weapon.recoil_recovery_per_sec
	combat.pellets_per_shot = maxi(1, weapon.pellets_per_shot)

static func _get_registry() -> WeaponRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	return registry if registry is WeaponRegistry else null
