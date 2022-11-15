extends Node2D


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const GAME = preload("res://Game/Game.tscn")
const TRACKBOT_BUILDER = preload("res://TrackBotBuilder/TrackBotBuilder.tscn")
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
	for action in INPUT_DEVICE_ACTION_BASES:
		MUI.register_action_name(action)
	MUI.set_user_count(2)
	
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
	elif _game_node != null:
		if MUI.get_unassigned_user_id() >= 0:
			var pid = MUI.get_unassigned_user_id()
			if event is InputEventKey:
				if not MUI.keyboard_device_in_use():
					MUI.assign_user_input_device(pid, MUI.DEVICE_TYPE.Keyboard, 0)
					_AddTrackbotBuilder(pid)
					#emit_signal("device_obtained", pid, MUI.DEVICE_TYPE.Keyboard, 0)
			elif event is InputEventJoypadButton:
				if not MUI.joypad_device_in_use(event.device):
					MUI.assign_user_input_device(pid, MUI.DEVICE_TYPE.Joypad, event.device)
					_AddTrackbotBuilder(pid)
					#emit_signal("device_obtained", pid, MUI.DEVICE_TYPE.Keyboard, 0)

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------

func _SpawnPlayer(pid : int) -> void:
	if get_tree().has_network_peer():
		_game_node.spawn_player(pid, get_tree().get_network_unique_id())
	else:
		_game_node.spawn_player(pid, 0)


func _AddTrackbotBuilder(pid : int) -> void:
	if not MUI.is_uid_valid(pid):
		printerr("Player ID ", pid, " is not valid.")
		return
	var tbb : Spatial = TRACKBOT_BUILDER.instance()
	tbb.pid = pid
	if pid == 0:
		viewport_p1.add_child(tbb)
	else:
		viewport_p2.add_child(tbb)
		vp2c.visible = true
	tbb.connect("start_game", self, "_on_start_game", [tbb])


func _CreateGame() -> void:
	if _game_node == null:
		_game_node = GAME.instance()
		viewport_game.add_child(_game_node)
		#viewport_p1.world = viewport_game.world
		#viewport_p2.world = viewport_game.world


func _RemoveGame() -> void:
	if _game_node != null:
		viewport_p1.world = viewport_p1_world
		viewport_p2.world = viewport_p2_world
		vp2c.visible = false
		viewport_game.remove_child(_game_node)
		_game_node.queue_free()
		_game_node = null
		MUI.clear_all_user_input_devices()




# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_entry_logged(e : Dictionary) -> void:
	print(e.message)


func _on_joy_connection_changed(device_id : int, connected : bool) -> void:
	if not connected:
		var pid : int = MUI.device_user(MUI.DEVICE_TYPE.Joypad, device_id)
		if pid >= 0:
			var _res : int = MUI.clear_user_input_device(pid)

func _on_MainMenu_quit():
	get_tree().quit()

func _on_MainMenu_local_start():
	if _game_node == null:
		ui.show_menu("")
		#ui.show_menu("LocalPlayerSetup")
		_CreateGame()

func _on_start_game(pid : int, tb : Spatial) -> void:
	_CreateGame()
	if pid == 0:
		viewport_p1.world = viewport_game.world
	elif pid == 1:
		viewport_p2.world = viewport_game.world
	var parent = tb.get_parent()
	if parent:
		parent.remove_child(tb)
		tb.queue_free()
	_SpawnPlayer(pid)

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



