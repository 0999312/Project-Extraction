extends UIPanel
class_name PauseMenuPanel
## Pause menu panel managed by UIManager.
## Wraps the existing Maaacks OverlaidWindow pause menu into the MSF panel stack.
## Pauses the game tree when opened, unpauses when closed.

@export var options_menu_scene: PackedScene
@export_file("*.tscn") var main_menu_scene_path: String

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _options_button: Button = %OptionsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _exit_button: Button = %ExitButton
@onready var _restart_confirmation: ConfirmationDialog = %RestartConfirmation
@onready var _main_menu_confirmation: ConfirmationDialog = %MainMenuConfirmation
@onready var _exit_confirmation: ConfirmationDialog = %ExitConfirmation

func _on_init() -> void:
	pass

func _on_open(_data: Dictionary = {}) -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	if _resume_button != null:
		_resume_button.grab_focus()

func _on_close() -> void:
	get_tree().paused = false

func _on_destroy() -> void:
	pass

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_buttons()
	_connect_signals()

func _connect_signals() -> void:
	if _resume_button != null:
		_resume_button.pressed.connect(_on_resume_pressed)
	if _restart_button != null:
		_restart_button.pressed.connect(_on_restart_pressed)
	if _options_button != null:
		_options_button.pressed.connect(_on_options_pressed)
	if _main_menu_button != null:
		_main_menu_button.pressed.connect(_on_main_menu_pressed)
	if _exit_button != null:
		_exit_button.pressed.connect(_on_exit_pressed)
	if _restart_confirmation != null:
		_restart_confirmation.confirmed.connect(_on_restart_confirmed)
	if _main_menu_confirmation != null:
		_main_menu_confirmation.confirmed.connect(_on_main_menu_confirmed)
	if _exit_confirmation != null:
		_exit_confirmation.confirmed.connect(_on_exit_confirmed)

func _refresh_buttons() -> void:
	if _exit_button != null:
		_exit_button.visible = not OS.has_feature("web")
	if _options_button != null:
		_options_button.visible = options_menu_scene != null
	if _main_menu_button != null:
		_main_menu_button.visible = not _get_main_menu_path().is_empty()

func _get_main_menu_path() -> String:
	if not main_menu_scene_path.is_empty():
		return main_menu_scene_path
	if Engine.has_singleton("AppConfig"):
		return ""
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

# ── Button callbacks ───────────────────────────────────────────────────────────

func _on_resume_pressed() -> void:
	UIManager.back(UILayer.POPUP)

func _on_restart_pressed() -> void:
	if _restart_confirmation != null:
		_restart_confirmation.popup_centered()

func _on_options_pressed() -> void:
	if options_menu_scene != null:
		var window := options_menu_scene.instantiate()
		window.visible = false
		add_child(window)
		window.show()
		await window.hidden
		window.queue_free()

func _on_main_menu_pressed() -> void:
	if _main_menu_confirmation != null:
		_main_menu_confirmation.popup_centered()

func _on_exit_pressed() -> void:
	if _exit_confirmation != null:
		_exit_confirmation.popup_centered()

func _on_restart_confirmed() -> void:
	get_tree().paused = false
	SceneLoader.reload_current_scene()

func _on_main_menu_confirmed() -> void:
	get_tree().paused = false
	var path := _get_main_menu_path()
	if not path.is_empty():
		SceneLoader.load_scene(path)

func _on_exit_confirmed() -> void:
	get_tree().quit()
