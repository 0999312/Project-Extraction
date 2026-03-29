class_name BuffCatalog
extends RefCounted

const REGISTRY_TYPE := "buff"

# ── Built-in Buff IDs ──────────────────────────────────────────────────────────
const BLEED_LIGHT  := "game:buff/bleed_light"
const BLEED_HEAVY  := "game:buff/bleed_heavy"
const FRACTURE     := "game:buff/fracture"

# ── Built-in Buff Definitions ─────────────────────────────────────────────────
static func _make_bleed_light() -> BuffDefinition:
	var d := BuffDefinition.new()
	d.id = BLEED_LIGHT
	d.display_name = "Light Bleed"
	d.stackable = false
	d.base_duration = 0.0        # permanent until treated
	d.damage_per_second = 1.0
	d.tags = ["bleed", "debuff"]
	return d

static func _make_bleed_heavy() -> BuffDefinition:
	var d := BuffDefinition.new()
	d.id = BLEED_HEAVY
	d.display_name = "Heavy Bleed"
	d.stackable = false
	d.base_duration = 0.0
	d.damage_per_second = 5.0
	d.tags = ["bleed", "debuff"]
	return d

static func _make_fracture() -> BuffDefinition:
	var d := BuffDefinition.new()
	d.id = FRACTURE
	d.display_name = "Fracture"
	d.stackable = false
	d.base_duration = 0.0        # permanent until splinted
	d.move_speed_mult = 0.6
	d.tags = ["fracture", "debuff"]
	return d

const _BUILT_IN_FACTORIES := {
	BLEED_LIGHT: "_make_bleed_light",
	BLEED_HEAVY: "_make_bleed_heavy",
	FRACTURE:    "_make_fracture",
}

# ── Registry helpers ──────────────────────────────────────────────────────────
static func ensure_registry() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, BuffRegistry.new())
	var registry := _get_buff_registry()
	if registry == null:
		push_error("[BuffCatalog] Unable to resolve buff registry.")
		return
	for buff_id in _BUILT_IN_FACTORIES:
		var rl := ResourceLocation.from_string(buff_id)
		if rl == null or registry.has_entry(rl):
			continue
		var factory: String = _BUILT_IN_FACTORIES[buff_id]
		var def: BuffDefinition = BuffCatalog.call(factory)
		registry.register(rl, def)

static func get_definition(buff_id: String) -> BuffDefinition:
	ensure_registry()
	var rl := ResourceLocation.from_string(buff_id)
	if rl == null:
		return null
	var registry := _get_buff_registry()
	if registry == null:
		return null
	var entry := registry.get_entry(rl)
	return entry if entry is BuffDefinition else null

static func _get_buff_registry() -> BuffRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	return registry if registry is BuffRegistry else null
