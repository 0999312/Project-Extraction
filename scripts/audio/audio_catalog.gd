class_name AudioCatalog
extends RefCounted
## Central audio catalog defining which audio files are loaded in each phase.
##
## Also provides static helper methods for audio registration so that
## callers (opening.gd, loading_screen.gd) do not duplicate the logic.

const REGISTRY_TYPE := "audio"
const REGISTRY_NAMESPACE := "game"
const SUPPORTED_AUDIO_EXTENSIONS := [".ogg", ".wav", ".mp3"]

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
		return
	for audio_group in audio_groups:
		_register_entry(registry, audio_group)


## Registers the gameplay audio groups (convenience wrapper).
static func register_gameplay_audio() -> void:
	var registry := _get_audio_registry()
	if registry == null:
		return
	for audio_group in GAMEPLAY_AUDIO_GROUPS:
		_register_entry(registry, audio_group)


static func _get_audio_registry() -> AudioRegistry:
	var registry := RegistryManager.get_registry(REGISTRY_TYPE)
	if registry is AudioRegistry:
		return registry
	return null


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
