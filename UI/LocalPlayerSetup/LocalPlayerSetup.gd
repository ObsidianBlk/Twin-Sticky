extends "res://UI/BaseUI.gd"


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal local_play_requested(player_count)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var play_button : Button = $Panel/Options/PlayButton
onready var count_scroll : HScrollBar = $Panel/Options/PlayerCountSelect/CountScroll

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_PlayButton_pressed() -> void:
	emit_signal("local_play_requested", int(count_scroll.value))

