extends RigidBody

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _boost_direction : Vector3 = Vector3.ZERO
var _boost_strength : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var hat_node : Spatial = $Hat
onready var booster_node : KinematicBody = $Hat/Booster

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	booster_node.connect("booster_facing_changed", self, "_on_booster_facing_changed")
	booster_node.connect("booster_ignited", self, "_on_booster_ignited")
	booster_node.connect("booster_off", self, "_on_booster_off")
	_boost_direction = booster_node.get_facing()

func _physics_process(delta : float) -> void:
	hat_node.set_rotation(-rotation)
	if _boost_strength > 0.0:
		apply_central_impulse(_boost_direction * _boost_strength * delta)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_booster() -> KinematicBody:
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


