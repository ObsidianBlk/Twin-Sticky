extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal part_changed(req)
signal playername_changed(player_name)
signal enter_arena_requested()


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var playername_line : LineEdit = $MC/VBC/PlayerName
onready var tbbody_menu : MenuButton = $MC/VBC/TBBody
onready var tbbooster_menu : MenuButton = $MC/VBC/TBBooster
onready var tbwm_menu : MenuButton = $MC/VBC/TBWM
onready var tblw_menu : MenuButton = $MC/VBC/TBLeftWeapon
onready var tbrw_menu : MenuButton = $MC/VBC/TBRightWeapon
onready var enterarena_button : Button = $MC/VBC/EnterArena

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
	
	pop = tbbooster_menu.get_popup()
	for key in AssetDB.get_database_keys("BOOSTERS"):
		var idx : int = pop.get_item_count()
		pop.add_item(key)
		pop.set_item_metadata(idx, "BOOSTERS.%s"%[key])
	pop.connect("index_pressed", self, "_on_item_index_press", [tbbooster_menu, "Booster"])
	
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
# Public Methods
# ------------------------------------------------------------------------------
func grab_focus() -> void:
	tbbody_menu.grab_focus()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_index_press(idx : int, mb : MenuButton, part_name : String) -> void:
	if mb == tbwm_menu:
		tblw_menu.disabled = false
		tbrw_menu.disabled = false
		enterarena_button.disabled = false
	
	var pop : PopupMenu = mb.get_popup()
	mb.text = pop.get_item_text(idx)
	var key : String = pop.get_item_metadata(idx)
	# TODO: We have no way to know if this is successful! Fix me!
	emit_signal("part_changed", {"part":part_name, "key":key})

func _on_PlayerName_text_changed(new_text : String) -> void:
	emit_signal("playername_changed", new_text)

func _on_EnterArena_pressed():
	emit_signal("enter_arena_requested")
