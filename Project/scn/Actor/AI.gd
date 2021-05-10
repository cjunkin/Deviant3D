class_name AI
extends KinematicBody

export var MAX_HP := 1
var hp := MAX_HP
var sync_timer: Timer
onready var Dust : Particles = get_node_or_null("Dust")

func _ready() -> void:
	if G.game.is_network_master():
#		print("Syncing")
		sync_timer = Timer.new()
		sync_timer.connect("timeout", self, "sync_self")
		sync_timer.wait_time = 10.0
		sync_timer.one_shot = false
		add_child(sync_timer)
		sync_timer.start()
	else:
		rpc_id(1, "req_syn")
	hp = MAX_HP
	toggle_particles()

func toggle_particles(on := G.particles != G.OFF) -> void:
	if Dust:
		Dust.visible = on
		Dust.emitting = on

# Damage
func dmg(amt := 1, _proj: Projectile = null) -> void:
	hp -= amt
	if hp <= 0:
		rpc("d")

func sync_self() -> void:
	rpc("t", translation)


# MULTIPLAYER STUFF --------------------------------------------

# Die
remotesync func d(particle_scale := 1.0) -> void:
	set_deferred("monitoring", false)

	# Remove grappling hooks safely
	for child in get_children():
		if child is Hook:
			remove_child(child)
			child.player.call(child.name)

	# Particle
	G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
	var e : Particles = G.game.explosions[G.game.exp_i]
	e.translation = translation
	e.scale = Vector3.ONE * particle_scale
	e.emitting = true

	# Remove self
	get_parent().remove_child(self)


puppet func t(transl: Vector3) -> void:
	translation = transl

master func req_syn() -> void:
	sync_self()

