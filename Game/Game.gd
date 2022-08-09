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

const SHOTTY : PackedScene = preload("res://Objects/TrackBot/Weapons/Jank_Shotty/Jank_Shotty.tscn")

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
			
			var shotty_1 = SHOTTY.instance()
			_local_tb[pid].mount_item(shotty_1, 1)
			
			var booster = BOOSTER.instance()
			booster.local_player_id = pid + 1
			_local_tb[pid].add_booster(booster)
			if pid == 1:
				emit_signal("local_player_2", true)

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------

