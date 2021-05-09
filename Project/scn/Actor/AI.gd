class_name AI
extends KinematicBody


var hp := 1
onready var Dust : Particles = get_node_or_null("Dust")

func _ready() -> void:
	toggle_particles()

func toggle_particles(on := G.particles != G.OFF) -> void:
	if Dust:
		Dust.visible = on
		Dust.emitting = on

# Damage
func dmg(proj: Projectile, amt := 1) -> void:
	hp -= amt
	if hp <= 0:
		rpc("d")

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




