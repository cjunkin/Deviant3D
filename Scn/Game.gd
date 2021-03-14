class_name Game
extends Spatial

const num_projectiles := 32
const num_explosions := 32
#const num_laser_audio := 8

export (PackedScene) var player_s := preload("res://Scn/Actor/Player/Player.tscn")
export (PackedScene) var proj_s := preload("res://Scn/Projectile.tscn")
export (PackedScene) var exp_s := preload("res://Scn/Fx/Explosion.tscn")

var projectiles: Array = []
var explosions: Array = []
var proj_i : int = 0
var exp_i : int = 0
var players: Array = []

func _ready()->void:
	if G.hosted:
		Network.register(get_tree().get_network_unique_id())
	G.game = self
	for __ in range(num_projectiles):
		var p : Projectile = proj_s.instance()
		projectiles.append(p)
	for __ in range(num_explosions):
		var e : Particles = exp_s.instance()
		explosions.append(e)
		add_child(e)
	$Enemy.set_target(players[0])
	$Enemy2.set_target(players[0])
	$Enemy3.set_target(players[0])
	$Enemy4.set_target(players[0])

func set_hinge(body):
	var h: HingeJoint = $HingeJoint
	h.set_node_b(body.get_path())
	print("set")
#	h.set("nodes:node_a", body)

func _physics_process(delta: float) -> void:
	for p in projectiles:
		if p.is_inside_tree():
			p.translation += p.speed * p.transform.basis.z * delta
#	for p in players:
		

# MULTIPLAYER STUFF --------------------------------------------

remote func spawn(id: int) -> void:
	var p: Player = player_s.instance()
	p.name = str(id)
	p.set_network_master(id, true)
	add_child(p)
	players.append(p)
