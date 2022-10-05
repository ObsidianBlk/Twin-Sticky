extends Spatial


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEFAULT_TRAJECTORY : Vector3 = Vector3.BACK

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
export var rof : float = 1.5						setget set_rof
export var damage : float = 1.0						setget set_damage
export var spread : float = 10.0					setget set_spread
export var shot_range : float = 100.0				setget set_shot_range
export var knockback_strength : float = 40.0		setget set_knockback_strength


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _fire_lock_timer : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var trajectories_node : Spatial = $Trajectories
onready var particle_node : Particles = $Particles
onready var blastlight_node : OmniLight = $BlastLight

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_rof(r : float) -> void:
	if r > 0.0:
		rof = r

func set_damage(d : float) -> void:
	if d > 0.0:
		damage = d

func set_spread(s : float) -> void:
	if s >= 0.0:
		spread = 0.0

func set_shot_range(r : float) -> void:
	if r > 0.0:
		shot_range = r

func set_knockback_strength(k : float) -> void:
	if k >= 0.0:
		knockback_strength = k

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_RandomizeTrajectories()

func _physics_process(delta : float) -> void:
	if _fire_lock_timer > 0.0:
		_fire_lock_timer = max(0.0, _fire_lock_timer - delta)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _RandomizeTrajectories() -> void:
	randomize()
	for child in trajectories_node.get_children():
		if child is RayCast:
			if child.name == "RayCast_C":
				continue
			
			var axis : Vector3 = Vector3.LEFT
			if child.name == "RayCast_L" or child.name == "RayCast_R":
				axis = Vector3.UP
			var angle = rand_range(0.0, spread)
			if child.name == "RayCast_L" or child.name == "RayCast_B":
				angle *= -1.0
			child.cast_to = DEFAULT_TRAJECTORY.rotated(axis, deg2rad(angle)) * shot_range

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
	var bodies : Array = []
	for child in trajectories_node.get_children():
		if child is RayCast:
			var body : Spatial = child.get_collider()
			if body != null:
				if body.has_method("hit"):
					var bidx : int = bodies.find(body)
					if bidx < 0:
						bodies.append({"node":body, "hits":1})
					else:
						bodies[bidx].hits += 1
	
	particle_node.emitting = true
	blastlight_node.visible = true
	
	var timer = get_tree().create_timer(particle_node.lifetime)
	timer.connect("timeout", self, "_on_blastlight_timeout")
	
	for body in bodies:
		# TODO: Damage fallout due to distance from weapon?
		body.node.hit(damage * body.hits, global_transform.basis.z * knockback_strength)
	_RandomizeTrajectories()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_blastlight_timeout() -> void:
	blastlight_node.visible = false
