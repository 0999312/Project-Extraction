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


## Localization and audio init must run BEFORE super._ready(), which starts
## loading the next scene and setting up the UI.  This guarantees translations
## are available and the audio registry exists before any text rendering or
## music playback begins.
func _ready() -> void:
	_init_localization()
	AudioCatalog.ensure_registry_and_register(AudioCatalog.STARTUP_AUDIO_GROUPS)
	_configure_ui_audio()
	AudioCatalog.play_registered_music("music", "main_menu.mp3")
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


func _configure_ui_audio() -> void:
	if ProjectUISoundController == null:
		return
	for child in ProjectUISoundController.get_children():
		if child is AudioStreamPlayer:
			child.queue_free()
	var select_stream := AudioCatalog.get_registered_stream("ui", "select.mp3")
	ProjectUISoundController.button_focused_player = _create_ui_audio_player(ProjectUISoundController, select_stream, "ButtonFocused")
	ProjectUISoundController.button_pressed_player = _create_ui_audio_player(ProjectUISoundController, select_stream, "ButtonPressed")
	ProjectUISoundController.tab_selected_player = _create_ui_audio_player(ProjectUISoundController, select_stream, "TabSelected")
	ProjectUISoundController.tab_changed_player = _create_ui_audio_player(ProjectUISoundController, select_stream, "TabChanged")
	if ProjectUISoundController.root_node != null:
		_connect_ui_sounds_recursive(ProjectUISoundController, ProjectUISoundController.root_node)


func _create_ui_audio_player(controller: UISoundController, stream: AudioStream, name_suffix: String) -> AudioStreamPlayer:
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = controller.audio_bus
	player.name = "%sAudioStreamPlayer" % name_suffix
	controller.add_child(player)
	return player


func _connect_ui_sounds_recursive(controller: UISoundController, node: Node, depth: int = 0) -> void:
	if depth >= UISoundController.MAX_DEPTH:
		return
	controller.connect_ui_sounds(node)
	for child in node.get_children():
		_connect_ui_sounds_recursive(controller, child, depth + 1)

#endregion Localization
