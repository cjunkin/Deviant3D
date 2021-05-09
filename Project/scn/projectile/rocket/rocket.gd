class_name Rocket
extends Laser

var expl := preload("res://scn/projectile/explosion/explosion.tscn").instance()

func _on_Laser_body_entered(body: Spatial) -> void:
	if expl.is_inside_tree():
		expl.get_parent().remove_child(expl)
	._on_Laser_body_entered(body)
	get_tree().get_root().add_child(expl)
	expl.transform.origin = Ray.get_collision_point()
	expl.visible = true
	expl.play()
#	print(expl.global_transform.origin)
	G.current_player.Cam.add_stress(20.0 / 
		global_transform.origin.distance_to(
			G.current_player.global_transform.origin
		),
		.85
	)
	
	
	
