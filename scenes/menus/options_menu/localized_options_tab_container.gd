extends "res://addons/maaacks_game_template/base/nodes/menus/options_menu/paginated_tab_container.gd"

const TAB_TITLE_KEYS := [
	"ui.options.tab_controls",
	"ui.options.tab_inputs",
	"ui.options.tab_audio",
	"ui.options.tab_video",
	"ui.options.tab_game",
]


func _ready() -> void:
	super._ready()
	_localize_tab_titles()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_localize_tab_titles()


func _localize_tab_titles() -> void:
	for i in mini(TAB_TITLE_KEYS.size(), get_tab_count()):
		set_tab_title(i, tr(TAB_TITLE_KEYS[i]))
