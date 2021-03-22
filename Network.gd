extends Node

const PORT := 8070
const GAME_SCENE := "res://Scn/Game.tscn"
const GAME_PATH := "/root/Game"
var players := {}

func host() -> void:
	G.hosted = true
	
	# Standard
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT)
	get_tree().set_network_peer(peer)
	
	# Choose what to do on connect/disconnect
	if get_tree().connect("network_peer_connected", self, "player_connected") != OK:
		print("ERROR: CAN'T HANDLE OTHERS CONNECTING, CHECK NETWORK.GD")
	if get_tree().connect("network_peer_disconnected", self, "player_disconnected") != OK:
		print("ERROR: CAN'T HANDLE OTHERS DISCONNECTING, CHECK NETWORK.GD")
	
	# Load game
#	var world = load(GAME_SCENE).instance()
#	get_tree().get_root().add_child(world)
#	get_node("/root/MainMenu").queue_free()
	if get_tree().change_scene(GAME_SCENE) != OK:
		print("ERROR: COULDN'T LOAD GAME")

func join() -> void:
	# Standard
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", PORT)
	get_tree().set_network_peer(peer)
	
	# Wait until we connect to server to load game
	get_node("/root/MainMenu").spinner.show()
	yield(get_tree(), "connected_to_server")
	if get_tree().change_scene(GAME_SCENE) != OK:
		print("ERROR: COULDN'T LOAD GAME")

remotesync func register(id: int) -> void:
	if not id in players:
		# if player isn't already there
		players[id] = 0
		get_node(GAME_PATH).spawn(id)

func player_connected(id: int) -> void:
	for pid in players:
		# spawn all other players on our new guy
		get_node(GAME_PATH).rpc_id(id, "spawn", pid)
	# spawn him on everyone else
	rpc("register", id)

remotesync func unregister(id: int) -> void:
	if players.erase(id):
		# if player is there
		get_node(GAME_PATH).get_node(str(id)).queue_free()

func player_disconnected(id: int) -> void:
	rpc("unregister", id)
