class_name Game
extends Level


func _ready():
	# Enemies
#	enemies.resize(num_enemies)
	var enemy_s := load(enemy_path)
	for i in range(num_enemies):
		var e : Enemy = enemy_s.instance()
		e.name = "E" + str(i)
		enemies.append(e)

	# If we pressed Host
	if is_network_master():
		
		# Generate random asteroids
		randomize()
		G.TERRAIN_SEED = randi() % 2048
		gen_boxes(G.TERRAIN_SEED)

		get_node(enemy_spawn_time).start(spawn_time)
		
		# Land
		$Land.gen_terrain(G.TERRAIN_SEED)
		
		# Spawn worm boss
		var worm: Worm = load(worm_path).instance()
		add_child(worm)
		worm.Head.translation = Vector3(0, 360, -850)
		worm.Head.rotation.y = -PI
		worm.set_target(players[0]) # TODO SYNC UP PROPERLY WORM
		bosses.append(worm)
	# Else send a network request to get host's data
	else:
		request_current_data()
