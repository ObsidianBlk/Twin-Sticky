extends Node2D


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const GAME = preload("res://Game/Game.tscn")
const EDITOR = preload("res://ArenaEditor/ArenaEditor.tscn")
const INPUT_DEVICE_ACTION_BASES = [
	"booster_forward",
	"booster_backward",
	"booster_left",
	"booster_right",
	"booster_strafe_left",
	"booster_strafe_right",
	"booster_thrust",
	"booster_jump",
	
	"wm_left",
	"wm_right",
	"wm_forward",
	"wm_backward",
	"wm_fire_l",
	"wm_fire_r",
]

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _local_player_info : Array = [null, null]

var _game_node : Spatial = null
var _editor_node : Spatial = null

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var ui : CanvasLayer = $UI
onready var vp1c : ViewportContainer = $GameView/Viewports/VP1C
onready var vp2c : ViewportContainer = $GameView/Viewports/VP2C
onready var vpc : ViewportContainer = $GameView/Viewports/Main
onready var viewport_game : Viewport = $GameView/Viewports/Main/Viewport
onready var viewport_p1 : Viewport = $GameView/Viewports/VP1C/Viewport_P1
onready var viewport_p1_world : World = $GameView/Viewports/VP1C/Viewport_P1.world
onready var viewport_p2 : Viewport = $GameView/Viewports/VP2C/Viewport_P2
onready var viewport_p2_world : World = $GameView/Viewports/VP2C/Viewport_P2.world

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	var _res : int = Log.connect("entry_logged", self, "_on_entry_logged")
	_res = Net.connect("add_game_world", self, "_on_add_game_world")
	_res = Net.connect("remove_game_world", self, "_on_remove_game_world")
#	viewport_p1.world = viewport_game.world
#	viewport_p2.world = viewport_game.world
#	var _res : int = game_node.connect("local_player_2", self, "_on_local_player_2")
#	_res = Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")


func _unhandled_input(event : InputEvent) -> void:
	if _game_node == null:
		return

	if event.is_action_pressed("ui_cancel"):
		if _game_node == null:
			ui.show_menu("MainMenu")
		else:
			ui.show_menu("GameMenu")
	elif event.is_action_pressed("terminal"):
		ui.show_menu("Terminal")
	else:
		if event is InputEventKey:
			if not _KeyboardDeviceInUse():
				if _local_player_info[0] == null:
					call_deferred("_SetLocalPlayerInputMap", 0, "kb", 0)
				elif _local_player_info[1] == null:
					call_deferred("_SetLocalPlayerInputMap", 1, "kb", 0)
		elif event is InputEventJoypadButton:
			if not _JoypadDeviceInUse(event.device):
				if _local_player_info[0] == null:
					call_deferred("_SetLocalPlayerInputMap", 0, "jp", event.device)
				elif _local_player_info[1] == null:
					call_deferred("_SetLocalPlayerInputMap", 1, "jp", event.device)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _PlayerUsingJoypadDevice(device_id : int) -> int:
	for pid in range(_local_player_info.size()):
		if _local_player_info[pid] != null and _local_player_info[pid].device_type == "jp":
			if _local_player_info[pid].device_id == device_id:
				return pid
	return -1

func _JoypadDeviceInUse(device_id : int) -> bool:
	return _PlayerUsingJoypadDevice(device_id) >= 0

func _KeyboardDeviceInUse() -> bool:
	if _local_player_info[0] != null and _local_player_info[0].device_type == "kb":
		return true
	if _local_player_info[1] != null and _local_player_info[1].device_type == "kb":
		return true
	return false 


