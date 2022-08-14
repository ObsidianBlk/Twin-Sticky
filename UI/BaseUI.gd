extends Control
# ----------------------------------
# Base script from which to create all other top-level UI scenes.
# ----------------------------------

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal close_menu()
signal request_menu(menu_name)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var start_visible : bool = false


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_menu_requested(menu_name : String) -> void:
	print("Menu Requested : ", menu_name)
	visible = (menu_name == name)
