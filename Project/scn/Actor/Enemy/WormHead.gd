class_name WormHead
extends AI

func _ready() -> void:
	hp = 20
	add_to_group(G.WORM)
	add_to_group(G.ENEMY)
	G.game.update_boss_hp(hp)

func dmg(proj: Projectile, amt := 1) -> void:
	.dmg(proj, amt)
	G.game.update_boss_hp(hp)

remotesync func d(particle_scale := 7.0) -> void:
	get_parent().die()
	.d(particle_scale)

puppetsync func t(transl: Vector3) -> void:
	translation = transl

func _on_Timer_timeout():
	rpc("t", translation)
