extends Level


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
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



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
