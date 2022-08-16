extends Spatial

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal booster_facing_changed(facing)
signal booster_ignited(power)
signal booster_off()
signal booster_jump(power)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BOOST_POWER_THRESHOLD : float = 0.001

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export (int, 0, 2) var local_player_id : int = 0
export var strength : float = 100.0					setget set_strength
export var jump_strength : float = 100.0			setget set_jump_strength
export var dps : float = 180.0						setget set_dps

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _networked : bool = false

var _target_facing : Vector3 = Vector3.FORWARD
var _active : bool = false
var _tween : Tween = null

var _dx : Array = [0.0, 0.0]
var _dy : Array = [0.0, 0.0]

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_strength(s : float) -> void:
	if s > 0.0:
		strength = s
		if _active:
			emit_signal("booster_ignited", _GetFacingStrength())

func set_jump_strength(j : float) -> void:
	if j > 0.0:
		jump_strength = j

func set_dps(_dps : float) -> void:
	if _dps > 0.0:
		dps = 0.0

func set_local_player_id(id : int) -> void:
	local_player_id = id
	set_process_unhandled_input(local_player_id != 0)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_networked = get_tree().has_network_peer()
#	if get_tree().has_network_peer():
#		if get_tree().get_network_unique_id() != get_network_master():
	if not is_network_master():
		set_process_unhandled_input(false)
	_tween = Tween.new()
	add_child(_tween)
	var _res : int = _tween.connect("tween_all_completed", self, "_on_facing_complete")

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("booster_left_%s"%[local_player_id]):
		_dx[0] = -event.get_action_strength("booster_left_%s"%[local_player_id])
	elif event.is_action_released("booster_left_%s"%[local_player_id]):
		_dx[0] = 0.0
	
	if event.is_action_pressed("booster_right_%s"%[local_player_id]):
		_dx[1] = event.get_action_strength("booster_right_%s"%[local_player_id])
	elif event.is_action_released("booster_right_%s"%[local_player_id]):
		_dx[1] = 0.0
	
	if event.is_action_pressed("booster_forward_%s"%[local_player_id]):
		_dy[0] = -event.get_action_strength("booster_forward_%s"%[local_player_id])
	elif event.is_action_released("booster_forward_%s"%[local_player_id]):
		_dy[0] = 0.0
	
	if event.is_action_pressed("booster_backward_%s"%[local_player_id]):
		_dy[1] = event.get_action_strength("booster_backward_%s"%[local_player_id])
	elif event.is_action_released("booster_backward_%s"%[local_player_id]):
		_dy[1] = 0.0
	
	if event.is_action_pressed("booster_thrust_%s"%[local_player_id]):
		boost(1.0)
	elif event.is_action_released("booster_thrust_%s"%[local_player_id]):
		boost(0.0)
	
	if event.is_action_pressed("booster_jump_%s"%[local_player_id]):
		jump()

func _physics_process(delta : float) -> void:
	face(-Vector2(_dx[0] + _dx[1], _dy[0] + _dy[1]).normalized())
	var target_angle = Vector3.FORWARD.angle_to(_target_facing)
	
	if rotation.y != target_angle:
		var target_position = transform.origin + _target_facing
		var new_transform = transform.looking_at(target_position, Vector3.UP)
		transform = transform.interpolate_with(new_transform, deg2rad(dps) * delta)
		_on_facing_complete()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetFacingStrength() -> Vector3:
	return transform.basis.z * strength

remotesync func _EmitFacingChanged() -> void:
	emit_signal("booster_facing_changed", transform.basis.z)

# ------------------------------------------------------------------------------
# Remote Methods
# ------------------------------------------------------------------------------
remotesync func r_emit_signal(sig_name : String, args : Array) -> void:
	var sargs : Array = [sig_name]
	sargs.append_array(args)
	callv("emit_signal", sargs)


remotesync func r_set_facing(facing : Vector2) -> void:
	var _res : int = _tween.remove_all()
	_active = false
	_target_facing = Vector3(facing.x, 0.0, facing.y)
	rotation.y = Vector3.FORWARD.angle_to(_target_facing)
	emit_signal("booster_facing_changed", transform.basis.z)

remotesync func r_face(facing : Vector2) -> void:
	if facing.length() > 0.5:
		facing = facing.normalized()
	else:
		return
	_target_facing = Vector3(facing.x, 0.0, facing.y)

remotesync func r_facing_degrees(angle : float) -> void:
	_target_facing = Vector3.FORWARD.rotated(Vector3.UP, deg2rad(angle))

remotesync func r_boost(amount : float) -> void:
	amount = max(0.0, min(1.0, amount))
	if amount < BOOST_POWER_THRESHOLD:
		_active = false
		emit_signal("booster_off")
	else:
		_active = true
		emit_signal("booster_ignited", strength * amount)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_facing(facing : Vector2) -> void:
	if _networked:
		rpc("r_set_facing", facing)
	else:
		r_set_facing(facing)


func get_facing() -> Vector3:
	return transform.basis.z

func face(facing : Vector2) -> void:
	if _networked:
		rpc("r_face", facing)
	else:
		r_face(facing)

func facing_degrees(angle : float) -> void:
	if _networked:
		rpc("r_facing_degrees", angle)
	else:
		r_facing_degrees(angle)

func boost(amount : float) -> void:
	if _networked:
		rpc("r_boost", amount)
	else:
		r_boost(amount)

func jump() -> void:
	if _networked:
		rpc("r_emit_signal", "booster_jump", [jump_strength])
	else:
		emit_signal("booster_jump", jump_strength)

func is_boosting() -> bool:
	return _active
	
func lock_player_control(lock : bool = true) -> void:
	# TODO: Handle AIs if needed.
	if local_player_id > 0:
		set_process_unhandled_input(not lock)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_facing_complete() -> void:
	if _networked:
		rpc("r_emit_signal", "booster_facing_changed", [transform.basis.z])
	else:
		emit_signal("booster_facing_changed", transform.basis.z)
