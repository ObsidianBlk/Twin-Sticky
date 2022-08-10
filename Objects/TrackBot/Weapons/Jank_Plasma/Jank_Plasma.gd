extends Spatial


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal spawn_projectile(projectile_name, position, direction)

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
export var rof : float = 0.1						setget set_rof


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _fire_lock_timer : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var spawn_point_node : Position3D = $Spawn_point

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_rof(r : float) -> void:
	if r > 0.0:
		rof = r


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _physics_process(delta : float) -> void:
	if _fire_lock_timer > 0.0:
		_fire_lock_timer = max(0.0, _fire_lock_timer - delta)


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func has_mount_point(id : int) -> bool:
	return get_mount_point(id) != null

func get_mount_point(id : int) -> Position3D:
	var p = get_node_or_null("Mount_%s"%[id])
	if p is Position3D:
		return p
	return null

func fire() -> void:
	if _fire_lock_timer > 0.0:
		return
	_fire_lock_timer = rof
	emit_signal("spawn_projectile", "PlasmaBullet", spawn_point_node.global_transform.origin, global_transform.basis.z)


