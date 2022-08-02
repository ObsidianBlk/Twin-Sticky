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
	"booster_thust",
	"booster_jump"
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

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	viewport_p2.world = viewport_p1.world

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey:
		if _local_player_info[0] == null:
			_SetLocalPlayerInputMap(0, "kb", 0)
		elif _local_player_info[1] == null:
			_SetLocalPlayerInputMap(1, "kb", 0)
	elif event is InputEventJoypadButton:
		pass

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _JoypadDeviceInUse(device_id : int) -> bool:
	if _local_player_info[0] != null and _local_player_info[0].device_type == "jp":
		if _local_player_info[0].device_id == device_id:
			return true
	if _local_player_info[1] != null and _local_player_info[1].device_type == "jp":
		if _local_player_info[1].device_id == device_id:
			return true
	return false


func _SetLocalPlayerInputMap(pid : int, device_type : String, device_id : int = 0) -> void:
	pass

func _ClearLocalPlayerInputMap(pid : int) -> void:
	pass



# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_local_player2(enable : bool) -> void:
	vp2c.visible = enable
