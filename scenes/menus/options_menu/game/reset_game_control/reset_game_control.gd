extends HBoxContainer

const RESET_STRING_KEY := "ui.options.reset_game.label"
const CONFIRM_STRING_KEY := "ui.options.reset_game.confirm_label"
const RESET_BUTTON_KEY := "ui.options.reset_game.reset"
const CANCEL_BUTTON_KEY := "ui.common.no"
const CONFIRM_BUTTON_KEY := "ui.common.yes"

signal reset_confirmed

func _on_cancel_button_pressed():
	%CancelButton.hide()
	%ConfirmButton.hide()
	%ResetButton.show()
	%ResetLabel.text = tr(RESET_STRING_KEY)

func _on_reset_button_pressed():
	%CancelButton.show()
	%ConfirmButton.show()
	%ResetButton.hide()
	%ResetLabel.text = tr(CONFIRM_STRING_KEY)

func _on_confirm_button_pressed():
	reset_confirmed.emit()
	get_tree().paused = false
	SceneLoader.reload_current_scene()


func _ready() -> void:
	%ResetLabel.text = tr(RESET_STRING_KEY)
	%ResetButton.text = tr(RESET_BUTTON_KEY)
	%CancelButton.text = tr(CANCEL_BUTTON_KEY)
	%ConfirmButton.text = tr(CONFIRM_BUTTON_KEY)
