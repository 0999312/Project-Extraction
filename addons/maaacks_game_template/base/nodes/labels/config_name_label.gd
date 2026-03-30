@tool
extends Label
## Displays the value of `application/config/name`, set in project settings.

const NO_NAME_STRING_KEY : String = "ui.main_menu.title_placeholder"

## If true, update the title when ready.
@export var auto_update : bool = true

func update_name_label():
	var config_name : String = ProjectSettings.get_setting("application/config/name", "")
	if config_name.is_empty():
		config_name = tr(NO_NAME_STRING_KEY)
	text = config_name

func _ready():
	if auto_update:
		update_name_label()
