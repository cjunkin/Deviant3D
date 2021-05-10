class_name WormBody
extends AI

func _ready():
	hp = 3
	add_to_group(G.WORM)
	add_to_group(G.ENEMY)

# Die
remotesync func d(particle_scale := 5.0) -> void:
	.d(particle_scale)



func _on_ShakeDetect_body_entered(_body: Spatial) -> void:
	Dust.emitting = true
	var player_dist := G.current_player.global_transform.origin.distance_to(global_transform.origin)
	G.current_player.Cam.add_stress(.5 / player_dist, .75)


func _on_ShakeDetect_body_exited(_body: Spatial) -> void:
	Dust.emitting = false
	var player_dist := G.current_player.global_transform.origin.distance_to(global_transform.origin)
	G.current_player.Cam.add_stress(.5 / player_dist, .75)

func toggle_particles(on := G.particles != G.OFF) -> void:
	.toggle_particles(on)
	Dust.emitting = false
