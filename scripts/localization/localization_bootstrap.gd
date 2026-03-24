extends Node

const EN_TRANSLATION := "res://resources/i18n/ui_text.en.json"
const ZH_TRANSLATION := "res://resources/i18n/ui_text.zh.json"
const DEFAULT_LANGUAGE := "en"
const LANGUAGE_SETTING_KEY := "Language"
const SUPPORTED_LANGUAGES := PackedStringArray(["en", "zh"])


func _ready() -> void:
	I18NManager.load_translation("en", EN_TRANSLATION)
	I18NManager.load_translation("zh", ZH_TRANSLATION)
	_apply_configured_language()


func get_supported_languages() -> PackedStringArray:
	return SUPPORTED_LANGUAGES


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
