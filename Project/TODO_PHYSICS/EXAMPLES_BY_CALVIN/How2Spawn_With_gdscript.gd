extends Node



func _ready():
	var prefab := preload("res://TODO_PHYSICS/Sambodh/Low_grav_powerup.tscn") # Prefab
	var powerup = prefab.instance() # Make instance
	# Setup
	powerup.translation = Vector3(4, 5, 3)
	powerup.rotation
	# etc
	
	# Put it in the game
	get_tree().get_root().add_child(powerup) # Puts it in the very top level node (one level above Game)
	# could also do
	get_node("/root")
	# To get game you could do
	G.game
	# Then add children under it as necessary, does same thing as draggin prefab onto Game
	
	powerup.queue_free() # Safely frees it (no mem checks needed)



