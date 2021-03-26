class_name Game
extends Spatial

# Num Cached     TODO: make caches in C++ for efficiency
const PROJ_PER_PLAYER := 10
const EXP_PER_PLAYER := 10
var num_lasers := PROJ_PER_PLAYER
var num_explosions := EXP_PER_PLAYER
const num_enemies := 16
#const num_laser_audio := 8
const num_grapple_sounds := 6

# Cached Arrays
var projectiles := []
var laser_i : int = 0
var explosions := []
var exp_i : int = 0
var enemies := []
var enemy_i : int = 0
var players := []
var hooks := []

# File Paths
export(String, FILE) var rock_path
export(String, FILE) var enemy_path

# Node Paths
export(NodePath) var enemy_spawn_time

# Packed Scenes
export (PackedScene) var player_s := preload("res://Scn/Actor/Player/Player.tscn")
export (PackedScene) var laser_s := preload("res://Scn/Projectile/Laser.tscn")
export (PackedScene) var exp_s

# Gameplay
const spawn_time := 1.0
onready var Reticule : TextureRect = $HUD/Reticule

# RNG
var TERRAIN_SEED : int
var spawn_rng := RandomNumberGenerator.new()

# Networking
signal received_data
var latency: float
#var enemy_spawn_time_left : float

func _ready()->void:
	# Enemies
	var enemy_s := load(enemy_path)
	for i in range(num_enemies):
		var e : Enemy = enemy_s.instance()
		e.name = "E" + str(i)
		enemies.append(e)

	G.game = self
	set_network_master(1, false)
	if is_network_master():
		randomize()
		TERRAIN_SEED = randi() % 2048
		Network.register(get_tree().get_network_unique_id())
		gen_boxes(TERRAIN_SEED)
		get_node(enemy_spawn_time).start(spawn_time)
	else:
		request_current_data()
	# Projectiles
	for __ in range(num_lasers):
		var p : Projectile = laser_s.instance()
		projectiles.append(p)

	# Explosions
	for __ in range(num_explosions):
		var e : Particles = exp_s.instance()
		explosions.append(e)
		add_child(e)


#	for __ in range(num_grapple_sounds):
#		var grapple_sfx := load("res://Sfx/Slap.wav")
#		var 
#	$Enemy.set_target(players[0])
#	$Enemy2.set_target(players[0])
#	$Enemy3.set_target(players[0])
#	$Enemy4.set_target(players[0])

#onready var TimeLeft := $Label
#onready var EnemySpawnTime : Timer = get_node(enemy_spawn_time)

func _physics_process(delta: float) -> void:
	for p in projectiles:
		if p.is_inside_tree():
			p.translation -= p.speed * p.transform.basis.z * delta
			

	# Enemies
	for e in enemies:
		if e.is_inside_tree():
			if is_instance_valid(e.target):
				#	vel = translation.direction_to(target.global_transform.origin)

				# Look at target, but not looking up
				e.look_at(e.target.global_transform.origin, Vector3.UP)
				e.rotation.x = 0
			
			e.acc = e.transform.basis.z * e.speed #* int(e.global_transform.origin.distance_squared_to(e.target.global_transform.origin) > 1)
			e.vel.z = e.vel.z * .8 + e.acc.z
			e.vel.x = e.vel.x * .8 + e.acc.x
			e.vel += Vector3.DOWN * e.grav
			
			e.vel = e.move_and_slide(e.vel , Vector3.UP, false, 4, .75, false)
			# If fallen too low, die
			if e.translation.y < -7:
				e.rpc("d")

	# Hooks
	for hook in hooks:
		if hook.enabled:
			hook.translation -= 1024 * hook.transform.basis.z * delta
			if hook.is_colliding():
				var hitpt : Vector3 = hook.get_collision_point()
				hook.get_parent().remove_child(hook)
				hook.get_collider().add_child(hook)# TODO: don't scale by paren
				hook.global_transform.origin = hitpt
				hook.player.call("hook", hook.name)
				hook.enabled = false
				hook.visible = false

#	TimeLeft.text =  str(EnemySpawnTime.time_left)
#	for p in players:
#		

