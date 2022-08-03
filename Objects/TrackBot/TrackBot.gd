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

var _booster_node : Area = null
var _weaponmount_node : Spatial = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var hat_node : Spatial = $Hat
onready var groundcast_node : RayCast = $Hat/GroundCast

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	pass

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
	return _booster_node

func add_booster(booster : Area) -> void:
	if _booster_node == null:
		# TODO: Varify booster is what we think it is!
		_booster_node = booster
		hat_node.add_child(_booster_node)
		
		_booster_node.connect("booster_facing_changed", self, "_on_booster_facing_changed")
		_booster_node.connect("booster_ignited", self, "_on_booster_ignited")
		_booster_node.connect("booster_off", self, "_on_booster_off")
		_booster_node.connect("booster_jump", self, "_on_booster_jump")
		_boost_direction = _booster_node.get_facing()

func remove_booster() -> Area:
	if _booster_node != null:
		_boost_strength = 0.0
		_boost_jump_strength = 0.0
		_boost_direction = Vector3.ZERO
		_booster_node.disconnect("booster_facing_changed", self, "_on_booster_facing_changed")
		_booster_node.disconnect("booster_ignited", self, "_on_booster_ignited")
		_booster_node.disconnect("booster_off", self, "_on_booster_off")
		_booster_node.disconnect("booster_jump", self, "_on_booster_jump")
		hat_node.remove_child(_booster_node)
		var t = _booster_node
		_booster_node = null
		return t
	return null

func add_weapon_mount(mount : Spatial) -> void:
	if _weaponmount_node == null:
		# TODO: Varify mount is what we think it is!
		_weaponmount_node = mount
		hat_node.add_child(_weaponmount_node)

func remove_weapon_mount() -> Spatial:
	if _weaponmount_node != null:
		hat_node.remove_child(_weaponmount_node)
		var t = _weaponmount_node
		_weaponmount_node = null
		return t
	return null

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


