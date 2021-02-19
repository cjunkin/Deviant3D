class_name Projectile
extends Area

export var speed := -64


func _on_Timer_timeout() -> void:
	get_parent().remove_child(self)


func _on_Proj_body_entered(body) -> void:
	if body is RigidBody:
		set_deferred("monitoring", false)
#		set_collision_mask_bit(0, false)
		visible = false
		body.apply_impulse(global_transform.origin - body.global_transform.origin, -500 * transform.basis.z)
#		get_parent().remove_child(self)
	elif body.is_in_group("Enemy"):
		set_deferred("monitoring", false)
#		set_collision_mask_bit(0, false)
		visible = false
		Global.game.exp_i = (Global.game.exp_i + 1) % Global.game.num_explosions
		var e : Particles = Global.game.explosions[Global.game.exp_i]
		e.translation = translation
		e.emitting = true

		body.queue_free()
#		get_parent().remove_child(self)
