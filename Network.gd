extends Node

const PORT = 8070
var players := {}

func host() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT)
	get_tree().set_network_peer(peer)
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().change_scene("res://Scn/Game.tscn")
	

func join() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", PORT)
	get_tree().set_network_peer(peer)
	
#	$Spinner.show()
	yield(get_tree(), "connected_to_server")
	get_tree().change_scene("res://Scn/Game.tscn")
#	$Spinner.hide()

remotesync func register(id: int) -> void:
	if not id in players: # if player isn't already there
		players[id] = 0
		get_node("/root/Game").spawn(id)

func _player_connected(id: int) -> void:
	for pid in players:
#		if pid != get_tree().get_network_unique_id():
		get_node("/root/Game").rpc_id(id, "spawn", pid)
	rpc("register", id)
#	print(id, typeof(id))
