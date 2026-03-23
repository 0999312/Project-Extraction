@tool
extends ListOptionControl

const LANGUAGE_VALUES := ["en", "zh"]
const LANGUAGE_TITLE_KEYS := ["ui.options.language.english", "ui.options.language.chinese_simplified"]


func _ready() -> void:
	option_values = LANGUAGE_VALUES
	option_titles = _get_localized_titles()
	super._ready()


func _on_setting_changed(value: Variant) -> void:
	super._on_setting_changed(value)
	if value is int and value >= 0 and value < LANGUAGE_VALUES.size():
		LocalizationBootstrap.set_language(LANGUAGE_VALUES[value])


func _get_localized_titles() -> Array[String]:
	var localized: Array[String] = []
	for key in LANGUAGE_TITLE_KEYS:
		localized.append(tr(key))
	return localized
