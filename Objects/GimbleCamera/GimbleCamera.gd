extends Spatial


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ZOOM_MIN : float = 1.0
const ZOOM_MAX : float = 100.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var current : bool = false								setget set_current
export var local_id : int = 0
export (float, 0.0, 1.0) var initial_zoom : float = 1.0			setget set_initial_zoom
export (float, 0.001, 1.0, 0.001) var zoom_step : float = 0.01	setget set_zoom_step
export var pitch_degree_min : float = -90.0						setget set_pitch_degree_min
export var pitch_degree_max : float = 90.0						setget set_pitch_degree_max
export var initial_pitch_degree : float = 60.0					setget set_initial_pitch_degree

export var target_group : String = ""

export var sensitivity : Vector2 = Vector2(0.2, 0.2)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target : WeakRef = weakref(null)

var _mouse_orbit_enabled : bool = false
var _zoom : float = 0.0

var _orbit_x : Array = [0.0, 0.0]
var _orbit_y : Array = [0.0, 0.0]
var _zoom_i : Array = [0.0, 0.0]

var _target_facing : Vector3 = Vector3.FORWARD

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _arm_node : Spatial = $Arm
onready var _camera_node : Camera = $Arm/Camera

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_current(c : bool) -> void:
	current = c
	if _camera_node:
		_camera_node.current = current

func set_initial_zoom(z : float) -> void:
	if z >= 0.0 and z <= 1.0:
		initial_zoom = z

func set_zoom_step(z : float) -> void:
	if z > 0.0 and z < 1.0:
		zoom_step = z

func set_pitch_degree_min(p : float) -> void:
	if p <= pitch_degree_max and p >= -90.0:
		pitch_degree_min = p
		if initial_pitch_degree < pitch_degree_min:
			initial_pitch_degree = pitch_degree_min

func set_pitch_degree_max(p : float) -> void:
	if p >= pitch_degree_min and p <= 90.0:
		pitch_degree_max = p
		if initial_pitch_degree > pitch_degree_max:
			initial_pitch_degree = pitch_degree_max

func set_initial_pitch_degree(p : float) -> void:
	if p >= pitch_degree_min and p <= pitch_degree_max:
		initial_pitch_degree = p

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_current(current)
	set_zoom(initial_zoom)
	rotation.x = clamp(deg2rad(-initial_pitch_degree), deg2rad(pitch_degree_min), deg2rad(pitch_degree_max))


#func _unhandled_input(event) -> void:
#	if event is InputEventMouseMotion:
#		if _mouse_orbit_enabled:
#			orbit(event.relative.x, event.relative.y)
#	elif event is InputEventMouseButton:
#		if event.is_action_pressed("orbit_enable"):
#			_mouse_orbit_enabled = true
#		elif event.is_action_released("orbit_enable"):
#			_mouse_orbit_enabled = false
#		elif event.is_action_pressed("zoom_in"):
#			zoom_in()
#		elif event.is_action_pressed("zoom_out"):
#			zoom_out()
#	else:
#		if event.is_action("orbit_left"):
#			_orbit_x[0] = event.get_action_strength("orbit_left")
#			_orbit_x[1] = event.get_action_strength("orbit_right")
#		elif event.is_action("orbit_right"):
#			_orbit_x[1] = event.get_action_strength("orbit_right")
#		elif event.is_action("orbit_up"):
#			_orbit_y[0] = event.get_action_strength("orbit_down")
#			_orbit_y[1] = event.get_action_strength("orbit_up")
#		elif event.is_action("orbit_down"):
#			_orbit_y[0] = event.get_action_strength("orbit_down")
#		elif event.is_action("zoom_in"):
#			_zoom_i[0] = event.get_action_strength("zoom_in")
#		elif event.is_action("zoom_out"):
#			_zoom_i[1] = event.get_action_strength("zoom_out")

func _physics_process(delta : float) -> void:
	_UpdateOrbit()
	_UpdateZoom()
	var target = _target.get_ref()
	if target == null:
		_GetTarget()
	else:
		global_translation = target.global_translation

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _lint(input_name : String) -> String: # LINT = Local Input Name Translation
	return "%s_%s"%[input_name, local_id]


func _GetTarget() -> void:
	if target_group != "":
		var _tg : String = target_group
		if get_tree().has_network_peer():
			var remote_pid = get_tree().get_network_unique_id()
			_tg = "%s_%s"%[_tg, remote_pid]
		#print("Target Group: ", _tg)
		var nodes : Array = get_tree().get_nodes_in_group(_tg)
		if nodes.size() > 0:
			_target = weakref(nodes[0])
	else:
		_target = null

func _UpdateOrbit() -> void:
	var ox : float = _orbit_x[1] - _orbit_x[0]
	var oy : float = _orbit_y[1] - _orbit_y[0]
	orbit(ox, oy)

#func _UpdateFacing(delta : float) -> void:
#	var nvec : Vector2 = -Vector2(_orbit_x[0] + _orbit_x[1], _orbit_y[0] + _orbit_y[1]).normalized()
#	if nvec.length() > 0.5:
#		_target_facing = Vector3(
#			nvec.x,
#			0.0,
#			nvec.y
#		)
#
#	var target_angle = Vector3.FORWARD.angle_to(_target_facing)
#	if rotation.y != target_angle:
#		var target_position = transform.origin + _target_facing
#		var new_transform : Transform = transform.looking_at(target_position, Vector3.UP)
#		transform = transform.interpolate_with(new_transform, deg2rad(orbit_dsp) * delta)
#	#rotation.y = wrapf(-target_angle, 0.0, TAU)


func _UpdateZoom() -> void:
	var z : float = _zoom_i[1] - _zoom_i[0]
	if z < -0.01:
		zoom_in()
	elif z > 0.01:
		zoom_out()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------

func view_camera(item : Spatial) -> void:
	var cpos = _camera_node.global_translation
	cpos.y = item.global_translation.y
	item.look_at(cpos, Vector3.UP)


func orbit(yaw : float, pitch : float) -> void:
	rotation.y = wrapf(rotation.y - (yaw * sensitivity.x), 0.0, TAU)
	rotation.x = clamp(rotation.x - (pitch * sensitivity.y), deg2rad(pitch_degree_min), deg2rad(pitch_degree_max))

func set_zoom(level : float) -> void:
	var dist : float = (ZOOM_MAX - ZOOM_MIN) * level
	_arm_node.transform.origin.z = ZOOM_MIN + dist

func zoom(amount : float) -> void:
	amount = max(-1.0, min(1.0, amount))
	var dist : float = (ZOOM_MAX - ZOOM_MIN) * amount
	var y = _arm_node.transform.origin.z
	_arm_node.transform.origin.z = min(ZOOM_MAX, max(ZOOM_MIN, y + dist))
	#_UpdateZoomStep()

func zoom_in() -> void:
	zoom(-zoom_step)

func zoom_out() -> void:
	zoom(zoom_step)

