extends RigidBody

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _boost_direction : Vector3 = Vector3.ZERO
var _boost_strength : float = 0.0
var _boost_jump_strength : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var hat_node : Spatial = $Hat
onready var booster_node : Area = $Hat/Booster

onready var groundcast_node : RayCast = $Hat/GroundCast

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	booster_node.connect("booster_facing_changed", self, "_on_booster_facing_changed")
	booster_node.connect("booster_ignited", self, "_on_booster_ignited")
	booster_node.connect("booster_off", self, "_on_booster_off")
	booster_node.connect("booster_jump", self, "_on_booster_jump")
	_boost_direction = booster_node.get_facing()

func _physics_process(delta : float) -> void:
	if _boost_strength > 0.0:
		apply_central_impulse(_boost_direction * _boost_strength * delta)
	if _boost_jump_strength > 0.0:
		if groundcast_node.is_colliding():
			apply_central_impulse(Vector3.UP * _boost_jump_strength)
		_boost_jump_strength = 0.0
	hat_node.transform.basis = Basis(transform.basis.get_rotation_quat().inverse())

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateHatRotation() -> void:
	hat_node.transform.basis = Basis(transform.basis.get_rotation_quat().inverse())
	print("Rotation: ", rotation, " | Hat Rotation: ", hat_node.rotation)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_booster() -> Area:
	return booster_node

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_booster_facing_changed(facing : Vector3) -> void:
	_boost_direction = facing

func _on_booster_ignited(strength : float) -> void:
	_boost_strength = strength

func _on_booster_off() -> void:
	_boost_strength = 0.0

func _on_booster_jump(strength : float) -> void:
	_boost_jump_strength = strength


