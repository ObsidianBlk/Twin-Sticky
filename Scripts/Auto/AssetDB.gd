extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DB : Dictionary = {
	"HEX": {
		"Default": {
			"res": "res://Objects/Hex/HexTypes/Default.tscn",
			"scene": null
		}
	},
	"TRACKBOTS":{
		"CyberSmiley": {
			"res": "res://Assets/Models/Trackballs/CyberSmiley/CyberSmiley.tscn",\
			"scene": null
		}
	},
	"WEAPONMOUNTS":{
		"CyberSmiley": {
			"res": "res://Objects/TrackBot/WeaponMount/WM_CyberSmiley.tscn",
			"scene": null
		}
	},
	"WEAPONS":{
		"SHOTTY" : {
			"res": "res://Objects/TrackBot/Weapons/Jank_Shotty/Jank_Shotty.tscn",
			"scene": null
		},
		"PLASMA" : {
			"res": "res://Objects/TrackBot/Weapons/Jank_Plasma/Jank_Plasma.tscn",
			"scene": null
		},
		"CyberShotgun": {
			"res": "res://Objects/TrackBot/Weapons/CyberShotgun/CyberShotgun.tscn",
			"scene": null
		}
	},
	"PROJECTILES":{
		"PlasmaBullet": {
			"res": "res://Objects/Projectiles/PlasmaBullet/PlasmaBullet.tscn",
			"scene": null
		},
		"CyberShot": {
			"res": "res://Objects/Projectiles/CyberShot/CyberShot.tscn",
			"scene": null
		}
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

func _GetScene(db_name : String, item_name : String) -> PackedScene:
	if db_name in DB:
		if item_name in DB[db_name]:
			var dbitem : Dictionary = DB[db_name][item_name]
			if dbitem.scene == null:
				dbitem.scene = load(dbitem.res)
				if not dbitem.scene is PackedScene:
					dbitem.scene = null
			return dbitem.scene
	return null

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

func get_database_keys(db_name : String) -> Array:
	if db_name in DB:
		return DB[db_name].keys()
	return []

func preload_by_name(key_name : String) -> bool:
	var keys : Array = _SplitName(key_name)
	var db_name = keys[0]
	var item_name = keys[1]
	return _GetScene(db_name, item_name) != null

func get_by_name(key_name : String) -> Spatial:
	var keys : Array = _SplitName(key_name)
	var db_name = keys[0]
	var item_name = keys[1]
	
	var scene : PackedScene = _GetScene(db_name, item_name)
				
	if scene != null:
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
	var scene : PackedScene = _GetScene(db_name, item_name)
	if scene != null:
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
