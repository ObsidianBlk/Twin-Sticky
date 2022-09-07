extends Spatial


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const MODEL_BASE_SIZE : float = 1.0

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var region_resource : Resource = null						setget set_region_resource
export var qrs : Vector3 = Vector3.ZERO								setget set_qrs
export var size : float = 20.0										setget set_size
export var height : float = 0.0										setget set_height


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _origin : HexCell = HexCell.new()

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var hex_node : Spatial = $Default

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
			var _res : int = region_resource.connect("region_cleared", self, "_on_region_cleared")
			_res = region_resource.connect("region_changed", self, "_on_region_changed")
			_res = region_resource.connect("region_hex_removed", self, "_on_region_hex_removed")
			_res = region_resource.connect("hex_size_changed", self, "_on_hex_size_changed")
			size = region_resource.hex_size
			height = region_resource.get_height_at(_origin)
			_UpdatePosition()
			_UpdateScale()


func set_qrs(_qrs : Vector3) -> void:
	qrs = _qrs
	_origin = HexCell.new(qrs)
	_UpdatePosition()

func set_size(s : float) -> void:
	if s > 0.0:
		size = s
		_UpdateScale()

func set_height(h : float) -> void:
	if h >= 0.0:
		height = h
		_UpdatePosition()

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_UpdateScale()


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdatePosition() -> void:
	var pos : Vector2 = _origin.to_point() * size
	transform.origin = Vector3(pos.x, height, pos.y)

func _UpdateScale() -> void:
	var s : float = size / MODEL_BASE_SIZE
	if Engine.editor_hint and not hex_node:
		hex_node = $Hex_Model
	if hex_node:
		hex_node.scale = Vector3(s, 1.0, s)

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
		_UpdatePosition()

func _on_region_hex_removed(hex_cell : HexCell) -> void:
	if _origin.eq(hex_cell):
		release()

func _on_hex_size_changed(hex_size : float) -> void:
	set_size(hex_size)

