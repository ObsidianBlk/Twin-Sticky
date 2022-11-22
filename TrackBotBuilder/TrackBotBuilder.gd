extends Spatial


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal device_obtained(pid, type, did)
signal start_game(pid)


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CLASS_NAME : String = "TrackBotBuilder"
const TRACKBOT : PackedScene = preload("res://Objects/TrackBot/TrackBot.tscn")
const BOOSTER : PackedScene = preload("res://Objects/TrackBot/Boosters/Jank_Booster.tscn")
#const WEAPONMOUNT : PackedScene = preload("res://Objects/TrackBot/WeaponMount/WeaponMount.tscn")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var pid : int = -1
export var orbit_horizontal_speed : float = 360.0
export var orbit_vertical_speed : float = 90.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _camera : Spatial = null
var _orbit_x : Array = [0.0, 0.0]
var _orbit_y : Array = [0.0, 0.0]

var _trackbot : Spatial = null

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
	_StartBuilder()

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
	if not _camera:
		return
	var ename : String = "booster_left_%s"%[pid + 1]
	if event.is_action_pressed(ename):
		_orbit_x[0] = -event.get_action_strength(ename)
	elif event.is_action_released(ename):
		_orbit_x[0] = 0.0
	
	ename = "booster_right_%s"%[pid + 1]
	if event.is_action_pressed(ename):
		_orbit_x[1] = event.get_action_strength(ename)
	elif event.is_action_released(ename):
		_orbit_x[1] = 0.0
	
	if event.is_action_pressed("wm_fire_l_%s"%[pid + 1]) or event.is_action_pressed("wm_fire_r_%s"%[pid + 1]):
		emit_signal("start_game", pid, {
			"trackbot": _trackbot.get_build_dict(),
			"playername": ""
		})


func _process(delta : float) -> void:
	var yaw = (_orbit_x[0] + _orbit_x[1]) * orbit_horizontal_speed * delta
	_camera.orbit(deg2rad(yaw), 0.0) 


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _StartBuilder() -> void:
	if _trackbot == null:
		_trackbot = TRACKBOT.instance()
		_trackbot.asset_key = "TRACKBOTS.CyberSmiley"
		_trackbot.set_static()
		_trackbot_container.add_child(_trackbot)
		var wmount = AssetDB.get_by_name("WEAPONMOUNTS.CyberSmiley")#WEAPONMOUNT.instance()
		wmount.local_player_id = pid + 1
		wmount.lock_player_control(true)
		_trackbot.add_weapon_mount(wmount)
	

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_class() -> String:
	return CLASS_NAME


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------




