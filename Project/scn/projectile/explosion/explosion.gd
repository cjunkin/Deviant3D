class_name Explosion
extends Area

export var dmg : int = 3

func _on_Expl_body_entered(body: Spatial):
	if body.is_in_group(G.WORM):
		return
	if body.is_in_group(G.ENEMY):
		# Damage enemy TODO: only enable ray when we collide
		body.dmg(dmg, self)
		
#		# Get a particle going
#		G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
#		var e : Particles = G.game.explosions[G.game.exp_i]
#		e.translation = translation
#		e.emitting = true
		
#		# Disable self
#		set_deferred("monitoring", false)
#		visible = false
		
#		# Update score GUI
#		if body == G.current_player:
#			G.game.score()


	var vec_btwn := body.global_transform.origin - global_transform.origin
	var distance := vec_btwn.length_squared()
	body.vel += vec_btwn / distance * 448.0

func play() -> void:
	$Anim.play("Explode")


func _on_Anim_animation_finished(anim_name):
	visible = false
	get_parent().remove_child(self)
