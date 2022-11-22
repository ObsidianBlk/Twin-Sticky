extends Node

# https://godotengine.org/qa/64801/sending-variable-data-from-server-to-a-client

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal network_initialized()
#signal network_disconnected()
signal network_init_failed()

signal add_game_world()
signal remove_game_world()
signal add_player(local_pid, remote_pid, def)
signal remove_player(local_pid, remote_pid)


# -----------------------------------------------------------------------------
# Constant
# -----------------------------------------------------------------------------
const MIN_PORT : int = 1024
const DEFAULT_PORT : int = 20226

enum NET_SIG_MODE {Server=0, Client=1, Both=2}
const NET_SIGNALS : Array = [
	{
		signal_name = "network_peer_connected",
		method_name = "_on_network_peer_connected",
		mode = NET_SIG_MODE.Both
	},
	{
		signal_name = "network_peer_disconnected",
		method_name = "_on_network_peer_disconnected",
		mode = NET_SIG_MODE.Both
	},
	{
		signal_name = "connected_to_server",
		method_name = "_on_connected_to_server",
		mode = NET_SIG_MODE.Client
	},
	{
		signal_name = "connection_failed",
		method_name = "_on_connection_failed",
		mode = NET_SIG_MODE.Client
	},
	{
		signal_name = "server_disconnected",
		method_name = "_on_server_disconnected",
		mode = NET_SIG_MODE.Client
	}
]

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _players : Dictionary = {}

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	print(get_path())
	var st : SceneTree = get_tree()
	var _res : int = st.connect("network_peer_connected", self, "_on_network_peer_connected")
	_res = st.connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	_res = st.connect("connected_to_server", self, "_on_connected_to_server")
	_res = st.connect("connection_failed", self, "_on_connection_failed")
	_res = st.connect("server_disconnected", self, "_on_server_disconnected")


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _PostNetworkInit(mode : int = -1) -> void:
	var st : SceneTree = get_tree()
	#_id = st.get_network_unique_id()
	for conn in NET_SIGNALS:
		if conn.mode == mode or conn.mode == NET_SIG_MODE.Both:
			if not st.is_connected(conn.signal_name, self, conn.method_name):
				var _res : int = st.connect(conn.signal_name, self, conn.method_name)

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func join_game(address : String, port : int = -1) -> int:
	var st : SceneTree = get_tree()
	if st.has_network_peer():
		Log.error("Network already connected.")
		#printerr("Network already connected.")
		emit_signal("network_init_failed", ERR_ALREADY_IN_USE)
		return ERR_ALREADY_IN_USE
	
	if port < MIN_PORT:
		port = DEFAULT_PORT
	
	var peer : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	var res : int = peer.create_client(address, port)
	if res == OK:
		st.network_peer = peer
		#_PostNetworkInit(NET_SIG_MODE.Client)
		emit_signal("network_initialized")
	else:
		emit_signal("network_init_failed", res)
	
	return res


func host_game(max_players : int = 2, port : int = -1) -> int:
	var st : SceneTree = get_tree()
	if st.has_network_peer():
		Log.error("Network already connected.")
		#printerr("Network already connected.")
		emit_signal("network_init_failed", ERR_ALREADY_IN_USE)
		return ERR_ALREADY_IN_USE
	
	if port < MIN_PORT:
		port = DEFAULT_PORT
	if max_players < 2:
		max_players = 2
	
	var peer : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	var res : int = peer.create_server(port, max_players - 1)
	if res == OK:
		st.network_peer = peer
		#_PostNetworkInit(NET_SIG_MODE.Server)
		emit_signal("network_initialized")
		emit_signal("add_game_world")
	else:
		Log.error("Network initialization failed", res)
		emit_signal("network_init_failed", res)
	return res


#func disconnect_network(unregister : bool = true) -> int:
#	var st : SceneTree = get_tree()
#	if not st.has_network_peer():
#		return ERR_DOES_NOT_EXIST
#	if unregister:
#		rpc("r_unregister_player_profile")
#	st.network_peer = null
#	emit_signal("network_disconnected")
#	return OK

