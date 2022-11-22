extends "res://Objects/TrackBot/Weapons/ProjectileWeapon.gd"


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var spawn_point_node : Position3D = $Spawn_point


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ProjectileSpawn() -> void:
	if projectile_name == "":
		return
	emit_signal("spawn_projectile", projectile_name, spawn_point_node.global_transform.origin, global_transform.basis.z)


