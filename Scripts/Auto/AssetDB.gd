extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const HEX : Dictionary = {
	"Default": "res://Objects/Hex/HexTypes/Default.tscn"
}


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_hex_by_name(hex_name : String) -> Spatial:
	if hex_name in HEX:
		var scene = load(HEX[hex_name])
		if scene is PackedScene:
			var node = scene.instance()
			if node is Spatial:
				return node
			node.queue_free()
	return null

func get_hexes_by_name(hex_name : String, amount : int) -> Array:
	var res : Array = []
	if amount > 0 and hex_name in HEX:
		var scene = load(HEX[hex_name])
		if scene is PackedScene:
			for _i in range(amount):
				res.append(scene.instance())
	return res

func get_hex_by_id(id : int) -> Spatial:
	if id >= 0 and id < HEX.size():
		return get_hex_by_name(HEX.keys()[id])
	return null

func get_hexes_by_id(id : int, amount : int) -> Array:
	if id >= 0 and id < HEX.size():
		return get_hexes_by_name(HEX.keys()[id], amount)
	return []

func hex_name_exists(hex_name : String) -> bool:
	return hex_name in HEX

func hex_id_exists(id : int) -> bool:
	return id >= 0 and id < HEX.size()
