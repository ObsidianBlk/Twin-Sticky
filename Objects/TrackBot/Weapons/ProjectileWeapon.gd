extends Spatial


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal spawn_projectile(projectile_name, position, direction)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var projectile_name : String = ""			setget set_projectile_name
export var rate_of_fire : float = 1.0				setget set_rate_of_fire
export var spread : float = 0.0						setget set_spread

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _fire_lock_timer : float = 0.0


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_projectile_name(p : String) -> void:
	projectile_name = p

func set_rate_of_fire(rof : float) -> void:
	if rof > 0.0:
		rate_of_fire = rof

func set_spread(s : float) -> void:
	if s >= 0.0 and s < 180.0:
		spread = s

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	# Let's preload our projectile...
	AssetDB.preload_by_name("PROJECTILES.%s"%[projectile_name])


func _physics_process(delta : float) -> void:
	if _fire_lock_timer > 0.0:
		_fire_lock_timer = max(0.0, _fire_lock_timer - delta)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ProjectileSpawn() -> void:
	pass


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
	_fire_lock_timer = rate_of_fire
	_ProjectileSpawn()
	#emit_signal("spawn_projectile", "PlasmaBullet", spawn_point_node.global_transform.origin, global_transform.basis.z)

