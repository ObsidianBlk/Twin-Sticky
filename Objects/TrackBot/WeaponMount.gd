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
var _networked : bool = false
var _target_facing : Vector3 = Vector3.FORWARD
var _mounted_items : Dictionary = {}

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
	_networked = get_tree().has_network_peer()
	if _networked:
		if not is_network_master():
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
	
	if event.is_action_pressed("wm_fire_l_%s"%[local_player_id]):
		fire(1)
	if event.is_action_pressed("wm_fire_r_%s"%[local_player_id]):
		fire(2)


func _physics_process(delta : float) -> void:
	face(-Vector2(_dx[0] + _dx[1], _dy[0] + _dy[1]).normalized())
	var target_angle = Vector3.FORWARD.angle_to(_target_facing)
	
	if rotation.y != target_angle:
		var target_position = transform.origin + _target_facing
		var new_transform = transform.looking_at(target_position, Vector3.UP)
		transform = transform.interpolate_with(new_transform, deg2rad(dps) * delta)


# ------------------------------------------------------------------------------
# Romote Methods
# ------------------------------------------------------------------------------
remotesync func r_fire(id) -> void:
	if id in _mounted_items:
		if _mounted_items[id].has_method("fire"):
			_mounted_items[id].fire()

remotesync func r_set_facing(facing : Vector2) -> void:
	_target_facing = Vector3(facing.x, 0.0, facing.y)
	rotation.y = Vector3.FORWARD.angle_to(_target_facing)

remotesync func r_face(facing : Vector2) -> void:
	if facing.length() > 0.5:
		facing = facing.normalized()
	else:
		return
	_target_facing = Vector3(facing.x, 0.0, facing.y)

remotesync func r_facing_degrees(angle : float) -> void:
	_target_facing = Vector3.FORWARD.rotated(Vector3.UP, deg2rad(angle))

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func fire(id) -> void:
	if _networked:
		rpc("r_fire", id)
	else:
		r_fire(id)

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

func item_mounted(id : int) -> bool:
	return id in _mounted_items

func mount_item(item : Spatial, id : int, unmount_existing : bool = false) -> void:
	if item == null:
		return
	if not item.has_method("get_mount_point"):
		return
	
	if _mounted_items.keys().find(id) >= 0:
		if not unmount_existing:
			return # Something is already mounted, and we're not told to remove. Bail
		var old_item : Spatial = unmount_item(id)
		if old_item != null:
			old_item.queue_free()
	
	var mp = get_node_or_null("MountPoint_%s"%[id])
	if mp is Position3D:
		var item_mp = item.get_mount_point(id)
		if item_mp != null:
			add_child(item)
			item.transform.origin = mp.transform.origin - item_mp.transform.origin
			_mounted_items[id] = item

func unmount_item(id : int) -> Spatial:
	if not (id in _mounted_items):
		return null
	
	remove_child(_mounted_items[id])
	var item : Spatial = _mounted_items[id]
	var _res : int = _mounted_items.erase(id)
	return item

func lock_player_control(lock : bool = true) -> void:
	# TODO: Handle AIs if needed.
	if local_player_id > 0:
		set_process_unhandled_input(not lock)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

