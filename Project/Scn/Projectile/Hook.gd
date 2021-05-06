class_name Hook
extends RayCast

var player: Spatial

# TODO: Optimize for DOTS and turning off physics process etc
func _physics_process(delta):
	if get_parent().get_class() == G.BASIC_ENEMY:
		var enemy = get_parent()
		enemy.vel += (player.global_transform.origin - enemy.global_transform.origin).normalized() * delta * 512
