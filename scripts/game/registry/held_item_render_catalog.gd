class_name HeldItemRenderCatalog
extends RefCounted

const CONFIGS_RESOURCE_DIR := "res://resources/registries/held_item_render_configs"
const MAPPINGS_JSON_PATH := "res://resources/registries/held_item_render_configs/held_item_render_mappings.json"
const DEFAULT_RENDER_CONFIG_ID := "game:held_item_render/default"

static var _is_loaded := false
static var _configs_by_id: Dictionary = {}
static var _weapon_render_config_ids: Dictionary = {}
static var _item_render_config_ids: Dictionary = {}
static var _default_render_config_id: String = DEFAULT_RENDER_CONFIG_ID

static func ensure_loaded() -> void:
	if _is_loaded:
		return
	_configs_by_id.clear()
	_weapon_render_config_ids.clear()
	_item_render_config_ids.clear()
	_default_render_config_id = DEFAULT_RENDER_CONFIG_ID
	_load_configs_from_resources()
	_load_mappings_from_json()
	_is_loaded = true

static func get_render_config_for(weapon_id: String, item_id: String) -> HeldItemRenderConfig:
	ensure_loaded()
	var config_id := ""
	if not weapon_id.is_empty():
		config_id = str(_weapon_render_config_ids.get(weapon_id, ""))
	if config_id.is_empty() and not item_id.is_empty():
		config_id = str(_item_render_config_ids.get(item_id, ""))
	if config_id.is_empty():
		config_id = _default_render_config_id
	return _resolve_config(config_id)

static func get_default_render_config() -> HeldItemRenderConfig:
	ensure_loaded()
	return _resolve_config(_default_render_config_id)

static func get_render_config_by_id(config_id: String) -> HeldItemRenderConfig:
	ensure_loaded()
	return _get_config(config_id)

static func get_registered_config_ids() -> Array[String]:
	ensure_loaded()
	var result: Array[String] = []
	for key_variant in _configs_by_id.keys():
		result.append(str(key_variant))
	return result

static func get_weapon_mappings() -> Dictionary:
	ensure_loaded()
	return _weapon_render_config_ids.duplicate(true)

static func get_item_mappings() -> Dictionary:
	ensure_loaded()
	return _item_render_config_ids.duplicate(true)

static func get_default_render_config_id() -> String:
	ensure_loaded()
	return _default_render_config_id

static func _load_configs_from_resources() -> void:
	var dir := DirAccess.open(CONFIGS_RESOURCE_DIR)
	if dir == null:
		LocalizedText.warn("logs.held_item_render_catalog.configs_dir_missing", [CONFIGS_RESOURCE_DIR])
		return
	dir.list_dir_begin(true, true)
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := "%s/%s" % [CONFIGS_RESOURCE_DIR, file_name]
			var res := ResourceLoader.load(path)
			if res is HeldItemRenderConfig:
				var render_config := res as HeldItemRenderConfig
				if not render_config.id.is_empty() and not _configs_by_id.has(render_config.id):
					_configs_by_id[render_config.id] = render_config
		file_name = dir.get_next()

static func _load_mappings_from_json() -> void:
	if not FileAccess.file_exists(MAPPINGS_JSON_PATH):
		LocalizedText.warn("logs.held_item_render_catalog.json_missing", [MAPPINGS_JSON_PATH])
		return
	var file := FileAccess.open(MAPPINGS_JSON_PATH, FileAccess.READ)
	if file == null:
		LocalizedText.warn("logs.held_item_render_catalog.json_open_failed", [MAPPINGS_JSON_PATH])
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		LocalizedText.error("logs.held_item_render_catalog.json_parse_failed", [MAPPINGS_JSON_PATH, json.get_error_message()])
		return
	var data: Variant = json.data
	if not (data is Dictionary):
		LocalizedText.error("logs.held_item_render_catalog.json_root_invalid")
		return
	var root := data as Dictionary
	_default_render_config_id = str(root.get("default_render_config_id", DEFAULT_RENDER_CONFIG_ID))
	_weapon_render_config_ids = _to_string_dictionary(root.get("weapon_render_configs", {}))
	_item_render_config_ids = _to_string_dictionary(root.get("item_render_configs", {}))

static func _to_string_dictionary(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if not (value is Dictionary):
		return normalized
	for key_variant in (value as Dictionary).keys():
		normalized[str(key_variant)] = str((value as Dictionary)[key_variant])
	return normalized

static func _resolve_config(config_id: String) -> HeldItemRenderConfig:
	var render_config := _get_config(config_id)
	if _has_valid_sprite(render_config):
		return render_config
	if config_id != _default_render_config_id:
		var fallback := _get_config(_default_render_config_id)
		if _has_valid_sprite(fallback):
			return fallback
	return render_config

static func _get_config(config_id: String) -> HeldItemRenderConfig:
	var config_variant = _configs_by_id.get(config_id, null)
	return config_variant if config_variant is HeldItemRenderConfig else null

static func _has_valid_sprite(render_config: HeldItemRenderConfig) -> bool:
	if render_config == null:
		return false
	var sprite_path := render_config.sprite_path
	if sprite_path.is_empty():
		return false
	if sprite_path.begins_with("uid://"):
		return ResourceLoader.load(sprite_path) is Texture2D
	return ResourceLoader.exists(sprite_path)
