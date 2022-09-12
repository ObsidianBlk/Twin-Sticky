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
	var _res : int = $"%LocalPlay".connect("pressed", self, "_on_pressed", ["local_start"])
	_res = $"%Multiplayer".connect("pressed", self, "_on_pressed", ["online_start"])
	_res = $"%ArenaEditor".connect("pressed", self, "_on_pressed", ["area_editor"])
	_res = $"%Quit".connect("pressed", self, "_on_pressed", ["quit"])


# ------------------------------------------------------------------------------
# Handler_Methods
# ------------------------------------------------------------------------------
func _on_pressed(signal_name : String) -> void:
	emit_signal(signal_name)

