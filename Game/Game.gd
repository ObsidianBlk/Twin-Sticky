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
var _local_tb : Array = [null, null]

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var hexregion_node : Spatial = $HexRegion

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------


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
# Public Methods
# -----------------------------------------------------------------------------
func spawn_local(pid : int) -> void:
	if not hexregion_node:
		return
	
	if pid >= 0 and pid < _local_tb.size():
		if _local_tb[pid] == null:
			var y : float = hexregion_node.region_resource.get_height_at(Vector3.ZERO)
			_local_tb[pid] = TRACKBOT.instance()
			_local_tb[pid].add_to_group("Player_%s"%[pid + 1])
			add_child(_local_tb[pid])
			_local_tb[pid].transform.origin.y = y + 1.0
			
			var wmount = WEAPONMOUNT.instance()
			wmount.local_player_id = pid + 1
			_local_tb[pid].add_weapon_mount(wmount)
			
			var res : int = _MountWeapon("SHOTTY", _local_tb[pid], 1)
			if res != OK:
				printerr("Failed to mount SHOTTY to Trackbot ID ", pid)
			
			res = _MountWeapon("PLASMA", _local_tb[pid], 2)
			if res != OK:
				printerr("Failed to mount PLASMA to Trackbot ID ", pid)
			
			var booster = BOOSTER.instance()
			booster.local_player_id = pid + 1
			_local_tb[pid].add_booster(booster)
			if pid == 1:
				emit_signal("local_player_2", true)

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_spawn_projectile(projectile_name : String, position : Vector3, direction : Vector3, trackbot : Spatial) -> void:
	if projectile_name in PROJECTILE:
		var projectile = PROJECTILE[projectile_name].instance()
		projectile.direction = direction
		add_child(projectile)
		projectile.global_transform.origin = position


