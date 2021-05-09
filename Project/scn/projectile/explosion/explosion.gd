class_name Explosion
extends Area



func _on_Expl_body_entered(body: Spatial):
#	print(body.name)
	if body.is_in_group(G.WORM):
		return
	var vec_btwn := body.global_transform.origin - global_transform.origin
	var distance := vec_btwn.length_squared()
	body.vel += vec_btwn / distance * 448.0

func play() -> void:
	$Anim.play("Explode")


func _on_Anim_animation_finished(anim_name):
	visible = false
	get_parent().remove_child(self)
