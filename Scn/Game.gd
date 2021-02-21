class_name Game
extends Spatial

const num_projectiles := 96
const num_explosions := 32
#const num_laser_shots := 8

export (PackedScene) var player_s := preload("res://Scn/Player/Player.tscn")
export (PackedScene) var proj_s := preload("res://Scn/Projectile.tscn")
export (PackedScene) var exp_s := preload("res://Scn/Fx/Explosion.tscn")

var projectiles: Array = []
var explosions: Array = []
var proj_i : int = 0
var exp_i : int = 0

func _ready()->void:
	if Global.hosted:
		Network.register(get_tree().get_network_unique_id())
	Global.game = self
	for __ in range(num_projectiles):
		var p : Projectile = proj_s.instance()
		projectiles.append(p)
	for __ in range(num_explosions):
		var e : Particles = exp_s.instance()
		explosions.append(e)
		add_child(e)

func _physics_process(delta: float) -> void:
	for p in projectiles:
		p.translation += p.speed * p.transform.basis.z * delta

# MULTIPLAYER STUFF --------------------------------------------

remote func spawn(id: int) -> void:
	var p: Player = player_s.instance()
	p.name = str(id)
	p.set_network_master(id, true)
	add_child(p)
