class_name LocalizedText
extends RefCounted


static func text(key: String, args: Array = []) -> String:
	return I18NManager.get_text(key, args)


static func warn(key: String, args: Array = []) -> void:
	push_warning(text(key, args))


static func error(key: String, args: Array = []) -> void:
	push_error(text(key, args))
