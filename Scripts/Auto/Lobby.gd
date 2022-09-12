extends Node


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal player_entered(pair_id, local_id, player_name)
signal player_name_changed(pair_id, local_id, player_name)
signal player_score_changed(pair_id, local_id, score)
signal player_removed(pair_id, local_id)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEFAULT_PLAYER_NAMES : Dictionary = {
	"Fluff Ball": false,
	"Roller": false,
	"Tumble": false,
	"Bouncy": false,
	"Eight": false,
	"Mr. Smarty Pants" : false,
	"Bally McBall Face" : false,
	"Captain Baller" : false,
	"Ybrik" : false,
	"Scooter" : false,
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _players : Dictionary = {}


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _Get_First_Available_Name() -> String:
	for pname in DEFAULT_PLAYER_NAMES.keys():
		if DEFAULT_PLAYER_NAMES[pname] == false:
			DEFAULT_PLAYER_NAMES[pname] = true
			return pname
	return ""


func _Get_Random_Name() -> String:
	var keys : Array = DEFAULT_PLAYER_NAMES.keys()
	var idx : int = int(randf() * keys.size())
	if not DEFAULT_PLAYER_NAMES[keys[idx]]:
		DEFAULT_PLAYER_NAMES[keys[idx]] = true
		return keys[idx]
	return _Get_First_Available_Name()


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func add_player_group(pid : int) -> int:
	if pid in _players:
		return ERR_ALREADY_IN_USE
	_players[pid] = {"local_1":null, "local_2":null}
	return OK

func remove_player_group(pid : int) -> int:
	if pid in _players:
		if _players[pid]["local_1"] != null:
			emit_signal("player_removed", pid, 0)
		if _players[pid]["local_2"] != null:
			emit_signal("player_removed", pid, 1)
		var _res : int = _players.erase(pid)
	return OK

func remove_all_players() -> int:
	for pid in _players.keys():
		var _res : int = remove_player_group(pid)
	return OK

func does_player_group_exist(pid : int) -> bool:
	return pid in _players

func get_player_groups() -> Array:
	return _players.keys()

func add_local_player(pid : int, lid : int, player_name : String = "") -> int:
	if not (lid >= 0 and lid < 2):
		return ERR_PARAMETER_RANGE_ERROR
	if not pid in _players:
		var _res : int = add_player_group(pid)
	if player_name == "":
		player_name = _Get_Random_Name()
		if player_name == "":
			player_name = "Trackbot_%s_%s"%[pid,lid]
	elif player_name in DEFAULT_PLAYER_NAMES and DEFAULT_PLAYER_NAMES[player_name] == false:
		DEFAULT_PLAYER_NAMES[player_name] = true
	
	_players[pid]["local_%s"%[lid + 1]] = {
		"name": player_name,
		"score": 0
	}
	emit_signal("player_entered", pid, lid, player_name)
	return OK

func remove_local_player(pid : int, lid : int) -> int:
	if not pid in _players:
		return ERR_DOES_NOT_EXIST
	if _players[pid]["local_%s"%[lid + 1]] == null:
		return ERR_DOES_NOT_EXIST
	_players[pid]["local_%s"%[lid + 1]] = null
	emit_signal("player_removed", pid, lid)
	var remove_pg : bool = true
	for key in _players[pid].keys():
		if _players[pid][key] != null:
			remove_pg = false
			break
	if remove_pg:
		var _res : int = _players.erase(pid)
	return OK

func does_local_player_exist(pid : int, lid : int) -> bool:
	if not pid in _players:
		return false
	var sidx : String = "local_%s"%[lid + 1]
	if not sidx in _players[pid]:
		return false
	if _players[pid][sidx] == null:
		return false
	return true

func get_local_player_info(pid : int, lid : int) -> Dictionary:
	var info : Dictionary = {}
	if pid in _players:
		var sidx : String = "local_%s"%[lid + 1]
		if sidx in _players[pid]:
			if _players[pid][sidx] != null:
				for key in _players[pid][sidx].keys():
					info[key] = _players[pid][sidx][key]
	return info


func get_player_name(pid : int, lid : int) -> String:
	if pid in _players:
		var sidx : String = "local_%s"%[lid + 1]
		if sidx in _players[pid]:
			if _players[pid][sidx] != null:
				return _players[pid][sidx].name
	return ""

func set_player_name(pid : int, lid : int, player_name : String) -> int:
	if not pid in _players:
		return ERR_DOES_NOT_EXIST
	var sidx : String = "local_%s"%[lid + 1]
	if not sidx in _players[pid]:
		return ERR_DOES_NOT_EXIST
	if _players[pid][sidx] == null:
		return ERR_DOES_NOT_EXIST
	_players[pid][sidx].name = player_name
	emit_signal("player_name_changed", pid, lid, player_name)
	return OK

func get_player_score(pid : int, lid : int) -> int:
	if pid in _players:
		var sidx : String = "local_%s"%[lid + 1]
		if sidx in _players[pid]:
			if _players[pid][sidx] != null:
				return _players[pid][sidx].score
	return 0

func set_player_score(pid : int, lid : int, score : int) -> int:
	if not pid in _players:
		return ERR_DOES_NOT_EXIST
	var sidx : String = "local_%s"%[lid + 1]
	if not sidx in _players[pid]:
		return ERR_DOES_NOT_EXIST
	if _players[pid][sidx] == null:
		return ERR_DOES_NOT_EXIST
	_players[pid][sidx].score = max(0, score)
	emit_signal("player_score_changed", pid, lid, score)
	return OK


func change_player_score(pid : int, lid : int, score : int) -> int:
	if not pid in _players:
		return ERR_DOES_NOT_EXIST
	var sidx : String = "local_%s"%[lid + 1]
	if not sidx in _players[pid]:
		return ERR_DOES_NOT_EXIST
	if _players[pid][sidx] == null:
		return ERR_DOES_NOT_EXIST
	_players[pid][sidx].score = max(0, _players[pid][sidx].score + score)
	emit_signal("player_score_changed", pid, lid, score)
	return OK
