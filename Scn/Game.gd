class_name Game
extends Spatial

const num_projectiles := 64
const num_explosions := 32

export (PackedScene) var proj_s = preload("res://Scn/Projectile.tscn")
export (PackedScene) var exp_s = preload("res://Scn/Fx/Explosion.tscn")

var projectiles: Array = []
var explosions: Array = []
var proj_i : int = 0
var exp_i : int = 0

func _ready()->void:
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
