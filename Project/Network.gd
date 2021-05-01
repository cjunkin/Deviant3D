extends Node

const PORT := 8070

const GAME_PATH := "/root/Game"
var players := {}

func host(game_scene := G.GAME_SCENE) -> void:
	
	# Standard
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT)
	get_tree().set_network_peer(peer)

	# Choose what to do on connect/disconnect

	if !get_tree().is_connected("network_peer_connected", self, "player_connected") and \
		get_tree().connect("network_peer_connected", self, "player_connected") != OK:
		print("ERROR: CAN'T HANDLE OTHERS CONNECTING, CHECK NETWORK.GD")
	if !get_tree().is_connected("network_peer_disconnected", self, "player_disconnected") and \
		get_tree().connect("network_peer_disconnected", self, "player_disconnected") != OK:
		print("ERROR: CAN'T HANDLE OTHERS DISCONNECTING, CHECK NETWORK.GD")
	
	# Load game
#	var world = load(GAME_SCENE).instance()
#	get_tree().get_root().add_child(world)
#	get_node("/root/MainMenu").queue_free()
	if get_tree().change_scene(game_scene) != OK:
		print("ERROR: COULDN'T LOAD GAME")


func join() -> void:
	# Standard
	var peer := NetworkedMultiplayerENet.new()
	if peer.create_client("127.0.0.1", PORT) != OK:
		print("ERROR: Couldn't connect!")
	get_tree().set_network_peer(peer)
	
	# Wait until we connect to server to load game
	get_node("/root/MainMenu").spinner.show()
	yield(get_tree(), "connected_to_server")
	if get_tree().change_scene(G.GAME_SCENE) != OK:
		print("ERROR: COULDN'T LOAD GAME")

remotesync func register(id: int) -> void:
	if not id in players:
		# if player isn't already there
		players[id] = 0
		get_node(GAME_PATH).spawn(id)
		get_tree().paused = false
		G.game.set_physics_process(true)
		Engine.time_scale = 1

func player_connected(id: int) -> void:
	for pid in players:
		# register and spawn all other players on our new guy
		rpc_id(id, "register", pid)
	# spawn him on everyone else
	rpc("register", id)

remotesync func unregister(id: int) -> void:
	if players.erase(id):
		# if player is there
		get_node(GAME_PATH).get_node(str(id)).unregister()

func player_disconnected(id: int) -> void:
	rpc("unregister", id)

# Disconnect and return to main menu
func disconnect_from_server() -> void:
	if get_tree().disconnect("network_peer_connected", self, "player_connected") != OK:
		print("WTF couldn't disconnect")
	players.clear()
	if get_tree().network_peer:
		get_tree().network_peer.close_connection()
	if get_tree().change_scene(G.MENU_SCENE) != OK:
		print("ERROR: Couldn't go back to main menu")
	
	
