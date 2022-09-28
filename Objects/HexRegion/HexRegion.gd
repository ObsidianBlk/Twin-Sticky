extends Spatial


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const HIGHLIGHT_MATERIAL : SpatialMaterial = preload("res://Objects/Hex/highlight.material")
const HEX : PackedScene = preload("res://Objects/Hex/Hex.tscn")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var region_resource : Resource = null		setget set_region_resource

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var hex_container_node : Spatial = $Hexes

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_region_resource(r : Resource) -> void:
	if r == null or r is RegionResource:
		if region_resource != null:
			region_resource.disconnect("region_hex_added", self, "_on_region_hex_added")
			clear()
		region_resource = r
		if region_resource != null:
			var _res : int = region_resource.connect("region_hex_added", self, "_on_region_hex_added")
			_Build()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_Build()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _Build() -> void:
	if region_resource != null and not region_resource.empty():
		var cells = region_resource.get_cells()
		for qrs in cells:
			_on_region_hex_added(HexCell.new(qrs))

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	if not hex_container_node:
		return
	
	for child in hex_container_node.get_children():
		hex_container_node.remove_child(child)
		child.queue_free()

func set_highlight_color(c : Color) -> void:
	HIGHLIGHT_MATERIAL.albedo_color = Color(c.r, c.g, c.b, 0.5)

func highlight(qrs : Vector3) -> void:
	for child in hex_container_node.get_children():
		child.highlight(HIGHLIGHT_MATERIAL if child.qrs.eq(qrs) else null)

func highlight_cells(cells : Array) -> void:
	for child in hex_container_node.get_children():
		var enable : bool = false
		for cell in cells:
			if cell.eq(child.qrs):
				enable = true
		child.highlight(HIGHLIGHT_MATERIAL if enable else null)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_region_hex_added(hex_cell : HexCell) -> void:
	if not hex_container_node:
		return
	
	var hex : Spatial = HEX.instance()
	hex_container_node.add_child(hex)
	hex.qrs = hex_cell.qrs
	hex.region_resource = region_resource


