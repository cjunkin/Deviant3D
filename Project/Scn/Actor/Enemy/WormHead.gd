extends KinematicBody


func _ready() -> void:
	add_to_group(G.ENEMY)

func dmg(_pos: Vector3, amt := 1) -> void:
	rpc("d")

remotesync func d() -> void:
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
	
	get_parent().get_parent().remove_child(get_parent())
