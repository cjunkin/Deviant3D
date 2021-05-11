class_name Arrow
extends Enemy

var final_speed := 8.0
var final_fric := 0.75

# TODO: make better
func _physics_process(delta):
	speed = lerp(speed, final_speed, .1)
	friction = lerp(friction, final_fric, .1)

func _ready():
	set_flying(true)

puppet func set_flying(on := true) -> void:
	flying = on

func _on_Speedup_timeout():
	if final_speed == 1.0:
		final_speed = 2.0
		final_fric = 2.0
		$Mesh.material_override.emission = Color("8651b5")
	else:
#		final_speed = 3.0
#		final_fric = 2.0
		final_speed = 1.0
		final_fric = .5
		$Mesh.material_override.emission = Color("633d85")
