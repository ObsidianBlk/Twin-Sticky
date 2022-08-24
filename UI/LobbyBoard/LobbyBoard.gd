extends Control


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _players : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _board_node : GridContainer = $Board

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Lobby.connect("player_entered", self, "_on_player_entered")
	Lobby.connect("player_removed", self, "_on_player_removed")
	Lobby.connect("player_name_changed", self, "_on_player_entered")
	Lobby.connect("player_score_changed", self, "_on_player_score_changed")


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_player_removed(pair_id : int, local_id : int) -> void:
	if pair_id in _players:
		if local_id in _players[pair_id]:
			var player = _players[pair_id][local_id]
			_board_node.remove_child(player.player_name)
			player.player_name.queue_free()
			_board_node.remove_child(player.score)
			player.score.queue_free()
		_players[pair_id].erase(local_id)
		if _players[pair_id].empty():
			_players.erase(pair_id)


func _on_player_entered(pair_id : int, local_id : int, player_name : String) -> void:
	if not pair_id in _players:
		_players[pair_id] = {}
	if not local_id in _players[pair_id]:
		_players[pair_id][local_id] = {
			"player_name": Label.new(),
			"score": Label.new()
		}
		_board_node.add_child(_players[pair_id][local_id].player_name)
		_board_node.add_child(_players[pair_id][local_id].score)
		_players[pair_id][local_id].score.text = "0"
	var player = _players[pair_id][local_id]
	player.player_name.text = player_name

func _on_player_score_changed(pair_id : int, local_id : int, score : int) -> void:
	if pair_id in _players:
		if local_id in _players[pair_id]:
			_players[pair_id][local_id].score.text = String(score)
