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
			if child.has_signal("close_menu"):
				child.connect("close_menu", self, "_on_close_menu", [child])
			if child.has_signal("request_menu"):
				child.connect("request_menu", self, "_on_request_menu")

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	emit_signal("menu_requested", menu_name)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_close_menu(menu_node : Control) -> void:
	show_menu("")

func _on_request_menu(menu_name : String) -> void:
	show_menu(menu_name)
