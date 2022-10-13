extends "res://Objects/TrackBot/Weapons/ProjectileWeapon.gd"


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var bullet_spawn_1 : Position3D = $Bullet_Spawns/Bullet_Spawn_1
onready var bullet_spawn_2 : Position3D = $Bullet_Spawns/Bullet_Spawn_2
onready var bullet_spawn_3 : Position3D = $Bullet_Spawns/Bullet_Spawn_3
onready var bullet_spawn_4 : Position3D = $Bullet_Spawns/Bullet_Spawn_4

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ProjectileSpawn() -> void:
	if projectile_name == "":
		pass
	emit_signal(
		"spawn_projectile", projectile_name, 
		bullet_spawn_1.global_transform.origin, global_transform.basis.z
	)

