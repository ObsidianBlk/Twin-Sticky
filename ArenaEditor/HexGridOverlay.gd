extends Spatial
tool

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var radius : int = 100						setget set_radius
export var hex_size : float = 1.0					setget set_hex_size
export var color_normal : Color = Color(0,1,0)
export var color_focus : Color = Color(1,0,0)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _grid_material_normal : SpatialMaterial = null
var _grid_material_focus : SpatialMaterial = null

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
	_grid_material_normal.albedo_color = Color(0,1,0)
	
	_grid_material_focus = _grid_material_normal.duplicate()
	_grid_material_focus.albedo_color = Color(0,0,1)
	_BuildMesh()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _BuildMesh() -> void:
	if not _basemesh_node:
		return
	print("Building Mesh")
	
	var st : SurfaceTool = SurfaceTool.new()
	if _basemesh_node.mesh != null:
		_basemesh_node.mesh.clear_surfaces()
	
	var hc : HexCell = HexCell.new()
	var cells : Array = hc.get_region(radius)
	for cell in cells:
		_BuildHex(st, cell, hex_size)
		st.set_material(_grid_material_normal)
		if _basemesh_node.mesh == null:
			_basemesh_node.mesh = st.commit()
		else:
			_basemesh_node.mesh = st.commit(_basemesh_node.mesh)
	
	if _cursormesh_node.mesh != null:
		_cursormesh_node.mesh.clear_surfaces()
	print("Cursor Size: ", hex_size)
	_BuildHex(st, hc, hex_size)
	st.set_material(_grid_material_focus)
	_cursormesh_node.mesh = st.commit()


func _BuildHex(st : SurfaceTool, cell : HexCell, size : float) -> void:
	var pos : Vector2 = cell.to_point()
	
	st.begin(Mesh.PRIMITIVE_LINE_LOOP)
	var point : Vector2 = Vector2(0, -size) if cell.orientation == 0 else Vector2(-size, 0)
	var offset : Vector2 = pos * size
	
	#st.add_color(map_data.color_normal)
	st.add_vertex(Vector3(point.x + offset.x, 0, point.y + offset.y))
	for i in range(1, 6):
		var rad = deg2rad(60 * i)
		var p = point.rotated(rad) + offset
		#st.add_color(map_data.color_normal)
		st.add_vertex(Vector3(p.x, 0, p.y))

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_cursor_from_position(pos : Vector3) -> void:
	var hc : HexCell = HexCell.new()
	hc.from_point(Vector2(pos.x, pos.z) / hex_size)
	var npos : Vector2 = hc.to_point() * hex_size
	_cursormesh_node.transform.origin = Vector3(npos.x, 0.1, npos.y)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

