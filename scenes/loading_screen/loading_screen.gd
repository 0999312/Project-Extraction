extends LoadingScreen
## Extended loading screen that registers gameplay-phase audio on ready.
##
## The opening scene registers the audio registry and startup audio groups.
## When the loading screen appears (transitioning to a game scene), we register
## the gameplay audio groups so they are available before the game scene loads.

const AUDIO_REGISTRY_TYPE := "audio"
const REGISTRY_NAMESPACE := "game"
const SUPPORTED_AUDIO_EXTENSIONS := [".ogg", ".wav", ".mp3"]


func _ready() -> void:
	super._ready()
	_register_gameplay_audio()


func _register_gameplay_audio() -> void:
	var registry := _get_audio_registry()
	if registry == null:
		return
	_register_audio_groups(AudioCatalog.GAMEPLAY_AUDIO_GROUPS)


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
