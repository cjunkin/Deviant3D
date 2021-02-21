extends Node

const PORT := 8070
var players := {}

func host() -> void:
	Global.hosted = true
	
	# Standard
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT)
	get_tree().set_network_peer(peer)
	
	# Choose what to do on connect/disconnect
	get_tree().connect("network_peer_connected", self, "player_connected")
	get_tree().connect("network_peer_disconnected", self, "player_disconnected")
	
	# Load game
	get_tree().change_scene("res://Scn/Game.tscn")

func join() -> void:
	# Standard
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", PORT)
	get_tree().set_network_peer(peer)
	
	# Wait until we connect to server to load game
	get_node("/root/MainMenu/Spinner").show()
	yield(get_tree(), "connected_to_server")
	get_tree().change_scene("res://Scn/Game.tscn")

remotesync func register(id: int) -> void:
	if not id in players:
		# if player isn't already there
		players[id] = 0
		get_node("/root/Game").spawn(id)

remotesync func unregister(id: int) -> void:
	if players.erase(id):
		# if player is there
		get_node("/root/Game").get_node(str(id)).queue_free()

func player_connected(id: int) -> void:
	for pid in players:
		# spawn all other players on our new guy
		get_node("/root/Game").rpc_id(id, "spawn", pid)
	# spawn him on everyone else
	rpc("register", id)

func player_disconnected(id: int) -> void:
	rpc("unregister", id)
