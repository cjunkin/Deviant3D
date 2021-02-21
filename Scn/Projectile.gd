class_name Projectile
extends Area

export var speed := -64


func _on_Timer_timeout() -> void:
	get_parent().remove_child(self)


func _on_Proj_body_entered(body) -> void:
	if body is RigidBody:
		
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Push body
		body.apply_impulse(global_transform.origin - body.global_transform.origin, -500 * transform.basis.z)
		
	elif body.is_in_group("Enemy"):
		
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Get a particle going
		Global.game.exp_i = (Global.game.exp_i + 1) % Global.game.num_explosions
		var e : Particles = Global.game.explosions[Global.game.exp_i]
		e.translation = translation
		e.emitting = true
		
		# Kill enemy
		body.queue_free()

