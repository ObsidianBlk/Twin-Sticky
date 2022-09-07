extends Spatial


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal editor_exited()


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _orbit_enabled : bool = false


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _camera : Spatial = $GimbleCamera
onready var _hex_grid_overlay : Spatial = $HexGridOverlay

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		emit_signal("editor_exited")
	if event is InputEventMouseMotion:
		if not _orbit_enabled:
			_UpdateMouseCursor(event.position)
	elif event is InputEventMouseButton:
		if event.is_action("orbit_enable"):
			_orbit_enabled = event.is_action_pressed("orbit_enabled")
	else:
		pass


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateMouseCursor(mouse_position : Vector2) -> void:
	if not _camera:
		return
	
	var p : Plane = Plane(Vector3.UP, 0.0)
	var from : Vector3 = _camera.project_ray_origin(mouse_position)
	var dir : Vector3 = _camera.project_ray_normal(mouse_position)
	var intersect = p.intersects_ray(from, dir)
	if intersect != null:
		_hex_grid_overlay.set_cursor_from_position(intersect)


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

