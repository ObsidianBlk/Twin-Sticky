extends Spatial
#tool

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal grid_clicked(cursor_cell, cursor_radius, alt)


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var radius : int = 100						setget set_radius
export var radius_major : int = 5					setget set_radius_major
export var hex_size : float = 1.0					setget set_hex_size
export var color_normal : Color = Color.darkgreen	setget set_color_normal
export var color_major : Color = Color.chartreuse	setget set_color_major
export var color_focus : Color = Color.cornflower	setget get_color_focus
export var target_path : NodePath = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _hex_points : Array = []
var _grid_material_normal : SpatialMaterial = null
var _grid_material_major : SpatialMaterial = null
var _grid_material_focus : SpatialMaterial = null
var _base_cell_surface : Dictionary = {}


var _alt_mode : bool = false
var _cursor_cell : HexCell = HexCell.new()
var _cursor_radius : int = 0

var _last_targ_cell : HexCell = HexCell.new()
var _target : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _basemesh_node : MeshInstance = $Base
onready var _cursormesh_node : MeshInstance = $Cursor

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_radius(r : int) -> void:
	if r > 0:
		radius = r
		_BuildMesh()

func set_radius_major(r : int) -> void:
	if r > 0:
		radius_major = r
		_UpdateGridMesh()

func set_hex_size(s : float) -> void:
	if s > 0.0:
		hex_size = s
		_BuildMesh()

func set_color_normal(c : Color) -> void:
	color_normal = c
	if _grid_material_normal == null:
		_grid_material_normal = SpatialMaterial.new()
		_grid_material_normal.flags_unshaded = true
	_grid_material_normal.albedo_color = color_normal

func set_color_major(c : Color) -> void:
	color_major = c
	if _grid_material_major == null:
		_grid_material_major = SpatialMaterial.new()
		_grid_material_major.flags_unshaded = true
	_grid_material_major.albedo_color = color_major

func get_color_focus(c : Color) -> void:
	color_focus = c
	if _grid_material_focus == null:
		_grid_material_focus = SpatialMaterial.new()
		_grid_material_focus.flags_unshaded = true
	_grid_material_focus.albedo_color = color_focus


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_grid_material_normal = SpatialMaterial.new()
	_grid_material_normal.flags_unshaded = true
	_grid_material_normal.albedo_color = color_normal
	
	_grid_material_major = _grid_material_normal.duplicate()
	_grid_material_major.albedo_color = color_major
	
	_grid_material_focus = _grid_material_normal.duplicate()
	_grid_material_focus.albedo_color = color_focus
	_BuildMesh()
	_BuildCursor()

func _unhandled_input(event : InputEvent) -> void:
	var handled : bool = false
	
	if event is InputEventKey and event.scancode == KEY_SHIFT:
		_alt_mode = event.is_pressed()
		handled = true
	elif _alt_mode:
		if event.is_action_pressed("zoom_in"):
			set_cursor_radius(_cursor_radius + 1)
			handled = true
		elif event.is_action_pressed("zoom_out"):
			set_cursor_radius(_cursor_radius - 1)
			handled = true
	else:
		if event.is_action_pressed("editor_select"):
			emit_signal("grid_clicked", _cursor_cell, _cursor_radius, false)
			handled = true
		if event.is_action_pressed("editor_select_alt"):
			emit_signal("grid_clicked", _cursor_cell, _cursor_radius, true)
			handled = true
		elif event.is_action_pressed("editor_grow_cursor"):
			set_cursor_radius(_cursor_radius + 1)
			handled = true
		elif event.is_action_pressed("editor_shrink_cursor"):
			set_cursor_radius(_cursor_radius - 1)
			handled = true
	
	if handled:
		get_tree().set_input_as_handled()


func _physics_process(_delta : float) -> void:
	var target : Spatial = _target.get_ref()
	if target != null:
		var new_targ_cell : HexCell = HexCell.new()
		new_targ_cell.from_point(Vector2(target.translation.x, target.translation.z) / hex_size)
		if not new_targ_cell.eq(_last_targ_cell):
			_last_targ_cell.qrs = new_targ_cell.qrs
			var pos : Vector2 = _last_targ_cell.to_point() * hex_size
			_basemesh_node.translation = Vector3(pos.x, 0.0, pos.y)
			_UpdateGridMesh()
	else:
		_GetTarget()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _PrepareHexPoints() -> void:
	var hc : HexCell = HexCell.new()
	if _hex_points.size() == 0:
		var point : Vector2 = Vector2(0, -1.0) if hc.orientation == 0 else Vector2(-1.0, 0)
		_hex_points.append(point)
		for i in range(1, 6):
			var p : Vector2 = point.rotated(deg2rad(60.0 * i))
			_hex_points.append(p)

