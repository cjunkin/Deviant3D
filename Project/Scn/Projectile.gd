class_name Projectile
extends Area

export var speed := -128
onready var timer := $Timer

func _on_Timer_timeout() -> void:
	get_parent().remove_child(self)


func _on_Proj_body_entered(body) -> void:
	if body is RigidBody:
		
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Push body
		body.apply_impulse(global_transform.origin - body.global_transform.origin, -50 * transform.basis.z)
		
	elif body.is_in_group("Enemy"):
		
		# Disable self
		set_deferred("monitoring", false)
		visible = false
		
		# Get a particle going
		G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
		var e : Particles = G.game.explosions[G.game.exp_i]
		e.translation = translation
		e.emitting = true
		
		# Kill enemy
		body.queue_free()

