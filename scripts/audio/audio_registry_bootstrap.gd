extends Node

const AUDIO_REGISTRY_TYPE := "audio"
const AUDIO_CATEGORY_GAME := "game"
const AUDIO_CATEGORY_UI := "ui"
const AUDIO_CATEGORY_ENVIRONMENT := "environment"
const AUDIO_CATEGORY_MUSIC := "music"
const AUDIO_LOAD_PHASE_STARTUP := "startup"
const AUDIO_LOAD_PHASE_GAME := "game_load"
const REGISTRY_NAMESPACE := "game"

const EN_TRANSLATION := "res://resources/i18n/ui_text.en.json"
const ZH_TRANSLATION := "res://resources/i18n/ui_text.zh.json"
const SUPPORTED_AUDIO_EXTENSIONS := [".ogg", ".wav", ".mp3"]


func _ready() -> void:
	_register_audio_registry()
	_register_startup_audio()
	_load_ui_translations()


func register_gameplay_audio() -> void:
	var registry := _get_audio_registry()
	if registry == null:
		return
	_register_entry(
		registry,
		AUDIO_CATEGORY_GAME,
		AUDIO_LOAD_PHASE_GAME,
		"res://assets/audio/sfx/game"
	)
	_register_entry(
		registry,
		AUDIO_CATEGORY_ENVIRONMENT,
		AUDIO_LOAD_PHASE_GAME,
		"res://assets/audio/sfx/environment"
	)


func _register_audio_registry() -> void:
	if not RegistryManager.has_registry(AUDIO_REGISTRY_TYPE):
		RegistryManager.register_registry(AUDIO_REGISTRY_TYPE, AudioRegistry.new())


func _register_startup_audio() -> void:
	var registry := _get_audio_registry()
	if registry == null:
		return
	_register_entry(
		registry,
		AUDIO_CATEGORY_UI,
		AUDIO_LOAD_PHASE_STARTUP,
		"res://assets/audio/sfx/ui"
	)
	_register_entry(
		registry,
		AUDIO_CATEGORY_MUSIC,
		AUDIO_LOAD_PHASE_STARTUP,
		"res://assets/audio/music"
	)


func _register_entry(registry: AudioRegistry, category: String, load_phase: String, folder: String) -> void:
	var resource_location := ResourceLocation.new(REGISTRY_NAMESPACE, "audio/%s" % category)
	registry.register(resource_location, {
		"category": category,
		"load_phase": load_phase,
		"path": folder,
		"streams": _load_streams_from_folder(folder),
	})


func _get_audio_registry() -> AudioRegistry:
	var registry := RegistryManager.get_registry(AUDIO_REGISTRY_TYPE)
	if registry is AudioRegistry:
		return registry
	return null


func _load_ui_translations() -> void:
	I18NManager.load_translation("en", EN_TRANSLATION)
	I18NManager.load_translation("zh", ZH_TRANSLATION)
	var locale := TranslationServer.get_locale().to_lower()
	if locale.begins_with("zh"):
		I18NManager.set_language("zh")
	else:
		I18NManager.set_language("en")


func _load_streams_from_folder(folder_path: String) -> Array:
	var streams: Array = []
	if not DirAccess.dir_exists_absolute(folder_path):
		return streams
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return streams
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_audio_file(file_name):
			var stream_path := "%s/%s" % [folder_path, file_name]
			var stream := load(stream_path)
			if stream is AudioStream:
				streams.append(stream)
		file_name = dir.get_next()
	dir.list_dir_end()
	return streams


func _is_audio_file(file_name: String) -> bool:
	var lower := file_name.to_lower()
	for extension in SUPPORTED_AUDIO_EXTENSIONS:
		if lower.ends_with(extension):
			return true
	return false
