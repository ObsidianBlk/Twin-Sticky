extends Node2D


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
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
]

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _local_player_info : Array = [null, null]

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var vp2c : ViewportContainer = $GameView/Viewports/VP2C
onready var viewport_p1 : Viewport = $GameView/Viewports/VP1C/Viewport_P1
onready var viewport_p2 : Viewport = $GameView/Viewports/VP2C/Viewport_P2
onready var game_node : Spatial = $GameView/Viewports/VP1C/Viewport_P1/Game

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	viewport_p2.world = viewport_p1.world
	var _res : int = game_node.connect("local_player_2", self, "_on_local_player_2")
	_res = Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")

func _physics_process(_delta : float) -> void:
	pass


func _unhandled_input(event : InputEvent) -> void:
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
	game_node.spawn_local(pid)

func _ClearLocalPlayerInputMap(pid : int) -> void:
	if not (pid >= 0 and pid < 2):
		return
	if _local_player_info[pid] == null:
		pass
	
	for action_name in INPUT_DEVICE_ACTION_BASES:
		var naction_name : String = "%s_%s"%[action_name, String(pid+1)]
		if InputMap.has_action(naction_name):
			InputMap.erase_action(naction_name)



# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_joy_connection_changed(device_id : int, connected : bool) -> void:
	if not connected:
		var pid : int = _PlayerUsingJoypadDevice(device_id)
		if pid >= 0:
			_ClearLocalPlayerInputMap(pid)

func _on_local_player_2(joined : bool) -> void:
	vp2c.visible = joined
