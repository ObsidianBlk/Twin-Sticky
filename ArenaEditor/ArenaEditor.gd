extends Spatial


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal editor_exited()


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const NON_MOUSE_MOVEMENT_ACTIONS : Array = [
	"orbit_up",
	"orbit_down",
	"orbit_left",
	"orbit_right",
	"booster_forward",
	"booster_backward",
	"booster_left",
	"booster_right"
]

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _region_resource : RegionResource = null
var _orbit_enabled : bool = false
var _non_mouse_move : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _camera : Spatial = $GimbleCamera
onready var _hex_grid_overlay : Spatial = $HexGridOverlay
onready var _hex_region : Spatial = $HexRegion

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_region_resource = RegionResource.new()
	_hex_grid_overlay.connect("grid_clicked", self, "_on_grid_clicked")
	_hex_grid_overlay.hex_size = _region_resource.hex_size
	_hex_region.region_resource = _region_resource
	$UI/RadialMenu.popup_centered()


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		emit_signal("editor_exited")
	if event is InputEventMouseMotion:
		if not _orbit_enabled:
			_UpdateMouseCursor(event.position)
	elif event is InputEventMouseButton:
		if event.is_action("orbit_enable"):
			_orbit_enabled = event.is_action_pressed("orbit_enable")
	else:
		_non_mouse_move = _IsEventNonMouseMovement()

func _physics_process(_delta : float) -> void:
	if _non_mouse_move:
		_UpdateJoypadCursor()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _IsEventNonMouseMovement() -> bool:
	for action_name in NON_MOUSE_MOVEMENT_ACTIONS:
		var strength : float = Input.get_action_strength(action_name)
		if strength != 0.0:
			return true
	return false


func _UpdateMouseCursor(mouse_position : Vector2) -> void:
	if not _camera:
		return
	
	var p : Plane = Plane(Vector3.UP, 0.0)
	var from : Vector3 = _camera.project_ray_origin(mouse_position)
	var dir : Vector3 = _camera.project_ray_normal(mouse_position)
	var intersect = p.intersects_ray(from, dir)
	if intersect != null:
		_hex_grid_overlay.set_cursor_from_position(intersect)


func _UpdateJoypadCursor() -> void:
	if not _camera:
		return
	_UpdateMouseCursor(get_tree().get_root().size * 0.5)
	


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_grid_clicked(cell : HexCell, radius : int, alt : bool) -> void:
	if _region_resource == null:
		return
	
	var cells = [cell]
	if radius > 0:
		cells = cell.get_region(radius)
	
	for ccell in cells:
		var height : int = 0
		if alt:
			if _region_resource.has_cell(ccell):
				height = _region_resource.get_height_at(ccell) - 1
				if height >= 0:
					_region_resource.add_cell(ccell, height)
				else:
					_region_resource.remove_cell(ccell)
		else:
			if _region_resource.has_cell(ccell):
				height = _region_resource.get_height_at(ccell) + 1
			if height >= 0:
				_region_resource.add_cell(ccell, height)




func _on_Test_pressed():
	print("Test Radial Button Pressed")
