class_name WormHead
extends AI

func _ready() -> void:
	add_to_group(G.WORM)
	add_to_group(G.ENEMY)
	G.game.update_boss_hp(hp)

func dmg(amt := 1, proj: Projectile = null) -> void:
	.dmg(amt, proj)
	G.game.update_boss_hp(hp)

remotesync func d(particle_scale := 7.0) -> void:
	get_parent().die()
	.d(particle_scale)

puppetsync func t(transl: Vector3) -> void:
	translation = transl

func _on_Timer_timeout():
	rpc("t", translation)

func _on_ShakeDetect_body_entered(body: Spatial) -> void:
	Dust.emitting = true
	var player_dist := G.current_player.global_transform.origin.distance_to(global_transform.origin)
	G.current_player.Cam.add_stress(1.0 / player_dist, .75)

func _on_ShakeDetect_body_exited(body: Spatial) -> void:
	Dust.emitting = false
	var player_dist := G.current_player.global_transform.origin.distance_to(global_transform.origin)
	G.current_player.Cam.add_stress(1.0 / player_dist, .75)

func toggle_particles(on := G.particles != G.OFF) -> void:
	.toggle_particles(on)
	Dust.emitting = false
