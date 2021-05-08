extends KinematicBody

var hp := 20

func _ready() -> void:
	add_to_group(G.ENEMY)
	G.game.update_boss_hp(hp)

func dmg(_pos: Vector3, amt := 1) -> void:
	hp -= 1
	G.game.update_boss_hp(hp)
	if hp <= 0:
		rpc("d")

remotesync func d() -> void:
	# Particle
	G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
	var e : Particles = G.game.explosions[G.game.exp_i]
	e.translation = translation
	e.emitting = true
	e.scale = Vector3(6, 6, 6)
	
	get_parent().die()
	
	# Remove grappling hooks safely
	for child in get_children():
		if child is Hook:
			remove_child(child)
			child.player.call(child.name)
	
	get_parent().remove_child(self)

puppetsync func t(transl: Vector3) -> void:
	translation = transl


func _on_Timer_timeout():
	rpc("t", translation)
