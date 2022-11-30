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
var _playername : String = ""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _trackbot_container : Spatial = $Turntable/TrackBotContainer
onready var _ui : Control = $UI/TBOptions

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ui.connect("part_changed", self, "_on_part_changed")
	_ui.connect("playername_changed", self, "_on_playername_changed")
	_ui.connect("enter_arena_requested", self, "_on_enter_arena_requested")
	if not MUI.is_uid_valid(pid):
		printerr("TrackBotBuilder given invalid Player ID, ", pid)
		# TODO: Lock away more stuff?
		return
	_StartBuilder()
	MUI.connect("ui_user_changed", self, "_on_ui_user_changed")
	if MUI.get_ui_control_user() < 0:
		if MUI.give_user_ui_control(pid):
			_ui.visible = true
	else:
		_ui.visible = false

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
	MUI.disconnect("ui_user_changed", self, "_on_ui_user_changed")
	if MUI.get_ui_control_user() == pid:
		MUI.free_ui_control()

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
	
#	if event.is_action_pressed("wm_fire_l_%s"%[pid + 1]) or event.is_action_pressed("wm_fire_r_%s"%[pid + 1]):
#		emit_signal("start_game", pid, {
#			"trackbot": _trackbot.get_build_dict(),
#			"playername": _playername
#		})


func _process(delta : float) -> void:
	var yaw = (_orbit_x[0] + _orbit_x[1]) * orbit_horizontal_speed * delta
	_camera.orbit(deg2rad(yaw), 0.0) 


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _StartBuilder() -> void:
	if _trackbot == null:
		_trackbot = TRACKBOT.instance()
		_trackbot.set_static()
		_trackbot_container.add_child(_trackbot)

func _SwapBody(body_key : String) -> void:
	if _trackbot != null:
		_trackbot.asset_key = body_key

func _SwapBooster(booster_key : String) -> void:
	if _trackbot != null:
		var booster = AssetDB.get_by_name(booster_key)
		if booster:
			booster.local_player_id = pid + 1
			booster.lock_player_control(true)
			_trackbot.remove_booster()
			_trackbot.add_booster(booster)

func _SwapMount(mount_key : String) -> void:
	if _trackbot != null:
		var lw : Spatial = null
		var rw : Spatial = null
		var wm : Spatial = _trackbot.remove_weapon_mount()
		if wm != null:
			lw = wm.unmount_item(1)
			rw = wm.unmount_item(2)
		wm = AssetDB.get_by_name(mount_key)
		if wm:
			wm.local_player_id = pid + 1
			wm.lock_player_control(true)
			_trackbot.add_weapon_mount(wm)
			if lw != null:
				wm.mount_item(lw, 1)
			if rw != null:
				wm.mount_item(rw, 2)

func _SwapWeapon(weapon_key : String, mount_id : int) -> void:
	if _trackbot != null:
		var item : Spatial = AssetDB.get_by_name(weapon_key)
		if item:
			_trackbot.mount_item(item, mount_id, true)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_class() -> String:
	return CLASS_NAME


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_ui_user_changed(ui_pid : int) -> void:
	if ui_pid < 0:
		MUI.give_user_ui_control(pid)
	elif ui_pid == pid:
		_ui.visible = true
		_ui.grab_focus()
	else:
		var fowner = _ui.get_focus_owner()
		fowner.release_focus()
		_ui.visible = false

func _on_enter_arena_requested() -> void:
	emit_signal("start_game", pid, {
		"trackbot": _trackbot.get_build_dict(),
		"playername": _playername
	})

func _on_playername_changed(player_name : String) -> void:
	_playername = player_name

func _on_part_changed(req : Dictionary):
	if "part" in req and "key" in req:
		match req["part"]:
			"Body":
				_SwapBody(req["key"])
			"Booster":
				_SwapBooster(req["key"])
			"Mount":
				_SwapMount(req["key"])
			"LeftWeapon":
				_SwapWeapon(req["key"], 1)
			"RightWeapon":
				_SwapWeapon(req["key"], 2)

