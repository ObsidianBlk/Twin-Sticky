extends CanvasLayer

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal menu_requested(menu_name)


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for child in get_children():
		if child.has_method("_on_menu_requested"):
			connect("menu_requested", child, "_on_menu_requested")

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	emit_signal("menu_requested", menu_name)
