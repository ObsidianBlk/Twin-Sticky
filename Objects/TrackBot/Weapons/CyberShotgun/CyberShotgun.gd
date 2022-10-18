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
		return
	
	var bz : Vector3 = global_transform.basis.z
	bz = Vector3(bz.x, 0.0, bz.z).normalized()
	for spawner in [bullet_spawn_1, bullet_spawn_2, bullet_spawn_3, bullet_spawn_4]:
		var direction : Vector3 = bz
		if spread > 0.0:
			var adj : float = deg2rad(rand_range(-spread, spread))
			direction = direction.rotated(Vector3.UP, adj)
		
		emit_signal(
			"spawn_projectile", projectile_name, 
			spawner.global_transform.origin, direction
		)

