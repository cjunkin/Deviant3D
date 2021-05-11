class_name Laser
extends Projectile

var rot := 0.0
onready var Ray := $Hitbox/Ray

func _on_Laser_body_entered(body: Spatial) -> void:
	if body.is_in_group(G.ENEMY):
		# Damage enemy TODO: only enable ray when we collide
		# FIXME: don't hardcode laser_dmg
		body.dmg(G.laser_dmg, self)
		
#		# Get a particle going
#		G.game.exp_i = (G.game.exp_i + 1) % G.game.num_particles
#		var e : Particles = G.game.particles[G.game.exp_i]
#		e.translation = translation
#		e.emitting = true
		
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Update score GUI
		if player == G.current_player:
			G.game.score()
	
	elif body is CSGBox or body is StaticBody:
		# Disable self
		set_deferred("monitoring", false)
		visible = false
	
	elif body is RigidBody:
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Push body
		body.apply_impulse(global_transform.origin - body.global_transform.origin, -50 * transform.basis.z)
	
	# RAFAEL ----
	
	# RAFAEL END ----


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
	