func send_data(data, to_id : int = -1) -> void:
	var self_id : int = get_tree().get_network_unique_id()
	if self_id == 1:
		if to_id > 1:
			rpc_id(to_id, "r_receive_data", data)
		else:
			rpc("r_receive_data", data)
	else:
		rpc_id(1, "r_receive_data", data, to_id)

func announce_local_player(pid : int, _rid : int, def : Dictionary) -> void:
	rpc("r_announce_local_player", pid, def)

# -----------------------------------------------------------------------------
# Remote Methods
# -----------------------------------------------------------------------------
remote func r_ready_network() -> void:
	Log.debug("Who am I: %s"%[get_tree().get_network_unique_id()])
	emit_signal("add_game_world")
	rpc_id(1, "r_network_readied")

master func r_network_readied() -> void:
	var rid : int = get_tree().get_rpc_sender_id()
	Log.debug("Remote player exists: %s"%[rid in _players])
	for id in Lobby.get_player_groups():
		if id != rid:
			Log.debug("Announcing player [%s] to receiver [%s]." %[id, rid])
			var info : Dictionary = Lobby.get_local_player_info(id, 0)
			if not info.empty():
				Log.debug("Announcing for local 0")
				rpc_id(rid, "r_host_announce_local_player", id, 0, info)
			info = Lobby.get_local_player_info(id, 1)
			if not info.empty():
				Log.debug("Announcing for local 1")
				rpc_id(rid, "r_host_announce_local_player", id, 1, info)

remotesync func r_announce_local_player(local_id : int, def : Dictionary) -> void:
	var id = get_tree().get_network_unique_id()
	var remote_pid = get_tree().get_rpc_sender_id()
	
	if remote_pid != id:
		var player_name : String = ""
		if "playername" in def:
			player_name = def["playername"]
		Log.info("Announced player %s:%s \"%s\"."%[remote_pid, local_id, player_name])
		emit_signal("add_player", local_id, remote_pid, def)

puppet func r_host_announce_local_player(remote_id : int, local_id : int, player_info : Dictionary):
	Log.debug("Host Announced to [%s] a player from [%s]"%[get_tree().get_network_unique_id(), remote_id])
	if remote_id != get_tree().get_network_unique_id():
		if "name" in player_info:
			Log.info("Host announced player %s:%s \"%s\"."%[remote_id, local_id, player_info.name])
			emit_signal("add_player", local_id, remote_id, player_info.name)
			if "score" in player_info:
				var _res : int = Lobby.set_player_score(remote_id, local_id, player_info.score)

#remote func r_register_player_profile(profile : Dictionary) -> void:
#	var id : int = get_tree().get_rpc_sender_id()
#	# TODO: Varify dictionary data
#	_pid[id] = profile
#	Log.info("Registered client: %d - %s"%[id, profile])
#	#print("Registered client: ", id, " - ", profile)
#
#remote func r_unregister_player_profile() -> void:
#	var id : int = get_tree().get_rpc_sender_id()
#	print(_pid)
#	if id in _pid:
#		var _res : int = _pid.erase(id)
#		Log.info("Unregistered client: %d"%[id])
#		#print("Unregistered client: ", id)

remote func r_receive_data(data, to_id : int = -1) -> void:
	var id : int = get_tree().get_rpc_sender_id()
	if id == 1 and to_id > 1:
		rpc_id(to_id, "r_receive_data", data)
	else:
		Log.debug("Obtained data from %d"%[id])
		# TODO: Process data for command

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_network_peer_connected(id : int) -> void:
	if id in _players:
		Log.warning("Client ID %d already exists."%[id])
	Log.info("New client connected, %d"%[id])
	var _res : int = Lobby.add_player_group(id)
	if get_tree().get_network_unique_id() == 1:
		rpc_id(id, "r_ready_network")

func _on_network_peer_disconnected(id : int) -> void:
	if id != get_tree().get_network_unique_id():
		emit_signal("remove_player", 0, id)
		emit_signal("remove_player", 1, id)
		var _res : int = Lobby.remove_player_group(id)
		Log.info("Client disconnected: %d"%[id])

func _on_connected_to_server() -> void:
	Log.info("Connected to server")

func _on_connection_failed() -> void:
	Log.info("Failed to connect to the server")

func _on_server_disconnected() -> void:
	Log.info("Server disconnected")
	emit_signal("remove_game_world")

