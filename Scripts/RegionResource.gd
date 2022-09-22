extends Resource
class_name RegionResource


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal region_cleared()
signal region_changed()
signal region_hex_removed(cell)
signal region_hex_added(cell)
signal hex_size_changed(size)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var hex_size : float = 10.0										setget set_hex_size


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _region : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_hex_size(s : float) -> void:
	if s > 0.0:
		hex_size = s
		emit_signal("hex_size_changed", hex_size)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init() -> void:
	pass



# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _CellToHexCell(cell) -> HexCell:
	if typeof(cell) == TYPE_VECTOR3:
		cell = HexCell.new(cell)
	if cell is HexCell:
		return cell
	return null

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func empty() -> bool:
	return _region.empty()

func get_size() -> int:
	return _region.keys().size()

func get_cells() -> PoolVector3Array:
	return PoolVector3Array(_region.keys())

func get_height_at(cell) -> int:
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		if cell.qrs in _region:
			return _region[cell.qrs]
	return -1

func has_cell(cell) -> bool:
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		return cell.qrs in _region
	return false

func add_cell(cell, height : int) -> void:
	if height < 0:
		return
	
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		var isnew : bool = not cell.qrs in _region
		_region[cell.qrs] = height
		if isnew:
			emit_signal("region_hex_added", cell)
		emit_signal("region_changed")

func remove_cell(cell) -> void:
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		if cell.qrs in _region:
			_region.erase(cell.qrs)
			emit_signal("region_hex_removed", cell)
		if _region.empty():
			emit_signal("region_cleared")

func clear() -> void:
	_region.clear()
	emit_signal("region_cleared")

