extends Spatial


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal device_obtained(pid, type, did)


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CLASS_NAME : String = "TrackBotBuilder"
const TRACKBOT : PackedScene = preload("res://Objects/TrackBot/TrackBot.tscn")
const BOOSTER : PackedScene = preload("res://Objects/TrackBot/Boosters/Jank_Booster.tscn")
const WEAPONMOUNT : PackedScene = preload("res://Objects/TrackBot/WeaponMount/WeaponMount.tscn")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var pid : int = -1
export var companion_builder_path : NodePath = ""
export var orbit_horizontal_speed : float = 360.0
export var orbit_vertical_speed : float = 90.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _obtained_input_device : bool = false
var _camera : Spatial = null
var _orbit_x : Array = [0.0, 0.0]
var _orbit_y : Array = [0.0, 0.0]


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _trackbot_container : Spatial = $Turntable/TrackBotContainer

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if not MUI.is_uid_valid(pid):
		printerr("TrackBotBuilder given invalid Player ID, ", pid)
		# TODO: Lock away more stuff?
		return
	connect("device_obtained", self, "_on_device_obtained")
	set_process_unhandled_input(false)

func _enter_tree() -> void:
	var nodes = get_tree().get_nodes_in_group("Camera_P%s"%[pid + 1])
	if nodes.size() > 0:
		_camera = nodes[0]
		_camera.free_look = false
		_camera.global_transform.origin = Vector3(0.0, 1.0, 0.0)
		_camera.initial_pitch_degree = 10.0
		_camera.reset_orbit()
		_camera.set_zoom(0.05)
	else:
		printerr("TrackBotBuilder failed to find associated camera!")
		return

func _exit_tree() -> void:
	_camera = null

func _unhandled_input(event : InputEvent) -> void:
	if _obtained_input_device:
		if not _camera:
			return
		if event.is_action_pressed("orbit_left"):
			_orbit_x[0] = -event.get_action_strength("orbit_left")
		elif event.is_action_released("orbit_left"):
			_orbit_x[0] = 0.0
		
		if event.is_action_pressed("orbit_right"):
			_orbit_x[1] = event.get_action_strength("orbit_right")
		elif event.is_action_released("orbit_right"):
			_orbit_x[1] = 0.0
		
	else:
		if event is InputEventKey:
			if not MUI.keyboard_device_in_use():
				MUI.assign_user_input_device(pid, MUI.DEVICE_TYPE.Keyboard, 0)
				_obtained_input_device = true
				emit_signal("device_obtained", pid, MUI.DEVICE_TYPE.Keyboard, 0)
		elif event is InputEventJoypadButton:
			if not MUI.joypad_device_in_use(event.device):
				MUI.assign_user_input_device(pid, MUI.DEVICE_TYPE.Joypad, event.device)
				_obtained_input_device = true
				emit_signal("device_obtained", pid, MUI.DEVICE_TYPE.Keyboard, 0)


func _process(delta : float) -> void:
	if _obtained_input_device:
		var yaw = (_orbit_x[0] + _orbit_x[1]) * orbit_horizontal_speed * delta
		_camera.orbit(deg2rad(yaw), 0.0) 


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _StartBuilder() -> void:
	var tb : Spatial = TRACKBOT.instance()
	tb.set_static()
	_trackbot_container.add_child(tb)
	var wmount = WEAPONMOUNT.instance()
	wmount.local_player_id = pid + 1
	wmount.lock_player_control(true)
	tb.add_weapon_mount(wmount)
	

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_class() -> String:
	return CLASS_NAME

func initialize() -> void:
	var cnode = get_node_or_null(companion_builder_path)
	if cnode != null:
		if cnode.get_class() == CLASS_NAME:
			cnode.connect("device_obtained", self, "_on_device_obtained")
			print("I, ", self, " am disabling input")
	else:
		set_process_unhandled_input(true)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_device_obtained(player_id : int, type : int, device_id : int) -> void:
	print("Owner, ", pid, " Obtained Device")
	if player_id == pid:
		_StartBuilder()
	elif player_id == pid - 1:
		set_process_unhandled_input(true)



