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
const WEAPONMOUNT : PackedScene = preload("res://Objects/TrackBot/WeaponMount/WeaponMount.tscn")

const WEAPON : Dictionary = {
	"SHOTTY" : preload("res://Objects/TrackBot/Weapons/Jank_Shotty/Jank_Shotty.tscn"),
	"PLASMA" : preload("res://Objects/TrackBot/Weapons/Jank_Plasma/Jank_Plasma.tscn"),
}

const PROJECTILE : Dictionary = {
	"PlasmaBullet": preload("res://Objects/Projectiles/PlasmaBullet/PlasmaBullet.tscn"),
}
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
	Net.connect("add_player", self, "_on_add_player")
	Net.connect("remove_player", self, "_on_remove_player")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _MountWeapon(weapon_name : String, trackbot : Spatial, mount_id : int) -> int:
	if weapon_name in WEAPON:
		if trackbot.has_method("mount_item"):
			if not trackbot.item_mounted(mount_id):
				var weapon = WEAPON[weapon_name].instance()
				if weapon.has_signal("spawn_projectile"):
					weapon.connect("spawn_projectile", self, "_on_spawn_projectile", [trackbot])
				trackbot.mount_item(weapon, mount_id)
				return OK
			else:
				return ERR_ALREADY_IN_USE
		else:
			return ERR_METHOD_NOT_FOUND
	return ERR_DOES_NOT_EXIST

# -----------------------------------------------------------------------------
# Remote Methods
# -----------------------------------------------------------------------------
remotesync func r_spawn_projectile(projectile_name : String, position : Vector3, direction : Vector3) -> void:
	if projectile_name in PROJECTILE:
		var projectile = PROJECTILE[projectile_name].instance()
		projectile.direction = direction
		add_child(projectile)
		projectile.global_transform.origin = position


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func spawn_player(pid : int, remote_pid : int) -> void:
	if not hexregion_node:
		return
	
	var group_name : String = "Player_%s"%[pid + 1]
	if remote_pid > 0:
		group_name = "%s_%s"%[group_name, remote_pid]
	print("Group Name: ", group_name)
	
	var bots = get_tree().get_nodes_in_group(group_name)
	if bots.size() <= 0:
		var y : float = hexregion_node.region_resource.get_height_at(Vector3.ZERO)
		var tb : Spatial = TRACKBOT.instance()
		tb.set_name("%s_%s"%[remote_pid, pid + 1])
		tb.add_to_group(group_name)
		tb.set_network_master(remote_pid)
		add_child(tb)
		tb.transform.origin.y = y + 1.0
		
		var wmount = WEAPONMOUNT.instance()
		wmount.local_player_id = pid + 1
		wmount.set_network_master(remote_pid)
		tb.add_weapon_mount(wmount)
		
		var res : int = _MountWeapon("SHOTTY", tb, 1)
		if res != OK:
			printerr("Failed to mount SHOTTY to Trackbot ID ", pid)
		
		res = _MountWeapon("PLASMA", tb, 2)
		if res != OK:
			printerr("Failed to mount PLASMA to Trackbot ID ", pid)
		
		var booster = BOOSTER.instance()
		booster.local_player_id = pid + 1
		booster.set_network_master(remote_pid)
		tb.add_booster(booster)
		if get_tree().has_network_peer():
			if remote_pid == get_tree().get_network_unique_id():
				if pid == 1:
					emit_signal("local_player_2", true)
				Net.announce_local_player(pid)
		elif pid == 1:
			emit_signal("local_player_2", true)

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_add_player(local_pid, remote_pid) -> void:
	spawn_player(local_pid, remote_pid)

func _on_remove_player(local_pid, remote_pid) -> void:
	var group_name : String = "Player_%s_%s"%[local_pid + 1, remote_pid]
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.size() > 0:
		remove_child(nodes[0])
		nodes[0].queue_free()

func _on_spawn_projectile(projectile_name : String, position : Vector3, direction : Vector3, trackbot : Spatial) -> void:
	if get_tree().has_network_peer():
		rpc("r_spawn_projectile", projectile_name, position, direction)
	else:
		r_spawn_projectile(projectile_name, position, direction)
#	if projectile_name in PROJECTILE:
#		var projectile = PROJECTILE[projectile_name].instance()
#		projectile.direction = direction
#		add_child(projectile)
#		projectile.global_transform.origin = position


