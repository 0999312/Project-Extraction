class_name WeaponCatalog
extends RefCounted

const REGISTRY_TYPE := "weapon"

const WEAPON_PISTOL := "game:weapon/pistol"
const WEAPON_CREATURE_ORGAN := "game:weapon/creature_organ"

static func _make_pistol() -> WeaponDefinition:
	var d := WeaponDefinition.new()
	d.id = WEAPON_PISTOL
	d.display_name = "Pistol"
	d.item_id = ItemCatalog.ITEM_WEAPON_PISTOL
	d.projectile_definition_id = ProjectileCatalog.BULLET
	d.ammo_capacity = 15
	d.fire_interval = 0.14
	d.reload_duration_sec = 1.5
	d.hipfire_spread_deg = 6.0
	d.ads_spread_deg = 1.5
	d.recoil_per_shot = 0.6
	d.recoil_recovery_per_sec = 2.0
	d.pellets_per_shot = 1
	return d

static func _make_creature_organ() -> WeaponDefinition:
	var d := WeaponDefinition.new()
	d.id = WEAPON_CREATURE_ORGAN
	d.display_name = "Creature Organ Bolt"
	d.item_id = ItemCatalog.ITEM_WEAPON_CREATURE
	d.projectile_definition_id = ProjectileCatalog.CREATURE_BOLT
	d.ammo_capacity = 6
	d.fire_interval = 0.35
	d.reload_duration_sec = 2.0
	d.hipfire_spread_deg = 8.0
	d.ads_spread_deg = 2.8
	d.recoil_per_shot = 0.3
	d.recoil_recovery_per_sec = 1.7
	d.pellets_per_shot = 1
	return d

const _FACTORIES := {
	WEAPON_PISTOL: "_make_pistol",
	WEAPON_CREATURE_ORGAN: "_make_creature_organ",
}

const _WEAPON_BY_ITEM_ID := {
	ItemCatalog.ITEM_WEAPON_PISTOL: WEAPON_PISTOL,
	ItemCatalog.ITEM_WEAPON_CREATURE: WEAPON_CREATURE_ORGAN,
}

static func ensure_registry() -> void:
	ItemCatalog.ensure_registry()
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, WeaponRegistry.new())
	var registry := _get_registry()
	if registry == null:
		push_error("[WeaponCatalog] Unable to resolve weapon registry.")
		return
	for weapon_id in _FACTORIES:
		var rl := ResourceLocation.from_string(weapon_id)
		if rl == null or registry.has_entry(rl):
			continue
		var factory_name: String = _FACTORIES[weapon_id]
		registry.register(rl, WeaponCatalog.call(factory_name))

static func get_weapon_definition(weapon_id: String) -> WeaponDefinition:
	ensure_registry()
	var rl := ResourceLocation.from_string(weapon_id)
	if rl == null:
		return null
	var registry := _get_registry()
	if registry == null:
		return null
	var entry := registry.get_entry(rl)
	return entry if entry is WeaponDefinition else null

static func get_weapon_for_item(item_id: String) -> WeaponDefinition:
	var weapon_id := str(_WEAPON_BY_ITEM_ID.get(item_id, ""))
	if weapon_id.is_empty():
		return null
	return get_weapon_definition(weapon_id)

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

