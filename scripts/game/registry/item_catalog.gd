class_name ItemCatalog
extends RefCounted

const REGISTRY_TYPE := "item"

const ITEM_WEAPON_PISTOL := "game:item/weapon/pistol"
const ITEM_WEAPON_CREATURE := "game:item/weapon/creature"
const ITEM_MED_BANDAGE := "game:item/med/bandage"
const ITEM_AMMO_9MM := "game:item/ammo/9x19"

static func _make_pistol_item() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ITEM_WEAPON_PISTOL
	d.display_name = "Pistol"
	d.category = "weapon"
	d.size_w = 2
	d.size_h = 1
	d.weight = 1.2
	d.max_stack = 1
	d.tags = ["weapon", "pistol"]
	return d

static func _make_creature_weapon_item() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ITEM_WEAPON_CREATURE
	d.display_name = "Creature Bolt Organ"
	d.category = "weapon"
	d.size_w = 2
	d.size_h = 2
	d.weight = 2.0
	d.max_stack = 1
	d.tags = ["weapon", "organic"]
	return d

static func _make_bandage_item() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ITEM_MED_BANDAGE
	d.display_name = "Bandage"
	d.category = "med"
	d.size_w = 1
	d.size_h = 1
	d.weight = 0.1
	d.max_stack = 5
	d.tags = ["med", "bleed_treatment"]
	return d

static func _make_ammo_9mm_item() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ITEM_AMMO_9MM
	d.display_name = "9x19 Ammo"
	d.category = "ammo"
	d.size_w = 1
	d.size_h = 1
	d.weight = 0.015
	d.max_stack = 60
	d.tags = ["ammo", "caliber_9x19"]
	return d

const _FACTORIES := {
	ITEM_WEAPON_PISTOL: "_make_pistol_item",
	ITEM_WEAPON_CREATURE: "_make_creature_weapon_item",
	ITEM_MED_BANDAGE: "_make_bandage_item",
	ITEM_AMMO_9MM: "_make_ammo_9mm_item",
}

static func ensure_registry() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, ItemRegistry.new())
	var registry := _get_registry()
	if registry == null:
		push_error("[ItemCatalog] Unable to resolve item registry.")
		return
	for item_id in _FACTORIES:
		var rl := ResourceLocation.from_string(item_id)
		if rl == null or registry.has_entry(rl):
			continue
		var factory_name: String = _FACTORIES[item_id]
		registry.register(rl, ItemCatalog.call(factory_name))

static func get_item_definition(item_id: String) -> ItemDefinition:
	ensure_registry()
	var rl := ResourceLocation.from_string(item_id)
	if rl == null:
		return null
	var registry := _get_registry()
	if registry == null:
		return null
	var entry := registry.get_entry(rl)
	return entry if entry is ItemDefinition else null

static func _get_registry() -> ItemRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	return registry if registry is ItemRegistry else null

