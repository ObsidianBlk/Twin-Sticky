extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal part_changed(req)
signal playername_changed(player_name)


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var playername_line : LineEdit = $MC/VBC/PlayerName
onready var tbbody_menu : MenuButton = $MC/VBC/TBBody
onready var tbwm_menu : MenuButton = $MC/VBC/TBWM
onready var tblw_menu : MenuButton = $MC/VBC/TBLeftWeapon
onready var tbrw_menu : MenuButton = $MC/VBC/TBRightWeapon

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	var pop : PopupMenu = tbbody_menu.get_popup()
	for key in AssetDB.get_database_keys("TRACKBOTS"):
		var idx : int = pop.get_item_count()
		pop.add_item(key)
		pop.set_item_metadata(idx, "TRACKBOTS.%s"%[key])
	pop.connect("index_pressed", self, "_on_item_index_press", [tbbody_menu, "Body"])
	
	pop = tbwm_menu.get_popup()
	for key in AssetDB.get_database_keys("WEAPONMOUNTS"):
		var idx : int = pop.get_item_count()
		pop.add_item(key)
		pop.set_item_metadata(idx, "WEAPONMOUNTS.%s"%[key])
	pop.connect("index_pressed", self, "_on_item_index_press", [tbwm_menu, "Mount"])
	
	pop = tblw_menu.get_popup()
	for key in AssetDB.get_database_keys("WEAPONS"):
		var idx : int = pop.get_item_count()
		pop.add_item(key)
		pop.set_item_metadata(idx, "WEAPONS.%s"%[key])
	pop.connect("index_pressed", self, "_on_item_index_press", [tblw_menu, "LeftWeapon"])
	
	pop = tbrw_menu.get_popup()
	for key in AssetDB.get_database_keys("WEAPONS"):
		var idx : int = pop.get_item_count()
		pop.add_item(key)
		pop.set_item_metadata(idx, "WEAPONS.%s"%[key])
	pop.connect("index_pressed", self, "_on_item_index_press", [tbrw_menu, "RightWeapon"])

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_index_press(idx : int, mb : MenuButton, part_name : String) -> void:
	var pop : PopupMenu = mb.get_popup()
	mb.text = pop.get_item_text(idx)
	var key : String = pop.get_item_metadata(idx)
	# TODO: We have no way to know if this is successful! Fix me!
	emit_signal("part_changed", {"part":part_name, "key":key})

func _on_PlayerName_text_changed(new_text : String) -> void:
	emit_signal("playername_changed", new_text)

