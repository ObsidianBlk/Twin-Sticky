extends RigidBody

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal hp_changed(owner_id, current_hp, max_hp)


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const EXPLOSION = preload("res://Objects/TrackBot/Explosion/Explosion.tscn")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var owner_id : int = 0
export var max_hp : float = 100.0					setget set_max_hp
export var bot_name : String = ""					setget set_bot_name
export var asset_key : String = ""					setget set_asset_key

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _is_ready : bool = false
var _network_mode : bool = false

var _boost_direction : Vector3 = Vector3.ZERO
var _boost_strength : float = 0.0
var _boost_jump_strength : float = 0.0

var _hp : float = 0.0
#var _base_color : Color = Color.white

var _booster_node : Spatial = null
var _weaponmount_node : Spatial = null
var _asset_ball_node : Spatial = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var hat_node : Spatial = $Hat
onready var groundcast_node : RayCast = $Hat/GroundCast
onready var ball_node : MeshInstance = $Ball
onready var label_name_node : Label3D = $Hat/Label_Name

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_max_hp(mhp : float) -> void:
	if mhp > 0.0:
		max_hp = mhp
		if max_hp < _hp:
			_hp = max_hp
		emit_signal("hp_changed", owner_id, _hp, max_hp)

func set_bot_name(n : String) -> void:
	bot_name = n
	if label_name_node:
		label_name_node.text = bot_name

func set_asset_key(akey : String) -> void:
	asset_key = akey
	_UpdateAssetKey()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_is_ready = true
	label_name_node.text = bot_name
	_network_mode = get_tree().has_network_peer()
	if _network_mode:
		if not is_network_master():
			mode = MODE_KINEMATIC
	
	_hp = max_hp
	_UpdateAssetKey()

func _physics_process(delta : float) -> void:
	if _network_mode:
		if is_network_master():
			_ProcessImpulses(delta)
			rpc("r_update", transform.origin, transform.basis)
	else:
		_ProcessImpulses(delta)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ProcessImpulses(delta : float) -> void:
	if _boost_strength > 0.0:
		apply_central_impulse(_boost_direction * _boost_strength * delta)
	if _boost_jump_strength > 0.0:
		if groundcast_node.is_colliding():
			apply_central_impulse(Vector3.UP * _boost_jump_strength)
		_boost_jump_strength = 0.0
	hat_node.transform.basis = Basis(transform.basis.get_rotation_quat().inverse())


func _UpdateHatRotation() -> void:
	hat_node.transform.basis = Basis(transform.basis.get_rotation_quat().inverse())

func _IsBooster(obj : Spatial) -> bool:
	var signals = obj.get_signal_list()
	for sig in signals:
		if sig.name.begins_with("booster_"):
			return true
	return false

func _SetBallColor(color : Color) -> void:
	if ball_node.get_surface_material_count() > 0:
		var material = ball_node.get_active_material(0)
		if material is ShaderMaterial:
			material.set_shader_param("Color", color)

func _UpdateAssetKey() -> void:
	if not _is_ready:
		return
	
	if asset_key == null:
		if _asset_ball_node != null:
			remove_child(_asset_ball_node)
		ball_node.visible = true
	else:
		var asset_node : Spatial = AssetDB.get_by_name(asset_key)
		if asset_node:
			_asset_ball_node = asset_node
			add_child_below_node(ball_node, _asset_ball_node)
			ball_node.visible = false

# ------------------------------------------------------------------------------
# Remote Methods
# ------------------------------------------------------------------------------
puppet func r_update(pos : Vector3, basis : Basis) -> void:
	transform.origin = pos
	transform.basis = basis
	hat_node.transform.basis = Basis(basis.get_rotation_quat().inverse())

puppet func r_hit(dmg : float, knockback : Vector3) -> void:
	pass

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectBooster(booster : Spatial) -> void:
	var _res : int = _booster_node.connect("booster_facing_changed", self, "_on_booster_facing_changed")
	_res = _booster_node.connect("booster_ignited", self, "_on_booster_ignited")
	_res = _booster_node.connect("booster_off", self, "_on_booster_off")
	_res = _booster_node.connect("booster_jump", self, "_on_booster_jump")

