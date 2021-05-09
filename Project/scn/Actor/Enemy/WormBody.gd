class_name WormBody
extends AI

func _ready():
	hp = 3
	add_to_group(G.WORM)
	add_to_group(G.ENEMY)

# Die
remotesync func d(particle_scale := 5.0) -> void:
	.d(particle_scale)

