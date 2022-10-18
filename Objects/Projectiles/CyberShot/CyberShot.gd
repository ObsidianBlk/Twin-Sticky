tool
extends "res://Objects/Projectiles/Projectile.gd"

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TRAIL_SIZE : int = 10

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _trail_points : Array = []


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if Engine.editor_hint:
		set_process(false)
	_trail_points.append(_last_location)

func _process(delta : float) -> void:
	if _TrailUpdated():
		pass

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _TrailUpdated() -> bool:
	if _trail_points.size() <= 0 or _last_location != _trail_points[_trail_points.size() - 1]:
		_trail_points.append(_last_location)
		if _trail_points.size() > TRAIL_SIZE:
			_trail_points.pop_front()
		return true
	return false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_class() -> String:
	return "CyberShot"