func _DisconnectBooster(booster : Spatial) -> void:
	_booster_node.disconnect("booster_facing_changed", self, "_on_booster_facing_changed")
	_booster_node.disconnect("booster_ignited", self, "_on_booster_ignited")
	_booster_node.disconnect("booster_off", self, "_on_booster_off")
	_booster_node.disconnect("booster_jump", self, "_on_booster_jump")

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_static(enable : bool = true) -> void:
	if enable:
		mode = MODE_KINEMATIC
	elif is_network_master():
		mode = MODE_RIGID

func get_booster() -> Spatial:
	return _booster_node

func add_booster(booster : Spatial) -> void:
	if _booster_node == null:
		if not _IsBooster(booster):
			return
		
		_booster_node = booster
		hat_node.add_child(_booster_node)
		
		if _network_mode:
			if is_network_master():
				_ConnectBooster(_booster_node)
		else:
			_ConnectBooster(_booster_node)
		
		_boost_direction = _booster_node.get_facing()

func remove_booster() -> Spatial:
	if _booster_node != null:
		_boost_strength = 0.0
		_boost_jump_strength = 0.0
		_boost_direction = Vector3.ZERO
		
		if _network_mode:
			if is_network_master():
				_DisconnectBooster(_booster_node)
		else:
			_DisconnectBooster(_booster_node)
		
		hat_node.remove_child(_booster_node)
		var t = _booster_node
		_booster_node = null
		return t
	return null

func add_weapon_mount(mount : Spatial) -> void:
	if _weaponmount_node == null:
		# TODO: Varify mount is what we think it is!
		_weaponmount_node = mount
		hat_node.add_child(_weaponmount_node)

func remove_weapon_mount() -> Spatial:
	if _weaponmount_node != null:
		hat_node.remove_child(_weaponmount_node)
		var t = _weaponmount_node
		_weaponmount_node = null
		return t
	return null

func item_mounted(id : int) -> bool:
	if _weaponmount_node != null:
		return _weaponmount_node.item_mounted(id)
	return false

func mount_item(item : Spatial, id : int, unmount_existing : bool = false) -> void:
	if _weaponmount_node == null:
		return
	_weaponmount_node.mount_item(item, id, unmount_existing)

func unmount_item(id : int) -> Spatial:
	if _weaponmount_node == null:
		return null
	return _weaponmount_node.unmount_item(id)

func hit(dmg : float, knockback : Vector3) -> void:
	if _hp > 0.0:
		_hp -= dmg
		emit_signal("hp_changed", owner_id, _hp, max_hp)
		if _hp <= 0.0:
			if _weaponmount_node:
				_weaponmount_node.lock_player_control(true)
			if _booster_node:
				_booster_node.lock_player_control(true)
			var parent = get_parent()
			if parent != null:
				print("EXPLOSION")
				_asset_ball_node.visible = false
				var expl = EXPLOSION.instance()
				parent.add_child(expl)
				expl.global_transform.origin = global_transform.origin
				expl.connect("explosion_completed", self, "_on_explosion_completed")
		if knockback.length() > 0.001:
			apply_central_impulse(knockback)

func revive() -> void:
	# TODO: Make this network aware!
	_hp = max_hp
	if _weaponmount_node:
		_weaponmount_node.lock_player_control(false)
	if _booster_node:
		_booster_node.lock_player_control(false)
	#_SetBallColor(_base_color)

func get_build_dict() -> Dictionary:
	var bd : Dictionary = {
		"body": asset_key,
		"weaponmount": "",
		"weapon_1": "",
		"weapon_2": "",
		"booster": ""
	}
	if _weaponmount_node != null:
		bd.weaponmount = _weaponmount_node.asset_key
		bd.weapon_1 = _weaponmount_node.get_mount_asset_key(1)
		bd.weapon_2 = _weaponmount_node.get_mount_asset_key(2)
	if _booster_node != null:
		bd.booster = _booster_node.asset_key
	return bd

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_explosion_completed() -> void:
	pass # TODO: Figure out how to reset and revive!

func _on_booster_facing_changed(facing : Vector3) -> void:
	_boost_direction = facing

func _on_booster_ignited(strength : float) -> void:
	_boost_strength = strength

func _on_booster_off() -> void:
	_boost_strength = 0.0

func _on_booster_jump(strength : float) -> void:
	_boost_jump_strength = strength


