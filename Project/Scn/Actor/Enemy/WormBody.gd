extends KinematicBody

var hp := 4

func _ready():
	add_to_group(G.WORM_BODY)

# Damage
remotesync func d(dmg := 1) -> void:
	hp -= dmg
	if hp <= 0:
		
		# Particle
		G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
		var e : Particles = G.game.explosions[G.game.exp_i]
		e.translation = translation
		e.emitting = true
		e.scale = Vector3(5, 5, 5)
		
		# Remove grappling hooks safely
		for child in get_children():
			if child is Hook:
				remove_child(child)
				child.player.call(child.name)
		
		# Die
		get_parent().remove_child(self)