func _UpdateGridMesh() -> void:
	if not _basemesh_node:
		return
	if _base_cell_surface.keys().size() <= 0:
		return
	
	var origin : HexCell = HexCell.new()
	origin.from_point3D(-_basemesh_node.translation / hex_size)
	for qrs in _base_cell_surface.keys():
		var cell : HexCell = HexCell.new(qrs)
		if int(cell.distance_to(origin)) % radius_major == 0:
			_basemesh_node.mesh.surface_set_material(_base_cell_surface[qrs], _grid_material_major)
		else:
			_basemesh_node.mesh.surface_set_material(_base_cell_surface[qrs], _grid_material_normal)

func _BuildMesh() -> void:
	if not _basemesh_node:
		return
	
	_PrepareHexPoints()
	var hc : HexCell = HexCell.new()
		
	var st : SurfaceTool = SurfaceTool.new()
	if _basemesh_node.mesh != null:
		_basemesh_node.mesh.clear_surfaces()
	_base_cell_surface.clear()
	
	var cells : Array = hc.get_region(radius)
	for cell in cells:
		_BuildHex(st, cell, hex_size, 0.96)
		if int(cell.distance_to(hc)) % radius_major == 0:
			st.set_material(_grid_material_major)
		else:
			st.set_material(_grid_material_normal)
		if _basemesh_node.mesh == null:
			_basemesh_node.mesh = st.commit()
		else:
			_basemesh_node.mesh = st.commit(_basemesh_node.mesh)
		_base_cell_surface[cell.qrs] = _basemesh_node.mesh.get_surface_count() - 1


func _BuildCursor() -> void:
	_PrepareHexPoints()
	var st : SurfaceTool = SurfaceTool.new()
	if _cursormesh_node.mesh != null:
		_cursormesh_node.mesh.clear_surfaces()
	var hc : HexCell = HexCell.new()
	var cregion : Array = [hc]
	if _cursor_radius > 0:
		cregion = hc.get_region(_cursor_radius)
	
	for cell in cregion:
		_BuildHex(st, cell, hex_size, 0.95, true)
		st.set_material(_grid_material_focus)
		if _cursormesh_node.mesh == null:
			_cursormesh_node.mesh = st.commit()
		else:
			_cursormesh_node.mesh = st.commit(_cursormesh_node.mesh)


func _BuildHex(st : SurfaceTool, cell : HexCell, size : float, hscale : float = 1.0, solid : bool = false) -> void:
	var offset : Vector2 = cell.to_point() * size
	if solid:
		st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	else:
		st.begin(Mesh.PRIMITIVE_LINE_LOOP)
	for point in _hex_points:
		var p : Vector2 = (point * size * hscale) + offset
		st.add_vertex(Vector3(p.x, 0.0, p.y))

func _GetTarget() -> void:
	if target_path != "":
		var original = _target.get_ref()
		var target = get_node_or_null(target_path)
		if original == null or original != target:
			if target is Spatial:
				_target = weakref(target)
	else:
		_target = weakref(null)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_cursor_radius(r : int) -> void:
	var nr : int = int(max(0, r))
	if nr != _cursor_radius:
		_cursor_radius = nr
		_BuildCursor()

func set_cursor_from_position(pos : Vector3) -> void:
	# Takes the given Vector3 position, converts it to a HexGridOverlay
	# HexCell position (adjusted by the current HexGridOverlay offset), and gets
	# the hex-map aligned Vector2 position
	# (converted to a Vector3, with Y set to 0)
	pos = pos - translation
	var new_cursor_cell : HexCell = HexCell.new()
	new_cursor_cell.from_point(Vector2(pos.x, pos.z) / hex_size)
	if not new_cursor_cell.qrs.is_equal_approx(_cursor_cell.qrs):
		_cursor_cell.qrs = new_cursor_cell.qrs
		var npos : Vector2 = _cursor_cell.to_point() * hex_size
		_cursormesh_node.transform.origin = Vector3(npos.x, 0.0, npos.y)

func get_cursor_world_position() -> Vector3:
	var cpos : Vector2 = _cursor_cell.to_point() * hex_size
	return Vector3(cpos.x, 0.0, cpos.y) + translation

func is_point_in_cursor(pos : Vector3) -> bool:
	var pcell : HexCell = HexCell.new()
	pcell.from_point3D(pos)
	return pcell.distance_to(_cursor_cell) <= float(_cursor_radius)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

