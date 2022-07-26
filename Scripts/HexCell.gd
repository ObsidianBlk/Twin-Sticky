extends Reference
tool
class_name HexCell

# Based on information at...
# https://www.redblobgames.com/grids/hexagons/

# -------------------------------------------------------------------------
# Constants and ENUMs
# -------------------------------------------------------------------------
const SQRT3 : float = sqrt(3)
const NEIGHBOR_OFFSET : Array = [
	Vector3(0, -1, 1),
	Vector3(-1, 0, 1),
	Vector3(-1, 1, 0),
	Vector3(0, 1, -1),
	Vector3(1, 0, -1),
	Vector3(1, -1, 0)
]

enum ORIENTATION {Pointy=0, Flat=1}

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var c : Vector3 = Vector3.ZERO
var _orientation : int = ORIENTATION.Pointy

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _init(value = null, point_is_spacial : bool = false, orientation : int = -1) -> void:
	if ORIENTATION.values().find(orientation) >= 0:
		_orientation = orientation
	
	if typeof(value) == TYPE_OBJECT and value.has_method("is_valid") and value.is_valid():
		c = value.qrs
	elif typeof(value) == TYPE_VECTOR3:
		c = value
		round_hex()
	elif typeof(value) == TYPE_VECTOR2:
		if point_is_spacial:
			from_point(value)
		else:
			c = Vector3(value.x, -value.x -value.y, value.y)

func _get(property : String):
	match property:
		"q":
			return c.x
		"r":
			return c.z
		"s":
			return c.y
		"qrs":
			return c
		"qr":
			return Vector2(c.x, c.z)
		"orientation":
			return _orientation
	return null


func _set(property : String, value) -> bool:
	var success : bool = true
	
	match property:
		"q":
			if typeof(value) == TYPE_REAL:
				c.x = value
			else : success = false
		"r":
			if typeof(value) == TYPE_REAL:
				c.z = value
			else : success = false
		"s":
			if typeof(value) == TYPE_REAL:
				c.y = value
			else : success = false
		"qrs":
			if typeof(value) == TYPE_VECTOR3:
				c = value
			elif typeof(value) == TYPE_OBJECT and value.has_method("round_hex"):
				c.x = value.q
				c.z = value.r
				c.y = value.s
			else : success = false
		"qr":
			if typeof(value) == TYPE_VECTOR2:
				c.x = value.x
				c.z = value.y
				c.y = (-c.x)-c.z
		"orientation":
			if typeof(value) == TYPE_INT and ORIENTATION.values().find(value) >= 0:
				_orientation = value
			else : success = false
	
	if success:
		property_list_changed_notify()
	return success


func _get_property_list() -> Array:
	var props : Array = [
		{
			name = "q",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_NO_INSTANCE_STATE
		},
		{
			name = "r",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_NO_INSTANCE_STATE
		},
		{
			name = "s",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_NO_INSTANCE_STATE
		},
		{
			name = "qrs",
			type = TYPE_VECTOR3,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "qr",
			type = TYPE_VECTOR2,
			usage = PROPERTY_USAGE_NO_INSTANCE_STATE
		},
		{
			name = "orientation",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		}
	]
	return props

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _CellLerp(a : HexCell, b : HexCell, t : float) -> HexCell:
	var q = lerp(a.q, b.q, t)
	var r = lerp(a.r, b.r, t)
	var s = lerp(a.s, b.s, t)
	return get_script().new(Vector3(q, s, r))

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func is_valid() -> bool:
	return c.x + c.y + c.z == 0

func clone() -> HexCell:
	return get_script().new(c)

func eq(v, point_is_spacial : bool = false) -> bool:
	if typeof(v) == TYPE_OBJECT and v.has_method("is_valid"):
		return c == v.qrs
	elif typeof(v) == TYPE_VECTOR3:
		return c == v
	elif typeof(v) == TYPE_VECTOR2:
		if point_is_spacial:
			return to_point() == v
		else:
			return c == Vector3(v.x, -v.x-v.y, v.y)
	return false

func round_hex() -> void:
	var q = round(c.x)
	var r = round(c.z)
	var s = round(c.y)
	
	var dq = abs(c.x - q)
	var dr = abs(c.z - r)
	var ds = abs(c.y - s)
	
	if dq > dr and dq > ds:
		q = -r -s
	elif dr > ds:
		r = -q -s
	else:
		s = -q -r
	
	c.x = q
	c.z = r
	c.y = s


func distance_to(cell : HexCell) -> float:
	if is_valid() and cell != null and cell.is_valid():
		var subc : Vector3 = c - cell.qrs
		return (abs(subc.x) + abs(subc.y) + abs(subc.z)) * 0.5
	return 0.0

func to_point() -> Vector2:
	var x : float = 0.0
	var y : float = 0.0
	if is_valid():
		match _orientation:
			ORIENTATION.Pointy:
				#var x = size * (sqrt(3) * hex.q  +  sqrt(3)/2 * hex.r)
				#var y = size * (                         3./2 * hex.r)
				x = (SQRT3 * c.x) + ((SQRT3 * 0.5) * c.z)
				y = 1.5 * c.z
			ORIENTATION.Flat:
				#var x = size * (     3./2 * hex.q                    )
				#var y = size * (sqrt(3)/2 * hex.q  +  sqrt(3) * hex.r)
				x = 1.5 * c.x
				y = ((SQRT3 * 0.5) * c.x) + (SQRT3 * c.z)
	return Vector2(x,y)

func from_point(point : Vector2) -> void:
	var fq : float = 0.0
	var fr : float = 0.0
	match _orientation:
		ORIENTATION.Pointy:
			fq = ((SQRT3/3.0) * point.x) - ((1.0/3.0) * point.y)
			fr = (2.0/3.0) * point.y
		ORIENTATION.Flat:
			fq = (2.0/3.0) * point.x
			fr = ((-1.0/3.0) * point.x) + ((SQRT3/3.0) * point.y)
	var fs : float = -fq -fr
	c = Vector3(fq, fs, fr)
	round_hex()



func get_neighbor(dir : int, amount : int = 1) -> HexCell:
	if is_valid() and amount > 0:
		if dir >= 0 and dir < NEIGHBOR_OFFSET.size():
			var vh : HexCell = get_script().new(c + (NEIGHBOR_OFFSET[dir] * float(amount)))
			return vh
	return null

func get_region(rng : int) -> Array:
	var res : Array = []
	for q in range(-rng, rng+1):
		for r in range(max(-rng, -q-rng), min(rng, -q+rng) + 1):
			print("QR: ", q, ", ", r)
			var s = -q-r
			res.append(get_script().new(Vector3(q + c.x, s + c.y, r + c.z)))
	return res

func get_ring(rng : int) -> Array:
	var res : Array = []
	var cell = get_neighbor(4, rng)
	for i in range(0, 6):
		for _j in range(rng):
			res.append(cell)
			cell = cell.get_neighbor(i)
	return res

func get_line_to_cell(cell : HexCell) -> Array:
	var res : Array = []
	if cell.is_valid():
		var dist = distance_to(cell)
		for i in range(0, dist):
			var ncell = _CellLerp(self, cell, i/dist)
			print("Valid Cell: ", ncell.is_valid(), " | qrs: ", ncell.qrs)
			res.append(ncell)
	return res

func get_line_to_point(point : Vector2) -> Array:
	var ecell = get_script().new(point, true)
	return get_line_to_cell(ecell)


