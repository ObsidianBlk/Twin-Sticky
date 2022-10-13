extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DB : Dictionary = {
	"HEX": {
		"Default": "res://Objects/Hex/HexTypes/Default.tscn"
	},
	"WEAPONS":{
		"SHOTTY" : "res://Objects/TrackBot/Weapons/Jank_Shotty/Jank_Shotty.tscn",
		"PLASMA" : "res://Objects/TrackBot/Weapons/Jank_Plasma/Jank_Plasma.tscn",
		"CyberShotgun": "res://Objects/TrackBot/Weapons/CyberShotgun/CyberShotgun.tscn"
	},
	"PROJECTILES":{
		"PlasmaBullet": "res://Objects/Projectiles/PlasmaBullet/PlasmaBullet.tscn",
	}
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active_db : String = "HEX"


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SplitName(key_name : String) -> Array:
	var items : Array = key_name.split(".")
	if items.size() > 0 and items.size() < 3:
		if items.size() == 1:
			return [_active_db, items[0]]
		else:
			if items[0] in DB:
				return items
			else:
				printerr("Database \"", items[0], "\" does not exist.")
				
	else:
		printerr("Database key \"", key_name, "\" is invalid.")
	return [_active_db, ""]

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_databases() -> Array:
	return DB.keys()

func set_active_db(db_name : String) -> void:
	if db_name in DB:
		_active_db = db_name

func get_active_db() -> String:
	return _active_db

func get_by_name(key_name : String) -> Spatial:
	var keys : Array = _SplitName(key_name)
	var db_name = keys[0]
	var item_name = keys[1]
	
	if item_name in DB[db_name]:
		var scene = load(DB[db_name][item_name])
		if scene is PackedScene:
			var node = scene.instance()
			if node is Spatial:
				return node
			node.queue_free()
	return null

func get_multiple_by_name(key_name : String, amount : int) -> Array:
	if amount <= 0:
		return []
	
	var keys : Array = _SplitName(key_name)
	var db_name = keys[0]
	var item_name = keys[1]
	
	var res : Array = []
	if item_name in DB[db_name]:
		var scene = load(DB[db_name][item_name])
		if scene is PackedScene:
			for _i in range(amount):
				var node = scene.instance()
				if node is Spatial:
					res.append(node)
				else:
					node.queue_free()
	return res

func get_by_db_id(db_name : String, id : int) -> Spatial:
	if db_name in DB:
		var keys : Array = DB[db_name].keys()
		if id >= 0 and id < keys.size():
			return get_by_name("%s.%s"%[db_name, keys[id]])
	return null

func get_multiple_by_db_id(db_name : String, id : int, amount : int) -> Array:
	var res : Array = []
	if db_name in DB:
		var keys : Array = DB[_active_db].keys()
		if id >= 0 and id < keys.size():
			return get_multiple_by_name("%s.%s"%[db_name, keys[id]], amount)
	return res

func get_by_id(id : int) -> Spatial:
	var keys : Array = DB[_active_db].keys()
	if id >= 0 and id < keys.size():
		return get_by_name("%s.%s"%[_active_db, keys[id]])
	return null

func get_multiple_by_id(id : int, amount : int) -> Array:
	var keys : Array = DB[_active_db].keys()
	if id >= 0 and id < keys.size():
		return get_multiple_by_name("%s.%s"%[_active_db, keys[id]], amount)
	return []

func key_exists(key_name : String) -> bool:
	var keys : Array = _SplitName(key_name)
	var db_name : String = keys[0]
	var item_name : String = keys[1]
	return item_name in DB[db_name]
