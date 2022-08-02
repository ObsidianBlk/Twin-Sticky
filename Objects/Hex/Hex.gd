extends Spatial
tool

# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
const RAD_60DEG : float = deg2rad(60.0)

enum ORIENTATION {Pointy=0, Flat=1}

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var region_resource : Resource = null						setget set_region_resource
export var qrs : Vector3 = Vector3.ZERO								setget set_qrs
export (ORIENTATION) var orientation : int = ORIENTATION.Pointy		setget set_orientation
export var size : float = 20.0										setget set_size
export var height : float = 0.0										setget set_height
export var color : Color = Color.burlywood							setget set_color

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _origin : HexCell = HexCell.new()

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var meshinst_node : MeshInstance = $MeshInstance


# -----------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------
func set_region_resource(r : Resource) -> void:
	if r == null or r is RegionResource:
		if region_resource != null:
			region_resource.disconnect("region_cleared", self, "_on_region_cleared")
			region_resource.disconnect("region_changed", self, "_on_region_changed")
			region_resource.disconnect("region_hex_removed", self, "_on_region_hex_removed")
			region_resource.disconnect("hex_size_changed", self, "_on_hex_size_changed")
		region_resource = r
		if region_resource != null:
			region_resource.connect("region_cleared", self, "_on_region_cleared")
			region_resource.connect("region_changed", self, "_on_region_changed")
			region_resource.connect("region_hex_removed", self, "_on_region_hex_removed")
			region_resource.connect("hex_size_changed", self, "_on_hex_size_changed")
			size = region_resource.hex_size
			height = region_resource.get_height_at(_origin)
			#print("My Height: ", height)
			_UpdatePosition()
			_Rebuild()


func set_qrs(_qrs : Vector3) -> void:
	qrs = _qrs
	_origin = HexCell.new(qrs)
	_UpdatePosition()
	


func set_orientation(o : int) -> void:
	if ORIENTATION.values().find(o) >= 0:
		orientation = o
		_Rebuild()


func set_size(s : float) -> void:
	if s > 0.0:
		size = s
		_Rebuild()
		_UpdatePosition()

func set_height(h : float) -> void:
	if h >= 0.0:
		height = h
		_Rebuild()

func set_color(c : Color) -> void:
	color = c
	_Rebuild()


# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_Rebuild()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdatePosition() -> void:
	var pos : Vector2 = _origin.to_point() * size
	transform.origin = Vector3(pos.x, 0.0, pos.y)


func _ClearCollisions() -> void:
	if Engine.editor_hint:
		return
	
	for child in meshinst_node.get_children():
		if child is StaticBody:
			meshinst_node.remove_child(child)
			child.queue_free()


func _AddWall(st : SurfaceTool, p1 : Vector3, p2 : Vector3):
	var rot : float = 30.0 if height >= 0.0 else 210.0
	var norm_dir = Vector2.ZERO.direction_to(Vector2(p1.x, p1.z)).rotated(deg2rad(rot))
	var norm : Vector3 = Vector3(norm_dir.x, 0.0, norm_dir.y)
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	st.add_color(color)
	st.add_uv2(Vector2(0.0, 0.0))
	st.add_normal(norm)
	st.add_vertex(p1)
	
	st.add_color(color)
	st.add_uv2(Vector2(0.0, 1.0))
	st.add_normal(norm)
	st.add_vertex(Vector3(p1.x, 0.0, p1.z))
	
	st.add_color(color)
	st.add_uv2(Vector2(1.0, 0.0))
	st.add_normal(norm)
	st.add_vertex(p2)
	
	st.add_color(color)
	st.add_uv2(Vector2(1.0, 1.0))
	st.add_normal(norm)
	st.add_vertex(Vector3(p2.x, 0.0, p2.z))


func _Rebuild() -> void:
	if not meshinst_node:
		return
	
	_ClearCollisions()
	var st : SurfaceTool = SurfaceTool.new()
	var mesh : ArrayMesh = null
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var verts : Array = [Vector3(0.0, height, 0.0)]
	var colors : Array = PoolColorArray([color, color, color, color, color, color, color, color])
	var norms : Array = PoolVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var uv : Array = [Vector2(0.5, 0.5)]
	
	var point : Vector2 = Vector2(0.0, 1.0)
	if orientation == ORIENTATION.Flat:
		point = point.rotated(deg2rad(30.0))
	for _i in range(6):
		verts.append(Vector3(point.x * size, height, point.y * size))
		uv.append(point)
		point = point.rotated(RAD_60DEG)
	
	verts.append(verts[1])
	uv.append(uv[1])
	
	st.add_triangle_fan(PoolVector3Array(verts), PoolVector2Array(uv), colors, PoolVector2Array(uv), norms)
	mesh = st.commit()
	
	# Let's build some walls
	if height != 0.0:
		for idx in range(1, verts.size()):
			var p1 = verts[idx]
			var p2 = verts[1]
			if idx+1 < verts.size():
				p2 = verts[idx + 1]
			_AddWall(st, p1, p2)
			mesh = st.commit(mesh)
	
	meshinst_node.mesh = mesh
	if not Engine.editor_hint:
		meshinst_node.create_convex_collision(true)
		#meshinst_node.create_trimesh_collision()

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func release() -> void:
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()


# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_region_cleared() -> void:
	release()

func _on_region_changed() -> void:
	var nheight : float = region_resource.get_height_at(_origin)
	if nheight != height:
		_Rebuild()

func _on_region_hex_removed(hex_cell : HexCell) -> void:
	if _origin.eq(hex_cell):
		release()

func _on_hex_size_changed(hex_size : float) -> void:
	set_size(hex_size)

