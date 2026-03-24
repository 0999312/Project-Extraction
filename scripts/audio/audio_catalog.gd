class_name AudioCatalog
extends RefCounted
## Central audio catalog defining which audio files are loaded in each phase.
##
## Also provides static helper methods for audio registration so that
## callers (opening.gd, loading_screen.gd) do not duplicate the logic.

const REGISTRY_TYPE := "audio"
const REGISTRY_NAMESPACE := "game"
const SUPPORTED_AUDIO_EXTENSIONS := [".ogg", ".wav", ".mp3"]
const DEFAULT_MUSIC_CROSSFADE := 0.35

const STARTUP_AUDIO_GROUPS := [
	{
		"category": "ui",
		"load_phase": "startup",
		"folder": "res://assets/game/sounds/ui",
		"files": [
			"cancel.mp3",
			"click.mp3",
			"equip.mp3",
			"select.mp3",
			"shopping_buy.mp3",
		],
	},
	{
		"category": "music",
		"load_phase": "startup",
		"folder": "res://assets/game/sounds/music",
		"files": [
			"main_menu.mp3",
		],
	},
]

const GAMEPLAY_AUDIO_GROUPS := [
	{
		"category": "game",
		"load_phase": "game_load",
		"folder": "res://assets/game/sounds/sounds",
		"files": [
			"entity_hurt.mp3",
			"handgun_shoot.mp3",
			"human_die.mp3",
			"mob_die.mp3",
			"mag_empty.mp3",
			"reload.mp3",
		],
	},
	{
		"category": "environment",
		"load_phase": "game_load",
		"folder": "res://assets/game/sounds/music",
		"files": [
			"game_scene.mp3",
		],
	},
]


#region Static Helpers ─────────────────────────────────────────

## Ensures the audio registry exists and registers the given audio groups.
static func ensure_registry_and_register(audio_groups: Array) -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, AudioRegistry.new())
	var registry := _get_audio_registry()
	if registry == null:
		push_error("[AudioCatalog] Unable to resolve audio registry during startup registration.")
		return
	for audio_group in audio_groups:
		_register_entry(registry, audio_group)
	_debug_print_registry_contents(registry, "startup")


## Registers the gameplay audio groups (convenience wrapper).
static func register_gameplay_audio() -> void:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		RegistryManager.register_registry(REGISTRY_TYPE, AudioRegistry.new())
	var registry := _get_audio_registry()
	if registry == null:
		push_error("[AudioCatalog] Unable to resolve audio registry during gameplay registration.")
		return
	for audio_group in GAMEPLAY_AUDIO_GROUPS:
		_register_entry(registry, audio_group)
	_debug_print_registry_contents(registry, "game_load")


static func _get_audio_registry() -> AudioRegistry:
	if not RegistryManager.has_registry(REGISTRY_TYPE):
		return null
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	if registry is AudioRegistry:
		return registry
	return null


static func get_registered_stream(category: String, preferred_file_name: String = "") -> AudioStream:
	var registry := _get_audio_registry()
	if registry == null:
		return null
	var key := "%s:audio/%s" % [REGISTRY_NAMESPACE, category]
	var entry: Variant = registry.get_all_entries().get(key, null)
	if not (entry is Dictionary):
		return null
	var streams: Array = entry.get("streams", [])
	if streams.is_empty():
		return null
	if not preferred_file_name.is_empty():
		for stream_entry_variant in streams:
			if not (stream_entry_variant is Dictionary):
				continue
			var stream_entry: Dictionary = stream_entry_variant
			if str(stream_entry.get("file_name", "")) != preferred_file_name:
				continue
			var stream: Variant = stream_entry.get("stream", null)
			if stream is AudioStream:
				return stream
	for stream_entry_variant in streams:
		if not (stream_entry_variant is Dictionary):
			continue
		var stream_entry: Dictionary = stream_entry_variant
		var stream: Variant = stream_entry.get("stream", null)
		if stream is AudioStream:
			return stream
	return null


static func play_registered_music(category: String, preferred_file_name: String = "", crossfade: float = DEFAULT_MUSIC_CROSSFADE) -> void:
	var stream := get_registered_stream(category, preferred_file_name)
	if stream == null:
		return
	if SoundManager.is_music_playing(stream):
		return
	SoundManager.play_music(stream, crossfade)


static func _register_entry(registry: AudioRegistry, audio_group: Dictionary) -> void:
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


static func _debug_print_registry_contents(registry: AudioRegistry, phase: String) -> void:
	var entries := registry.get_all_entries()
	print("[DEBUG][AudioCatalog] Registry loaded for phase=%s, entries=%d" % [phase, entries.size()])
	for key_variant in entries.keys():
		var key := str(key_variant)
		var entry_variant: Variant = entries[key]
		if not (entry_variant is Dictionary):
			print("[DEBUG][AudioCatalog] key=%s entry=%s" % [key, str(entry_variant)])
			continue
		var entry: Dictionary = entry_variant
		var stream_paths: Array[String] = []
		for stream_variant in entry.get("streams", []):
			if stream_variant is Dictionary:
				stream_paths.append(str(stream_variant.get("path", "")))
		var entry_summary := {
			"category": str(entry.get("category", "")),
			"load_phase": str(entry.get("load_phase", "")),
			"path": str(entry.get("path", "")),
			"files": entry.get("files", []),
			"stream_paths": stream_paths,
		}
		print("[DEBUG][AudioCatalog] key=%s entry=%s" % [key, str(entry_summary)])


static func _load_streams_from_files(folder_path: String, file_names: Array) -> Array:
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


static func _is_audio_file(file_name: String) -> bool:
	var lower := file_name.to_lower()
	for extension in SUPPORTED_AUDIO_EXTENSIONS:
		if lower.ends_with(extension):
			return true
	return false

#endregion Static Helpers
