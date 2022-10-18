tool
extends Spatial


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum COLLISION_TYPE {AREA=0, RAY=1}

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _size : float = 1.0
var _collision_type : int = COLLISION_TYPE.AREA
var _area_node_path : NodePath = "Area"
var _ray_collision_mask : int = 1
var _damage : float = 100.0
var _speed : float = 10.0
var _direction : Vector3 = Vector3.BACK
var _lifetime : float = 3.0
var _owner_name : String = ""


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _networked : bool = false
var _last_location : Vector3 = Vector3.ZERO


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_size(s : float) -> void:
	if s > 0.0:
		_size = s

func set_collision_type(t : int) -> void:
	if COLLISION_TYPE.values().find(t) >= 0:
		_collision_type = t

func set_area_node_path(p : NodePath) -> void:
	_area_node_path = p

func set_ray_collision_mask(m : int) -> void:
	_ray_collision_mask = m

func set_damage(d : float) -> void:
	if d >= 0.0:
		_damage = d

func set_speed(s : float) -> void:
	if s > 0.0:
		_speed = s

func set_direction(d : Vector3) -> void:
	if d.length() > 0.0:
		_direction = d.normalized()

func set_lifetime(l : float) -> void:
	if l > 0.0:
		_lifetime = l


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if Engine.editor_hint:
		set_physics_process(false)
		return
	
	_last_location = global_transform.origin
	_networked = get_tree().has_network_peer()
	if _networked:
		if is_network_master():
			if _collision_type == COLLISION_TYPE.AREA:
				_ConnectArea()
	else:
		if _collision_type == COLLISION_TYPE.AREA:
			_ConnectArea()

func _get(property : String):
	match property:
		"size":
			return _size
		"collision_type":
			return _collision_type
		"area_node_path":
			return _area_node_path
		"ray_collision_mask":
			return _ray_collision_mask
		"damage":
			return _damage
		"speed":
			return _speed
		"direction":
			return _direction
		"lifetime":
			return _lifetime
		"owner_name":
			return _owner_name
	return null

func _set(property : String, value) -> bool:
	var success : bool = true
	
	match property:
		"size":
			if typeof(value) == TYPE_REAL:
				set_size(value)
			else : success = false
		"collision_type":
			if typeof(value) == TYPE_INT:
				set_collision_type(value)
			else : success = false
		"area_node_path":
			if typeof(value) == TYPE_NODE_PATH:
				set_area_node_path(value)
			else : success = false
		"ray_collision_mask":
			if typeof(value) == TYPE_INT:
				set_ray_collision_mask(value)
			else : success = false
		"damage":
			if typeof(value) == TYPE_REAL:
				set_damage(value)
			else : success = false
		"speed":
			if typeof(value) == TYPE_REAL:
				set_speed(value)
			else : success = false
		"direction":
			if typeof(value) == TYPE_VECTOR3:
				set_direction(value)
			else : success = false
		"lifetime":
			if typeof(value) == TYPE_REAL:
				set_lifetime(value)
			else : success = false
		"owner_name":
			if typeof(value) == TYPE_STRING:
				_owner_name = value
			else : success = false
		_:
			success = false
	
	if success:
		property_list_changed_notify()
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name = get_class(),
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "collision_type",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = "AREA:0,RAY:1",
			usage = PROPERTY_USAGE_DEFAULT
		},
	]
	match _collision_type:
		COLLISION_TYPE.AREA:
			arr.append({
				name = "area_node_path",
				type = TYPE_NODE_PATH,
				usage = PROPERTY_USAGE_DEFAULT
			})
		COLLISION_TYPE.RAY:
			arr.append({
				name = "ray_collision_mask",
				type = TYPE_INT,
				hint = PROPERTY_HINT_LAYERS_3D_PHYSICS,
				usage = PROPERTY_USAGE_DEFAULT
			})
	arr.append_array([
		{
			name = "size",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "damage",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "speed",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "direction",
			type = TYPE_VECTOR3,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "lifetime",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "owner_name",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		},
	])
	
	return arr

func _physics_process(delta : float) -> void:
	var _process : bool = true
	if _networked:
		_process = is_network_master()
	
	if _process:
		global_transform.origin += _direction * (_speed * delta)
		if _collision_type == COLLISION_TYPE.RAY:
			_CheckRayCollision()
		_last_location = global_transform.origin
		_lifetime -= delta
		if _lifetime <= 0.0:
			_Die()
		elif _networked:
			rpc("r_update", global_transform.origin)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectArea() -> void:
	var area = get_node_or_null("Area")
	if area:
		if not area.is_connected("body_entered", self, "_on_body_entered"):
			area.connect("body_entered", self, "_on_body_entered")

func _CheckRayCollision() -> void:
	var space_state = get_world().get_direct_space_state()
	var result = space_state.intersect_ray(_last_location, global_transform.origin, 
		[self], _ray_collision_mask, true, false)
	if result:
		if result.collider.has_method("hit"):
			result.collider.hit(_damage, _direction)
		call_deferred("_Die")


func _Die() -> void:
	if _networked:
		if is_network_master():
			rpc("r_Die")
	r_Die()

# ------------------------------------------------------------------------------
# Remote Methods
# ------------------------------------------------------------------------------
puppet func r_update(position : Vector3) -> void:
	global_transform.origin = position

puppet func r_Die() -> void:
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
		queue_free()


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_class() -> String:
	return "Projectile"

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body):
	if body.name != _owner_name and body.has_method("hit"):
		body.hit(_damage, Vector3.ZERO)
		call_deferred("_Die")

