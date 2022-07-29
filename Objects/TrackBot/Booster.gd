extends KinematicBody

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal booster_facing_changed(facing)
signal booster_ignited(power)
signal booster_off()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BOOST_POWER_THRESHOLD : float = 0.001

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var strength : float = 10.0					setget set_strength
export var dps : float = 90.0						setget set_dps

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target_facing : Vector3 = Vector3.ZERO
var _active : bool = false
var _tween : Tween = null

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

func set_dps(_dps : float) -> void:
	if _dps > 0.0:
		dps = 0.0

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_tween = Tween.new()
	add_child(_tween)
	_tween.connect("tween_all_completed", self, "_on_facing_complete")

func _physics_process(delta : float) -> void:
	if transform.basis.z != _target_facing:
		emit_signal("booster_facing_changed", transform.basis.z)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetFacingStrength() -> Vector3:
	return transform.basis.z * strength

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_facing(facing : Vector3) -> void:
	_tween.remove_all()
	_active = false
	_target_facing = Vector3(facing.x, 0.0, facing.z)
	transform.basis.z = _target_facing
	emit_signal("booster_facing_changed", transform.basis.z)

func get_facing() -> Vector3:
	return transform.basis.z

func face(facing : Vector3) -> void:
	_target_facing = Vector3(0.0, facing.y, 0.0)
	var rps = deg2rad(dps)
	if rps > 0.0:
		var angle = transform.basis.z.angle_to(_target_facing)
		var duration = abs(angle / rps)
		_tween.remove_all()
		_tween.interpolate_property(
			self, "transform.basis.z",
			transform.basis.z, _target_facing,
			duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_tween.start()

func rotate_facing_degrees(angle : float) -> void:
	face(transform.basis.z.rotated(Vector3.UP, deg2rad(angle)))

func boost(amount : float) -> void:
	amount = max(0.0, min(1.0, amount))
	if amount < BOOST_POWER_THRESHOLD:
		_active = false
		emit_signal("booster_off")
	else:
		_active = true
		emit_signal("booster_ignited", strength * amount)

func is_boosting() -> bool:
	return _active

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_facing_complete() -> void:
	transform.basis.z = _target_facing # Just to be sure
	emit_signal("booster_facing_changed", transform.basis.z)
