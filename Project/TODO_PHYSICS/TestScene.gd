extends Level


func _ready():
	# Standard networking
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(Network.PORT)
	get_tree().set_network_peer(peer)
	
	# Make sure we spawn player
	G.game = self
	set_network_master(1, false)
	if is_network_master():
		Network.register(get_tree().get_network_unique_id())

