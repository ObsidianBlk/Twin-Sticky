extends Spatial


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ZOOM_MIN : float = 1.0
const ZOOM_MAX : float = 100.0

const MAX_SPEED : float = 5.0
const ACCELERATION : float = 40.0
const FRICTION : float = 0.7

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var free_look : bool = false								setget set_free_look
export var current : bool = false								setget set_current
export var local_id : int = 0
export var orbit_dps : float = 360.0
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
var _move_x : Array = [0.0, 0.0]
var _move_y : Array = [0.0, 0.0]
var _zoom_i : Array = [0.0, 0.0]

var _velocity : Vector3 = Vector3.ZERO

var _target_facing : Vector3 = Vector3.FORWARD

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _arm_node : Spatial = $Arm
onready var _camera_node : Camera = $Arm/Camera

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_free_look(f : bool) -> void:
	free_look = f
	set_process_unhandled_input(free_look)


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
	set_process_unhandled_input(free_look)
	rotation.x = clamp(deg2rad(-initial_pitch_degree), deg2rad(pitch_degree_min), deg2rad(pitch_degree_max))


func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		if _mouse_orbit_enabled:
			orbit(event.relative.x, event.relative.y)
	elif event is InputEventMouseButton:
		if event.is_action("orbit_enable"):
			_mouse_orbit_enabled = event.is_action_pressed("orbit_enable")
		elif event.is_action_pressed("zoom_in"):
			zoom_in()
		elif event.is_action_pressed("zoom_out"):
			zoom_out()
	else:
		if event.is_action("orbit_left") or event.is_action("orbit_right"):
			_orbit_x[0] = Input.get_action_strength("orbit_left")
			_orbit_x[1] = Input.get_action_strength("orbit_right")
		elif event.is_action("orbit_up") or event.is_action("orbit_down"):
			_orbit_y[0] = Input.get_action_strength("orbit_down")
			_orbit_y[1] = Input.get_action_strength("orbit_up")
		elif event.is_action("zoom_in"):
			_zoom_i[0] = event.get_action_strength("zoom_in")
		elif event.is_action("zoom_out"):
			_zoom_i[1] = event.get_action_strength("zoom_out")
		if _target.get_ref() == null:
			if event.is_action("booster_left") or event.is_action("booster_right"):
				_move_x[0] = Input.get_action_strength("booster_left")
				_move_x[1] = Input.get_action_strength("booster_right")
			elif event.is_action("booster_forward") or event.is_action("booster_backward"):
				_move_y[0] = Input.get_action_strength("booster_forward")
				_move_y[1] = Input.get_action_strength("booster_backward")

func _physics_process(delta : float) -> void:
	_UpdateOrbit()
	_UpdateZoom()
	var target = _target.get_ref()
	if target == null:
		_UpdateVelocity(delta)
		_GetTarget()
	elif target.is_inside_tree():
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
		_target = weakref(null)

func _UpdateVelocity(delta : float) -> void:
	var xs : float = _move_x[1] - _move_x[0]
	var ys : float = _move_y[1] - _move_y[0]
	var dir : Vector3 = Vector3(xs, 0.0, ys).rotated(Vector3.UP, rotation.y)
	if dir.length() > 0.01:
		_velocity += dir * ACCELERATION * delta
		if _velocity.length() > MAX_SPEED:
			_velocity = _velocity.normalized() * MAX_SPEED
	else:
		_velocity = lerp(_velocity, Vector3.ZERO, FRICTION)
	if _velocity.length() > 0.01:
		transform.origin += _velocity
	else:
		_velocity = Vector3.ZERO

func _UpdateOrbit() -> void:
	var ox : float = _orbit_x[1] - _orbit_x[0]
	var oy : float = _orbit_y[1] - _orbit_y[0]
	orbit(ox, oy)

func _UpdateFacing(delta : float) -> void:
	var nvec : Vector2 = -Vector2(_orbit_x[0] + _orbit_x[1], _orbit_y[0] + _orbit_y[1]).normalized()
	if nvec.length() > 0.5:
		_target_facing = Vector3(
			nvec.x,
			0.0,
			nvec.y
		)

	var target_angle = Vector3.FORWARD.angle_to(_target_facing)
	if rotation.y != target_angle:
		var target_position = transform.origin + _target_facing
		var new_transform : Transform = transform.looking_at(target_position, Vector3.UP)
		transform = transform.interpolate_with(new_transform, deg2rad(orbit_dps) * delta)
	rotation.y = wrapf(-target_angle, 0.0, TAU)


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


func orbit(yaw : float, pitch : float, ignore_sensitivity : bool = false) -> void:
	var senx : float = sensitivity.x if not ignore_sensitivity else 1.0
	var seny : float = sensitivity.y if not ignore_sensitivity else 1.0
	rotation.y = wrapf(rotation.y - (yaw * senx), 0.0, TAU)
	rotation.x = clamp(rotation.x - (pitch * seny), deg2rad(pitch_degree_min), deg2rad(pitch_degree_max))

func reset_orbit() -> void:
	rotation.x = clamp(deg2rad(-initial_pitch_degree), deg2rad(pitch_degree_min), deg2rad(pitch_degree_max))
	rotation.y = 0.0

func get_yaw() -> float:
	return rotation.y

func get_pitch() -> float:
	return rotation.x 

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

func project_ray_origin(pos : Vector2) -> Vector3:
	if _camera_node:
		return _camera_node.project_ray_origin(pos)
	return Vector3.ZERO

func project_ray_normal(pos : Vector2) -> Vector3:
	if _camera_node:
		return _camera_node.project_ray_normal(pos)
	return Vector3.ZERO
