class_name Arrowhead
extends Enemy


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
puppet func set_flying(on := true) -> void:
	flying = true
	
	var mat := load("res://Gfx/Material/grid.material")
	$Mesh.material_override = mat
	mat = load("res://Gfx/Material/laser.material")
	Dust.material_override = mat


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	if speed == 1:
		speed = 9
	elif speed == 0:
		speed = 0
	else:
		speed = 1


func _on_Respawn_timeout():
	G.game.spawn_arrowhead(1)
