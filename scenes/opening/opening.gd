extends "res://addons/maaacks_game_template/base/nodes/opening/opening.gd"
## Project Extraction opening scene script.
##
## Responsibilities formerly handled by autoload bootstraps:
##   - Loads i18n translation files and applies the configured language
##     (was LocalizationBootstrap).
##   - Registers the audio registry and loads startup-phase audio groups
##     (was AudioRegistryBootstrap).

const EN_TRANSLATION := "res://resources/i18n/ui_text.en.json"
const ZH_TRANSLATION := "res://resources/i18n/ui_text.zh.json"
const DEFAULT_LANGUAGE := "en"
const LANGUAGE_SETTING_KEY := "Language"
const SUPPORTED_LANGUAGES := ["en", "zh"]

const AUDIO_REGISTRY_TYPE := "audio"
const REGISTRY_NAMESPACE := "game"
const SUPPORTED_AUDIO_EXTENSIONS := [".ogg", ".wav", ".mp3"]


func _ready() -> void:
	_init_localization()
	_init_startup_audio()
	super._ready()


#region Localization ──────────────────────────────────────────

func _init_localization() -> void:
	I18NManager.load_translation("en", EN_TRANSLATION)
	I18NManager.load_translation("zh", ZH_TRANSLATION)
	_apply_configured_language()


func get_supported_languages() -> PackedStringArray:
	return PackedStringArray(SUPPORTED_LANGUAGES)


func set_language(language_code: String) -> void:
	var normalized := _normalize_language(language_code)
	I18NManager.set_language(normalized)
	PlayerConfig.set_config(AppSettings.GAME_SECTION, LANGUAGE_SETTING_KEY, normalized)


func _apply_configured_language() -> void:
	var configured := str(PlayerConfig.get_config(AppSettings.GAME_SECTION, LANGUAGE_SETTING_KEY, ""))
	if configured.is_empty():
		configured = _detect_system_language()
	set_language(configured)


func _detect_system_language() -> String:
	var locale := TranslationServer.get_locale().to_lower()
	if locale.begins_with("zh"):
		return "zh"
	return DEFAULT_LANGUAGE


func _normalize_language(language_code: String) -> String:
	var normalized := language_code.to_lower()
	if normalized.begins_with("zh"):
		return "zh"
	if normalized in SUPPORTED_LANGUAGES:
		return normalized
	return DEFAULT_LANGUAGE

#endregion Localization


#region Audio Registration ────────────────────────────────────

func _init_startup_audio() -> void:
	_register_audio_registry()
	_register_audio_groups(AudioCatalog.STARTUP_AUDIO_GROUPS)


func register_gameplay_audio() -> void:
	var registry := _get_audio_registry()
	if registry == null:
		return
	_register_audio_groups(AudioCatalog.GAMEPLAY_AUDIO_GROUPS)


func _register_audio_registry() -> void:
	if not RegistryManager.has_registry(AUDIO_REGISTRY_TYPE):
		RegistryManager.register_registry(AUDIO_REGISTRY_TYPE, AudioRegistry.new())


func _register_audio_groups(audio_groups: Array) -> void:
	var registry := _get_audio_registry()
	if registry == null:
		return
	for audio_group in audio_groups:
		_register_entry(registry, audio_group)


func _register_entry(registry: AudioRegistry, audio_group: Dictionary) -> void:
	var category := str(audio_group.get("category", ""))
	var load_phase := str(audio_group.get("load_phase", ""))
	var folder := str(audio_group.get("folder", ""))
	var resource_location := ResourceLocation.new(REGISTRY_NAMESPACE, "audio/%s" % category)
	var file_names: Array = audio_group.get("files", [])
	var stream_entries := _load_streams_from_files(folder, file_names)
	registry.register(resource_location, {
		"category": category,
		"load_phase": load_phase,
		"path": folder,
		"files": file_names.duplicate(),
		"streams": stream_entries,
	})


func _get_audio_registry() -> AudioRegistry:
	var registry := RegistryManager.get_registry(AUDIO_REGISTRY_TYPE)
	if registry is AudioRegistry:
		return registry
	return null


func _load_streams_from_files(folder_path: String, file_names: Array) -> Array:
	var streams: Array = []
	if folder_path.is_empty() or not DirAccess.dir_exists_absolute(folder_path):
		return streams
	for file_name_variant in file_names:
		var file_name := str(file_name_variant)
		if not _is_audio_file(file_name):
			continue
		var stream_path := "%s/%s" % [folder_path, file_name]
		if not ResourceLoader.exists(stream_path):
			continue
		var stream := load(stream_path)
		if stream is AudioStream:
			streams.append({
				"file_name": file_name,
				"path": stream_path,
				"stream": stream,
			})
	return streams


func _is_audio_file(file_name: String) -> bool:
	var lower := file_name.to_lower()
	for extension in SUPPORTED_AUDIO_EXTENSIONS:
		if lower.ends_with(extension):
			return true
	return false

#endregion Audio Registration
