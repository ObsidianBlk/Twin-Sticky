extends Spatial


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var size : float = 1.0						setget set_size
export var damage : float = 100.0					setget set_damage
export var speed : float = 10.0						setget set_speed
export var direction : Vector3 = Vector3.BACK		setget set_direction
export var lifetime : float = 3.0					setget set_lifetime


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var sprite_node : Sprite3D = $Sprite3D
onready var light_node : OmniLight = $OmniLight
onready var area_collision_node : CollisionShape = $Area/CollisionShape

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_size(s : float) -> void:
	if s > 0.0:
		size = s

func set_damage(d : float) -> void:
	if d >= 0.0:
		damage = d

func set_speed(s : float) -> void:
	if s > 0.0:
		speed = s

func set_direction(d : Vector3) -> void:
	if d.length() > 0.0:
		direction = d.normalized()

func set_lifetime(l : float) -> void:
	if l > 0.0:
		lifetime = l

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateSprite()
	_UpdateCollision()


func _physics_process(delta : float) -> void:
	if is_network_master():
		global_transform.origin += direction * (speed * delta)
		lifetime -= delta
		if lifetime <= 0.0:
			_Die()
		else:
			rpc("r_update", global_transform.origin)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateSprite() -> void:
	# TODO: Store baseline value if size is going to vary
	sprite_node.pixel_size *= size
	light_node.omni_range *= size

func _UpdateCollision() -> void:
	# TODO: Store baseline value if size is going to vary
	area_collision_node.shape.radius *= size

func _Die() -> void:
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
# Handler Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body):
	if body.has_method("hit"):
		body.hit(damage, Vector3.ZERO)
		call_deferred("_Die")
