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

onready var _ui : CanvasLayer = $UI
onready var _radialmenu : Popup = $UI/RadialMenu

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_region_resource = RegionResource.new()
	var _res : int = _hex_grid_overlay.connect("grid_clicked", self, "_on_grid_clicked")
	_hex_grid_overlay.hex_size = _region_resource.hex_size
	_hex_region.region_resource = _region_resource


func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not _orbit_enabled:
			_UpdateMouseCursor(event.position)
	else:
		if event.is_action_pressed("ui_cancel"):
			emit_signal("editor_exited")
		if event.is_action_pressed("editor_menu"):
			_radialmenu.popup_centered()
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
		_hex_region.set_highlight_color(_hex_grid_overlay.color_focus)
		_hex_region.highlight_cells(_hex_grid_overlay.get_cursor_region())


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
					_region_resource.add_cell(ccell, 0, height)
				else:
					_region_resource.remove_cell(ccell)
		else:
			if _region_resource.has_cell(ccell):
				height = _region_resource.get_height_at(ccell) + 1
			if height >= 0:
				_region_resource.add_cell(ccell, 0, height)


func _on_save_file_selected(path : String) -> void:
	var res : int = ResourceSaver.save(path, _region_resource)
	if res != OK:
		Log.error("Failed to save arena map to \"%s\". Error code %s"%[path, res])

func _on_load_file_selected(path : String) -> void:
	var new_resource = ResourceLoader.load(path)
	if new_resource is RegionResource:
		_region_resource = new_resource
		_hex_grid_overlay.hex_size = _region_resource._hex_size
		_hex_region.region_resource = _region_resource
	else:
		Log.error("Failed to load arena map \"%s\"."%[path]) 

func _on_NewArena_pressed():
	_region_resource = RegionResource.new()
	_hex_grid_overlay.hex_size = _region_resource.hex_size
	_hex_region.region_resource = _region_resource
	_radialmenu.hide()


func _on_SaveArena_pressed():
	if _region_resource == null:
		return
	if _region_resource.empty():
		return
	_radialmenu.hide()
	var fd : FileDialog = FileDialog.new()
	fd.add_filter("*.tres ; Map Resource")
	fd.access = FileDialog.ACCESS_USERDATA
	_ui.add_child(fd)
	var _res : int = fd.connect("file_selected", self, "_on_save_file_selected")
	_res = fd.connect("popup_hide", self, "_on_close_file_dialog", [fd])
	fd.popup_centered(Vector2(640,480))

func _on_LoadArena_pressed():
	_radialmenu.hide()
	var fd : FileDialog = FileDialog.new()
	fd.mode = FileDialog.MODE_OPEN_FILE
	fd.add_filter("*.tres ; Map Resource")
	fd.access =FileDialog.ACCESS_USERDATA
	_ui.add_child(fd)
	var _res : int = fd.connect("file_selected", self, "_on_load_file_selected")
	_res = fd.connect("popup_hide", self, "_on_close_file_dialog", [fd])
	fd.popup_centered(Vector2(640, 480))
	

func _on_close_file_dialog(fd : FileDialog) -> void:
	if fd != null:
		print("Removing file dialog")
		_ui.remove_child(fd)
		fd.queue_free()
