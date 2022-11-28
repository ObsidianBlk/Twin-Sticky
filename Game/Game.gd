extends Spatial

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal local_player_2(joined)


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const TRACKBOT : PackedScene = preload("res://Objects/TrackBot/TrackBot.tscn")
const BOOSTER : PackedScene = preload("res://Objects/TrackBot/Boosters/Jank_Booster.tscn")

const DEFAULT_TRACKBOT_DEFINITION : Dictionary = {
	"body":"",
	"weaponmount": "WEAPONMOUNTS.CyberSmile",
	"weapon_1":"",
	"weapon_2":"",
	"booster":""
}

const ZOOM_LEVEL : float = 0.25
const PITCH_DEGREE : float = 60.0

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var hexregion_node : Spatial = $HexRegion

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	var _res : int = Net.connect("add_player", self, "_on_add_player")
	_res = Net.connect("remove_player", self, "_on_remove_player")
	hexregion_node.region_resource = preload("res://Arenas/Map1.tres")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _MountWeapon(weapon_key : String, trackbot : Spatial, mount_id : int) -> int:
	var weapon : Spatial = AssetDB.get_by_name(weapon_key)
	if weapon:
		if trackbot.has_method("mount_item"):
			if not trackbot.item_mounted(mount_id):
				#weapon.set_network_master(remote_id)
				if weapon.has_signal("spawn_projectile"):
					weapon.connect("spawn_projectile", self, "_on_spawn_projectile", [trackbot])
				trackbot.mount_item(weapon, mount_id)
				return OK
			else:
				return ERR_ALREADY_IN_USE
		else:
			return ERR_METHOD_NOT_FOUND
	return ERR_DOES_NOT_EXIST


func _ConfigCamera(pid : int) -> void:
	var cnode = get_tree().get_nodes_in_group("Camera_P%s"%[pid + 1])
	if cnode.size() <= 0:
		printerr("Cannot find Camera_P", pid + 1)
		return
	
	cnode[0].set_zoom(ZOOM_LEVEL)
	cnode[0].initial_pitch_degree = PITCH_DEGREE
	cnode[0].reset_orbit()

# -----------------------------------------------------------------------------
# Remote Methods
# -----------------------------------------------------------------------------
remotesync func r_spawn_projectile(projectile_name : String, position : Vector3, direction : Vector3, owner_name : String = "") -> void:
	var pkey : String = "PROJECTILES.%s"%[projectile_name]
	if AssetDB.key_exists(pkey):
		var projectile = AssetDB.get_by_name(pkey)
		if projectile:
			projectile.owner_name = owner_name
			projectile.direction = direction
			projectile.translation = position
			#projectile.transform.origin = position
			add_child(projectile)


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func spawn_player(pid : int, remote_pid : int, def : Dictionary) -> void:
	if not hexregion_node:
		return
	
	var player_name : String = ""
	if "playername" in def:
		player_name = def["playername"]
	
	var group_name : String = "Player_%s"%[pid + 1]
	if remote_pid > 0:
		group_name = "%s_%s"%[group_name, remote_pid]
	
	var tbdef : Dictionary = {}
	if "trackbot" in def:
		tbdef = def.trackbot
		for key in DEFAULT_TRACKBOT_DEFINITION.keys():
			if not key in tbdef:
				tbdef[key] = DEFAULT_TRACKBOT_DEFINITION[key]
		
	var bots = get_tree().get_nodes_in_group(group_name)
	if bots.size() <= 0:
		var y : float = hexregion_node.region_resource.get_height_at(Vector3.ZERO)
		var tb : Spatial = TRACKBOT.instance()
		tb.asset_key = tbdef.body
		tb.set_name("%s_%s"%[remote_pid, pid + 1])
		tb.add_to_group(group_name)
		tb.set_network_master(remote_pid)
		add_child(tb)
		tb.transform.origin.y = y + 1.0
		var _res : int = Lobby.add_local_player(remote_pid, pid, player_name)
		tb.bot_name = Lobby.get_player_name(remote_pid, pid)
		
		var wmount = AssetDB.get_by_name(tbdef.weaponmount)
		wmount.local_player_id = pid + 1
		wmount.set_network_master(remote_pid)
		tb.add_weapon_mount(wmount)
		
		if tbdef.weapon_1 != "":
			var res : int = _MountWeapon(tbdef.weapon_1, tb, 1)
			if res != OK:
				printerr("Failed to mount CyberShotgun to Trackbot ID ", pid)
		
		if tbdef.weapon_2 != "":
			var res : int = _MountWeapon(tbdef.weapon_2, tb, 2)
			if res != OK:
				printerr("Failed to mount PLASMA to Trackbot ID ", pid)
		
		var booster = BOOSTER.instance()
		booster.local_player_id = pid + 1
		booster.set_network_master(remote_pid)
		tb.add_booster(booster)
		_ConfigCamera(pid)
		
		if get_tree().has_network_peer():
			if remote_pid == get_tree().get_network_unique_id():
				def["playername"] = Lobby.get_player_name(remote_pid, pid)
				Net.announce_local_player(pid, remote_pid, def)

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_add_player(local_pid : int , remote_pid : int, def : Dictionary) -> void:
	spawn_player(local_pid, remote_pid, def)

func _on_remove_player(local_pid, remote_pid) -> void:
	var _res : int = Lobby.remove_local_player(remote_pid, local_pid)
	var group_name : String = "Player_%s_%s"%[local_pid + 1, remote_pid]
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.size() > 0:
		remove_child(nodes[0])
		nodes[0].queue_free()

func _on_spawn_projectile(projectile_name : String, position : Vector3, direction : Vector3, trackbot : Spatial) -> void:
	if get_tree().has_network_peer():
		rpc("r_spawn_projectile", projectile_name, position, direction, trackbot.name)
	else:
		r_spawn_projectile(projectile_name, position, direction, trackbot.name)


