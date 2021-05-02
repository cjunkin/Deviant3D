extends Projectile

var rot := .05

func _on_Laser_body_entered(body) -> void:
	if body.is_in_group(G.ENEMY):
		# Damage enemy
		body.dmg(global_transform.origin)
		
#		# Get a particle going
#		G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
#		var e : Particles = G.game.explosions[G.game.exp_i]
#		e.translation = translation
#		e.emitting = true
		
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Update score GUI
		if player == G.current_player:
			G.game.score()

	elif body is RigidBody:
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Push body
		body.apply_impulse(global_transform.origin - body.global_transform.origin, -50 * transform.basis.z)

	elif body is CSGBox or body is StaticBody:
		# Disable self
		set_deferred("monitoring", false)
		visible = false


#func _on_Laser_area_entered(area: Area) -> void:
##	print(area.name)
#	# For worm TODO: rpc damage
#	area.get_parent().dmg()
#
#	# Disable self
#	set_deferred("monitoring", false)
#	visible = false
#
#	# Update score GUI
#	if player == G.current_player:
#		G.game.score()
	
