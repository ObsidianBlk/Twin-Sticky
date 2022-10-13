extends Spatial


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const MODEL_BASE_SIZE : float = 1.0

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var region_resource : Resource = null						setget set_region_resource
export var hex_id : int = 0
export var qrs : Vector3 = Vector3.ZERO								setget set_qrs
export var size : float = 20.0										setget set_size
export var height : int = 0.0										setget set_height


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _origin : HexCell = HexCell.new()
var _hexes : Array = []

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------

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
			_UpdateHeight()
			_UpdateScale()

func set_hex_id(id : int) -> void:
	if id >= 0 and AssetDB.hex_id_exists(id):
		hex_id = id
		for i in range(_hexes.size()):
			remove_child(_hexes[i])
			_hexes[i].queue_free()
		_hexes = AssetDB.get_hexes_by_id(hex_id, 1)

func set_qrs(_qrs : Vector3) -> void:
	qrs = _qrs
	_origin = HexCell.new(qrs)
	_UpdatePosition()

func set_size(s : float) -> void:
	if s > 0.0:
		size = s
		_UpdateScale()

func set_height(h : int) -> void:
	if h >= 0 and h != height:
		height = h
		_UpdateHeight()

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_UpdatePosition()
	_UpdateHeight()


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdateHeight() -> void:
	if height+1 < _hexes.size():
		for i in range(_hexes.size() - 1, height, -1):
			remove_child(_hexes[i])
			_hexes[i].queue_free()
			_hexes.pop_back()
		var top : Spatial = _hexes[_hexes.size() - 1].get_node_or_null("top")
		if top != null:
			top.visible = true
	elif height+1 > _hexes.size():
		var new_hexes : Array = AssetDB.get_multiple_by_db_id("HEX", hex_id, (height + 1) - _hexes.size())
		if new_hexes.size() > 0:
			var top : Spatial = null
			if _hexes.size() > 0:
				top = _hexes[_hexes.size() - 1].get_node_or_null("top")
			if top != null:
				top.visible = false
			
			var s : float = size / MODEL_BASE_SIZE
			for nhex in new_hexes:
				var nheight : float  = float(_hexes.size()) * size
				nhex.scale = Vector3(s,s,s)
				nhex.translation = Vector3(0, nheight, 0)
				top = nhex.get_node_or_null("top")
				if top != null:
					top.visible = false
				add_child(nhex)
				_hexes.append(nhex)
			top = _hexes[_hexes.size() - 1].get_node_or_null("top")
			if top != null:
				top.visible = true
			_UpdateHighlight()

func _UpdateHighlight() -> void:
	if _hexes.size() <= 1:
		return
	var top = _hexes[0].get_node_or_null("Top")
	if top is MeshInstance:
		var mat : Material = top.material_overlay
		for i in range(1, _hexes.size()):
			top = _hexes[i].get_node_or_null("Top")
			if top is MeshInstance:
				top.material_overlay = mat
			var side = _hexes[i].get_node_or_null("Side")
			if side is MeshInstance:
				side.material_overlay = mat

func _UpdatePosition() -> void:
	var pos : Vector2 = _origin.to_point() * size
	transform.origin = Vector3(pos.x, 0.0, pos.y)

func _UpdateScale() -> void:
	var s : float = size / MODEL_BASE_SIZE
	var nscale : Vector3 = Vector3(s,s,s)
	for i in range(_hexes.size()):
		_hexes[i].scale = nscale
		var nheight : float  = float(i) * size
		_hexes[i].translation = Vector3(0, nheight, 0)
		

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func release() -> void:
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()

func is_highlighted() -> bool:
	if _hexes.size() > 0:
		var top = _hexes[0].get_node_or_null("Top")
		if top is MeshInstance:
			return top.material_overlay != null
	return false

func highlight(mat : Material) -> void:
	if _hexes.size() <= 0:
		return
	var cur_enabled : bool = is_highlighted()
	if cur_enabled != (mat != null): # I know this looks weird... go with it!
		for hex in _hexes:
			var top = hex.get_node_or_null("Top")
			if top is MeshInstance:
				top.material_overlay = mat
			var side = hex.get_node_or_null("Side")
			if side is MeshInstance:
				side.material_overlay = mat

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_region_cleared() -> void:
	release()

func _on_region_changed() -> void:
	set_height(region_resource.get_height_at(_origin))

func _on_region_hex_removed(hex_cell : HexCell) -> void:
	if _origin.eq(hex_cell):
		release()

func _on_hex_size_changed(hex_size : float) -> void:
	set_size(hex_size)

