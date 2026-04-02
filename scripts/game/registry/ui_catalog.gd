class_name UICatalog
extends RefCounted
## Registers all game UI panels and toasts with the MSF UIRegistry.
## Follow the same catalog pattern as ItemCatalog, WeaponCatalog, etc.

const REGISTRY_TYPE := "ui"

# ── Panel IDs ──────────────────────────────────────────────────────────────────
const PANEL_PAUSE_MENU := "game:ui/pause_menu"
const PANEL_INVENTORY  := "game:ui/inventory"

# ── Overlay IDs ────────────────────────────────────────────────────────────────
const OVERLAY_PLAYER_HUD := "game:ui/player_hud"

static func ensure_registry() -> void:
	if RegistryManager.has_registry(REGISTRY_TYPE):
		return
	var registry := UIRegistry.new()
	RegistryManager.register_registry(REGISTRY_TYPE, registry)
	_register_panels(registry)

static func _register_panels(registry: UIRegistry) -> void:
	# Pause menu — POPUP layer, destroyed on close
	var pause_scene := load("res://scenes/game_scene/ui/pause_menu_panel.tscn")
	if pause_scene != null:
		registry.register_panel(
			ResourceLocation.new("game", "ui/pause_menu"),
			pause_scene,
			UILayer.POPUP,
			UIPanel.CacheMode.NONE
		)

	# Inventory — NORMAL layer, cached for reuse
	var inventory_scene := load("res://scenes/game_scene/ui/inventory_panel.tscn")
	if inventory_scene != null:
		registry.register_panel(
			ResourceLocation.new("game", "ui/inventory"),
			inventory_scene,
			UILayer.NORMAL,
			UIPanel.CacheMode.CACHE
		)

static func _get_registry() -> UIRegistry:
	return RegistryManager.get_registry(REGISTRY_TYPE) as UIRegistry

## Convenience: get a ResourceLocation by string constant
static func id(panel_id_str: String) -> ResourceLocation:
	return ResourceLocation.from_string(panel_id_str)
