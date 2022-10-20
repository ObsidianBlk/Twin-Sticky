extends Popup

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal quit_game()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		visible = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_menu_requested(menu_name : String) -> void:
	if menu_name == name:
		popup_centered()

func _on_Resume_pressed():
	visible = false

func _on_ToMain_pressed():
	visible = false
	emit_signal("quit_game")

func _on_ToDesktop_pressed():
	get_tree().quit()

func _on_about_to_show():
	$Main/Panel/Layout/Resume.grab_focus()
