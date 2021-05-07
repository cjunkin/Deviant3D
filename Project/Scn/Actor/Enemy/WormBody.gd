class_name WormBody
extends KinematicBody

var hp := 4

func _ready():
	add_to_group(G.WORM_BODY)
	add_to_group(G.ENEMY)

# Damage
func dmg(_hitpoint := Vector3.ZERO, dmg := 1) -> void:
	hp -= dmg
	if hp <= 0:
		rpc("d")

# Die
remotesync func d() -> void:
	# Remove grappling hooks safely
	for child in get_children():
		if child is Hook:
			remove_child(child)
			child.player.call(child.name)
	
	# Particle
	G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
	var e : Particles = G.game.explosions[G.game.exp_i]
	e.translation = translation
	e.emitting = true
	e.scale = Vector3(5, 5, 5)
	
	# Die
	get_parent().remove_child(self)
