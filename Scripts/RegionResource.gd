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
# "Export" Variables
# ------------------------------------------------------------------------------
var _hex_size : float = 10.0
var _region : Dictionary = {}


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_hex_size(s : float) -> void:
	if s > 0.0:
		_hex_size = s
		emit_signal("hex_size_changed", _hex_size)

func set_region(r : Dictionary) -> void:
	_region.clear()
	var hc : HexCell = HexCell.new()
	for qrs in r.keys():
		if qrs is Vector3:
			hc.qrs = qrs
			if hc.is_valid():
				_region[qrs] = {"height":r[qrs].height, "id":r[qrs].id}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init() -> void:
	pass

func _get(property : String):
	match property:
		"hex_size":
			return _hex_size
		"region":
			# TODO: Return a duplicate/clone of the region dictionary
			return _region
	return null

func _set(property : String, value) -> bool:
	var success = false
	
	match property:
		"hex_size":
			if typeof(value) == TYPE_REAL:
				if value > 1.0 and value <= 20.0:
					_hex_size = value
					success = true
		"region":
			if typeof(value) == TYPE_DICTIONARY:
				set_region(value)
				success = true
	
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name = "Region Resource",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "hex_size",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "1.0, 20.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "region",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE
		}
	]
	
	return arr

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
			return _region[cell.qrs].height
	return -1

func get_id_at(cell) -> int:
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		if cell.qrs in _region:
			return _region[cell.qrs].id
	return -1

func get_cell_info_at(cell) -> Dictionary:
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		if cell.qrs in _region:
			return {
				"height":_region[cell.qrs].height,
				"id":_region[cell.qrs].id
			}
	return {"height": 0, "id":-1}

func has_cell(cell) -> bool:
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		return cell.qrs in _region
	return false

func add_cell(cell, id : int, height : int) -> void:
	if height < 0:
		return
	if not AssetDB.hex_id_exists(id):
		return
	
	cell = _CellToHexCell(cell)
	if cell is HexCell:
		var isnew : bool = not cell.qrs in _region
		_region[cell.qrs] = {"height": height, "id":id}
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