func _SetLocalPlayerInputMap(pid : int, device_type : String, device_id : int = 0) -> void:
	if not (pid >= 0 and pid < 2):
		return
	if _local_player_info[pid] != null:
		return
	
	_local_player_info[pid] = {
		"device_type":device_type,
		"device_id":device_id
	}
	
	for action_name in INPUT_DEVICE_ACTION_BASES:
		if InputMap.has_action(action_name):
			var naction_name : String = "%s_%s"%[action_name, String(pid+1)]
			for input in InputMap.get_action_list(action_name):
				match device_type:
					"kb":
						if input.get_class() == "InputEventKey":
							var kinput : InputEventKey = input.duplicate()
							InputMap.add_action(naction_name)
							InputMap.action_add_event(naction_name, kinput)
							break
					"jp":
						var icls = input.get_class()
						if icls == "InputEventJoypadButton" or icls == "InputEventJoypadMotion":
							var jinput = input.duplicate()
							jinput.device = device_id
							if not InputMap.has_action(naction_name):
								InputMap.add_action(naction_name)
							InputMap.action_add_event(naction_name, jinput)
	if get_tree().has_network_peer():
		_game_node.spawn_player(pid, get_tree().get_network_unique_id())
	else:
		_game_node.spawn_player(pid, 0)

func _ClearLocalPlayerInputMap(pid : int) -> void:
	if not (pid >= 0 and pid < 2):
		return
	if _local_player_info[pid] == null:
		pass
	
	for action_name in INPUT_DEVICE_ACTION_BASES:
		var naction_name : String = "%s_%s"%[action_name, String(pid+1)]
		if InputMap.has_action(naction_name):
			InputMap.erase_action(naction_name)


func _CreateGame() -> void:
	if _game_node == null:
		_game_node = GAME.instance()
		var _res : int = _game_node.connect("local_player_2", self, "_on_local_player_2")
		viewport_game.add_child(_game_node)
		viewport_p1.world = viewport_game.world
		viewport_p2.world = viewport_game.world

func _RemoveGame() -> void:
	if _game_node != null:
		if _game_node.is_connected("local_player_2", self, "_on_local_player_2"):
			_game_node.disconnect("local_player_2", self, "_on_local_player_2")
		viewport_p1.world = viewport_p1_world
		viewport_p2.world = viewport_p2_world
		vp2c.visible = false
		viewport_game.remove_child(_game_node)
		_game_node.queue_free()
		_game_node = null
		_local_player_info = [null, null]




# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_entry_logged(e : Dictionary) -> void:
	print(e.message)


func _on_joy_connection_changed(device_id : int, connected : bool) -> void:
	if not connected:
		var pid : int = _PlayerUsingJoypadDevice(device_id)
		if pid >= 0:
			_ClearLocalPlayerInputMap(pid)

func _on_local_player_2(joined : bool) -> void:
	vp2c.visible = joined

func _on_MainMenu_quit():
	get_tree().quit()

func _on_MainMenu_local_start():
	if _game_node == null:
		ui.show_menu("")
		_CreateGame()

func _on_MainMenu_online_start():
	ui.show_menu("Network")

func _on_add_game_world() -> void:
	_CreateGame()

func _on_remove_game_world() -> void:
	_RemoveGame()
	var _res : int = Lobby.remove_all_players()
	ui.show_menu("MainMenu")

func _on_close_game():
	_RemoveGame()
	var _res : int = Lobby.remove_all_players()

func _on_MainMenu_area_editor() -> void:
	set_process_unhandled_input(false)
	ui.show_menu("")
	_editor_node = EDITOR.instance()
	var _res : int = _editor_node.connect("editor_exited", self, "_on_arena_editor_exited")
	viewport_game.add_child(_editor_node)
	vp1c.visible = false
	vpc.visible = true

func _on_arena_editor_exited() -> void:
	if _editor_node != null:
		_editor_node.disconnect("editor_exited", self, "_on_arena_editor_exited")
		vpc.visible = false
		vp1c.visible = true
		viewport_game.remove_child(_editor_node)
		_editor_node.queue_free()
		ui.show_menu("MainMenu")
		set_process_unhandled_input(true)
