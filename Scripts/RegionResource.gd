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
#export var region_seed : int = 571234									setget set_region_seed
#export (int, 1, 9) var octaves : int = 4								setget set_octaves
#export var period : float = 20.0										setget set_period
#export (float, 0.0, 1.0, 0.01) var persistence : float = 0.8			setget set_persistence

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
#func _BuildRegion(reset : bool = false) -> void:
#	if size > 0:
#		if reset: # If we're resetting, just empty the board.
#			_region.clear()
#			emit_signal("region_cleared")
#
#		# The center point of the board.
#		var origin : HexCell = HexCell.new()
#
#		# Let's just build the board if it's empty
#		if not _region.empty():
#			# Let's remove cells out of range...
#			for qrs in _region.keys():
#				var hex : HexCell = HexCell.new(qrs)
#				if int(hex.distance_to(origin)) > size:
#					emit_signal("region_hex_removed", hex)
#					var _res : int = _region.erase(qrs)
#
#		# Now we fill the board up, only adding cells not already there...
#		var cells = origin.get_region(size)
#		for cell in cells:
#			var new_cell : bool = not cell.qrs in _region
#			_region[cell.qrs] = (_osn.get_noise_2dv(cell.to_point() * hex_size) + 1.0) * max_height
#			if new_cell:
#				emit_signal("region_hex_added", cell)
#
#		emit_signal("region_changed")

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

