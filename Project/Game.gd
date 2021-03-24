class_name Game
extends Spatial

# Num Cached TODO: make caches in C++ for efficiency
const num_projectiles := 42
const num_explosions := 8
#const num_laser_audio := 8
const num_grapple_sounds := 6

# Cached Arrays
var projectiles: Array = []
var proj_i : int = 0
var explosions: Array = []
var exp_i : int = 0
var players: Array = []

export(String, FILE) var rock_path

export (PackedScene) var player_s := preload("res://Scn/Actor/Player/Player.tscn")
# Only use this if num_proj isn't constant
#export (PackedScene) var proj_s := preload("res://Scn/Projectile.tscn")
#export (PackedScene) var exp_s := preload("res://Scn/Fx/Explosion.tscn")

var SEED : int

func _ready()->void:
	if G.hosted:
		randomize()
		SEED = randi() % 2048
		Network.register(get_tree().get_network_unique_id())
		gen_boxes(SEED)
	else:
		rpc("req_seed")

	G.game = self
	for __ in range(num_projectiles):
		var proj_s := load("res://Scn/Projectile.tscn")
		var p : Projectile = proj_s.instance()
		projectiles.append(p)
	for __ in range(num_explosions):
		var exp_s := load("res://Scn/Fx/Explosion.tscn")
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

func _physics_process(delta: float) -> void:
	for p in projectiles:
		if p.is_inside_tree():
			p.translation += p.speed * p.transform.basis.z * delta
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
	var static_box_s := load(rock_path)
	for x in range(-400, 400, 40):
		for z in range(-400, 400, 40):
			if (noise.get_noise_3d(x, x, z) > 0):
				var b : Spatial = static_box_s.instance()
				b.translation = Vector3(x, 64 + rng.randf() * 1000, z)
				b.rotation = Vector3(rng.randf(), rng.randf(), rng.randf()) * 2 * PI
				b.scale = Vector3(1, 1, 1) * rng.randf_range(8, 16)
				add_child(b)


# MULTIPLAYER STUFF --------------------------------------------

# Request seed, should only be called on hosts
remote func req_seed() -> void:
	rpc("set_seed", SEED)

# Send seed, should only be called on non-host
remote func set_seed(s: int) -> void:
	# To ensure only host sends it
	if get_tree().get_rpc_sender_id() == 1:
		gen_boxes(s)

# Spawn player with id PLAYER TODO: use get_rpc_sender_id to avoid hack
remote func spawn(id: int) -> void:
	var p: Spatial = player_s.instance()
	p.name = str(id)
	p.set_network_master(id, true)
	add_child(p)
	players.append(p)