# Generate boxes using Simplex and Rngs with MY_SEED
func gen_boxes(my_seed: int) -> void:
	var noise := OpenSimplexNoise.new()
	noise.seed = my_seed
	noise.octaves = 4
	noise.period = 20
	noise.persistence = .8

	var rng := RandomNumberGenerator.new()
	rng.seed = my_seed
	var mat : SpatialMaterial = load("res://Gfx/Material/Rock1.tres").duplicate()
	mat.albedo_color -= Color(rng.randf(), rng.randf(), rng.randf()) / 10
	
	var static_box_s := load(rock_path)
	for x in range(-400, 400, 40):
		for z in range(-400, 400, 40):
			if (noise.get_noise_3d(x, x, z) > 0):
				var b : Spatial = static_box_s.instance()
				b.translation = Vector3(x, 64 + rng.randf() * 1000, z)
				b.rotation = Vector3(rng.randf(), rng.randf(), rng.randf()) * 2 * PI
				b.scale = Vector3(1, 1, 1) * rng.randf_range(8, 16)
				if rng.randf() > .5:
					b.get_node("Cube001").set_surface_material(0, mat)

				add_child(b)

func spawn_enemy(trans := Vector3.INF, velocity := Vector3.INF, target_name := "") -> void:
	var enemy: Enemy = enemies[enemy_i]
	enemy_i = (enemy_i + 1) % num_enemies
	# If enemy isn't already spawned in
	if !enemy.is_inside_tree():
		# Not syncing
		if trans == Vector3.INF:
			enemy.translation = Vector3(spawn_rng.randf(), .5 + spawn_rng.randf() / 16, spawn_rng.randf()) * 100
			enemy.set_target(players[spawn_rng.randi() % players.size()])
		# Called via rpc
		else:
			enemy.translation = trans
			enemy.vel = velocity
			enemy.set_target(get_node(target_name))

		call_deferred("add_child", enemy)

func _on_EnemySpawnTime_timeout():
	spawn_enemy()

# MULTIPLAYER STUFF --------------------------------------------

# Reqeuests current seed
func request_current_data() -> void:
	var latency_timer := Timer.new()
	get_node("/root").add_child(latency_timer)
	rpc("sen_seed")
	latency_timer.start(4)
	
	# When packet comes back, read latency
	yield(self, "received_data")
	latency = 4 - latency_timer.time_left

	# Now that we have latency (TODO: average latency rather than just
	# taking 1 sample), we can request the time 
	rpc("sen_time")

	# Cleanup timer
	latency_timer.queue_free()

# Sends seed and current enemies, should only be called on hosts
master func sen_seed() -> void:
	# Send seed and our current spawn timer's time
	var new_spawn_seed := randi() % 2048
	rpc("set_cur", TERRAIN_SEED, new_spawn_seed)
	spawn_rng.seed = new_spawn_seed


# Sends enemy spawn timer's time_left
master func sen_time() -> void:
	rpc("set_time", get_node(enemy_spawn_time).time_left)
	# Sync up all existing enemies
	for enemy in enemies:
		if enemy.is_inside_tree() and enemy.target:
			rpc("s", enemy.translation, enemy.vel, enemy.target.get_network_master())
	enemy_i = 0

puppet func s(master_translation: Vector3, velocity: Vector3, target_i : int) -> void:
	spawn_enemy(master_translation, velocity, str(target_i))

# Recieve current seeds, should only be called on non-host
puppet func set_cur(terrain_seed: int, spawn_seed: int) -> void:
	# To ensure only host sends it
	if get_tree().get_rpc_sender_id() == 1:
		emit_signal("received_data")
		spawn_rng.seed = spawn_seed
		gen_boxes(terrain_seed)

# Recieve current spawn_time, should only be called on non-host
puppet func set_time(spawn_time_left: float) -> void:
	# To ensure only host sends it
	if get_tree().get_rpc_sender_id() == 1:
		# Start spawn timer, must be positive amount mod 4
		var enemy_spawn: Timer = get_node(enemy_spawn_time)
		enemy_spawn.start(fposmod(spawn_time_left - latency, 4))
#		print("TIME RECEIVED: ", spawn_time_left - latency)
#		print("TIME SET: ", fposmod(spawn_time_left - latency, 4))
		
		# Reset wait_time (since timer should go back to 4 seconds)
		yield(enemy_spawn, "timeout")
		enemy_spawn.start(spawn_time)


# Spawn player with id PLAYER TODO: use get_rpc_sender_id to avoid hack
remote func spawn(id: int) -> void:
	var player: Spatial = player_s.instance()
	player.name = str(id)
	player.set_network_master(id, true)
	add_child(player)
	players.append(player)
	
	# Projectiles
	for __ in range(PROJ_PER_PLAYER):
		var p : Projectile = laser_s.instance()
		projectiles.append(p)
	num_lasers += PROJ_PER_PLAYER

	# Explosions
	for __ in range(EXP_PER_PLAYER):
		var e : Particles = exp_s.instance()
		explosions.append(e)
		add_child(e)
	num_explosions += EXP_PER_PLAYER

