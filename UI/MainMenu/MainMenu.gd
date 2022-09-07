extends "res://UI/BaseUI.gd"

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal local_start()
signal online_start()
signal area_editor()
signal quit()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visible = start_visible
	$"%LocalPlay".connect("pressed", self, "_on_pressed", ["local_start"])
	$"%Multiplayer".connect("pressed", self, "_on_pressed", ["online_start"])
	$"%ArenaEditor".connect("pressed", self, "_on_pressed", ["area_editor"])
	$"%Quit".connect("pressed", self, "_on_pressed", ["quit"])


# ------------------------------------------------------------------------------
# Handler_Methods
# ------------------------------------------------------------------------------
func _on_pressed(signal_name : String) -> void:
	emit_signal(signal_name)

