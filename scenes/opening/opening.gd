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
	ProjectUISoundController.button_focused = AudioCatalog.get_registered_stream("ui", "select.mp3")
	ProjectUISoundController.button_pressed = AudioCatalog.get_registered_stream("ui", "click.mp3")
	ProjectUISoundController.tab_selected = AudioCatalog.get_registered_stream("ui", "select.mp3")
	ProjectUISoundController.tab_changed = AudioCatalog.get_registered_stream("ui", "select.mp3")
	if ProjectUISoundController.has_method("_build_all_stream_players"):
		ProjectUISoundController._build_all_stream_players()
	if ProjectUISoundController.has_method("_recursive_connect_ui_sounds"):
		ProjectUISoundController._recursive_connect_ui_sounds(ProjectUISoundController.root_node)

#endregion Localization
