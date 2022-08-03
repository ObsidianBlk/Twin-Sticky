extends Spatial

# TODO: L1/R1 Strafe or Independant weapon triggers?

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export (int, 0, 2) var local_player_id : int = 0
export var dps : float = 180.0						setget set_dps

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target_facing : Vector3 = Vector3.FORWARD

var _dx : Array = [0.0, 0.0]
var _dy : Array = [0.0, 0.0]

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_dps(_dps : float) -> void:
	if _dps > 0.0:
		dps = _dps

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if local_player_id <= 0:
		set_process_unhandled_input(false)
	
func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("wm_left_%s"%[local_player_id]):
		_dx[0] = -event.get_action_strength("wm_left_%s"%[local_player_id])
	elif event.is_action_released("wm_left_%s"%[local_player_id]):
		_dx[0] = 0.0
	
	if event.is_action_pressed("wm_right_%s"%[local_player_id]):
		_dx[1] = event.get_action_strength("wm_right_%s"%[local_player_id])
	elif event.is_action_released("wm_right_%s"%[local_player_id]):
		_dx[1] = 0.0
	
	if event.is_action_pressed("wm_forward_%s"%[local_player_id]):
		_dy[0] = -event.get_action_strength("wm_forward_%s"%[local_player_id])
	elif event.is_action_released("wm_forward_%s"%[local_player_id]):
		_dy[0] = 0.0
	
	if event.is_action_pressed("wm_backward_%s"%[local_player_id]):
		_dy[1] = event.get_action_strength("wm_backward_%s"%[local_player_id])
	elif event.is_action_released("wm_backward_%s"%[local_player_id]):
		_dy[1] = 0.0


func _physics_process(delta : float) -> void:
	face(-Vector2(_dx[0] + _dx[1], _dy[0] + _dy[1]).normalized())
	var target_angle = Vector3.FORWARD.angle_to(_target_facing)
	
	if rotation.y != target_angle:
		var target_position = transform.origin + _target_facing
		var new_transform = transform.looking_at(target_position, Vector3.UP)
		transform = transform.interpolate_with(new_transform, deg2rad(dps) * delta)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
remotesync func set_facing(facing : Vector2) -> void:
	_target_facing = Vector3(facing.x, 0.0, facing.y)
	rotation.y = Vector3.FORWARD.angle_to(_target_facing)

func get_facing() -> Vector3:
	return transform.basis.z

remotesync func face(facing : Vector2) -> void:
	if facing.length() > 0.5:
		facing = facing.normalized()
	else:
		return
	_target_facing = Vector3(facing.x, 0.0, facing.y)

remotesync func facing_degrees(angle : float) -> void:
	_target_facing = Vector3.FORWARD.rotated(Vector3.UP, deg2rad(angle))

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

